local ADD_ON_MANAGER = GetAddOnManager()

ScootworksItemsFCOIS = ZO_Object:Subclass()

function ScootworksItemsFCOIS:New(chat)
	local vendor = ZO_Object.New(self)
	vendor.isActive = vendor:IsItemSaverEnabled()
	if vendor.isActive then
		local FCOIS_CON_ICON_SELL = FCOIS_CON_ICON_SELL

		vendor.IsMarked = FCOIS.IsMarked
		vendor.IsVendorSellLocked = FCOIS.IsVendorSellLocked
		vendor.IsIconEnabled = FCOIS.IsIconEnabled

		vendor.IsMarkedToSell = function(bagId, slotIndex)
			if vendor.IsMarked(bagId, slotIndex, FCOIS_CON_ICON_SELL) and not vendor.IsVendorSellLocked(bagId, slotIndex) then
				return true
			end
			return false
		end

		CALLBACK_MANAGER:RegisterCallback("ScootworksItems_SettingsCreated", function(settings)
			settings:AddSetting {
				type = LibHarvensAddonSettings.ST_SECTION,
				label = "FCO ItemSaver",
			}
			settings:AddSetting {
				type = LibHarvensAddonSettings.ST_CHECKBOX,
				label = GetString(SI_SCOOTWORKS_ITEMS_SETTINGS_FCOIS),
				tooltip = GetString(SI_SCOOTWORKS_ITEMS_SETTINGS_FCOIS_TT),
				getFunction = function() return ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_FCOIS, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
				setFunction = function(value) ScootworksItems_SetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_FCOIS, SCOOTWORKS_ITEMS_SETTING_ENABLED, value) end,
				disable = function() return not ScootworksItems_GetSetting(SCOOTWORKS_ITEMS_SETTING_TYPE_SELL_JUNK, SCOOTWORKS_ITEMS_SETTING_ENABLED) end,
			}
		end)
	end
	return vendor
end

function ScootworksItemsFCOIS:IsItemSaverEnabled()
	for i = 1, ADD_ON_MANAGER:GetNumAddOns() do
		local name, _, _, _, _, state = ADD_ON_MANAGER:GetAddOnInfo(i)
		if name == "FCOItemSaver" and state == ADDON_STATE_ENABLED then
			return true
		end
	end
	return false
end

function ScootworksItemsFCOIS:IsActive()
	if self.isActive then
		return true
	end
	return false
end

function ScootworksItemsFCOIS:GetCallback()
	if self.isActive then
		return self.IsMarkedToSell
	end
	return
end

function ScootworksItemsFCOIS:HasItems()
	if self.isActive then
		local CALLED_FROM_EXTERNAL_ADDON = true
		return self.IsIconEnabled(FCOIS_CON_ICON_SELL, CALLED_FROM_EXTERNAL_ADDON)
	end
	return nil
end