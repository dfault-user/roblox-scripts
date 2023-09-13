--[[
	Muse, an extensible admin system by brandan/Control22/dfu
	Made for Kapish 2016

	MIT License

	Copyright (c) 2023 Brandan C. Delafuente
	
	Permission is hereby granted, f`ree of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

Muse = {}

Muse.Version = '2.0.0'

Muse.Settings = {
	Seperator = "/",
		
	Admins = {
		--	"Player1",
		--	"Player",
			"brandan",
			"gyro",
			"Molly",
			"Pedrinho",
			"para",
			"Stitch",
	},
	
	Banned = {
		-- no one should be here
	},
	
	Blacklist = {
		-- no one should be here either
	}
}

Muse.ChatHooks = {
	
}

Muse.SLCS = ReplicatedStorage:FindFirstChild("SendLuaChatSignal")

--[[

	SLCS is a client RemoteEvent, parented to ReplicatedStorage. This remote takes a string like "Muse/bla" and outputs it to the Roblox Lua Chat (pre-2022 chat) as "[Muse] bla", using a string.split polyfill and SetCore.
	
	An example implementation would be as follows as a LocalScript: 
	local RS = game:GetService("ReplicatedStorage")
	local RSM = RS:FindFirstChild"SendLuaChatSignal"
	local Split = require(RS:WaitForChild"Split")

	RSM.OnClientEvent:Connect(function(msg)
		local splitmsg = Split(msg,"/")
			game.StarterGui:SetCore("ChatMakeSystemMessage", {
				Text=("["..splitmsg[1].."] "..splitmsg[2]);
				Color=BrickColor.new(101).Color
			})
		print("Processed message of "..#splitmsg[2].." characters ("..splitmsg[1]..")")
	end)

	This requires a ModuleScript that returns the following function from http://lua-users.org/wiki/SplitJoin , which is a good polyfill for string.split from newer versions of Roblox.
	If you are attempting to run Muse on newer Roblox, and god save your soul if you are.. use string.split instead. It's better.

]]--

function Muse.Output(thread,output)
	print("[Muse:"..tostring(thread).."] " .. output)
end

function Muse.ShowHint(plr,text)
	local Hint = Instance.new("Hint",workspace)
	Hint.Name = "Muse"..tostring(plr).."Hint"
	Hint.Text=("[Muse] "..text);Debris:AddItem(Hint,3)
end

function Muse.StartAudioSubsys(id)
	local soundid
	if id~=nil then soundid="rbxassetid://"..tostring(id) end
		Muse.Output("audio","Preparing Muse Global Audio")
		local MuseAudio = Instance.new("Sound",workspace)
		MuseAudio.Name = "MuseAudio"
		MuseAudio.Looped=true
		MuseAudio.Volume = 0.5
		Muse.Audio = MuseAudio
		
		MuseAudio.Changed:Connect(function(prop)
			if prop == "SoundId" then
				Muse.ShowHint("Server","SoundId has been changed to "..tostring(MuseAudio.SoundId))
			end
		end)
	
		if id~=nil then
			Muse.Audio.SoundId = soundid
			Muse.Audio:Play()
		end
end

function Muse.PlayerExistsInTable(plr,tbl)
	if not plr:IsA("Player") then error"Not a player" end
	
	local exists = false
	
	table.foreach(tbl,function(k,v)
		
			if v == plr.Name then
		exists = true
			end
			
	end)
	
	return exists
end

function Muse.Authenticate(plr)
	return Muse.PlayerExistsInTable(plr,Muse.Settings.Admins)
end

function Muse.CheckBanned(plr)
	return Muse.PlayerExistsInTable(plr,Muse.Settings.Banned)
end

function Muse.CheckBlacklist(plr)
	return Muse.PlayerExistsInTable(plr,Muse.Settings.Banned)
end

function Muse.Boot(plr,reason)
		Muse.Output("Boot",(tostring(plr)).." was removed from the server by Muse")
		plr:Kick("Kicked by Muse "..(reason or "No reason provided"))
end

function Muse.Ban(plr,reason)
	table.insert(Muse.Settings.Banned,tostring(plr));Muse.Boot(plr,reason)
end



Muse.Commands = {
	test = {
		NonAdmin = true,
		Description = "Test command.. it does what you might think it does",
		
		Exec = function(plr,...)
		Muse.Output("test",tostring(plr) .. " fired test comm with " .. (...) .. " as args (length: " ..(#...) .. ")")
		end,
	},
	
	kick = {
		NonAdmin = false,
		Description = "Kicks a player",
		
		Exec = function(plr,victim)
			local victobj = Players:FindFirstChild'victobj'
			
			if not victobj then 
				error("No player") 
			elseif plr.Name == Players[tostring(victim)].Name then
				error'Player tried to kick self'
			else
			Muse.Boot(victobj)
			end
		end

	},
	
	ban = {
		NonAdmin = false,
		Description = "Bans a player",
		
		Exec = function(plr,victim)
			Muse.Ban(victim);
		end,
	},
		
	
	help = {
		NonAdmin = true,
		Description = "Sends description of command to calling player",
		
		Exec = function(plr,cmd)
			if Muse.Commands[cmd] then
				
			Muse.SLCS:FireClient(plr,"Muse/"..(cmd ..": " ..Muse.Commands[cmd].Description))
			
			if not Muse.Commands[cmd].NonAdmin and not Muse.Authenticate(plr) then
				Muse.SLCS:FireClient(plr,"Muse/You don't have permission to run the above command.")
			end
			
			else error'Command not found'
			end
		end
	},
	
	cmds = {
		NonAdmin = true,
		Description = "Sends list of authorized commands",
		
		Exec = function(plr)
			wait(.25) -- intentional wait because it fires it too fast after chatted
			for ind,cmd in pairs(Muse.Commands) do
				Muse.SLCS:FireClient(plr,"Muse/"..(tostring(ind).. " ("..tostring(cmd.Description)..")"))
			end
		end
	},
	
	mplay = {
		NonAdmin = true,
		Description = "Plays audio or changes it if one is already playing",
		
		Exec = function(plr,id)
			if Muse.PlayerExistsInTable(plr,Muse.Settings.Blacklist) then error'Player blacklisted' return false end
			local id = tonumber(id) or 1867
				if Muse.Audio then
					local snd = Muse.Audio
				    snd.TimePosition = 0;snd:Stop();wait(.5)
				    snd.SoundId = "rbxassetid://"..id;wait(.5)
				    snd:Play()
				Muse.ShowHint(tostring(plr),tostring(plr).." changed audio")
				end
		end
	},
	
	maddbl = {
		NonAdmin = false,
		Description = "Blacklists a player from changing music",
		
		Exec = function(plr,victim)
			local victobj = Players:FindFirstChild(victim)
			if not Muse.CheckBlacklist(victobj) then
				table.insert(Muse.Settings.Blacklist,victim);
				Muse.SLCS:FireClient(victobj,"Muse/You have been blacklisted from changing audio.")
			end
		end
	},
	
	mclearbl = {
		NonAdmin = false,
		Description = "Clears blacklist",
		
		Exec = function(plr)
			Muse.Settings.Blacklist = {}
		end
	},
	
	mpp = {
		NonAdmin = true,
		Description = "Pauses or resumes audio",
		
		Exec = function(plr)
		if Muse.Audio then
			if Muse.Audio.IsPlaying then
				Muse.Audio:Pause()
			else 
				Muse.Audio:Resume()
			end
		end
			Muse.Output("MPP",tostring(plr).. " changed playback state of audio")
			if type(plr) == "userdata" and plr:IsA("Player") then Muse.SLCS:FireAllClients("Muse/Playback toggled") end
		end
	},
	
	mvol = {
		NonAdmin = false,
		Description = "Changes audio volume",
		
		Exec = function(plr,vol)
			if Muse.Audio then
				Muse.Audio.Volume = vol
				Muse.SLCS:FireAllClients("Muse/Volume changed to "..tostring(vol).." (MGA)")
			end
		end
	},
	
	mpitch = {
		NonAdmin = false,
		Description = "Changes audio pitch",
		
		Exec = function(plr,pitch)
			if Muse.Audio then
				Muse.Audio.Pitch = pitch
				Muse.SLCS:FireAllClients("Muse/Pitch changed to "..tostring(pitch))
			end
		end
	},

}

function Muse.PlayerAdded(plr)
	local Banned = Muse.CheckBanned(plr) or false
	if Banned then Muse.Boot(plr,"Banned from server by Muse") end
	
	local Admin = Muse.Authenticate(plr) or false
	local AuthorizedCommands = {}
	pcall(table.foreachi,Muse.ChatHooks[plr.Name],function(i,v)
		i:Disconnect()
	end)

	Muse.ChatHooks[plr.Name] = {}

	if Admin then
		plr.TeamColor = game:GetService("Teams")["Admins"].TeamColor
	end
	
	for cmdl,cmda in pairs(Muse.Commands) do 		
		if cmda.NonAdmin or Admin then
			table.insert(AuthorizedCommands,tostring(cmdl))
			
		local cmd = (cmdl .. Muse.Settings.Seperator)
			
				Muse.ChatHooks[plr.Name][cmd] = plr.Chatted:Connect(function(message)
					if message:sub(1,#cmd) == cmd then		
						local s,e = pcall(cmda.Exec,plr,message:sub(#cmd+1))
						
						if not s and e then 
							Muse.Output("err",tostring(plr) .. " failed to execute command " .. cmdl .. ":",e)
						elseif s then
							Muse.Output("cmd",tostring(plr) .." executed command " .. cmdl .. " with arguments " .. message:sub(#cmd+1))
						end
						
					end			
				end)
			end
	end		
	
	Muse.Output("auth","Authorized ".. tostring(plr) .." to use ".. #AuthorizedCommands .." commands (".. table.concat(AuthorizedCommands,", ") ..")")
	Muse.SLCS:FireClient(plr,"Muse/You're authorized to use ".. #AuthorizedCommands .." commands: ".. table.concat(AuthorizedCommands,", "))	
end

Muse.Output("ver",("Muse version ".. Muse.Version))
Muse.StartAudioSubsys(1867); -- This is a Kapish asset, but any valid asset ID will work
Players.PlayerAdded:Connect(Muse.PlayerAdded);

Muse.Output("api","Setting up global API")


local MuseAPIKey = "CHANGEMPL0X"
local MuseAPI = {
	
	GiveAdmin = function(plr,key)
		if key == MuseAPIKey then
			table.insert(Muse.Settings.Admins,plr)
		end
	end	
		
	}

setmetatable(MuseAPI,{
	__newindex = function(self,...)
		error'Attempted to create new index in locked table'
	end,
	
	__index = function(self,ind)
		if Muse[ind] and type(Muse[ind]) ~= "function" then
			return Muse[ind]
		elseif rawget(self,ind) then
			return rawget(self,ind)
		else
			error('Failed to index')
		end
	end,

	__call = function(self,func,...)	
		if rawget(self,func) and type(rawget(self,func)) == "function" then
				rawget(self,func)(...)
		end
	end
})

_G.Muse = MuseAPI

 
if #Players:children'' > 0 then -- Muse might honestly work if it was LoadAssetted into a game with InsertService but I have never tried it. This is just coniditoning
for i,v in pairs(Players:children'') do
	Muse.PlayerAdded(v)
end
end

workspace.ChildRemoved:Connect(function(child)
	if child == Muse.Audio then
		wait();Muse.StartAudioSubsys(1867) -- This is a Kapish asset, but any valid asset ID will work
	end
end)