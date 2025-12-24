--!strict

--[[

MIT License

Copyright (c) 2025 clairgt

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

]]--

local Players = game:GetService("Players")

--[[ elapsis 2.0.0 ]] --

local Timer = {}
Timer.__index = Timer -- metatable for the inevitable timer

export type TimerClass = typeof(setmetatable({} :: {
	Label: string,
	Cadence: number, -- always in seconds
	Callback: () -> (), -- function on cadence
	AutomaticLeaderboardManagement: boolean,
}, Timer)) -- Timer class

function Timer:new(Label: string, 
	Cadence: number, -- always in seconds, how long until the next callback?
	Callback: () -> (), -- callback to be called on cadence
	AutomaticLeaderboardManagement: boolean, -- should leaderstats be automatically managed by elapsis?
	IncrementOverride: number | nil) -- if we're overriding the increment then how much should the value be incremented
	: TimerClass
	
	local timerLeaderstat -- leaderstat if we're using ALM
	AutomaticLeaderboardManagement = AutomaticLeaderboardManagement or false -- ALM on/off fallback
	
	local function setupLeaderstats(Player: Player)
		if Player:FindFirstChild("leaderstats") == nil then
			local newLeaderstats = Instance.new("Folder", Player) -- (Player +> Folder)
			newLeaderstats.Name = "leaderstats" -- (Folder &> 'leaderstats')

			timerLeaderstat = Instance.new("NumberValue", newLeaderstats) -- ('leaderstats' +> NumberValue)
			timerLeaderstat.Name = Label -- (NumberValue &> Label)
		end
	end
	
	if AutomaticLeaderboardManagement then -- are we doing this or not
		Players.PlayerAdded:Connect(setupLeaderstats) -- connect setting up leaderstats
		for _, Player in Players:GetPlayers() do
			setupLeaderstats(Player) -- do it again but for everyone currently connected
		end
	end
	
	coroutine.resume(coroutine.create(function()
		while task.wait(Cadence) do -- when its time to run the timer
			Callback() -- run the timer's callback
			if AutomaticLeaderboardManagement and timerLeaderstat then
				timerLeaderstat.Value += IncrementOverride or 1 -- increment the leaderstat if we're using ALM
			end
		end
	end))
	
	
	return setmetatable({
		Label = Label,
		Cadence = Cadence,
		Callback = Callback,
		AutomaticLeaderboardManagement = AutomaticLeaderboardManagement,
	}, Timer) -- return all this stuff because it lets us do stuff like "print(Timer.Label)" if that's the fancy you're looking for
end

return Timer