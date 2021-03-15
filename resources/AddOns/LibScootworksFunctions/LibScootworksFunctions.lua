local LibScootworksFunctions = ZO_Object:Subclass()

local API_VERSION = GetAPIVersion()
local ADDON_MANAGER = GetAddOnManager()
local DEBUG_ENABLED = true

function LibScootworksFunctions:New(...)
	local object = ZO_Object.New(self)
	object:Initialize(...)
	return object
end

function LibScootworksFunctions:Initialize()
	-- Collect messages if your chat system is not ready. It fires all the collected messages if the chat system is ready automatically.
	self.messages = { }
	
	local function SendCollectedMessages()
		local numMessages = #self.messages
		if numMessages > 0 then
			for i=1, numMessages do
				self:AddMessage(self.messages[i])
			end
			ZO_ClearNumericallyIndexedTable(self.messages)
		end
	end
	EVENT_MANAGER:RegisterForEvent("LibScootworksFunctions", EVENT_PLAYER_ACTIVATED, SendCollectedMessages)

	-- slash commands
	SLASH_COMMANDS["/rl"] = function() ReloadUI("ingame") end
	SLASH_COMMANDS["/langfr"] = function() SetCVar("language.2", "fr") end
	SLASH_COMMANDS["/langen"] = function() SetCVar("language.2", "en") end
	SLASH_COMMANDS["/langde"] = function() SetCVar("language.2", "de") end
	SLASH_COMMANDS["/vote"] = function(...) BeginGroupElection(GROUP_ELECTION_TYPE_GENERIC_SUPERMAJORITY, tostring(...)) end
end

-- if player not activated, collect the message. otherwise send a system message in every tab
function LibScootworksFunctions:AddMessage(message, prefix)
	local messageFormat
	if prefix then
		messageFormat = string.format("%s%s", ZO_ERROR_COLOR:Colorize(prefix), message)
	else
		messageFormat = message
	end
	
	if CHAT_SYSTEM.primaryContainer then
		CHAT_SYSTEM.primaryContainer:OnChatEvent(nil, messageFormat, CHAT_CATEGORY_SYSTEM)
	else
		self.messages[#self.messages+1] = messageFormat
	end
end

function LibScootworksFunctions:MessageDelayHandler(message, prefix, delayMs)
	if delayMs and type(delayMs) == "number" then
		zo_callLater(function() self:AddMessage(message, prefix) end, delayMs)
	else
		self:AddMessage(message, prefix)
	end
end

-- This is the main function to send a normal chat message
function LibScootworksFunctions:ChatMessage(message, addonName, delayMs)
	self:MessageDelayHandler(message, addonName and string.format("[%s] ", addonName) or nil, delayMs or nil)
end

-- This is the main function to send a debug chat message
function LibScootworksFunctions:ChatMessageDebug(message, addonName, isInDebugMode, delayMs)
	local isDebugTypeValid = type(isInDebugMode) == "boolean" and isInDebugMode or false
	if isDebugTypeValid then
		local prefix
		if type(addonName) == "string" then
			prefix = string.format("[%s Debug] ", addonName)
		else
			prefix = "[Debug] "
		end		
		self:MessageDelayHandler(message, prefix, delayMs)
	end
end

-- If an addon is out of date, return false
function LibScootworksFunctions:IsAddonVersionSameGameVersion(supportedAPIVersion1, supportedAPIVersion2, addonName)
	local addonVersion
	if type(supportedAPIVersion1) == "table" then
		addonVersion = math.max(unpack(supportedAPIVersion1))
		addonName = supportedAPIVersion2
	elseif type(supportedAPIVersion1) == "number" then
		addonVersion = math.max(supportedAPIVersion1, supportedAPIVersion2 or 0)
	end
	
	if API_VERSION > addonVersion then
		self:ChatMessageDebug(GetString(SI_SCOOTWORKS_FUNCTIONS_UPDATE_ADDON), addonName, DEBUG_ENABLED)
		return false
	end
	return true
end

-- Is a specific addon enabled?
function LibScootworksFunctions:IsAddonStateEnabled(addonName)
	for i = 1, ADDON_MANAGER:GetNumAddOns() do
		local name, _, _, _, _, state = ADDON_MANAGER:GetAddOnInfo(i)
		if name == addonName and state == ADDON_STATE_ENABLED then
			return true
		end
	end
	return false
end

-- Wrap a function
function LibScootworksFunctions:WrapFunction(object, functionName, wrapper)
	if type(object) == "string" then
		wrapper = functionName
		functionName = object
		object = _G
	end
	local originalFunction = object[functionName]
	object[functionName] = function(...) return wrapper(originalFunction, ...) end
end

-- global
LIB_SCOOTWORKS_FUNCTIONS = LibScootworksFunctions:New()
