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

-- def players
local players = game:GetService("Players")

-- retrieve current f3x version
local f3x = require(580330877)(); 

-- begin initialization

local product = "f3xdist"
local version = {
	-- version information
	1,
	2,
	4,
	-- end version information
}

type data = {
	gid:number;
	minrank:number;
}

-- config with new layout (1.2.0)
local groups:{} = {
	BeneathEbott = {
		gid = 2737830;
		minrank = 150;
	} :: data
}

local users:{} = {
	18875912;
	39787900;
}

-- util
local util = { 

	distribute = function(t: Tool,p: Player)
		local nt = t:Clone()
		nt.Parent = p:WaitForChild('Backpack')

		return nt

	end,

	output = function(call:string,...)
		if call == 'warn' then warn(`[{product}:warn] {...}`) else
			print(`[{product}:{call}] {...}`)	
		end
	end,
}

-- auth
local authenticate:(Player) -> boolean = function(plr)
	local allowed = false;

	for _,curgr:data in groups do
		local s,e = pcall(function() allowed = plr:GetRankInGroup(curgr.gid) >= curgr.minrank end)
	end

	if table.find(users,plr.UserId) and not allowed then 
		allowed = true 
	elseif allowed then 
		util.output('warn',`Player already authenticated by group association, redundant entry in player table: {plr.Name}:{tostring(plr.UserId)}`)
	end

	return allowed
end

-- present arms
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