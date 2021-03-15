local LibFilters = LibStub("LibFilters-2.0")
LibFilters:InitializeLibFilters()

LibFilters.test = {}

SLASH_COMMANDS["/testfilters"] = function()
    local filterTag = "TEST"
    local filterTypes = {
        LF_INVENTORY, LF_BANK_WITHDRAW, LF_BANK_DEPOSIT, LF_GUILDBANK_WITHDRAW,
        LF_GUILDBANK_DEPOSIT, LF_VENDOR_BUY, LF_VENDOR_SELL, LF_VENDOR_BUYBACK,
        LF_VENDOR_REPAIR, LF_GUILDSTORE_SELL, LF_MAIL_SEND, LF_TRADE,
        LF_SMITHING_REFINE, LF_SMITHING_DECONSTRUCT, LF_SMITHING_IMPROVEMENT,
        LF_SMITHING_RESEARCH, LF_ALCHEMY_CREATION, LF_ENCHANTING_CREATION,
        LF_ENCHANTING_EXTRACTION, LF_FENCE_SELL, LF_FENCE_LAUNDER, LF_CRAFTBAG,
        LF_QUICKSLOT, LF_RETRAIT,
    }

    for _, filterType in pairs(filterTypes) do
        LibFilters.test[filterType] = {}

        local function filterCallback(...)
            table.insert(LibFilters.test[filterType], {...})
            return false
        end

        if LibFilters:IsFilterRegistered(filterTag, filterType) then
            d("Unregistering " .. filterType)
            LibFilters:UnregisterFilter(filterTag, filterType)
            LibFilters:RequestUpdate(filterType)
        else
            d("Registering " .. filterType)
            LibFilters:RegisterFilter(filterTag, filterType, filterCallback)
            LibFilters:RequestUpdate(filterType)
        end
    end
end

--depends on Item Saver by Randactyl
SLASH_COMMANDS["/testenchant"] = function()
    local filterTag = "TestEnchant"
    local isRegistered = LibFilters:IsFilterRegistered(filterTag, LF_ENCHANTING_CREATION)

    local function filterCallback(slotOrBagId, slotIndex)
        local bagId

        if type(slotOrBagId) == "number" then
            if not slotIndex then return false end

            bagId = slotOrBagId
        else
            bagId, slotIndex = ItemSaver.util.GetInfoFromRowControl(slotOrBagId)
        end

        local isSaved, savedSet = ItemSaver_IsItemSaved(bagId, slotIndex)

        return not isSaved
    end

    if not isRegistered then
        LibFilters:RegisterFilter(filterTag, LF_ENCHANTING_CREATION, filterCallback)
        LibFilters:RequestUpdate(LF_ENCHANTING_CREATION)
        LibFilters:RegisterFilter(filterTag, LF_ENCHANTING_EXTRACTION, filterCallback)
        LibFilters:RequestUpdate(LF_ENCHANTING_EXTRACTION)
    else
        LibFilters:UnregisterFilter(filterTag, LF_ENCHANTING_CREATION)
        LibFilters:RequestUpdate(LF_ENCHANTING_CREATION)
        LibFilters:UnregisterFilter(filterTag, LF_ENCHANTING_EXTRACTION)
        LibFilters:RequestUpdate(LF_ENCHANTING_EXTRACTION)
    end
end