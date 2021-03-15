local CATEGORY_ID = {
    ALL = 1,
    WEAPONS = 2,
    ARMOR = 3,
    JEWELRY = 4,
    CONSUMABLE = 5,
    CRAFTING = 6,
    FURNISHING = 7,
    MISCELLANEOUS = 8,
}

local SUB_CATEGORY_ID = {
    ALL = 1,
    WEAPONS_ALL = 2,
    WEAPONS_ONE_HANDED = 3,
    WEAPONS_TWO_HANDED = 4,
    WEAPONS_BOW = 5,
    WEAPONS_DESTRUCTION_STAFF = 6,
    WEAPONS_RESTORATION_STAFF = 7,
    ARMOR_ALL = 8,
    ARMOR_HEAVY = 9,
    ARMOR_MEDIUM = 10,
    ARMOR_LIGHT = 11,
    ARMOR_SHIELD = 12,
    JEWELRY_ALL = 14,
    JEWELRY_RING = 15,
    JEWELRY_NECK = 16,
    CONSUMABLE_ALL = 17,
    CONSUMABLE_FOOD = 18,
    CONSUMABLE_DRINK = 19,
    CONSUMABLE_RECIPE = 20,
    CONSUMABLE_POTION = 21,
    CONSUMABLE_POISON = 22,
    CONSUMABLE_WRIT = 23,
    CONSUMABLE_MOTIF = 24,
    CONSUMABLE_CONTAINER = 25,
    CONSUMABLE_TOOL = 26,
    CONSUMABLE_TROPHY = 27,
    CRAFTING_ALL = 28,
    CRAFTING_BLACKSMITHING = 29,
    CRAFTING_CLOTHIER = 30,
    CRAFTING_WOODWORKING = 31,
    CRAFTING_JEWELRY = 32,
    CRAFTING_ALCHEMY = 33,
    CRAFTING_ENCHANTING = 34,
    CRAFTING_PROVISIONING = 35,
    CRAFTING_STYLE_MATERIAL = 36,
    CRAFTING_TRAIT_MATERIAL = 37,
    CRAFTING_FURNISHING_MATERIAL = 38,
    FURNISHING_ALL = 39,
    FURNISHING_CRAFTING_STATION = 40,
    FURNISHING_LIGHT = 41,
    FURNISHING_ORNAMENTAL = 42,
    FURNISHING_SEATING = 43,
    FURNISHING_TARGET_DUMMY = 44,
    MISCELLANEOUS_ALL = 45,
    MISCELLANEOUS_COSTUME = 13,
    MISCELLANEOUS_GLYPHS = 46,
    MISCELLANEOUS_SOUL_GEM = 47,
    MISCELLANEOUS_SIEGE = 48,
    MISCELLANEOUS_FISHING = 49,
    MISCELLANEOUS_TOOL = 50,
    MISCELLANEOUS_TROPHY = 51,
    MISCELLANEOUS_TRASH = 52,
    MISCELLANEOUS_MISC = 53,
}

local CATEGORY_MAPPING = {
    {
        category = CATEGORY_ID.ALL,
        subcategories = {
            SUB_CATEGORY_ID.ALL
        },
    },
    {
        category = CATEGORY_ID.WEAPONS,
        subcategories = {
            SUB_CATEGORY_ID.WEAPONS_ALL,
            SUB_CATEGORY_ID.WEAPONS_ONE_HANDED,
            SUB_CATEGORY_ID.WEAPONS_TWO_HANDED,
            SUB_CATEGORY_ID.WEAPONS_BOW,
            SUB_CATEGORY_ID.WEAPONS_DESTRUCTION_STAFF,
            SUB_CATEGORY_ID.WEAPONS_RESTORATION_STAFF,
        },
    },
    {
        category = CATEGORY_ID.ARMOR,
        subcategories = {
            SUB_CATEGORY_ID.ARMOR_ALL,
            SUB_CATEGORY_ID.ARMOR_LIGHT,
            SUB_CATEGORY_ID.ARMOR_MEDIUM,
            SUB_CATEGORY_ID.ARMOR_HEAVY,
            SUB_CATEGORY_ID.ARMOR_SHIELD,
        },
    },
    {
        category = CATEGORY_ID.JEWELRY,
        subcategories = {
            SUB_CATEGORY_ID.JEWELRY_ALL,
            SUB_CATEGORY_ID.JEWELRY_NECK,
            SUB_CATEGORY_ID.JEWELRY_RING,
        },
    },
    {
        category = CATEGORY_ID.CONSUMABLE,
        subcategories = {
            SUB_CATEGORY_ID.CONSUMABLE_ALL,
            SUB_CATEGORY_ID.CONSUMABLE_FOOD,
            SUB_CATEGORY_ID.CONSUMABLE_DRINK,
            SUB_CATEGORY_ID.CONSUMABLE_RECIPE,
            SUB_CATEGORY_ID.CONSUMABLE_POTION,
            SUB_CATEGORY_ID.CONSUMABLE_POISON,
            SUB_CATEGORY_ID.CONSUMABLE_MOTIF,
            SUB_CATEGORY_ID.CONSUMABLE_WRIT,
            SUB_CATEGORY_ID.CONSUMABLE_CONTAINER,
            SUB_CATEGORY_ID.CONSUMABLE_TOOL,
            SUB_CATEGORY_ID.CONSUMABLE_TROPHY,
        },
    },
    {
        category = CATEGORY_ID.CRAFTING,
        subcategories = {
            SUB_CATEGORY_ID.CRAFTING_ALL,
            SUB_CATEGORY_ID.CRAFTING_BLACKSMITHING,
            SUB_CATEGORY_ID.CRAFTING_CLOTHIER,
            SUB_CATEGORY_ID.CRAFTING_WOODWORKING,
            SUB_CATEGORY_ID.CRAFTING_JEWELRY,
            SUB_CATEGORY_ID.CRAFTING_ALCHEMY,
            SUB_CATEGORY_ID.CRAFTING_ENCHANTING,
            SUB_CATEGORY_ID.CRAFTING_PROVISIONING,
            SUB_CATEGORY_ID.CRAFTING_STYLE_MATERIAL,
            SUB_CATEGORY_ID.CRAFTING_TRAIT_MATERIAL,
            SUB_CATEGORY_ID.CRAFTING_FURNISHING_MATERIAL,
        },
    },
    {
        category = CATEGORY_ID.FURNISHING,
        subcategories = {
            SUB_CATEGORY_ID.FURNISHING_ALL,
            SUB_CATEGORY_ID.FURNISHING_CRAFTING_STATION,
            SUB_CATEGORY_ID.FURNISHING_TARGET_DUMMY,
            SUB_CATEGORY_ID.FURNISHING_LIGHT,
            SUB_CATEGORY_ID.FURNISHING_SEATING,
            SUB_CATEGORY_ID.FURNISHING_ORNAMENTAL,
        },
    },
    {
        category = CATEGORY_ID.MISCELLANEOUS,
        subcategories = {
            SUB_CATEGORY_ID.MISCELLANEOUS_ALL,
            SUB_CATEGORY_ID.MISCELLANEOUS_COSTUME,
            SUB_CATEGORY_ID.MISCELLANEOUS_GLYPHS,
            SUB_CATEGORY_ID.MISCELLANEOUS_SOUL_GEM,
            SUB_CATEGORY_ID.MISCELLANEOUS_SIEGE,
            SUB_CATEGORY_ID.MISCELLANEOUS_TOOL,
            SUB_CATEGORY_ID.MISCELLANEOUS_TROPHY,
            SUB_CATEGORY_ID.MISCELLANEOUS_FISHING,
            SUB_CATEGORY_ID.MISCELLANEOUS_TRASH,
            SUB_CATEGORY_ID.MISCELLANEOUS_MISC,
        },
    },
}

local CATEGORY_DEFINITION = {
    [CATEGORY_ID.ALL] = {
        id = CATEGORY_ID.ALL,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        isDefault = true,
    },
    [CATEGORY_ID.WEAPONS] = {
        id = CATEGORY_ID.WEAPONS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
    },
    [CATEGORY_ID.ARMOR] = {
        id = CATEGORY_ID.ARMOR,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
    },
    [CATEGORY_ID.JEWELRY] = {
        id = CATEGORY_ID.JEWELRY,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
    },
    [CATEGORY_ID.CONSUMABLE] = {
        id = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE,
    },
    [CATEGORY_ID.CRAFTING] = {
        id = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING,
    },
    [CATEGORY_ID.FURNISHING] = {
        id = CATEGORY_ID.FURNISHING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING,
    },
    [CATEGORY_ID.MISCELLANEOUS] = {
        id = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
    }
}

for id, data in pairs(CATEGORY_DEFINITION) do
    local filterData = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterDisplayInfo(data.filterKey)
    data.filterData = filterData
    data.label = filterData.filterString
    data.icons = filterData.icons
end

local SUB_CATEGORY_DEFINITION = {
    [SUB_CATEGORY_ID.ALL] =  {
        id = SUB_CATEGORY_ID.ALL,
        category = CATEGORY_ID.ALL,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        isDefault = true,
    },
    [SUB_CATEGORY_ID.WEAPONS_ALL] = {
        id = SUB_CATEGORY_ID.WEAPONS_ALL,
        category = CATEGORY_ID.WEAPONS,
        filterKey = EQUIPMENT_FILTER_TYPE_NONE,
        isDefault = true,
    },
    [SUB_CATEGORY_ID.WEAPONS_ONE_HANDED] = {
        id = SUB_CATEGORY_ID.WEAPONS_ONE_HANDED,
        category = CATEGORY_ID.WEAPONS,
        filterKey = EQUIPMENT_FILTER_TYPE_ONE_HANDED,
    },
    [SUB_CATEGORY_ID.WEAPONS_TWO_HANDED] = {
        id = SUB_CATEGORY_ID.WEAPONS_TWO_HANDED,
        category = CATEGORY_ID.WEAPONS,
        filterKey = EQUIPMENT_FILTER_TYPE_TWO_HANDED,
    },
    [SUB_CATEGORY_ID.WEAPONS_BOW] = {
        id = SUB_CATEGORY_ID.WEAPONS_BOW,
        category = CATEGORY_ID.WEAPONS,
        filterKey = EQUIPMENT_FILTER_TYPE_BOW,
    },
    [SUB_CATEGORY_ID.WEAPONS_DESTRUCTION_STAFF] = {
        id = SUB_CATEGORY_ID.WEAPONS_DESTRUCTION_STAFF,
        category = CATEGORY_ID.WEAPONS,
        filterKey = EQUIPMENT_FILTER_TYPE_DESTRO_STAFF,
    },
    [SUB_CATEGORY_ID.WEAPONS_RESTORATION_STAFF] = {
        id = SUB_CATEGORY_ID.WEAPONS_RESTORATION_STAFF,
        category = CATEGORY_ID.WEAPONS,
        filterKey = EQUIPMENT_FILTER_TYPE_RESTO_STAFF,
    },
    [SUB_CATEGORY_ID.ARMOR_ALL] = {
        id = SUB_CATEGORY_ID.ARMOR_ALL,
        category = CATEGORY_ID.ARMOR,
        filterKey = EQUIPMENT_FILTER_TYPE_NONE,
        isDefault = true,
    },
    [SUB_CATEGORY_ID.ARMOR_HEAVY] = {
        id = SUB_CATEGORY_ID.ARMOR_HEAVY,
        category = CATEGORY_ID.ARMOR,
        filterKey = EQUIPMENT_FILTER_TYPE_HEAVY,
    },
    [SUB_CATEGORY_ID.ARMOR_MEDIUM] = {
        id = SUB_CATEGORY_ID.ARMOR_MEDIUM,
        category = CATEGORY_ID.ARMOR,
        filterKey = EQUIPMENT_FILTER_TYPE_MEDIUM,
    },
    [SUB_CATEGORY_ID.ARMOR_LIGHT] = {
        id = SUB_CATEGORY_ID.ARMOR_LIGHT,
        category = CATEGORY_ID.ARMOR,
        filterKey = EQUIPMENT_FILTER_TYPE_LIGHT,
    },
    [SUB_CATEGORY_ID.ARMOR_SHIELD] = {
        id = SUB_CATEGORY_ID.ARMOR_SHIELD,
        category = CATEGORY_ID.ARMOR,
        filterKey = EQUIPMENT_FILTER_TYPE_SHIELD,
    },
    [SUB_CATEGORY_ID.JEWELRY_ALL] = {
        id = SUB_CATEGORY_ID.JEWELRY_ALL,
        category = CATEGORY_ID.JEWELRY,
        filterKey = EQUIPMENT_FILTER_TYPE_NONE,
        isDefault = true,
    },
    [SUB_CATEGORY_ID.JEWELRY_RING] = {
        id = SUB_CATEGORY_ID.JEWELRY_RING,
        category = CATEGORY_ID.JEWELRY,
        filterKey = EQUIPMENT_FILTER_TYPE_RING,
    },
    [SUB_CATEGORY_ID.JEWELRY_NECK] = {
        id = SUB_CATEGORY_ID.JEWELRY_NECK,
        category = CATEGORY_ID.JEWELRY,
        filterKey = EQUIPMENT_FILTER_TYPE_NECK,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_ALL] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_ALL,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        isDefault = true,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_FOOD] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_FOOD,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_FOOD,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_DRINK] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_DRINK,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_DRINK,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_RECIPE] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_RECIPE,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_RECIPE,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_POTION] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_POTION,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_POTION,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_POISON] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_POISON,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_POISON,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_WRIT] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_WRIT,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_MASTER_WRIT,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_MOTIF] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_MOTIF,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MOTIF,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_CONTAINER] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_CONTAINER,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_CONTAINER,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_TOOL] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_TOOL,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_REPAIR_ITEM,
    },
    [SUB_CATEGORY_ID.CONSUMABLE_TROPHY] = {
        id = SUB_CATEGORY_ID.CONSUMABLE_TROPHY,
        category = CATEGORY_ID.CONSUMABLE,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
    },
    [SUB_CATEGORY_ID.CRAFTING_ALL] = {
        id = SUB_CATEGORY_ID.CRAFTING_ALL,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        isDefault = true,
    },
    [SUB_CATEGORY_ID.CRAFTING_BLACKSMITHING] = {
        id = SUB_CATEGORY_ID.CRAFTING_BLACKSMITHING,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING,
    },
    [SUB_CATEGORY_ID.CRAFTING_CLOTHIER] = {
        id = SUB_CATEGORY_ID.CRAFTING_CLOTHIER,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING,
    },
    [SUB_CATEGORY_ID.CRAFTING_WOODWORKING] = {
        id = SUB_CATEGORY_ID.CRAFTING_WOODWORKING,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING,
    },
    [SUB_CATEGORY_ID.CRAFTING_JEWELRY] = {
        id = SUB_CATEGORY_ID.CRAFTING_JEWELRY,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING,
    },
    [SUB_CATEGORY_ID.CRAFTING_ALCHEMY] = {
        id = SUB_CATEGORY_ID.CRAFTING_ALCHEMY,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY,
    },
    [SUB_CATEGORY_ID.CRAFTING_ENCHANTING] = {
        id = SUB_CATEGORY_ID.CRAFTING_ENCHANTING,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING,
    },
    [SUB_CATEGORY_ID.CRAFTING_PROVISIONING] = {
        id = SUB_CATEGORY_ID.CRAFTING_PROVISIONING,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING,
    },
    [SUB_CATEGORY_ID.CRAFTING_STYLE_MATERIAL] = {
        id = SUB_CATEGORY_ID.CRAFTING_STYLE_MATERIAL,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL,
    },
    [SUB_CATEGORY_ID.CRAFTING_TRAIT_MATERIAL] = {
        id = SUB_CATEGORY_ID.CRAFTING_TRAIT_MATERIAL,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM,
    },
    [SUB_CATEGORY_ID.CRAFTING_FURNISHING_MATERIAL] = {
        id = SUB_CATEGORY_ID.CRAFTING_FURNISHING_MATERIAL,
        category = CATEGORY_ID.CRAFTING,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL,
    },
    [SUB_CATEGORY_ID.FURNISHING_ALL] = {
        id = SUB_CATEGORY_ID.FURNISHING_ALL,
        category = CATEGORY_ID.FURNISHING,
        filterKey = SPECIALIZED_ITEMTYPE_NONE,
        isDefault = true,
    },
    [SUB_CATEGORY_ID.FURNISHING_CRAFTING_STATION] = {
        id = SUB_CATEGORY_ID.FURNISHING_CRAFTING_STATION,
        category = CATEGORY_ID.FURNISHING,
        filterKey = SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION,
    },
    [SUB_CATEGORY_ID.FURNISHING_TARGET_DUMMY] = {
        id = SUB_CATEGORY_ID.FURNISHING_TARGET_DUMMY,
        category = CATEGORY_ID.FURNISHING,
        filterKey = SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY,
    },
    [SUB_CATEGORY_ID.FURNISHING_LIGHT] = {
        id = SUB_CATEGORY_ID.FURNISHING_LIGHT,
        category = CATEGORY_ID.FURNISHING,
        filterKey = SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT,
    },
    [SUB_CATEGORY_ID.FURNISHING_SEATING] = {
        id = SUB_CATEGORY_ID.FURNISHING_SEATING,
        category = CATEGORY_ID.FURNISHING,
        filterKey = SPECIALIZED_ITEMTYPE_FURNISHING_SEATING,
    },
    [SUB_CATEGORY_ID.FURNISHING_ORNAMENTAL] = {
        id = SUB_CATEGORY_ID.FURNISHING_ORNAMENTAL,
        category = CATEGORY_ID.FURNISHING,
        filterKey = SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_ALL] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_ALL,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        isDefault = true,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_COSTUME] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_COSTUME,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_APPEARANCE,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_GLYPHS] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_GLYPHS,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_GLYPH,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_SOUL_GEM] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_SOUL_GEM,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_SOUL_GEM,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_SIEGE] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_SIEGE,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_SIEGE,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_TOOL] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_TOOL,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_TOOL,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_TROPHY] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_TROPHY,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_TROPHY,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_FISHING] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_FISHING,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_LURE,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_TRASH] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_TRASH,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_TRASH,
    },
    [SUB_CATEGORY_ID.MISCELLANEOUS_MISC] = {
        id = SUB_CATEGORY_ID.MISCELLANEOUS_MISC,
        category = CATEGORY_ID.MISCELLANEOUS,
        filterKey = ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
    },
}
for id, data in pairs(SUB_CATEGORY_DEFINITION) do
    local categoryData = CATEGORY_DEFINITION[data.category]
    local filterData = ZO_ItemFilterUtils.GetSearchFilterData(categoryData.filterKey, data.filterKey)
    data.filterData = filterData
    data.label = filterData.filterString
    data.icons = filterData.icons
end

local DEFAULT_CATEGORY_ID = CATEGORY_ID.ALL
local DEFAULT_SUB_CATEGORY_ID = {
    [CATEGORY_ID.ALL] = SUB_CATEGORY_ID.ALL,
    [CATEGORY_ID.WEAPONS] = SUB_CATEGORY_ID.WEAPONS_ALL,
    [CATEGORY_ID.ARMOR] = SUB_CATEGORY_ID.ARMOR_ALL,
    [CATEGORY_ID.JEWELRY] = SUB_CATEGORY_ID.JEWELRY_ALL,
    [CATEGORY_ID.CONSUMABLE] = SUB_CATEGORY_ID.CONSUMABLE_ALL,
    [CATEGORY_ID.CRAFTING] = SUB_CATEGORY_ID.CRAFTING_ALL,
    [CATEGORY_ID.FURNISHING] = SUB_CATEGORY_ID.FURNISHING_ALL,
    [CATEGORY_ID.MISCELLANEOUS] = SUB_CATEGORY_ID.MISCELLANEOUS_ALL
}

local AGS = AwesomeGuildStore
AGS.data.CATEGORY_ID = CATEGORY_ID
AGS.data.SUB_CATEGORY_ID = SUB_CATEGORY_ID
AGS.data.CATEGORY_MAPPING = CATEGORY_MAPPING
AGS.data.CATEGORY_DEFINITION = CATEGORY_DEFINITION
AGS.data.SUB_CATEGORY_DEFINITION = SUB_CATEGORY_DEFINITION
AGS.data.DEFAULT_CATEGORY_ID = DEFAULT_CATEGORY_ID
AGS.data.DEFAULT_SUB_CATEGORY_ID = DEFAULT_SUB_CATEGORY_ID