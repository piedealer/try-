ShoppingList = {}
ShoppingList.Name = "ShoppingList"
local internal       = _G["LibGuildStore_Internal"]
local purchases_data    = _G["LibGuildStore_PurchaseData"]

if LibDebugLogger then
  logger = LibDebugLogger.Create(ShoppingList.Name)
  ShoppingList.logger = logger
end
local SDLV = DebugLogViewer
if SDLV then ShoppingList.viewer = true else ShoppingList.viewer = false end

local function create_log(log_type, log_content)
  if log_type == "Debug" then
    ShoppingList.logger:Debug(log_content)
  end
  if log_type == "Info" then
    ShoppingList.logger:Info(log_content)
  end
  if log_type == "Verbose" then
    ShoppingList.logger:Verbose(log_content)
  end
  if log_type == "Warn" then
    ShoppingList.logger:Warn(log_content)
  end
end

local function emit_message(log_type, text)
  if (text == "") then
    text = "[Empty String]"
  end
  create_log(log_type, text)
end

local function emit_table(log_type, t, indent, table_history)
  indent = indent or "."
  table_history = table_history or {}

  for k, v in pairs(t) do
    local vType = type(v)

    emit_message(log_type, indent .. "(" .. vType .. "): " .. tostring(k) .. " = " .. tostring(v))

    if (vType == "table") then
      if (table_history[v]) then
        emit_message(log_type, indent .. "Avoiding cycle on table...")
      else
        table_history[v] = true
        emit_table(log_type, v, indent .. "  ", table_history)
      end
    end
  end
end

function ShoppingList.dm(log_type, ...)
  if not ShoppingList.logger then return end
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if (type(value) == "table") then
      emit_table(log_type, value)
    else
      emit_message(log_type, tostring(value))
    end
  end
end

ShoppingList.Version = "1.0.5"
ShoppingList.FONT = "EsoUI/Common/Fonts/ProseAntiquePSMT.otf"
ShoppingList.SavedData = {
  Account = nil,
  System  = nil
}

----- List functions
SLList = ZO_SortFilterList:Subclass()
SLList.defaults = {}
SLList.SORT_KEYS = { ["account"] = { tiebreaker = "time" },
                     ["guild"]   = { tiebreaker = "time" },
                     ["item"]    = { tiebreaker = "time" },
                     ["price"]   = { tiebreaker = "time" },
                     ["time"]    = {}
}
ShoppingList.isReady = false

local TOGGLE_BUYER = 0
local TOGGLE_SELLER = 1

function SLList:Initialize(control)
  ZO_SortFilterList.Initialize(self, control)
  self.masterList = {}

  ZO_ScrollList_AddDataType(self.list, 1, "ShoppingListDataRow", 30,
    function(control, data)
      self:SetupUnitRow(control, data)
    end
  )

  ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

  self.sortFunction = function(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, self.SORT_KEYS,
      self.currentSortOrder)
  end

  self.sortHeaderGroup:SelectHeaderByKey("time")
  self.sortHeaderGroup:SelectHeaderByKey("time")
  self:RefreshData()
end

function SLList:SetupUnitRow(control, data)
  control.data = data
  control.account = GetControl(control, "Account")
  control.guild = GetControl(control, "Guild")
  control.icon = GetControl(control, "Icon")
  control.quantity = GetControl(control, "Quantity")
  control.item = GetControl(control, "Item")
  control.time = GetControl(control, "Time")
  control.price = GetControl(control, "Price")

  local icon = GetItemLinkInfo(data.item)

  --- Set text ---
  control.account:SetText(data.account)
  control.guild:SetText(data.guild)
  control.icon:SetTexture(icon)
  if (data.quantity <= 1) then
    control.quantity:SetHidden(true)
  else
    control.quantity:SetText(data.quantity)
    control.quantity:SetHidden(false)
  end
  control.item:SetText(data.item)

  local secsSince = GetTimeStamp() - data.time

  if secsSince < 864000 then
    control.time:SetText(ZO_FormatDurationAgo(secsSince))
  else
    control.time:SetText(zo_strformat(GetString(SK_TIME_DAYS), math.floor(secsSince / ZO_ONE_DAY_IN_SECONDS)))
  end

  control.price:SetText(data.price .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t")

  --- Set colors ---
  if (GetDisplayName() == data.account) then
    control.account.normalColor = ZO_ColorDef:New(0.18, 0.77, 0.05, 1)
  else
    control.account.normalColor = ZO_ColorDef:New(1, 1, 1, 1)
  end

  control.guild.normalColor = ZO_ColorDef:New(1, 1, 1, 1)
  control.quantity.normalColor = ZO_ColorDef:New(1, 1, 1, 1)
  control.item.normalColor = ZO_ColorDef:New(1, 1, 1, 1)
  control.time.normalColor = ZO_ColorDef:New(1, 1, 1, 1)
  control.price.normalColor = ZO_ColorDef:New(0.84, 0.71, 0.15, 1)

  control.item:SetHandler('OnMouseEnter', function()
    InitializeTooltip(ItemTooltip, control.item)
    ItemTooltip:SetLink(data.item)
  end)

  control.item:SetHandler('OnMouseExit', function()
    ClearTooltip(ItemTooltip)
  end)

  ZO_SortFilterList.SetupRow(self, control, data)
end

function SLList:BuildMasterList()
  ShoppingList.dm("Debug", "BuildMasterList")
  self.masterList = {}

  for itemid, versionlist in pairs(purchases_data) do
    if purchases_data[itemid] then
      for versionid, versiondata in pairs(versionlist) do
        if purchases_data[itemid][versionid] then
          if versiondata.sales then
            for saleid, saledata in pairs(versiondata.sales) do
              local purchase = {}
              if (ShoppingList.BuyerSellerToggle == TOGGLE_BUYER) then
                purchase["account"] = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, saledata.buyer)
              else
                purchase["account"] = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, saledata.seller)
              end
              purchase["item"] = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, saledata.itemLink)
              purchase["guild"] = internal:GetStringByIndex(internal.GS_CHECK_GUILDNAME, saledata.guild)
              purchase["quantity"] = saledata.quant
              purchase["price"] = saledata.price
              purchase["time"] = saledata.timestamp
              table.insert(self.masterList, purchase)
            end
          end
        end
      end
    end
  end
end

local function getTraitName(itemLink)
  local t = GetItemLinkTraitInfo(itemLink)

  if (t == 0) then
    return nil
  end

  return GetString("SI_ITEMTRAITTYPE", t)
end

function SLList:FilterScrollList()
  local scrollData = ZO_ScrollList_GetDataList(self.list)
  ZO_ClearNumericallyIndexedTable(scrollData)
  local searchTerms = { zo_strsplit(' ', zo_strlower(ShoppingListWindowSearchBox:GetText())) }

  for i = 1, #self.masterList do
    local data = self.masterList[i]

    if (#searchTerms > 0) then
      for j = 1, #searchTerms do
        if (string.find(zo_strlower(data.account), searchTerms[j]) ~= nil) or
          (string.find(zo_strlower(data.guild), searchTerms[j]) ~= nil) or
          (string.find(zo_strlower(GetItemLinkName(data.item)), searchTerms[j]) ~= nil) or
          (string.find(zo_strlower(getTraitName(data.item)), searchTerms[j]) ~= nil) then
          if (j == #searchTerms) then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
          end
        else
          break
        end
      end

    else
      table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
    end
  end
end

function SLList:SortScrollList()
  local scrollData = ZO_ScrollList_GetDataList(self.list)
  table.sort(scrollData, self.sortFunction)
end

function SLList:Refresh()
  self:RefreshData()
end

function ShoppingList:ToggleBuyerSeller()
  if self.BuyerSellerToggle == TOGGLE_SELLER then
    ShoppingListWindowHeadersAccount:GetNamedChild('Name'):SetText(GetString(SL_LISTHEADER_BUYER))
    self.BuyerSellerToggle = TOGGLE_BUYER
  else
    ShoppingListWindowHeadersAccount:GetNamedChild('Name'):SetText(GetString(SL_LISTHEADER_SELLER))
    self.BuyerSellerToggle = TOGGLE_SELLER
  end

  self.List:Refresh()
end

function ShoppingList:initialize()
  ShoppingList.dm("Debug", "ShoppingList Initializing")

  ShoppingListWindow:ClearAnchors()
  ShoppingListWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)

  ShoppingListWindowTitle:SetFont(self.FONT .. "|26")
  ShoppingListWindowTitle:SetText(GetString(MM_EXTENSION_SHOPPINGLIST_NAME) .. ' - ' .. GetString(SL_WINDOW_TITLE))

  ShoppingListWindowHeadersAccount:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ShoppingListWindowHeadersAccount:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  ShoppingListWindowHeadersAccount:GetNamedChild('Name'):SetText(GetString(SL_LISTHEADER_SELLER))

  ShoppingListWindowHeadersGuild:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ShoppingListWindowHeadersGuild:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  ShoppingListWindowHeadersGuild:GetNamedChild('Name'):SetText(GetString(SL_LISTHEADER_GUILD))

  ShoppingListWindowHeadersItem:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ShoppingListWindowHeadersItem:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  ShoppingListWindowHeadersItem:GetNamedChild('Name'):SetText(GetString(SL_LISTHEADER_ITEM))

  ShoppingListWindowHeadersTime:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ShoppingListWindowHeadersTime:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  ShoppingListWindowHeadersTime:GetNamedChild('Name'):SetText(GetString(SL_LISTHEADER_TIME))

  ShoppingListWindowHeadersPrice:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ShoppingListWindowHeadersPrice:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  ShoppingListWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SL_LISTHEADER_PRICE))
  ShoppingListWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)

  self.BuyerSellerToggle = TOGGLE_SELLER

  ShoppingList.List = SLList:New(ShoppingListWindow)
  ShoppingList.isReady = true

end

function ShoppingList:StartInitialize()
  ShoppingList.dm("Debug", "ShoppingList StartInitialize")
  if MasterMerchant.isInitialized then
    ShoppingList:initialize()
  else
    zo_callLater(function() ShoppingList:StartInitialize() end, (ZO_ONE_MINUTE_IN_MILLISECONDS / 3 ) ) -- 60000 1 minute
  end
end

local function onPlayerActivated(eventCode)
  EVENT_MANAGER:UnregisterForEvent(ShoppingList.Name, eventCode)

  if (MasterMerchant == nil) then
    d("ShoppingList: Master Merchant not found!")
    return
  end
  --[[
  ShoppingList:StartInitialize()

  EVENT_MANAGER:RegisterForEvent(ShoppingList.Name, EVENT_MAIL_CLOSE_MAILBOX, function()
    ShoppingListWindow:SetHidden(true)
  end)

  EVENT_MANAGER:RegisterForEvent(ShoppingList.Name, EVENT_CLOSE_TRADING_HOUSE, function()
    ShoppingListWindow:SetHidden(true)
  end)
  ]]--
end

local function onAddOnLoaded(eventCode, addonName)
  if (addonName ~= ShoppingList.Name) then
    return
  end
  ShoppingList.dm("Debug", "onAddOnLoaded")

  ShoppingList.SavedData.System = ZO_SavedVars:NewAccountWide(ShoppingList.Name .. "Var", 1, nil,
    { Tables = {}, Purchases = {}, Settings = { KeepDays = 60 } }, nil, "ShoppingList")

  EVENT_MANAGER:RegisterForEvent(ShoppingList.Name, EVENT_PLAYER_ACTIVATED, onPlayerActivated)
  EVENT_MANAGER:UnregisterForEvent(ShoppingList.Name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(ShoppingList.Name, EVENT_ADD_ON_LOADED, onAddOnLoaded)
