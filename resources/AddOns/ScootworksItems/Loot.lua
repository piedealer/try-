local ADDON_NAME = "ScootworksItems"

local EM = GetEventManager()
local LLS = LibLootSummary

local GetGameTimeMilliseconds = GetGameTimeMilliseconds

local USE_INTERNAL_FORMAT, IS_JUNK, IS_NEW_ITEM = true, true, true
local NO_UNIT_TAG, NO_PLAYER_NAME = nil, nil

local PLAYER_UNIT_TAG = "player"
local PLAYER_JUNK = "junk"

local LOOT_REFRESH_TIMER = 500
local LOOT_REFRESH_TIMER_SLOW = 2000

local ITEMS_WHITELIST =
{
	[56862] = true, -- Fortified Nirncrux
	[56863] = true, -- Potent Nirncrux
	[64222] = true, -- Perfect Roe
	[68342] = true, -- Hakeijo
	[139019] = true, -- Powdered Mother of Pearl
}

local TRACK_LOOT_QUALITY =
{
	[ITEM_QUALITY_ARTIFACT] = true,
	[ITEM_QUALITY_LEGENDARY] = true,
}

local ITEMTYPE_BOOSTERS =
{
	[ITEMTYPE_BLACKSMITHING_BOOSTER] = true,
	[ITEMTYPE_CLOTHIER_BOOSTER] = true,
	[ITEMTYPE_ENCHANTMENT_BOOSTER] = true,
	[ITEMTYPE_ENCHANTING_RUNE_ASPECT] = true,
	[ITEMTYPE_JEWELRYCRAFTING_BOOSTER] = true,
	[ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER] = true,
	[ITEMTYPE_WEAPON_BOOSTER] = true,
	[ITEMTYPE_WOODWORKING_BOOSTER] = true,
}

local function IsJunkFoodOrDrink(itemType, itemLink, quality)
	if quality == ITEM_QUALITY_NORMAL or quality == ITEM_QUALITY_TRASH then
		if itemType == ITEMTYPE_FOOD or itemType == ITEMTYPE_DRINK then
			return true
		end
	end
	return false
end

local function IsOrnateItem(itemTraitInformation)
	if itemTraitInformation == ITEM_TRAIT_INFORMATION_ORNATE then
		return true
	end
	return false
end

local function IsJewelery(equipType)
	return equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING
end

local function IsNotMonsterHeadOrShoulder(equipType, maxEquipped)
	if (equipType == EQUIP_TYPE_HEAD or equipType == EQUIP_TYPE_SHOULDERS) and maxEquipped > 2 then
		return true
	end
	return false
end

local function IsUnwantedSet(setId)
	return ScootworksItems_GetSettingSetId(setId)
end

local function GetPlayerNames(receivedBy)
	local masterList = GROUP_LIST_MANAGER.masterList
	local receivedCharacterName = ZO_CachedStrFormat(SI_UNIT_NAME, receivedBy)

	local characterName
	for i = 1, #masterList do
		characterName = ZO_CachedStrFormat(SI_UNIT_NAME, masterList[i].characterName)
		if characterName == receivedCharacterName then
			return characterName, ZO_CachedStrFormat(SI_UNIT_NAME, masterList[i].displayName), masterList[i].unitTag
		end
	end
	return receivedBy, NO_PLAYER_NAME, NO_UNIT_TAG
end

local function GetReceivedName(receivedBy)
	if receivedBy == nil then
		return GetString(SI_TARGETTYPE2), PLAYER_UNIT_TAG
	end

	local characterName, displayName, unitTag = GetPlayerNames(receivedBy)
	if displayName then
		return ZO_LinkHandler_CreatePlayerLink(ZO_GetPrimaryPlayerName(displayName, characterName, USE_INTERNAL_FORMAT)), unitTag
	end
	return receivedBy, NO_UNIT_TAG
end

local function IsColdFireSiege(itemLink)
	if GetItemLinkItemType(itemLink) == ITEMTYPE_SIEGE then
		if string.match(GetItemLinkInfo(itemLink), "bluefire") then
			return true
		end
	end
	return false
end

local function IsItemWorthToDisplay(itemLink, itemId)
	itemId = itemId or GetItemLinkItemId(itemLink)
	if ITEMS_WHITELIST[itemId] then
		return true
	elseif GetItemLinkSetInfo(itemLink) then
		return true
	elseif ITEMTYPE_BOOSTERS[GetItemLinkItemType(itemLink)] and GetItemLinkQuality(itemLink) == ITEM_QUALITY_LEGENDARY then
		return true
	end
	return false
end

local function GetSubSetting(subSetting)
	return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, subSetting)
end


-- ScootworksItemsLoot
----------------------
ScootworksItemsLoot = ZO_Object:Subclass()

function ScootworksItemsLoot:New(chat)
	local loot = ZO_Object.New(self)
	if loot then
		loot:EventHandler()

		loot.chat = chat

		loot.isLootReceivedCollecting = false
		loot.timeLastLootReceived = 0
		loot.refreshTimer = LOOT_REFRESH_TIMER

		loot.lootReceivedList = { }
		loot.junkReceivedList = { }
	end
	return loot
end

function ScootworksItemsLoot:IsItemLinkJunk(itemLink)
	local icon, _, _, equipType, itemStyleId = GetItemLinkInfo(itemLink)
	local itemType, specializedItemType = GetItemLinkItemType(itemLink)
	local hasSet, _, _, _, maxEquipped, setId = GetItemLinkSetInfo(itemLink)
	local isOrnateItemTrait = IsOrnateItem(GetItemTraitInformationFromItemLink(itemLink))
	local quality = GetItemLinkQuality(itemLink)
	local isJewelery = IsJewelery(equipType)
	local isWeapon = itemType == ITEMTYPE_WEAPON
	local isArmor = itemType == ITEMTYPE_ARMOR

	local itemIsJunk = false

	if isJewelery and isOrnateItemTrait then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_JEWELERY) then itemIsJunk = true end
	elseif isArmor and isOrnateItemTrait then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_ARMOR) then itemIsJunk = true end
	elseif isWeapon and isOrnateItemTrait then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_WEAPON) then itemIsJunk = true end
	elseif itemType == ITEMTYPE_TRASH or IsJunkFoodOrDrink(itemType, itemLink, quality) then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TRASH) then itemIsJunk = true end
	elseif itemType == ITEMTYPE_COLLECTIBLE and specializedItemType == SPECIALIZED_ITEMTYPE_COLLECTIBLE_MONSTER_TROPHY then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TROPHY) then itemIsJunk = true end
	elseif itemType == ITEMTYPE_COLLECTIBLE and specializedItemType == SPECIALIZED_ITEMTYPE_COLLECTIBLE_RARE_FISH then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_RAREFISH) then itemIsJunk = true end
	elseif itemType == ITEMTYPE_TREASURE and specializedItemType == SPECIALIZED_ITEMTYPE_TREASURE then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TREASURE) then itemIsJunk = true end
	elseif itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_JEWELRY or itemType == ITEMTYPE_GLYPH_WEAPON then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_GLYPHE) then itemIsJunk = true end
	elseif itemType == ITEMTYPE_POTION and quality <= ITEM_QUALITY_MAGIC then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_POTION) then itemIsJunk = true end
	elseif itemType == ITEMTYPE_POISON and quality <= ITEM_QUALITY_MAGIC then
		if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_POISON) then itemIsJunk = true end
	elseif hasSet then
		if IsNotMonsterHeadOrShoulder(equipType, maxEquipped) then
			if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_HEAD_AND_SHOULDER) then itemIsJunk = true end
		elseif IsUnwantedSet(setId) then
			itemIsJunk = true
		end
	elseif not hasSet then
		if isWeapon then
			if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_WEAPON) then itemIsJunk = true end
		elseif isArmor then
			if isJewelery then
				if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_JEWELERY) then itemIsJunk = true end
			else
				if GetSubSetting(SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_APPAREL) then itemIsJunk = true end
			end
		end
	end

	return itemIsJunk
end

function ScootworksItemsLoot:StartUpdate()
	self.isLootReceivedCollecting = true
	EM:RegisterForUpdate(ADDON_NAME.."OnLootReceivedUpdate", self.refreshTimer, function() self:PrintLootReceived() end)
end

function ScootworksItemsLoot:EndUpdate()
	EM:UnregisterForUpdate(ADDON_NAME.."OnLootReceivedUpdate")
	self.isLootReceivedCollecting = false
end

function ScootworksItemsLoot:PrintLootReceived()
	local updatedThreshold = GetGameTimeMilliseconds() - self.timeLastLootReceived
	if self.isLootReceivedCollecting and updatedThreshold < self.refreshTimer then
		return
	end

	-- Tr�del
	if self.junkReceivedList.itemList then
		self.junkReceivedList:Print()
	end

	-- Loot
	for _, receivedBy in pairs(self.lootReceivedList) do
		receivedBy:Print()
	end

	self:EndUpdate()
end

function ScootworksItemsLoot:AddNewLootSummary(prefix, unitTag)
	local summary

	local defaults =
	{
		chat = self.chat,
		hideSingularQuantities = true,
		sortedByQuality = true,
		showTrait = true,
		delimiter = ", ",
		showIcon = true,
		iconSize = 100,
		linkStyle = LINK_STYLE_BRACKETS,
		prefix = prefix,
	}

	if unitTag then
		self.lootReceivedList[unitTag] = LLS:New( defaults )
		summary = self.lootReceivedList[unitTag]
	else
		self.junkReceivedList = LLS:New( defaults )
		summary = self.junkReceivedList
	end
end

function ScootworksItemsLoot:AddItemToLootList(receivedBy, quantity, itemLink, unitTag)
	self.timeLastLootReceived = GetGameTimeMilliseconds()

	if not self.isLootReceivedCollecting then
		self:StartUpdate()
	end

	if self.isLootReceivedCollecting then
		if receivedBy == PLAYER_JUNK then
			if next(self.junkReceivedList) == nil then
				self:AddNewLootSummary(ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_MARKED_AS_JUNK))
			end
			self.junkReceivedList:AddItemLink(itemLink, quantity)
		else
			if self.lootReceivedList[unitTag] == nil then
				self:AddNewLootSummary(ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_LOOT_RECEIVED, receivedBy), unitTag)
				self.lootReceivedList[unitTag].lastUnitName = receivedBy
			end
			if self.lootReceivedList[unitTag].lastUnitName ~= receivedBy then
				self.lootReceivedList[unitTag]:SetPrefix(ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_LOOT_RECEIVED, receivedBy))
				self.lootReceivedList[unitTag].lastUnitName = receivedBy
			end
			self.lootReceivedList[unitTag]:AddItemLink(itemLink, quantity)
		end
	end
end

function ScootworksItemsLoot:OnLootReceived(_, receivedBy, itemLink, quantity, _, lootType, player, _, _, itemId)
	if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ENABLED) and lootType == LOOT_TYPE_ITEM then
		if IsColdFireSiege(itemLink) or not player then
			if IsItemWorthToDisplay(itemLink, itemId) then
				local receivedPlayerName, unitTag = GetReceivedName(receivedBy)
				self:AddItemToLootList(receivedPlayerName, quantity, itemLink, unitTag)
			end
		end
	end
end

function ScootworksItemsLoot:OnInventorySingleSlotUpdate(_, bagId, slotId, isNewItem, _, inventoryUpdateReason, stackCountChange)
	if stackCountChange == nil then
		stackCountChange = GetSlotStackSize(bagId, slotId)
	end

	local itemLink = GetItemLink(bagId, slotId, LINK_STYLE_BRACKETS)
	if not IsItemLinkCrafted(itemLink) then
		if self:IsItemLinkJunk(itemLink) and not IsItemPlayerLocked(bagId, slotId) and ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) then
			SetItemIsJunk(bagId, slotId, IS_JUNK)
			if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MESSAGE) then
				self:AddItemToLootList("junk", stackCountChange, itemLink, NO_UNIT_TAG)
			end
		elseif isNewItem and IsItemWorthToDisplay(itemLink) then
			if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ENABLED) then
				local isInGroup = self:IsPlayerGrouped()
				if self:ShowPlayerItemsOnlyInGroup(isInGroup) or self:HidePlayerItemsInGroup(isInGroup) then
					return
				end
				local receivedPlayerName, unitTag = GetReceivedName()
				self:AddItemToLootList(receivedPlayerName, stackCountChange, itemLink, unitTag)
			end
		end
	end
end

function ScootworksItemsLoot:IsPlayerGrouped()
	return IsUnitGrouped(PLAYER_UNIT_TAG) == true
end

function ScootworksItemsLoot:HidePlayerItemsInGroup(isInGroup)
	return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_HIDE_PLAYER_ITEMS) and isInGroup
end

function ScootworksItemsLoot:ShowPlayerItemsOnlyInGroup(isInGroup)
	return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ONLY_IN_GROUP) and not isInGroup
end

function ScootworksItemsLoot:OnInventoryItemUsed(_, itemSoundCategory)
	-- Handwerksboxen werden mit ITEM_SOUND_CATEGORY_FOOTLOCKER geöffnet, z.B. via Unboxer oder Lazy Writ Crafting.
	-- Diese haben entsprechend eine Verzögerung, welche wir mit einem erhöhten UpdateTimer probieren zu umgehen.
	if itemSoundCategory == ITEM_SOUND_CATEGORY_FOOTLOCKER then
		self.refreshTimer = LOOT_REFRESH_TIMER_SLOW
	else
		self.refreshTimer = LOOT_REFRESH_TIMER
	end
end

function ScootworksItemsLoot:ScanBagForJunk()
	for slotIndex in ZO_IterateBagSlots(BAG_BACKPACK) do
		-- Nur noch nicht als Trödel markierte Gegenstände werden abgesucht.
		if not IsItemJunk(BAG_BACKPACK, slotIndex) then
			self:OnInventorySingleSlotUpdate(nil, BAG_BACKPACK, slotIndex, not IS_NEW_ITEM)
		end
	end
end

function ScootworksItemsLoot:RegisterEvents()
	EM:RegisterForEvent(ADDON_NAME, EVENT_LOOT_RECEIVED, function(...) self:OnLootReceived(...) end)
	EM:AddFilterForEvent(ADDON_NAME, EVENT_LOOT_RECEIVED, REGISTER_FILTER_UNIT_TAG_PREFIX, "group")
	EM:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) self:OnInventorySingleSlotUpdate(...) end)
	EM:AddFilterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT, REGISTER_FILTER_IS_NEW_ITEM, IS_NEW_ITEM)

	EM:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_ITEM_USED, function(...) self:OnInventoryItemUsed(...) end)
end

function ScootworksItemsLoot:UnregisterEvents()
	EM:UnregisterForEvent(ADDON_NAME, EVENT_LOOT_RECEIVED)
	EM:UnregisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
	EM:UnregisterForEvent(ADDON_NAME, EVENT_INVENTORY_ITEM_USED)
end

function ScootworksItemsLoot:EventHandler()
	if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ENABLED) or ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) then
		self:RegisterEvents()
	else
		self:UnregisterEvents()
	end
end