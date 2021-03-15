CraftAutoLoot = {}

CraftAutoLoot.name = "CraftAutoLoot"

function CraftAutoLoot:Initialize()
   ZO_ReticleContainerInteract:SetHandler("OnShow", function()
      local action, container, _, _, additionalInfo, _ = GetGameCameraInteractableActionInfo()
      if action == "Mine" or action == "Collect" or action == "Cut" or action == "Reel In" or ((container == "Apple Basket" or container == "Apple Crate" or container == "Barrel" or container == "Barrels" or container == "Basket" or container == "Cabinet" or container == "Corn Basket" or container == "Crate" or container == "Crates" or container == "Flour Sack" or container == "Greens Basket" or container == "Melon Basket" or container == "Millet Sack" or container == "Sack" or container == "Saltrice Sack" or container == "Seasoning Sack" or container == "Tomato Crate" or container == "Heavy Sack" or container == "Heavy Crate") and action == "Search") then
         SetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT, 1)
      else
	 SetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT, 0)
      end
   end)
end

function CraftAutoLoot.OnAddOnLoaded(event, addonName)
  if addonName == CraftAutoLoot.name then
    CraftAutoLoot:Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(CraftAutoLoot.name, EVENT_ADD_ON_LOADED, CraftAutoLoot.OnAddOnLoaded)
