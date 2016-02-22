--[[
	OreMiner 1.0
	by macker
	
	this program mine ore like this
	||||
	||||
	---->
	||||
	||||

	one master tunnel and lots of sub tunnels
	features
	- find and mine all neibour ores
	- auto fill holes caused by mining neibour ores with cobblestones
	- return to the origin point if finish job or fuel is only enough to go back to the origin point
]]--

local tArgs={ ... }

local mainMove=0
local subMove=0
local downMove=0
local deepMove=0

local subTunnelLength=64
local mainTunnelLength=64
local margin=3
local mineLeft=true
local mineRight=true

local function printUsage()
	print("Usage: mine [options]")
	print("Options:")
	print("-d <master dist> <sub dist> Default master and sub all 64")
	print("-m <margin> margin between 2 sub tunnels. Default 3")
	print("-L <on/off> Mine left sub tunnel or not. Default on")
	print("-R <on/off> Mine right sub tunnel or not. Default on")
end

if #tArgs>0 then
	local nArg=1
	while nArg<=#tArgs do
		local option=tArgs[nArg]
		if option=="-d" then
			local num1=tonumber(tArgs[nArg+1])
			local num2=tonumber(tArgs[nArg+2])
			if num1 and num2 then
				if num1<0 or num2<0 then
					print("distance must >=0")
					return
				else
					mainTunnelLength=num1
					subTunnelLength=num2
					nArg=nArg+3
				end
			else
				printUsage()
				return
			end
		elseif option=="-m" then
			local num=tonumber(tArgs[nArg+1])
			if num then
				if num<0 then
					print("margin must >=0")
					return
				else
					margin=num
					nArg=nArg+2
				end
			else
				printUsage()
				return
			end
		elseif option=="-L" then
			local choose=string.lower(tArgs[nArg+1])
			if choose then
				if choose=="off" then
					mineLeft=false
				elseif choose=="on" then
					mineLeft=true
				else
					printUsage()
					return
				end
				nArg=nArg+2
			else
				printUsage()
				return
			end
			elseif option=="-R" then
				local choose=string.lower(tArgs[nArg+1])
			if choose then
				if choose=="off" then
					mineRight=false
				elseif choose=="on" then
					mineRight=true
				else
					printUsage()
					return
				end
				nArg=nArg+2
			else
				printUsage()
				return
			end
		else
			printUsage()
			return
		end
	end
end

local fuel=turtle.getFuelLevel()
local lackFuel=false

local tOreNames={
	"minecraft:gold_ore",
	"minecraft:iron_ore",
	"minecraft:coal_ore",
	"minecraft:lapis_ore",
	"minecraft:redstone_ore",
	"minecraft:diamond_ore",
	"minecraft:emerald_ore",
	"IC2:blockOreCopper",
	"IC2:blockOreTin",
	"IC2:blockOreUran",
	"IC2:blockOreLead",
	"appliedenergistics2:tile.OreQuartz",
	"appliedenergistics2:tile.OreQuartzCharged",
}

local tInspectHandle={
	["forward"]=turtle.inspect,
	["up"]=turtle.inspectUp,
	["down"]=turtle.inspectDown,
}

local tPlaceHandle={
	["forward"]=turtle.place,
	["up"]=turtle.placeUp,
	["down"]=turtle.placeDown,
}

local function placeStone(handler)
	for i=1,16,1 do
		local info=turtle.getItemDetail(i)
		if info then
			if info.name=="minecraft:cobblestone" or
					info.name=="minecraft:dirt" then
				turtle.select(i)
				tPlaceHandle[handler]()
				turtle.select(1)
				return true
			end
		end
	end
	return false
end

local function bagFull()
	for i=1,16,1 do
		local info=turtle.getItemDetail(i)
		if not info then
			return false
		end
	end
	return true
end

local function clearBag()
	for i=1,16,1 do
		local info=turtle.getItemDetail(i)
		if info then
			if info.name=="minecraft:cobblestone" or
					info.name=="minecraft:dirt" or
					info.name=="minecraft:gravel" then
				turtle.select(i)
				turtle.drop()
				turtle.select(1)
				return
			end
		end
	end
	-- bag is full and can not clear, go back
	lackFuel=true
end

local function forward_s(IsRollback,fill)
	fuel=turtle.getFuelLevel()
	if fuel-2<mainMove+subMove+downMove+deepMove then
		lackFuel=true
	end
	if lackFuel then
		if not IsRollback then
			return false
		end
	end
	while turtle.forward()==false do
		turtle.dig()
		if bagFull() then
			clearBag()
		end 
	end
	fuel=turtle.getFuelLevel()
	return true
end

local function back_s(IsRollback,fill)
	fuel=turtle.getFuelLevel()
	if fuel-2<mainMove+subMove+downMove+deepMove then
		lackFuel=true
	end
	if lackFuel then
		if not IsRollback then
			return false
		end
	end
	while turtle.back()==false do
		turtle.turnLeft()
		turtle.turnLeft()
		turtle.dig()
		turtle.turnRight()
		turtle.turnRight()
	end
	if fill then
		placeStone("forward")
	end
	fuel=turtle.getFuelLevel()
	return true
end

local function up_s(IsRollback,fill)
	fuel=turtle.getFuelLevel()
	if fuel-2<mainMove+subMove+downMove+deepMove then
		lackFuel=true
	end
	if lackFuel then
		if not IsRollback then
			return false
		end
	end
	while turtle.up()==false do
		turtle.digUp()
	end
	if fill then
		placeStone("down")
	end
	fuel=turtle.getFuelLevel()
	return true
end

local function down_s(IsRollback,fill)
	fuel=turtle.getFuelLevel()
	if fuel-2<mainMove+subMove+downMove+deepMove then
		lackFuel=true
	end
	if lackFuel then
		if not IsRollback then
			return false
		end
	end
	while turtle.down()==false do
		turtle.digDown()
	end
	if fill then
		placeStone("up")
	end
	fuel=turtle.getFuelLevel()
	return true
end

local tMoveHandle={
	["forward"]=forward_s,
	["up"]=up_s,
	["down"]=down_s,
	["back"]=back_s,
}

local function checkBlockInfo(info)
	for _,oreName in pairs(tOreNames) do
		if info.name==oreName then
			return true
		end
	end
	return false
end

local function moveDeeper(handler)
	if tMoveHandle[handler](false,false) then
		deepMove=deepMove+1
		print("In Deep:"..tostring(deepMove).." Fuel:"..tostring(fuel))
		return true
	else
		print("In Deep:"..tostring(deepMove).." Fuel:"..tostring(fuel))
		return false
	end
	
end

local function moveShallower(handler)
	if tMoveHandle[handler](true,true) then
		deepMove=deepMove-1
	end
	print("Out Deep:"..tostring(deepMove).." Fuel:"..tostring(fuel))
end

local function mineOre(forward,back)
	if lackFuel then
		return
	end
	local haveBlock,info=tInspectHandle[forward]()
	if haveBlock then
		if checkBlockInfo(info) then
			if moveDeeper(forward) then
				-- mineAllOre
				mineOre("forward","back")
				mineOre("up","down")
				mineOre("down","up")
				for i=0,2,1 do
					turtle.turnLeft()
					mineOre("forward","back")
				end
				turtle.turnLeft()
				-- end
				moveShallower(back)
			end
		end
	end
end

local function mineAllOre()
	mineOre("forward","back")
	mineOre("up","down")
	mineOre("down","up")
	for i=0,2,1 do
		turtle.turnLeft()
		mineOre("forward","back")
	end
	turtle.turnLeft()
end

local function mineSubTunnel()
	for j=1,subTunnelLength,1 do
		-- forward
		if not lackFuel then
			if forward_s(false,false) then
				subMove=subMove+1
				print("subTunnel:"..tostring(subMove).." Fuel:"..tostring(fuel))
				if not lackFuel then
					mineAllOre()
				else
					break
				end
			else
				break
			end
		else
			break
		end
	end
	while subMove>0 do
		if back_s(true,false) then
			subMove=subMove-1
			print("subTunnel:"..tostring(subMove).." Fuel:"..tostring(fuel))
		end
	end
end

local function mineMainTunnel()
	for k=1,mainTunnelLength,1 do
		-- forward
		if not lackFuel then
			if forward_s(false,false) then
				mainMove=mainMove+1
				print("MainTunnel:"..tostring(mainMove).." Fuel:"..tostring(fuel))
				if not lackFuel then
					mineAllOre()
					if k%(margin+1)==0 then
						if mineLeft then
							turtle.turnLeft()
							mineSubTunnel()
							turtle.turnRight()
						end
						if mineRight then
							turtle.turnRight()
							mineSubTunnel()
							turtle.turnLeft()
						end
					end
				else
					break
				end
			else
				break
			end
		else
			break
		end
	end
	while mainMove>0 do
		if back_s(true,false) then
			mainMove=mainMove-1
			print("MainTunnel:"..tostring(mainMove).." Fuel"..tostring(fuel))
		end
	end
end

mineMainTunnel()
