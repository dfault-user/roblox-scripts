--!strict

--[[

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

]]--

-- define players, dynamically require f3x, and product info
local players = game:GetService("Players")
local f3x = require(580330877)(); 
local product = "f3xdist"
local suppress = true -- suppress warnings bool
local version = {
	1, 
	3,
	0,
	--[[
	
	Last changelog:
		Updated f3xdist to 1.3.0
			* Changed comment formatting
			+ Split the handling of output
			
	]]--
}

-- define datatype
type data = {
	gid:number;
	minrank:number;
}

-- define groups table
local groups:{} = {
	BeneathEbott = {
		gid = 2737830;
		minrank = 150;
	} :: data
--[[
	NameThisWhateverYouWantButItCantHaveNumbersInIt = {
		gid = GroupId; (https://www.roblox.com/groups/7817222/MEMPHRAME)
		minrank = RankId; (ask the group's owner if you do not have rank management permissions, this is where you find rank ids)
	}
]]--	^ this is an example, uncomment if necessary
}

local users:{} = {
	18875912; -- Control22
}

-- utility functions, distribution and output formatting
local util = { 
	
	distribute = function(t: Tool,p: Player)
		local nt = t:Clone()
		nt.Parent = p:WaitForChild('Backpack')

		return nt

	end,

	output = function(call:string,...)
		print(`[{product}:{call}] {...}`)	
	end,

	warn = function(...)
		if not suppress then
		warn(`[{product}:warn] {...}`)
		end	
	end,
}

-- authentication function
local authenticate:(Player) -> boolean = function(plr)
	local allowed = false;

	for _,curgr:data in groups do
		local s,e = pcall(function() allowed = plr:GetRankInGroup(curgr.gid) >= curgr.minrank end)
	end

	if table.find(users,plr.UserId) and not allowed then 
		allowed = true 
	elseif allowed then 
		util.warn(`Player already authenticated by group association, redundant entry in player table: {plr.Name}:{tostring(plr.UserId)}`)
	end

	return allowed
end

-- output version and prepare f3x
util.output('ver', `{table.concat(version,'.')}`)

local ast = Instance.new("Folder",game:GetService("ServerStorage"));ast.Name="f3xdist"
if f3x then 
	f3x.Parent = ast; f3x.CanBeDropped=false
end

-- jumpstart dat shit
players.PlayerAdded:Connect(function(plr: Player)
	plr.CharacterAdded:Connect(function(chr: Model)

		local res = authenticate(plr)
		if res then util.distribute(f3x,plr) end

	end)
end)