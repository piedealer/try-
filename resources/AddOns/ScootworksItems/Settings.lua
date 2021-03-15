local ADDON_DISPLAY_NAME = "Scootworks Items"
local ADDON_DISPLAY_NAME_SETS = "Scootworks Items Sets"

local LIB_ITEM_LINK = LIB_ITEM_LINK

local QUALITY_VALUES =
{
	ITEM_DISPLAY_QUALITY_NORMAL,
	ITEM_DISPLAY_QUALITY_MAGIC,
	ITEM_DISPLAY_QUALITY_ARCANE,
	ITEM_DISPLAY_QUALITY_ARTIFACT,
	ITEM_DISPLAY_QUALITY_LEGENDARY,
}

local ITEMS_DISPLAY_QUALITY = { }
for _, displayQuality in ipairs(QUALITY_VALUES) do
	local color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality))
	local qualityString = color:Colorize(GetString("SI_ITEMQUALITY", displayQuality))
	local qualityData =
	{
		name = qualityString,
		data = displayQuality,
	}
	ITEMS_DISPLAY_QUALITY[displayQuality] = qualityData
end

local function ShowTooltip(settingsControl, itemLink)
	InitializeTooltip(ItemTooltip, settingsControl.control)
	ItemTooltip:SetLink(itemLink)
end

local function MergeString(stringId, secondStringId)
	if secondStringId then
		return ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_LAM_MERGE_SECOND, GetString(stringId), GetString(secondStringId))
	end
	return ZO_CachedStrFormat(SI_SCOOTWORKS_ITEMS_LAM_MERGE, GetString(stringId))
end

function ScootworksItems_InitializeSettings()
	local scootworksItemLoot = ScootworksItems_GetLoot()
	local scootworksItemVendor = ScootworksItems_GetVendor()

	local LibHarvensAddonSettings = LibHarvensAddonSettings
	local settings = LibHarvensAddonSettings:AddAddon(ADDON_DISPLAY_NAME, { allowRefresh = true })

	local NO_CALLBACK = nil

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_LSV_ACCOUNT_WIDE),
		tooltip = GetString(SI_LSV_ACCOUNT_WIDE_TT),
		getFunction = function()
			local savedVars = ScootworksItems_GetSetting()
			savedVars:LoadAllSavedVars()
			return savedVars:GetAccountSavedVarsActive()
		end,
		setFunction = function(value)
			local savedVars = ScootworksItems_GetSetting()
			savedVars:LoadAllSavedVars()
			savedVars:SetAccountSavedVarsActive(value)
		end,
		default = ScootworksItems_GetSetting().__dataSource.defaultToAccount,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_LOOT_TITLE),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_LOOT),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_LOOT_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ENABLED, value, scootworksItemLoot) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_LOOT_ONLY_GROUP),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_LOOT_ONLY_GROUP_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ONLY_IN_GROUP) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ONLY_IN_GROUP, value) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_LOOT_HIDE_PLAYER_LOOT),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_LOOT_HIDE_PLAYER_LOOT_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_HIDE_PLAYER_ITEMS) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_HIDE_PLAYER_ITEMS, value) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ENABLED) or not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_LOOT, SCOOTWORKS_ITEMS_SETTING_ONLY_IN_GROUP) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_SELL_JUNK_TITLE),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_SELL_JUNK),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_SELL_JUNK_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_ENABLED, value, scootworksItemVendor) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_SELL_JUNK_MESSAGE),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_SELL_JUNK_MESSAGE_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_MESSAGE) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_MESSAGE, value) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_REPAIR_TITLE),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_REPAIR),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_REPAIR_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR, SCOOTWORKS_ITEMS_SETTING_ENABLED, value, scootworksItemVendor) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_REPAIR_MESSAGE),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_REPAIR_MESSAGE_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR, SCOOTWORKS_ITEMS_SETTING_MESSAGE) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR, SCOOTWORKS_ITEMS_SETTING_MESSAGE, value) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_AUTO_REPAIR, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_TITLE),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_LABEL,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_DESC),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED, value, scootworksItemLoot) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_MESSAGE),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_MESSAGE_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MESSAGE) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MESSAGE, value) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_NON_MONSTER_PCS),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_NON_MONSTER_PCS_TT),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_HEAD_AND_SHOULDER) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_HEAD_AND_SHOULDER) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_QUALITY),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_QUALITY_TT),
		items = ITEMS_DISPLAY_QUALITY,
		getFunction = function()
			local item = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_HEAD_AND_SHOULDER_QUALITY)
			return ITEMS_DISPLAY_QUALITY[item].name
		end,
		setFunction = function(combobox, name, item)
			ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY, item.data, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_HEAD_AND_SHOULDER_QUALITY)
		end,
		disable = function()
			local markEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED)
			local subSettingEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_HEAD_AND_SHOULDER)
			return not markEnabled and not subSettingEnabled
		end,
	}
	
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_ITEMTYPE1, SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_WITHOUT_SET),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_WEAPON) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_WEAPON) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = zo_strformat(SI_SCOOTWORKS_ITEMS_LAM_MARK_QUALITY, GetString(SI_TRADINGHOUSEFEATURECATEGORY5)),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_QUALITY_TT),
		items = ITEMS_DISPLAY_QUALITY,
		getFunction = function()
			local item = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_WEAPON_QUALITY)
			return ITEMS_DISPLAY_QUALITY[item].name
		end,
		setFunction = function(combobox, name, item)
			ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY, item.data, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_WEAPON_QUALITY)
		end,
		disable = function()
			local markEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED)
			local subSettingEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_WEAPON)
			return not markEnabled and not subSettingEnabled
		end,
	}
	
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_EQUIPSLOTVISUALCATEGORY2, SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_WITHOUT_SET),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_APPAREL) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_APPAREL) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_QUALITY),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_QUALITY_TT),
		items = ITEMS_DISPLAY_QUALITY,
		getFunction = function()
			local item = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_APPAREL_QUALITY)
			return ITEMS_DISPLAY_QUALITY[item].name
		end,
		setFunction = function(combobox, name, item)
			ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY, item.data, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_APPAREL_QUALITY)
		end,
		disable = function()
			local markEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED)
			local subSettingEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_APPAREL)
			return not markEnabled and not subSettingEnabled
		end,
	}

	
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_ITEMFILTERTYPE25, SI_SCOOTWORKS_ITEMS_LAM_MARK_ITEMS_WITHOUT_SET),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_JEWELERY) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_JEWELERY) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_QUALITY),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_QUALITY_TT),
		items = ITEMS_DISPLAY_QUALITY,
		getFunction = function()
			local item = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_JEWELERY_QUALITY)
			return ITEMS_DISPLAY_QUALITY[item].name
		end,
		setFunction = function(combobox, name, item)
			ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS_QUALITY, item.data, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_JEWELERY_QUALITY)
		end,
		disable = function()
			local markEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED)
			local subSettingEnabled = ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_JEWELERY)
			return not markEnabled and not subSettingEnabled
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_ITEMFILTERTYPE25, SI_ITEMTRAITTYPE24),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_JEWELERY) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_JEWELERY) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_ITEMTYPE2, SI_ITEMTRAITTYPE10),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_ARMOR) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_ARMOR) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_ITEMTYPE1, SI_ITEMTRAITTYPE19),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_WEAPON) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_ORNATE_WEAPON) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_SPECIALIZEDITEMTYPE2150),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TRASH) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TRASH) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_SPECIALIZEDITEMTYPE81),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TROPHY) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TROPHY) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_SPECIALIZEDITEMTYPE80),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_RAREFISH) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_RAREFISH) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_SPECIALIZEDITEMTYPE2550),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TREASURE) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_TREASURE) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_GAMEPADITEMCATEGORY13),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_GLYPHE) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_GLYPHE) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_SPECIALIZEDITEMTYPE450),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_POTION) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_POTION) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = MergeString(SI_SPECIALIZEDITEMTYPE1400),
		getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_POISON) end,
		setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_MARK_ITEMS, value, NO_CALLBACK, SCOOTWORKS_ITEMS_SUB_SETTING_MARK_ITEMS_POISON) end,
		disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_MARK_ITEMS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_INVENTORY_MENU_INVENTORY),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_SCAN),
		tooltip = GetString(SI_SCOOTWORKS_ITEMS_LAM_MARK_SCAN_TT),
		buttonText = GetString(SI_KEYCODE127),
		clickHandler = ScootworksItems_ScanBagForJunk,
	}

	local settingsSets = LibHarvensAddonSettings:AddAddon(ADDON_DISPLAY_NAME_SETS, { allowRefresh = true })
	local savedVarsSet = ScootworksItems_GetSettingSetId()
	settingsSets:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_LSV_ACCOUNT_WIDE),
		tooltip = GetString(SI_LSV_ACCOUNT_WIDE_TT),
		getFunction = function() 
			savedVarsSet:LoadAllSavedVars()
			return savedVarsSet:GetAccountSavedVarsActive()
		end,
		setFunction = function(value)
			savedVarsSet:LoadAllSavedVars()
			savedVarsSet:SetAccountSavedVarsActive(value)
		end,
		default = savedVarsSet.__dataSource.defaultToAccount,
	}
	settingsSets:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = "",
	}
	settingsSets:AddSetting {
		type = LibHarvensAddonSettings.ST_LABEL,
		label = GetString(SI_SCOOTWORKS_ITEMS_SETTINGS_SETS_DESC),
	}

	local LIBSETS_SETTYPE_CRAFTED = LIBSETS_SETTYPE_CRAFTED
	local GetSetTypeName = LibSets.GetSetTypeName
	local clientLanguage = LibSets.clientLang or "en"
	local setNameToIndexTable = ScootworksItems_GetSetsTable()

	for setType = LIBSETS_SETTYPE_ITERATION_BEGIN, LIBSETS_SETTYPE_ITERATION_END do
		if setType ~= LIBSETS_SETTYPE_CRAFTED and setType ~= LIBSETS_SETTYPE_MYTHIC then
			settingsSets:AddSetting {
				type = LibHarvensAddonSettings.ST_SECTION,
				label = GetSetTypeName(setType, clientLanguage),
			}
		end
		for _, layoutData in ipairs(setNameToIndexTable) do
			if layoutData.setType ~= LIBSETS_SETTYPE_CRAFTED and layoutData.setType ~= LIBSETS_SETTYPE_MYTHIC and layoutData.setType == setType then
				settingsSets:AddSetting {
					type = LibHarvensAddonSettings.ST_CHECKBOX,
					label = function()
						if layoutData.isRecentlyAdded then
							return zo_iconTextFormat("esoui/art/inventory/newitem_icon.dds", "100%", "100%", layoutData.setName)
						end
						return layoutData.setName
					end,
					tooltip = function(settingsControl)
						local setItemId = layoutData.setItemId
						if setItemId then
							return LIB_ITEM_LINK:ShowTooltip(settingsControl.control, LIB_ITEM_LINK:BuildItemLink(setItemId, ITEM_QUALITY_LEGENDARY, 50, 160, nil, nil, nil, ITEM_QUALITY_LEGENDARY))
						end
						return nil
					end,
					getFunction = function() return ScootworksItems_GetSettingSetId(layoutData.setId) or layoutData.enabled end,
					setFunction = function(value)
						layoutData.enabled = value
						ScootworksItems_SetSettingSetId(layoutData.setId, value)
					end,
				}
			end
		end
	end

	CALLBACK_MANAGER:FireCallbacks("ScootworksItems_SettingsCreated", settings, settingsSets)
end