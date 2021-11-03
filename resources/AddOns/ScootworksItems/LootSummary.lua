local ScootworksItems = SCOOTWORKS_ITEMS

local LOOT_SUMMARY_NAME = "ScootworksItemsLootSummary"

local logger = ScootworksItems.logger
local chat = ScootworksItems.chat
local LibItemLink = LIB_ITEM_LINK

local ReplaceLinkStyle = LibItemLink.ReplaceLinkStyle
local GetGameTimeMilliseconds, GetItemLinkSetInfo = GetGameTimeMilliseconds, GetItemLinkSetInfo
local zo_iconFormat, zo_iconTextFormat = zo_iconFormat, zo_iconTextFormat
local concat = table.concat
local sort = table.sort
local tostring = tostring
local zo_max = zo_max
local ipairs = ipairs
local pairs = pairs
local stringFormat = string.format

local IS_UPDATING, FORCE_RESET = true, true
local DEFAULT_REFRESH_TIME_MILLISCONDS = 600
local UPDATE_TIME_MILLISECONDS = 2000

local COLLECTION_ICON = zo_iconFormat("EsoUI/Art/Collections/collections_tabIcon_itemSets_down.dds", "120%", "120%")


----------------------------------


local Updater = ZO_InitializingObject:Subclass()

local function IsCollectionIconEnabled()
	return ScootworksItems.sv.trackLoot.setCollectionIcon
end

local function IsTraitNameEnabled()
	return ScootworksItems.sv.trackLoot.enableTraitName
end

local function AppendBracketsToLink(itemLink)
	return ReplaceLinkStyle(LibItemLink, itemLink, LINK_STYLE_BRACKETS)
end

local function SortQuality(list)
	sort(list, function(left, right)
		if left.quality == right.quality then
			return left.itemName < right.itemName
		else
			return left.quality < right.quality
		end
	end)
end

local function IsSetItemNotCollected(itemLink)
	if not IsItemLinkSetCollectionPiece(itemLink) then
		return nil
	end
	local setId = select(6, GetItemLinkSetInfo(itemLink, false))
	local slot = GetItemLinkItemSetCollectionSlot(itemLink)
	return not IsItemSetCollectionSlotUnlocked(setId, slot)
end

local function GetTraitTypeFormatted(itemLink)
	if GetItemLinkEquipType(itemLink) ~= EQUIP_TYPE_INVALID then
		local traitType = GetItemLinkTraitInfo(itemLink)
		return GetString("SI_ITEMTRAITTYPE", traitType)
	end
	return nil
end

local function GetItemIconAndName(itemLink)
	return zo_iconTextFormat(GetItemLinkIcon(itemLink), "100%", "100%", itemLink)
end

local function GetItemNameCountString(itemNameFormatted, quantity)
	if quantity and quantity > 1 then
		local countString = ZO_CachedStrFormat(SI_HOOK_POINT_STORE_REPAIR_KIT_COUNT, quantity)
		return stringFormat("%s %s", itemNameFormatted, countString)
	end
	return itemNameFormatted
end

local function AddToLootList(lootList, hashId, itemLink, quantity)
	local data =
	{
		itemLink = AppendBracketsToLink(itemLink),
		itemName = GetItemLinkName(itemLink),
		quantity = quantity,
		quality = GetItemLinkQuality(itemLink),
		trait = GetTraitTypeFormatted(itemLink),
	}
	lootList[hashId] = data
end

local nextId = 0
function Updater:Initialize(unitTag, prefix)
	nextId = nextId + 1 -- create a unique key
	local namespace = LOOT_SUMMARY_NAME .. nextId .. unitTag
	self.name = namespace
	self.task = LibAsync:Create(namespace)

	self.lootList = { }

	self:SetPrefix(prefix)
	self:SetLastTimeLootReceived()
	self:SetUpdatingState()
end

function Updater:AddItemLink(itemLink, quantity)
	local hashId = HashString(itemLink)
	local item = self.lootList[hashId]
	if not item then
		AddToLootList(self.lootList, hashId, itemLink, quantity)
	else
		item.quantity = item.quantity + quantity
	end
end

function Updater:SetPrefix(prefix)
	self.prefix = prefix
	logger:Debug("%s new prefix: %s", self.name, prefix or "nil")
end

function Updater:SetUpdatingState(bool)
	self.isUpdating = bool or not IS_UPDATING
end

function Updater:SetLastTimeLootReceived()
	self.lastTimeLootReceived = GetGameTimeMilliseconds()
end

function Updater:GetItemString(data)
	local itemLink = data.itemLink
	local itemString = GetItemIconAndName(itemLink)

	local itemTrait = data.trait
	if IsTraitNameEnabled() and itemTrait then
		itemString = ZO_CachedStrFormat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2, itemString, itemTrait)
	end
	if IsCollectionIconEnabled() and IsSetItemNotCollected(itemLink) then
		itemString = ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_CHAT_ITEM_COLLECTOR, itemString, COLLECTION_ICON)
	end
	return GetItemNameCountString(itemString, data.quantity)
end

function Updater:GetLastLootReceived()
	return self.lastTimeLootReceived
end

function Updater:IsEqualPrefix(prefix)
	return self.prefix == prefix
end

function Updater:IsUpdating()
	return self.isUpdating
end

function Updater:IsBelowLastReceivedThreshold(currentTime)
	return currentTime < self:GetLastLootReceived() + UPDATE_TIME_MILLISECONDS
end

function Updater:RegisterForUpdate()
	if self:IsUpdating() then return end

	self.task:Call(function(task)
		logger:Verbose("%s - RegisterForUpdate", self.name)
		EVENT_MANAGER:RegisterForUpdate(self.name, UPDATE_TIME_MILLISECONDS, function(currentTime)
			task:Call(function()
				if not self:IsBelowLastReceivedThreshold(currentTime) then
					self:Print()
				end
			end)
		end)
	end)
end

function Updater:UnregisterForUpdate()
	EVENT_MANAGER:UnregisterForUpdate(self.name)
	self:SetUpdatingState(not IS_UPDATING)
	logger:Verbose("%s - UnregisterForUpdate", self.name)
end

function Updater:Print()
	self.task:Call(function()
		self:SetUpdatingState(IS_UPDATING)
	end):Then(function()
		SortQuality(self.lootList)
	end):Then(function()
		local itemStrings = { }
		for itemLink, itemData in pairs(self.lootList) do
			itemStrings[#itemStrings + 1] = self:GetItemString(itemData)
			self.lootList[itemLink] = nil
		end
		chat:Print(self.prefix .. concat(itemStrings, ", "))
	end):Then(function()
		self:UnregisterForUpdate()
	end)
end

----------------------------------


ScootworksItemsLootSummary = ZO_InitializingObject:Subclass()

function ScootworksItemsLootSummary:Initialize(unitTag, preventOverwritePrefix)
	self.unitList = { }
	self.preventOverwritePrefix = preventOverwritePrefix
	if unitTag then
		self:CreateOrUpdateUnit(unitTag)
	end
end


function ScootworksItemsLootSummary:GetUnitTagUpdater(unitTag)
	return self.unitList[unitTag]
end

function ScootworksItemsLootSummary:SetPrefix(unitTag, prefix)
	self.unitList[unitTag]:SetPrefix(prefix)
	logger:Info("'%s' prefix changed to '%s'", unitTag, prefix)
end

function ScootworksItemsLootSummary:CreateOrUpdateUnit(unitTag)
	if unitTag then
		local unitTagUpdater = self:GetUnitTagUpdater(unitTag)

		-- create if not exists
		if unitTagUpdater == nil then
			self.unitList[unitTag] = Updater:New(unitTag)
			unitTagUpdater = self.unitList[unitTag]
			logger:Info("unit '%s' created", unitTag)
		end

		-- change characterName if not equal
		if not self.preventOverwritePrefix then
			local userTag = ZO_ShouldPreferUserId() and GetUnitDisplayName(unitTag) or GetUnitName(unitTag)
			local prefix = ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_CHAT_LOOT_RECEIVED, userTag)
			if not unitTagUpdater:IsEqualPrefix(prefix) then
				unitTagUpdater:SetPrefix(prefix)
			end
		end

		return unitTagUpdater
	end
end

do
	local function GetUnitTagFromCharacterName(rawCharacterName)
		local unitName = ZO_CachedStrFormat(SI_UNIT_NAME, rawCharacterName)
		for _, data in ipairs(GROUP_LIST_MANAGER.masterList) do
			if unitName == ZO_CachedStrFormat(SI_UNIT_NAME, data.rawCharacterName) then
				return data.unitTag
			end
		end
		return nil
	end

	local function GetDisplayAndCharacterName(unitTagOrReceivedBy)
		if unitTagOrReceivedBy == "player" then
			return unitTagOrReceivedBy
		else
			return GetUnitTagFromCharacterName(unitTagOrReceivedBy)
		end
	end

	function ScootworksItemsLootSummary:AddItem(itemLink, quantity, unitTagOrReceivedBy)
		local unitTag = GetDisplayAndCharacterName(unitTagOrReceivedBy)
		if unitTag then
			local unitTagUpdater = self:CreateOrUpdateUnit(unitTag)
			unitTagUpdater:AddItemLink(itemLink, quantity)
			unitTagUpdater:SetLastTimeLootReceived()
			unitTagUpdater:RegisterForUpdate()
		else
			logger:Warn("no unit '%s' found", unitTagOrReceivedBy)
		end
	end
end