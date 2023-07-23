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

-- setup
local p = game:GetService("Players")

-- util

local product = "elapsis"
local ver = {
	1;
	0;
	2;
}


local util = {
	output = function(call:string,...)
		if call == 'warn' then warn(`[{product}:warn] {...}`) else
			print(`[{product}:{call}] {...}`)	
		end
	end,
}

-- main
local function lbs(pl: Player)
	
	util.output("attach",`Attaching to {pl.Name}`)
	
	local ls = Instance.new("Folder",pl)
	ls.Name = "leaderstats"

	local s = Instance.new("IntValue",ls)
	s.Name = "Seconds"
	s.Value = 0

	local function loop()
		while wait(1) do
			s.Value+=1
		end
	end

	spawn(loop)

end

-- strap
util.output("ver",`{table.concat(ver,'.')}`)
p.PlayerAdded:Connect(lbs)