-- LibHistoire & its files © sirinsidiator                      --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local LIB_IDENTIFIER = "LibHistoire"

assert(not _G[LIB_IDENTIFIER], LIB_IDENTIFIER .. " is already loaded")

local lib = {}
_G[LIB_IDENTIFIER] = lib

local nextNamespaceId = 1

local function RegisterForEvent(event, callback)
    local namespace = LIB_IDENTIFIER .. nextNamespaceId
    EVENT_MANAGER:RegisterForEvent(namespace, event, callback)
    nextNamespaceId = nextNamespaceId + 1
    return namespace
end

local function UnregisterForEvent(namespace, event)
    return EVENT_MANAGER:UnregisterForEvent(namespace, event)
end

local function RegisterForUpdate(interval, callback)
    local namespace = LIB_IDENTIFIER .. nextNamespaceId
    EVENT_MANAGER:RegisterForUpdate(namespace, interval, callback)
    nextNamespaceId = nextNamespaceId + 1
    return namespace
end

local function UnregisterForUpdate(namespace)
    return EVENT_MANAGER:UnregisterForUpdate(namespace)
end

local callbackObject = ZO_CallbackObject:New()
lib.internal = {
    callbackObject = callbackObject,
    callback = {
        INITIALIZED = "HistyIsReadyForAction",
        UNLINKED_EVENTS_ADDED = "HistyHasAddedUnlinkedEvents",
        EVENT_STORED = "HistyStoredAnEvent",
        HISTORY_BEGIN_LINKING = "HistyHasStartedLinkingEvents",
        HISTORY_LINKED = "HistyHasLinkedEvents",
        HISTORY_RELOADED = "HistyHasDetectedAHistoryReload",
        HISTORY_RESCAN_STARTED = "HistyHasStartedAHistoryRescan",
        HISTORY_RESCAN_ENDED = "HistyHasFinishedAHistoryRescan",
        SELECTED_GUILD_CHANGED = "HistyDetectedTheSelectedGuildHasChanged",
        SELECTED_CATEGORY_CHANGED = "HistyDetectedTheSelectedCategoryHasChanged",
    },
    class = {},
    logger = LibDebugLogger(LIB_IDENTIFIER),
    RegisterForEvent = RegisterForEvent,
    UnregisterForEvent = UnregisterForEvent,
    RegisterForUpdate = RegisterForUpdate,
    UnregisterForUpdate = UnregisterForUpdate,
}
local internal = lib.internal

function internal:FireCallbacks(...)
    return callbackObject:FireCallbacks(...)
end

function internal:RegisterCallback(...)
    return callbackObject:RegisterCallback(...)
end

function internal:UnregisterCallback(...)
    return callbackObject:UnregisterCallback(...)
end

function internal:InitializeSaveData()
    LibHistoire_Settings = LibHistoire_Settings or {
        version = 1,
        statusWindow = {
            enabled = true,
            locked = true
        }
    }

    LibHistoire_GuildNames = LibHistoire_GuildNames or {}
    LibHistoire_NameDictionary = LibHistoire_NameDictionary or {}
    LibHistoire_GuildHistory = LibHistoire_GuildHistory or {}

    local server = GetWorldName()
    self.guildNames = LibHistoire_GuildNames[server] or {}
    LibHistoire_GuildNames[server] = self.guildNames
end

function internal:Initialize()
    local logger = self.logger
    logger:Info("Initializing LibHistoire...")

    local namespace
    namespace = RegisterForEvent(EVENT_ADD_ON_LOADED, function(event, name)
        if(name ~= LIB_IDENTIFIER) then return end
        UnregisterForEvent(namespace, EVENT_ADD_ON_LOADED)
        self:InitializeSaveData()
        logger:Debug("Saved Variables loaded")

        self.nameCache = self.class.DisplayNameCache:New(LibHistoire_NameDictionary)
        self.historyAdapter = self.class.GuildHistoryAdapter:New()
        self.statusTooltip = self.class.GuildHistoryStatusTooltip:New()
        self.historyCache = self.class.GuildHistoryCache:New(self.nameCache, self.statusTooltip, LibHistoire_GuildHistory)

        self.statusWindow = self.class.GuildHistoryStatusWindow:New(self.historyAdapter, self.statusTooltip, LibHistoire_Settings.statusWindow)

        self:SetupDialogHook("LOG_OUT")
        self:SetupDialogHook("QUIT")

        local count = 0
        for _, events in pairs(LibHistoire_GuildHistory) do
            count = count + #events
        end
        logger:Info("Initialization complete - holding %d guild history events", count)
        self:FireCallbacks(self.callback.INITIALIZED)
    end)
end

function internal:ConvertNumberToId64(value)
    return StringToId64(tostring(value))
end

function internal:ConvertId64ToNumber(value)
    return tonumber(Id64ToString(value))
end

function internal:CreateAsyncTask()
    local taskId = self.nextTaskId or 1
    self.nextTaskId = taskId + 1
    local task = LibAsync:Create(LIB_IDENTIFIER .. taskId)
    task:OnError(function()
        self.logger:Error(task.Error)
    end)
    return task
end
