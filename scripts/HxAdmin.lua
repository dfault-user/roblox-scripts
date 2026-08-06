-- BEGIN HEXAGON 2015 ADMIN SCRIPT
-- BY CLAIR FOR HEXAGON
-- All rights reserved

-- Top level service defs
Players = game:GetService("Players")
Debris = game:GetService("Debris")
Chat = game:GetService("Chat")
ReplicatedStorage = game:GetService("ReplicatedStorage")
HttpService = game:GetService("HttpService")
MarketplaceService = game:GetService("MarketplaceService")

-- absolute raw funcs
function toboolean(inp)
	if type(inp) == "string" then
		if inp:lower() == "true" then return true else return false end -- Python "True" or "False" -> true/false
	elseif type(inp) == "number" then
		if inp == 1 then return true else return false end -- it's fucking binary dude
	end

	return false
end

-- ALL SYSTEMS GO
HxAdmin = {
	Version = '0.4.0',

	Separator = "/",

	TestMode = false,

    Clients = {}
}

function HxAdmin.TblFind(t, condition)
    if type(condition) == 'function' then
        for key, value in pairs(t) do
            if condition(value, key) then
                return value, key
            end
        end
    else
        for key, value in pairs(t) do
            if value == condition then
                return value, key
            end
        end
    end
end

function HxAdmin.ttTrim(str)
	return str:match("^%s*(.-)%s*$")
end

function HxAdmin:Split(input, separator, limit)
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
	local items = HxAdmin:Split(rest, separator, limit - 1)
	table.insert(items, 1, first)
	return items
end

function HxAdmin:ChatOutput(player, str, ChatColor)
	if not type(player) == "userdata" and player:IsA("Player") or type(str) ~= "string" then return false end
	repeat wait() until player.Character ~= nil
	return Chat:Chat(player.Character, string.format("[HxAdmin] %s", str),
		ChatColor or Enum.ChatColor.Green
	)
end

function HxAdmin:Output(thread, ...)
	return print(
		string.format("[HxAdmin:%s] %s",
			tostring(thread),
			...)
	)
end

function HxAdmin:Warn(thread, ...)
	return warn(
		string.format("[HxAdmin:%s] %s",
			tostring(thread),
			...)
	)
end

function HxAdmin:Error(thread, ...)
	return error(
		string.format("[HxAdmin:%s] %s",
			tostring(thread),
			...)
	)
end

function HxAdmin:HintDisplay(thread, output)
	pcall(function()
		if workspace["HxAdminHint"] then
			workspace["HxAdminHint"]:Destroy()
		end
	end)

	local new_hint = Instance.new("Hint", workspace)
	Debris:AddItem(new_hint, 1.5)
	new_hint.Name = "HxAdminHint"
	local hint_text = ("[HxAdmin:%s] %s"):format(tostring(thread), output)
	new_hint.Text = hint_text
end

function HxAdmin.PlayerLookup(inp)
	local normalized_input = inp:lower()
	for _, player in pairs(Players:GetChildren()) do
		local normalized_name = player.Name:lower()
		if normalized_name:sub(1, #normalized_input) == normalized_input then
			return player
		end
	end
	return nil
end

function HxAdmin:Attest(player)
	if not type(player) == "userdata" and not player:IsA("Player") then return false end

	if ReplicatedStorage:FindFirstChild("HxOptout") then
		return false
	end

	if HxAdmin.TestMode then
		return true
	end

	local StaffAttestationRequest = game:HttpGet(("https://hexagon.pw/api/staff?userId=%u"):format(player.userId), true)
	if toboolean(StaffAttestationRequest) then
		return true
	end

	return false
end

function HxAdmin:NewLocalScript(player, source, destroyAfterExecution)
	destroyAfterExecution = destroyAfterExecution or false
	if type(player) ~= "userdata" or not player:IsA("Player") then return false end
	if type(source) ~= "string" then return false end

    local player_backpack = player:WaitForChild("Backpack")
	local localScriptContainer = Instance.new("LocalScript")
	localScriptContainer.Name = "HxLSC" .. HttpService:GenerateGUID(false):sub(1,8)
	localScriptContainer.Source = [[print(script.Name.. " running from HxAdmin")
	]]..source
	
	if destroyAfterExecution then
		localScriptContainer.Source = localScriptContainer.Source .. [[
		wait(3);script:Destroy()]]
	end


	localScriptContainer.Parent = player_backpack
end

function HxAdmin.Evict(moderator, victim, reason)
	if type(moderator) ~= "userdata" or not moderator:IsA("Player") then return false end
	if type(victim) ~= "userdata" or not victim:IsA("Player") then return false end

	if reason == "" or reason == nil then reason = "(no reason attached)" end

	local kuic14s = Instance.new("ScreenGui", victim.PlayerGui) -- kick ui cuz 2014 sucks
	local kuic14s_f = Instance.new("Frame", kuic14s)
	kuic14s_f.Size = UDim2.new(1, 0, 1, 0)
	kuic14s_f.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
	kuic14s_f.BackgroundTransparency = 0.2
	kuic14s_f.BorderSizePixel = 0 

	local kuic14s_ftl = Instance.new("TextLabel", kuic14s_f)
	kuic14s_ftl.TextScaled = true
	kuic14s_ftl.Size = UDim2.new(1, 0, 1, 0)
	kuic14s_ftl.BackgroundTransparency = 1
	kuic14s_ftl.BorderSizePixel = 0
	kuic14s_ftl.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	kuic14s_ftl.TextWrapped = true
	kuic14s_ftl.Font = Enum.Font.SourceSans	

	local kick_reason = ("You were removed from the server by %s for %s."):format(tostring(moderator), HxAdmin.ttTrim(reason))
	kuic14s_ftl.Text = kick_reason
	wait(1)
	victim:Kick(kick_reason)

	return HxAdmin:Output("Evict", ("%s was removed from the server by HxAdmin for %s"):format(tostring(victim), tostring(reason)))
end

-- Start HxAudio
HxAudio = {
	Audio = Instance.new("Sound"),
	AudioNormalizedTitle = nil,	
	Container = Instance.new("Model")
}

HxAudio["Container"].Parent = workspace
HxAudio["Container"].Name = "HxAudio"

HxAudio["Audio"].Parent = HxAudio["Container"]
HxAudio["Audio"].Name = "HxAudio"

function HxAudio:ResolveSID(soundId)
	if type(soundId) ~= "number" then 
		if type(soundId) == "string" then
			if tonumber(soundId) then
				soundId = tonumber(soundId)
			else
				HxAdmin:Error("HxAudio:ResolveSID", "String passed could not be resolved to a number")
			end
		end
	end

	local mpResolveSuccess, mpResolveResult = pcall(MarketplaceService.GetProductInfo, MarketplaceService, soundId)
	
	if mpResolveSuccess and mpResolveResult.AssetTypeId == 3 then
		HxAudio["AudioNormalizedTitle"] = mpResolveResult.Name
	elseif mpResolveSuccess and mpResolveResult.AssetTypeId ~= 3 then
		HxAdmin:Error("HxAudio:ResolveSID", "Invalid asset type")
	else
		HxAudio["AudioNormalizedTitle"] = ("rbxassetid://%u"):format(soundId)
	end
	return ("rbxassetid://%u"):format(soundId)
end

function HxAudio:Reset()
	if HxAudio["Audio"] then
		local Audio = HxAudio["Audio"]
		Audio:Stop()
		wait()
		Audio.SoundId = "rbxassetid://0"
		wait()
		return true
	else
		return false
	end
end

function HxAudio:Play(soundId, volume, pitch, looped)
	if HxAudio["Audio"] then 
		if soundId ~= nil then 
			HxAudio:Reset()
			
			local Audio = HxAudio["Audio"]
			local resolvedSoundId = HxAudio:ResolveSID(soundId)
			
			Audio.SoundId = resolvedSoundId
			Audio.Volume = volume or 1
			Audio.Pitch = pitch or 1
			Audio.Looped = looped or true
			HxAdmin:Output("HxAudio:Play", "Set sound ID to " .. soundId)
			
			HxAdmin:Output("HxAudio:Play", "Now playing: " .. tostring(HxAudio.AudioNormalizedTitle))
			HxAdmin:HintDisplay("HxAudio", "Now playing: " .. tostring(HxAudio.AudioNormalizedTitle))

			wait()
			Audio:Play()
			return true
		end
	end

	return false
end

function HxAdmin:SetVolume(volume)
	if HxAudio["Audio"] then
		if volume>2 then volume = 2 elseif volume<0 then volume = 0 end
		HxAudio["Audio"].Volume = volume
		HxAdmin:Output("HxAudio:Volume", "Set volume to " .. tostring(volume))
		return true
	end
	return false
end

function HxAdmin:SetPitch(pitch)
	if HxAudio["Audio"] then
		if pitch>2 then pitch = 2 elseif pitch<0.1 then pitch = 0.1 end
		HxAudio["Audio"].Pitch = pitch
		HxAdmin:Output("HxAudio:Pitch", "Set pitch to " .. tostring(pitch))
		return true
	end
	return false
end

function HxAdmin:TogglePlayback()
	if HxAudio["Audio"] then
		local Audio = HxAudio["Audio"]
		if Audio.IsPlaying then
			wait()
			Audio:Pause()
			HxAdmin:Output("HxAudio:TogglePlayback", "Paused audio")
		else
			wait()
			Audio:Play()
			HxAdmin:Output("HxAudio:TogglePlayback", "Resumed audio")
		end
		return true
	end
	return false
end

-- End HxAudio

-- Start HxServer
local HxServer = Instance.new("RemoteFunction", ReplicatedStorage)
HxServer.Name = "HxServer"
HxServer.OnServerInvoke = function(Player, Command)
    local acceptedCommands = {"reg"}
    local Command = Command:lower()
    if HxAdmin.TblFind(acceptedCommands, Command:lower()) then
        if Command:lower() == "reg" then
			HxAdmin.Clients[Player.Name] = Player
			HxAdmin:Output("Register_"..Player.Name, "HxClient registered")
			HxServer:InvokeClient(Player, "reg_suc")
			return true
		end
    end
end
-- End HxServer

HxAdmin.Commands = {
	test = {
		["FriendlyName"] = "Test",
		["Exec"] = function(player, ...)
			HxAdmin:ChatOutput(player, "Arguments: " .. table.concat(..., ','))
			return {
				player, ...
			}
		end,
	},
	kick = {
		["FriendlyName"] = "Kick",
		["Exec"] = function(player, args)
			local victim, reason = HxAdmin.PlayerLookup(args[1]), (args[2] or "(no reason attached)")
			if victim ~= nil then 
				HxAdmin.Evict(player, victim, reason)
			end
		end,
	},
	goto = {
		["FriendlyName"] = "Go To",
		["Exec"] = function(player, args)
			local target = HxAdmin.PlayerLookup(args[1])
			if target ~= nil then
				local modCharacter, targetCharacter = player.Character, target.Character
				repeat wait() until modCharacter ~= nil or targetCharacter ~= nil
				modCharacter.HumanoidRootPart.CFrame = targetCharacter.HumanoidRootPart.CFrame + Vector3.new(math.random(3,7), math.random(3,7), math.random(3,7))
				HxAdmin:ChatOutput(player, "Teleported to "..tostring(target)..".", Enum.ChatColor.Blue)
				HxAdmin:ChatOutput(target, tostring(player).. " teleported to you.", Enum.ChatColor.Blue)
			end
		end
	},
	errortest = {
        ["FriendlyName"] = "Error Test",
        ["Exec"] = function(player, ...)
            return error(table.concat(..., ", "))
        end,
    },
    regtest = {
        ["FriendlyName"] = "Register Test",
        ["Exec"] = function(player)
            local collectedPlayers = ""
            for player,_ in pairs(HxAdmin.Clients) do 
                collectedPlayers = collectedPlayers .. player .. ", "
            end
            collectedPlayers = collectedPlayers:sub(1,#collectedPlayers-2)
            HxAdmin:ChatOutput(player, "Registered players: " .. collectedPlayers)
        end
    },	
	mute = {
		["FriendlyName"] = "Mute",
		["Exec"] = function(player, args)
			local target = HxAdmin.PlayerLookup(args[1])
			if target ~= nil then
				HxAdmin:NewLocalScript(target, [[local sg=game:GetService("StarterGui");sg:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false);wait();script:Remove()]])
				HxAdmin:ChatOutput(target, "You have been muted by "..tostring(player)..".", Enum.ChatColor.Red)
			end
		end,
	},
	unmute = {
		["FriendlyName"] = "UnMute",
		["Exec"] = function(player, args)
			local target = HxAdmin.PlayerLookup(args[1])
			if target ~= nil then
				HxAdmin:NewLocalScript(target, [[local sg=game:GetService("StarterGui");sg:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true);wait();script:Remove()]])
				HxAdmin:ChatOutput(target, "You have been unmuted by "..tostring(player)..".", Enum.ChatColor.Blue)
			end
		end,
	},

	play = {
		["FriendlyName"] = "HxAudio Play",
		["Exec"] = function(player, args)
			local sid = args[1]
			local volume, pitch, looped
			if #args>1 then
				volume = tonumber(args[2]) or 1
				pitch = tonumber(args[3]) or 1
				looped = args[4] == "true" and true or false
			end

			if #sid>0 then HxAudio:Play(sid, volume, pitch, looped) else HxAudio:Reset() end
		end
	},

	volume = {
		["FriendlyName"] = "HxAudio Volume",
		["Exec"] = function(player, args)
			local volume = tonumber(args[1])
			if volume then HxAdmin:SetVolume(volume) end
		end,
	},
	pitch = {
		["FriendlyName"] = "HxAudio Pitch",
		["Exec"] = function(player, args)
			local pitch = tonumber(args[1])
			if pitch then HxAdmin:SetPitch(pitch) end
		end,
	},
	pause = {
		["FriendlyName"] = "HxAudio Pause/Resume",
		["Exec"] = function(player, args)
			HxAdmin:TogglePlayback()
		end,
	}
}

-- Start HxClient
function HxAdmin:AttachHxClient(player)
	local hxClientSource = [[
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local StarterGui = game:GetService("StarterGui")
	repeat wait() until ReplicatedStorage["HxServer"]
    local HxServer = ReplicatedStorage["HxServer"]
    local HxClient = {}

	function HxClient:Output(thread, ...)
		return print(
			string.format("[HxAdmin:%s] %s",
				tostring(thread),
				...)
		)
	end

	function HxClient:Warn(thread, ...)
		return warn(
			string.format("[HxAdmin:%s] %s",
				tostring(thread),
				...)
		)
	end

	function HxClient:Error(thread, ...)
		return error(
			string.format("[HxAdmin:%s] %s",
				tostring(thread),
				...)
		)
	end

    function HxClient.TblFind(t, condition)
        if type(condition) == 'function' then
            for key, value in pairs(t) do
                if condition(value, key) then
                    return value, key
				end
            end
        else
            for key, value in pairs(t) do
                if value == condition then
                    return value, key
                end
            end
        end
    end
    HxClient:Output("Bootstrap", "Waking up the client")
    HxServer.OnClientInvoke = function(Command, ...)
		local acceptedCommands = {
			["reg_suc"] = function()
				HxClient:Output("Register", "Server accepted our registration")
				return "Registration accepted"
			end,
			["out"] = function(thread, ...)
				HxClient:Output(thread, ...)
			end,
		}
        local Command = Command:lower()
        if acceptedCommands[Command] then
			local clientCommandSuccess, clientCommandResult = pcall(acceptedCommands[Command], ...)
			HxClient:Output(Command.."_Output", "Client invoke fired with success state of "..tostring(clientCommandSuccess).. " (Result: "..(tostring(clientCommandResult) or "none")..")")
        end
    end

    HxServer:InvokeServer("reg")
	]]
    
	HxAdmin:NewLocalScript(player, hxClientSource)
end
-- End HxClient

function HxAdmin:connect(player)
	HxAdmin:HintDisplay("Chat", player.Name .. " joined.")
	HxAdmin:ChatOutput(player, string.format("Welcome, %s. HxAdmin version %s", player.Name, HxAdmin.Version))
	return player.Chatted:connect(function(con_msg)
		local isCommandInvocation = (string.find(con_msg, HxAdmin.Separator) and string.sub(con_msg, 1, string.find(con_msg, HxAdmin.Separator) - 1) ~= "") and HxAdmin.Commands[string.sub(con_msg, 1, string.find(con_msg, HxAdmin.Separator) - 1)] ~= nil
		if isCommandInvocation then
			local command = HxAdmin.Commands[string.sub(con_msg, 1, string.find(con_msg, HxAdmin.Separator) - 1)]
			local firstSep, _ = string.find(con_msg, HxAdmin.Separator), nil
			local commandArguments = HxAdmin:Split(con_msg:sub(firstSep+1), HxAdmin.Separator)
			local commandAttemptSuccess, commandAttemptReturnStatus = pcall(command.Exec, player, commandArguments)
			if not commandAttemptSuccess then
				HxAdmin:ChatOutput(player, "An error occurred while executing a command. You're on your own!", Enum.ChatColor.Red)
				HxAdmin:Output(command.FriendlyName, string.format("An error occurred while executing command: %s", tostring(commandAttemptReturnStatus)))
				HxServer:InvokeClient(player, "out", tostring(command.FriendlyName), tostring(commandAttemptReturnStatus))
			end
		end
	end)
end

	Players.PlayerAdded:connect(function(player)
		HxAdmin:Output("PlayerAdded", 
			string.format(
				"%s joined", 
				tostring(player)
			)
		)
		
		HxAdmin:AttachHxClient(player)
		if HxAdmin:Attest(player) then
			HxAdmin:connect(player)
		end
	end)

    Players.PlayerRemoving:connect(function(player)
        pcall(function()
			if HxAdmin.Clients[player.Name] then
				HxAdmin.Clients[player.Name] = nil
			end
		end)
		HxAdmin:Output("PlayerRemoving", 
		string.format(
			"%s left", 
			tostring(player)
		)
	)
    end)