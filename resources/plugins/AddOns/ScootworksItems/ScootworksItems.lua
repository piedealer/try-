local ADDON_NAME = "ScootworksItems"
local ADDON_PREFIX = "Items"

local EM = GetEventManager()

local GetSetName, GetSetType, GetSetItemId, IsCurrentDLC = LibSets.GetSetName, LibSets.GetSetType, LibSets.GetSetItemId, LibSets.IsCurrentDLC

local DEFAULTS =
{
	[SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS] =
	{
		[SCOOTWORKS_ITEMS_SETTING_ENABLED] = true,
		[SCOOTWORKS_ITEMS_SETTING_MESSAGE] = true,
		[SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS] =
		{
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_JEWELERY] = false,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_ARMOR] = false,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_WEAPON] = false,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TRASH] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TROPHY] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_RAREFISH] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TREASURE] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_GLYPHE] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_POTION] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_POISON] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_WEAPON] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_APPAREL] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_JEWELERY] = true,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_HEAD_AND_SHOULDER] = true,
		},
		[SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY] =
		{
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_WEAPON_QUALITY] = ITEM_DISPLAY_QUALITY_NORMAL,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_APPAREL_QUALITY] = ITEM_DISPLAY_QUALITY_NORMAL,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_JEWELERY_QUALITY] = ITEM_DISPLAY_QUALITY_NORMAL,
			[SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_HEAD_AND_SHOULDER_QUALITY] = ITEM_DISPLAY_QUALITY_NORMAL,
		}
	},
	[SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK] =
	{
		[SCOOTWORKS_ITEMS_SETTING_ENABLED] = false,
		[SCOOTWORKS_ITEMS_SETTING_MESSAGE] = true,
	},
	[SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR] =
	{
		[SCOOTWORKS_ITEMS_SETTING_ENABLED] = false,
		[SCOOTWORKS_ITEMS_SETTING_MESSAGE] = true,
	},
	[SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT] =
	{
		[SCOOTWORKS_ITEMS_SETTING_ENABLED] = true,
		[SCOOTWORKS_ITEMS_SETTING_ONLY_IN_GROUP] = true,
		[SCOOTWORKS_ITEMS_SETTING_HIDE_PLAYER_ITEMS] = true,
	},
	[SCOOTWORKS_ITEMS_SETTING_TYPE_FCOIS] =
	{
		[SCOOTWORKS_ITEMS_SETTING_ENABLED] = false,
	},
}


-- ScootworksItems
------------------
local ScootworksItems = ZO_Object:Subclass()

function ScootworksItems:New(...)
	local container = ZO_Object.New(self)
	container:Initialize(...)
	return container
end

function ScootworksItems:Initialize()
	local function OnAddOnLoaded(eventCode, addonName)
		if addonName == ADDON_NAME then
			self.sv = LibSavedVars
				:NewAccountWide(ADDON_NAME.."_Save", DEFAULTS, "Default")
				:AddCharacterSettingsToggle(ADDON_NAME.."_SaveChar")
			self.svSets = LibSavedVars
				:NewAccountWide(ADDON_NAME.."Sets_Save", { }, "Default")
				:AddCharacterSettingsToggle(ADDON_NAME.."Sets_SaveChar")

			self.chat = LibChatMessage(ADDON_PREFIX, "SI")
			self.loot = ScootworksItemsLoot:New(self.chat)
			self.vendor = ScootworksItemsVendor:New(self.chat)

			self:InitializeSets()
			ScootworksItems_InitializeSettings()

			EM:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
		end
	end
	EM:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ScootworksItems:InitializeSets()
	self.setNamesTable = { }
	self.setIdTable = { }
	self.setNameToIndexTable = { }

	for setId, _ in pairs(LibSets.setIds) do
		local setName = GetSetName(setId)
		if setName then
			self.setNamesTable[#self.setNamesTable + 1] = setName
			self.setIdTable[setName] = setId
		end
	end
	table.sort(self.setNamesTable)

	for _, setName in ipairs(self.setNamesTable) do
		local setId = self.setIdTable[setName]
		local data =
		{
			setId = setId,
			setName = setName,
			setType = GetSetType(setId),
			setItemId = GetSetItemId(setId),
			isRecentlyAdded = IsCurrentDLC(setId),
			enabled = self.svSets[setId] == true,
		}
		self.setNameToIndexTable[#self.setNameToIndexTable + 1] = data
	end
end


SCOOTWORKS_ITEMS = ScootworksItems:New()


-- GLOBAL
---------
function ScootworksItems_GetLoot()
	return SCOOTWORKS_ITEMS.loot
end

function ScootworksItems_GetVendor()
	return SCOOTWORKS_ITEMS.vendor
end

function ScootworksItems_GetSetsTable()
	return SCOOTWORKS_ITEMS.setNameToIndexTable
end

function ScootworksItems_SetSetting(settingType, setting, value, callback, subSetting)
	local savedVars = SCOOTWORKS_ITEMS.sv
	if savedVars then
		if subSetting then
			savedVars[settingType][setting][subSetting] = value
		else
			savedVars[settingType][setting] = value
		end
		if callback then
			callback:EventHandler()
		end
	end
end

function ScootworksItems_GetSetting(settingType, setting, subSetting)
	local savedVars = SCOOTWORKS_ITEMS.sv
	if savedVars then
		if settingType and setting then
			if subSetting then
				return savedVars[settingType][setting][subSetting]
			else
				return savedVars[settingType][setting]
			end
		elseif settingType and setting == nil then
			return savedVars[settingType]
		else
			return savedVars
		end
	end
	return nil
end

function ScootworksItems_SetSettingSetId(setId, value)
	local savedVars = SCOOTWORKS_ITEMS.svSets
	if savedVars and setId then
		savedVars[setId] = value
	end
end

function ScootworksItems_GetSettingSetId(setId)
	local savedVars = SCOOTWORKS_ITEMS.svSets
	if savedVars then
		if setId then
			local svSetId = savedVars[setId]
			if svSetId then
				return svSetId
			end
		else
			return savedVars
		end
	end
	return nil
end

function ScootworksItems_ScanBagForJunk()
	SCOOTWORKS_ITEMS.loot:ScanBagForJunk()
end