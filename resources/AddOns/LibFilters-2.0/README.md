**DISCLAIMER**: This Add-on is not created by, affiliated with or sponsored by
  ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and related logos are
  registered trademarks or trademarks of ZeniMax Media Inc. in the United States
  and/or other countries. All rights reserved.

---

Welcome to LibFilters-2.0!

The goal of LibFilters is to provide an easy interface for applying custom
  sorting rules to different lists of items found in the game. At the moment,
  you can filter the inventory, bank withdrawal, bank deposits, guild bank
  withdrawal, guild bank deposits, vendor buying, vendor selling, buyback,
  repair, guild store selling, mail sending, trading, smithing (refinement,
  deconstruction, improvement, research), alchemy creation, enchanting creation,
  enchanting extraction, fence selling, fence laundering, the craftbag, and the
  quickslot inventory.

To use LibFilters in your addon, you need to copy the LibStub (if you don't
  already have it from elsewhere) and LibFilters-2.0 folders from this directory
  to your addon's directory. In your manifest you need to load these files:

    path\to\LibStub\LibStub.lua
    path\to\LibFilters-2.0\LibFilters-2.0.lua
    path\to\LibFilters-2.0\helper.lua

In your addon, you need to invoke LibFilters with LibStub and then initialize
  LibFilters:

    local LibFilters = LibStub("LibFilters-2.0")
    LibFilters:InitializeLibFilters()

This is the list of available filterType constants:

    LF_INVENTORY             --inventory slot
    LF_BANK_WITHDRAW         --inventory slot
    LF_BANK_DEPOSIT          --inventory slot
    LF_GUILDBANK_WITHDRAW    --inventory slot
    LF_GUILDBANK_DEPOSIT     --inventory slot
    LF_VENDOR_BUY            --store slot
    LF_VENDOR_SELL           --inventory slot
    LF_VENDOR_BUYBACK        --buyback slot
    LF_VENDOR_REPAIR         --repair slot
    LF_GUILDSTORE_SELL       --inventory slot
    LF_MAIL_SEND             --inventory slot
    LF_TRADE                 --inventory slot
    LF_SMITHING_REFINE       --bagId, slotIndex
    LF_SMITHING_DECONSTRUCT  --bagId, slotIndex
    LF_SMITHING_IMPROVEMENT  --bagId, slotIndex
    LF_SMITHING_RESEARCH     --bagId, slotIndex
    LF_ALCHEMY_CREATION      --bagId, slotIndex
    LF_ENCHANTING_CREATION   --bagId, slotIndex
    LF_ENCHANTING_EXTRACTION --bagId, slotIndex
    LF_FENCE_SELL            --inventory slot
    LF_FENCE_LAUNDER         --inventory slot
    LF_CRAFTBAG              --inventory slot
    LF_QUICKSLOT             --quickslot slot
    LF_RETRAIT               --bagId, slotIndex

Listed next to the filterTypes is what is passed to a filterCallback registered
  to that filterType. For the slots, these are the keys available in the passed
  table:

    inventory slot: age, bagId, condition, dataEntry, equipType, filterData,
      iconFile, inventory, isJunk, isPlayerLocked, itemInstanceId, itemType,
      launderPrice, locked, meetsUsageRequirement, name, quality, rawName,
      requiredLevel, searchData, sellPrice, slotControl, slotIndex,
      specializedItemType, stackCount, stackLaunderPrice, statValue, stolen,
      uniqueId

    store slot: currencyQuantity1, currencyQuantity2, currencyType1,
      currencyType2, dataEntry, entryType, filterData, icon, isUnique,
      meetsRequirementsToBuy, meetsRequirementsToEquip, name, price, quality,
      questNameColor, sellPrice, slotIndex, stack, stackBuyPrice,
      stackBuyPriceCurrency1, stackBuyPriceCurrency2, statValue

    buyback slot: icon, meetsRequirements, name, price, quality, slotIndex,
      stack, stackBuyPrice

    repair slot: bagId, condition, dataEntry, icon, name, quality, repairCost,
      slotIndex, stackCount

    quickslot slot: age, bagId, filterData, iconFile, locked,
      meetsUsageRequirement, name, quality, sellPrice, slotIndex, slotType,
      stackCount, stackSellPrice, stolen

LibFilters has the following functions available:

    LibFilters:HookAdditionalFilter(filterType, inventory)
    FilterType is one of the provided "LF_" prefixed constants. Inventory needs
      to be some construct which can make use of an additionalFilter to
      determine if an item is shown or not. Look in
      LibFilters:InitializeLibFilters and/or helper.lua for examples.

    LibFilters:InitializeLibFilters()
    Must be called after you've invoked LibFilters-2.0 with LibStub

    LibFilters:GetCurrentFilterTypeForInventory(inventoryType)
    Returns the filterType currently affecting the provided inventoryType.

    LibFilters:GetFilterCallback(filterTag, filterType)
    filterTag is the unique string that identifies your filter. filterType is
      the provided "LF_" prefixed constants your filter was registered for.
      Returns the filterCallback registered for the provided filterTag and
      filterType; returns nil otherwise.

    LibFilters:IsFilterRegistered(filterTag, filterType)
    filterTag is the unique string that identifies your filter. filterType is
      the provided "LF_" prefixed constants your filter was registered for.
      Returns true if there is a filter registered with the provided filterTag.
      Returns false if there is not a filter registered with the provided
      filterTag. filterType is optional. If a filterType is provided, will only
      return true if a filter is registered to that filterType under the
      provided filterTag.

    LibFilters:RegisterFilter(filterTag, filterType, filterCallback)
    filterTag is a unique string to identify your filter. filterType is one of
      the provided "LF_" prefixed constants. filterCallback is a function which
      accepts either one or two arguments; this is determined by the filterType.
      filterCallback should return true if an item is to be shown.
      filterCallback should return false if an item should not be shown.

    LibFilters:RequestUpdate(filterType)
    filterType is one of the provided "LF_" prefixed constants. Runs the updater
      appropriate for the provided filter type to pick up any filtering changes.

    LibFilters:UnregisterFilter(filterTag, filterType)
    filterTag is the unique string that identifies your filter. filterType the
      provided "LF_" prefixed constants your filter was registered for.
      filterType is optional. If a filterType is not provided, all filters
      registered with the provided filterTag will be unregistered.