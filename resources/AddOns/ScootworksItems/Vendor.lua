local ADDON_NAME = "ScootworksItemsVendor"

local EM = GetEventManager()

local DONT_COUNT_STOLEN_ITEMS, HIDE_CHAT_TAG = true, true
local RESET_TO_ZERO = 0
local NUM_ITEMS_FOR_DELAY = 40 -- [count]
local TIME_DELAY_FOR_SELLINGS_MESSAGE = 100 -- [ms]
local TIME_DELAY_FOR_SELLINGS_BEFORE_KICK = 250 -- [ms]

local function NormalizeValue(value)
	return zo_roundToZero(value)
end

local function IsItemJunkAtFence(bagId, slotIndex)
	if IsItemJunk(bagId, slotIndex) and GetItemSellInformation(bagId, slotIndex) ~= ITEM_SELL_INFORMATION_CANNOT_SELL then
		return true
	end
	return false
end

local function IsItemJunkAndNotStolen(bagId, slotIndex)
	if IsItemJunk(bagId, slotIndex) and not IsItemStolen(bagId, slotIndex) and GetItemSellInformation(bagId, slotIndex) ~= ITEM_SELL_INFORMATION_CANNOT_SELL then
		return true
	end
	return false
end


-- ScootworksItemsVendor
------------------------
ScootworksItemsVendor = ZO_Object:Subclass()

function ScootworksItemsVendor:New(chat)
	local vendor = ZO_Object.New(self)
	if vendor then
		vendor:EventHandler()
		vendor.chat = chat
		vendor.task = LibAsync:Create(ADDON_NAME)
		vendor.fcois = ScootworksItemsFCOIS:New()
	end
	return vendor
end

function ScootworksItemsVendor:GetSoldPrice()
	return self.soldPrice
end

function ScootworksItemsVendor:SetSoldPrice(value)
	self.soldPrice = value or 0
end

function ScootworksItemsVendor:OnSoldMessage(chatOutputEnabled)
	if chatOutputEnabled then
		local soldPrice = self:GetSoldPrice()
		if soldPrice == 0 then
			self.chat:Print(GetString(SI_SCOOTWORKS_ITEMS_JUNK_SOLD), HIDE_CHAT_TAG)
		else
			self.chat:Print(ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_JUNK_SOLD_WITH_PRICE, ZO_Currency_FormatPlatform(CURT_MONEY, soldPrice, ZO_CURRENCY_FORMAT_AMOUNT_ICON)), HIDE_CHAT_TAG)
		end
		self:SetSoldPrice(RESET_TO_ZERO)
	end
end

function ScootworksItemsVendor:SellItem(filterCallback)
	local chatOutputEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_MESSAGE)

	if not chatOutputEnabled then
		SellAllJunk()
	end

	local itemList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, filterCallback)
	if self.fcois:IsActive() and ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_FCOIS, SCOOTWORKS_ITEMS_SETTING_ENABLED) then
		itemList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, self.fcois:GetCallback(), itemList)
	end

	if next(itemList) then
		local totalPrice = 0
		if chatOutputEnabled then
			for _, itemInfo in pairs(itemList) do
				totalPrice = totalPrice + itemInfo.stack * GetItemSellValueWithBonuses(itemInfo.bag, itemInfo.index)
			end
		end

		local counter = 0
		local countDelays = 0
		for _, itemInfo in pairs(itemList) do
			counter = counter + 1
			if counter % NUM_ITEMS_FOR_DELAY == 0 then
				countDelays = countDelays + 1
				self.task:Delay(TIME_DELAY_FOR_SELLINGS_BEFORE_KICK, SellInventoryItem(itemInfo.bag, itemInfo.index, itemInfo.stack))
			else
				SellInventoryItem(itemInfo.bag, itemInfo.index, itemInfo.stack)
			end
		end

		local delay = countDelays > 0 and NormalizeValue(TIME_DELAY_FOR_SELLINGS_MESSAGE * countDelays * .8) or TIME_DELAY_FOR_SELLINGS_MESSAGE
		self.task:Delay(delay, function()
			if numBagUsedSlots ~= GetNumBagUsedSlots(BAG_BACKPACK) then
				self:SetSoldPrice(totalPrice)
				self:OnSoldMessage(chatOutputEnabled)
			end
		end)
	end
end

function ScootworksItemsVendor:OnOpenFence()
	if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_ENABLED) then
		local fcoisHasItems = self.fcois:HasItems()
		if (AreAnyItemsStolen(BAG_BACKPACK) and HasAnyJunk(BAG_BACKPACK)) or fcoisHasItems == true then
			self:SellItem(IsItemJunkAtFence)
		end
	end
end

function ScootworksItemsVendor:SellItems()
	if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_ENABLED) then
		local fcoisHasItems = self.fcois:HasItems()
		if (GetInteractionType() == INTERACTION_VENDOR and HasAnyJunk(BAG_BACKPACK, DONT_COUNT_STOLEN_ITEMS)) or fcoisHasItems == true then
			self:SellItem(IsItemJunkAndNotStolen)
		end
	end
end

function ScootworksItemsVendor:RepairItems()
	if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR, SCOOTWORKS_ITEMS_SETTING_ENABLED) and CanStoreRepair() then
		local repairCost = GetRepairAllCost()
		if repairCost > 0 then
			RepairAll()
			if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR, SCOOTWORKS_ITEMS_SETTING_MESSAGE) then
				self.chat:Print(ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_REPAIRED, ZO_Currency_FormatPlatform(CURT_MONEY, repairCost, ZO_CURRENCY_FORMAT_AMOUNT_ICON)), HIDE_CHAT_TAG)
			end
		end
	end
end

function ScootworksItemsVendor:OnOpenStore()
	self:SellItems()
	self:RepairItems()
end

function ScootworksItemsVendor:RegisterEvents()
	EM:RegisterForEvent(ADDON_NAME, EVENT_OPEN_STORE, function() self:OnOpenStore() end)
	EM:RegisterForEvent(ADDON_NAME, EVENT_OPEN_FENCE, function() self:OnOpenFence() end)
end

function ScootworksItemsVendor:UnregisterEvents()
	EM:UnregisterForEvent(ADDON_NAME, EVENT_OPEN_STORE)
	EM:UnregisterForEvent(ADDON_NAME, EVENT_OPEN_FENCE)
end

function ScootworksItemsVendor:EventHandler()
	if ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_ENABLED) or ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR, SCOOTWORKS_ITEMS_SETTING_ENABLED) then
		self:RegisterEvents()
	else
		self:UnregisterEvents()
	end
end