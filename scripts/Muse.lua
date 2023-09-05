--[[
	Muse by Control22
	Made for Kapish 2016

	MIT License

	Copyright (c) 2023 Brandan C. Delafuente

	Permission is hereby granted, free of charge, to any person obtaining a copy
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
Muse = {}

Muse.Version = {
	 1;
	 3;
	 0;
}

Muse.CS = script["CrashScript"]
Muse.Audio = workspace["MuseAudio"]

Muse.PlayerExistsInTable = function(plr,tbl)
	if not plr:IsA("Player") then error"Not a player" end
	
	local exists = false
	
	table.foreach(tbl,function(k,v)
		
			if v == plr.Name then
		exists = true
			end
			
	end)
	
	return exists
end

Muse.Authenticate = function(plr)
	return Muse.PlayerExistsInTable(plr,Muse.Admins)
end

Muse.CheckBanned = function(plr)
	return Muse.PlayerExistsInTable(plr,Muse.Banned)
end

Muse.Crash = function(plr)
	local CS = Muse.CS:Clone()
	CS.Parent = plr:WaitForChild'Backpack';CS.Disabled=false
end

Muse.Output = function(thread,output)
	print("[Muse:"..tostring(thread).."] " .. output)
end

Muse.SMR = ReplicatedStorage:FindFirstChild("SSM")

Muse.Settings = {
	Seperator = "/",	
}

Muse.Admins = {
	--"Player1",
	"brandan",
	"gyro",
	"Molly",
	"Pedrinho",
	"para",
}

Muse.Banned = {
	-- hopefully no one will ever need to be here
}

Muse.Commands = {
	test = {
		NonAdmin = true,
		Description = "Test command.. it does what you might think it does",
		
		Exec = function(plr,...)
		Muse.Output(tostring(plr) .. " fired test comm with " .. (...) .. " as args (length: " ..(#...) .. ")")
		end,
	},
	
	kick = {
		NonAdmin = false,
		Description = "Kicks a player",
		
		Exec = function(plr,p)
			local player = Players[tostring(p)]
			if not player then 
				error("No player") 
			elseif plr.Name == Players[tostring(p)].Name then
				error'Player tried to kick self'
			else
			Muse.Crash(p)
			end
		end

	},
	
	help = {
		NonAdmin = true,
		Description = "Sends description of command to calling player",
		
		Exec = function(plr,cmd)
			if Muse.Commands[cmd] then
				
			Muse.SMR:FireClient(plr,
				(cmd ..": " ..Muse.Commands[cmd].Description)
			)
			
			if not Muse.Commands[cmd].NonAdmin and not Muse.Authenticate(plr) then
				Muse.SMR:FireClient(plr,
					"You don't have permission to run the above command."
				)
			end
			
			else error'Command not found'
			end
		end
	},
	
	mplay = {
		NonAdmin = true,
		Description = "Plays audio or changes it if one is already playing",
		
		Exec = function(plr,id)
			local id = tonumber(id) or 142376088
		    local snd = Muse.Audio
		    snd.TimePosition = 0;snd:Stop();wait()
		    snd.SoundId = "rbxassetid://"..id;wait()
		    snd:Play()
		end
	},
	
	mpp = {
		NonAdmin = true,
		Description = "Pauses or resumes audio",
		
		Exec = function(plr)
			if Muse.Audio.IsPlaying then
				Muse.Audio:Pause()
			else 
				Muse.Audio:Resume()
			end
			Muse.Output("MPLAY",tostring(plr).. " changed playback state of audio")
		end
	},
	
	mvol = {
		NonAdmin = false,
		Description = "Changes audio volume",
		
		Exec = function(plr,vol)
			Muse.Audio.Volume = tonumber(vol)
			Muse.Output("MVOL",tostring(plr).. " changed volume of audio to " ..vol)
		end
	},

}

Muse.PlayerAdded = function(plr)
	local Banned = Muse.CheckBanned(plr) or false;if Banned then Muse.Crash(plr) end
	local Admin = Muse.Authenticate(plr) or false
	local AuthorizedCommands = {}
	
	for cmdl,cmda in pairs(Muse.Commands) do 
		if cmda.NonAdmin or Admin then
			table.insert(AuthorizedCommands,tostring(cmdl))
			
		local cmd = (cmdl .. Muse.Settings.Seperator)
			plr.Chatted:Connect(function(message)
				if message:sub(1,#cmd) == cmd then
					
					local s,e = pcall(function() 
						cmda.Exec(plr,message:sub(#cmd+1))
					end) 
					
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
end

Players.PlayerAdded:Connect(Muse.PlayerAdded)

Muse.Output("ver",table.concat(Muse.Version,"."))
for i,v in pairs(Players:children'') do
	Muse.PlayerAdded(v)
end

