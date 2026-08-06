--[[
  _    _                   _           _         ___  
 | |  | |         /\      | |         (_)       |__ \ 
 | |__| |_  __   /  \   __| |_ __ ___  _ _ __      ) |
 |  __  \ \/ /  / /\ \ / _` | '_ ` _ \| | '_ \    / / 
 | |  | |>  <  / ____ \ (_| | | | | | | | | | |  / /_ 
 |_|  |_/_/\_\/_/    \_\__,_|_| |_| |_|_|_| |_| |____|
                                                      
                                                      
--]]

-- Top-level service definitions
Players = game:GetService("Players")
ReplicatedStorage = game:GetService("ReplicatedStorage")
HttpService = game:GetService("HttpService")
InsertService = game:GetService("InsertService")
MarketplaceService = game:GetService("MarketplaceService")
_LOCAL = (function() local privCallSuccess, _ = pcall(function() game:HttpGet('https://hexagon.pw') end) return not privCallSuccess end)()

_RBX_VERSION = (function()
        if (function() local s, r = pcall(function() return game:GetService("GuiService").GetClosestDialogToPosition end) if s then return true else return false end end)() then
            return "2015"
        elseif (function() local s, r = pcall(function() return Enum.UserInputType.Accelerometer end) if s then return true else return false end end)() then
            return "2014"
        else
            return "2013"
        end
end)()

-- Top-level HxAdmin
HxAdmin = {
	ReportedVersion = "NXG",
	Prefix = "hx!",
	Commands = {},
	Subsystems = {
		ReplicatedStorage.HxMessaging.MainModule, -- Messaging
		ReplicatedStorage.HxAudio2.MainModule, -- HxAudio
		ReplicatedStorage.HxTeleport.MainModule, -- Teleport
		ReplicatedStorage.HxExample.MainModule, -- Example
		ReplicatedStorage.HxAsset.MainModule, -- Asset
		ReplicatedStorage.HxClient.MainModule, -- Asset
	}
}

-- Top-level utility definitions
Util = {}

function Util:Output(thread, ...)
	return print(
		string.format("[HxAdmin:%s] %s",
			tostring(thread),
			...)
	)
end

function Util:Warn(thread, ...)
	return warn(
		string.format("[HxAdmin:%s] %s",
			tostring(thread),
			...)
	)
end

function Util:Error(thread, ...)
	return error(
		string.format("[HxAdmin:%s] %s",
			tostring(thread),
			...)
	)
end

function Util:Split(input, separator, limit)
	
	if input == nil or input == "" then
		return {}
	end
	
	if #input == 0 then
		if string.find(input, separator) then
			return {}
		else
			return {""}
		end
	end
	if not limit then
		limit = -1
	end
	if limit == 1 then
		return {input}
	end
	if not separator then
		separator = "%s+"
	end
	local start, stop = string.find(input, separator)
	if not start then
		return {input}
	end
	-- special case, delimiter resolved to ""
	if stop < 1 then
		start, stop = string.find(string.sub(input, 2), separator)
		start = start + 1
		stop = stop + 1
	end
	local first = string.sub(input, 1, start - 1)
	local rest = string.sub(input, stop + 1)
	-- special case, non empty pattern found at the end
	if #rest == 0 and stop >= start then
		return {first, rest}
	end
	local items = Util:Split(rest, separator, limit - 1)
	table.insert(items, 1, first)
	return items
end

function Util:GatherSplit(str)
	return Util:Split(str, ",")
end

function Util:toboolean(inp)
	if type(inp) == "string" then
		if inp:lower() == "true" then return true else return false end -- Python "True" or "False" -> true/false
	elseif type(inp) == "number" then
		if inp == 1 then return true else return false end -- it's fucking binary dude
	end

	return false
end

-- Start HxAdmin
Util:Output("Init", ("Starting HxAdmin %s on %s"):format(HxAdmin.ReportedVersion, _RBX_VERSION))

function HxAdmin:Select(player, str)
	if type(player) ~= "userdata" or not player:IsA("Player") then
		return nil
	elseif type(str) ~= "string" or str == nil then
		return nil
	end
		
	local Selectors = {
		all = (function() return Players:GetPlayers() end),
		others = (function() local g = {} for _,p in pairs(Players:GetPlayers()) do if p ~= player then table.insert(g,p) end end return g end),
		me = (function() return player end)
		}
	
	if Selectors[str] then
		return Selectors[str]()
	elseif #str>0 then
		local normalizedInput = str:lower()
		for _, p in pairs(Players:GetPlayers()) do
			local normalizedName = p.Name:lower()
			if normalizedName:sub(1, #normalizedInput) == normalizedInput then
				return p
			end
		end
	end
	
	return nil
end

function HxAdmin:Connect(player)
	if type(player) ~= "userdata" or not player:IsA("Player") then Util:Error("Instance isn't a player, bailing") end
	Util:Output("HxAdmin:Connect", ("Connecting to %s (%u)"):format(player.Name, player.userId))
	player.Chatted:connect(function(message)
		local isPossibleCommand, isMostDefinitelyACommand, firstSpaceInCommand, hxCommand, hxCommandArguments 
		isPossibleCommand = (message:sub(1, #HxAdmin.Prefix) == HxAdmin.Prefix)
		isMostDefinitelyACommand = (isPossibleCommand and HxAdmin.Commands[message:lower():sub(#HxAdmin.Prefix+1, (message:find(" ") or 0)-1)] ~= nil)
		if isMostDefinitelyACommand then
			firstSpaceInCommand = message:find(" ")
			hxCommand = HxAdmin.Commands[message:lower():sub(#HxAdmin.Prefix+1, firstSpaceInCommand and firstSpaceInCommand-1 or nil)]
			hxCommandArguments = firstSpaceInCommand and Util:Split(message:sub(firstSpaceInCommand+1)) or {}
			for index, argument in pairs(hxCommandArguments) do
				if argument:find(",") then
					hxCommandArguments[index] = Util:Split(argument, ",")
				end
			end
			
			local hxCommandAttempt, hxCommandAttemptReturn = pcall(hxCommand.Exec, player, hxCommandArguments)
			if not hxCommandAttempt then
				Util:Warn(hxCommand.CommandFriendlyName, string.format("An error occurred while executing command: %s", tostring(hxCommandAttemptReturn)))
			end
		end
	end)
	
end

-- Top-level command constructor
Command = setmetatable({}, {
	__index = function()
		Util:Error("Command:__index", "Table unindexable")
	end,
	
	__call = function(self, command_data)
		-- validate command structure
		if type(command_data) ~= "table" then
			Util:Error("Commands:construct", "Command data is not a table, bailing")
		end
		
		if not ((command_data["CommandName"] ~= nil) and type(command_data["CommandName"]) == "string") 
		or not ((command_data["CommandFriendlyName"] ~= nil) and (type(command_data["CommandFriendlyName"]) == "string"))
		or not ((command_data["CommandExec"] ~= nil) and(type(command_data["CommandExec"]) == "function")) then
			Util:Error("Commands:construct", "Command data structure is invalid, bailing")
		end
		
		Util:Output("CommandSystem", ("Registering %s as %s"):format(command_data.CommandFriendlyName, command_data.CommandName))
		if HxAdmin.Commands[command_data["CommandName"]:lower()] then
			Util:Error("Commands:construct", "DUPLICATE!!!")
		end
		HxAdmin.Commands[command_data["CommandName"]:lower()] = {
			CommandFriendlyName = command_data["CommandFriendlyName"],
			Exec = command_data["CommandExec"]
		}
	end
})


-- Define all base commands
Command({
		CommandName = "test",
		CommandFriendlyName = "Test",
		CommandExec = function(calling_player, arguments)
			Util:Output("HxCommand:Test", #arguments)
		end
})

Command({
	CommandName = "stest",
	CommandFriendlyName = "Selector Test",
	CommandExec = function(calling_player, arguments)
		if #arguments>1 then return false end
		if arguments[1]:find(",") then return false end
		local selectResult = HxAdmin:Select(calling_player, arguments[1])
		if type(selectResult) == "table" then
			local opString = "Players: "
			for _, player in pairs(selectResult) do
				opString = opString .. (player.Name .. " ")
			end
			
			Util:Output("HxCommand:STest", opString)
		elseif type(selectResult) == "userdata" then
			if selectResult:IsA("Player") then
				Util:Output("HxCommand:STest", selectResult.Name)
			end
		end
	end
})

-- Start HxAdmin
Util:Output("Init", "Adding PlayerAdded hooks")

Players.PlayerAdded:connect(function(player)
	Util:Output("PlayerAdded", ("%s (%u) connected"):format(player.Name, player.userId))
	if ReplicatedStorage:FindFirstChild("HxOptout") == nil then
		HxAdmin:Connect(player)	
	end
end)

-- Initialize subsystems, if we can
for _, Subsystem in pairs(HxAdmin.Subsystems) do
	if type(Subsystem) == "userdata" and _LOCAL then 
		if Subsystem:IsA("ModuleScript") then 
			require(Subsystem)(getfenv()) 
		end 
	elseif type(Subsystem) == "number" then 
		if _LOCAL then 
			require(Subsystem)(getfenv())
		else
			local InsertSubsystem = game:GetObjects("https://hexagon.pw/asset?id="..tostring(Subsystem))
			if InsertSubsystem then 
				local Module = InsertSubsystem[1]
				require(Module)(getfenv())
			end
		end
	end
end