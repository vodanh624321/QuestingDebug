-- Copyright © 2016 g0ld <g0ld@tuta.io>
-- This work is free. You can redistribute it and/or modify it under the
-- terms of the Do What The Fuck You Want To Public License, Version 2,
-- as published by Sam Hocevar. See the COPYING file for more details.
-- Quest: @Rympex


local sys    = require "Libs/syslib"
local pc     = require "Libs/pclib"
local game   = require "Libs/gamelib"
local util   = require "Libs/utillib"
local Quest  = require "Quests/Quest"
local Dialog = require "Quests/Dialog"

local name		  = 'Goldenrod City'
local description = " Complete Guard's Quest"
local level = 22

local dialogs = {
	martElevatorFloorB1F = Dialog:new({ 
		"on the underground"
	}),
	martElevatorFloor1 = Dialog:new({ 
		"the first floor"
	}),
	martElevatorFloor2 = Dialog:new({ 
		"the second floor"
	}),
	martElevatorFloor3 = Dialog:new({ 
		"the third floor"
	}),
	martElevatorFloor4 = Dialog:new({ 
		"the fourth floor"
	}),
	martElevatorFloor5 = Dialog:new({ 
		"the fifth floor"
	}),
	martElevatorFloor6 = Dialog:new({ 
		"the sixth floor"
	}),
	directorQuestPart1 = Dialog:new({ 
		"there is nothing to see here"
	}),
	guardQuestPart1 = Dialog:new({ 
		"any information on his whereabouts"
	}),
	guardQuestPart2 = Dialog:new({ 
		"where did you find him",
		"he might be able to help"
	})
}

local GoldenrodCityQuest = Quest:new()

function GoldenrodCityQuest:new()
	local o = Quest.new(GoldenrodCityQuest, name, description, level, dialogs)
	o.gavine_done = false
	o.checkCrate1 = false
	o.checkCrate2 = false
	o.checkCrate3 = false
	o.checkCrate4 = false
	o.checkCrate5 = false
	o.checkCrate6 = false
	o.checkCrate7 = false
	return o
end

function GoldenrodCityQuest:isDoable()
	if self:hasMap() then
		if getMapName() == "Goldenrod City" then 
			return isNpcOnCell(48,34)
		else
			return true
		end
	end
	return false
end

function GoldenrodCityQuest:isDone()
	if getMapName() == "Goldenrod City" and not isNpcOnCell(50,34) then
		return true
	end
	return false
end

function GoldenrodCityQuest:pokemart_()
	local pokeballCount = getItemQuantity("Pokeball")
	local money         = getMoney()
	if money >= 200 and pokeballCount < 50 then
		if not isShopOpen() then
			return talkToNpcOnCell(21,6)
		else
			local pokeballToBuy = 50 - pokeballCount
			local maximumBuyablePokeballs = money / 200
			if maximumBuyablePokeballs < pokeballToBuy then
				pokeballToBuy = maximumBuyablePokeballs
			end
				return buyItem("Pokeball", pokeballToBuy)
		end
	else
		return moveToMap("Goldenrod Mart 1")
	end
end

function GoldenrodCityQuest:PokecenterGoldenrod()
	--Get Bellsprout From PC || hopefully already done on Route 32 though
	if hasItem("Basement Key")
		and dialogs.guardQuestPart2.state
		and not hasItem("SquirtBottle")
		and not (hasPokemonInTeam("Bellsprout")
			or hasPokemonInTeam("Weepinbell"))
	then
		local bellSproutId = {069}
		local result, pkmBoxId, slotId, swapTeamId = pc.retrieveFirst{id = bellSproutId, region={"Jotho"}}

		--working 	| then return because of open proShine functions to be resolved
		--			| if not returned, a "can only execute one function per frame" might occur
		if result == pc.result.WORKING then return sys.info("Searching PC")

		--no solution, terminate quest
		elseif  result == pc.result.NO_RESULT then
			return sys.error("Unfortunatly you skipped a quest. So be it, get a Bellsprout or Oddish yourself.")

		--has a bellsprout on the pc
		else
			local pkm = result
			local msg = "Found "..pkm.name.." on BOX: " .. pkmBoxId .. "  Slot: " .. slotId
			if swapTeamId then  msg = msg .. " | Swapping with pokemon in team N: " .. swapTeamId
			else                msg = msg .. " | Added to team." end
			return sys.log(msg)
		end
    end

    -- have Bellsprout
    self:pokecenter("Goldenrod City")
end

function GoldenrodCityQuest:GoldenrodCity()
	if self:needPokecenter() or not game.isTeamFullyHealed() or self.registeredPokecenter ~= "Pokecenter Goldenrod" then
		return moveToMap("Pokecenter Goldenrod")
	elseif self:needPokemart() then
		return moveToMap("Goldenrod Mart 1")
	elseif hasItem("Bike Voucher") then
		return moveToMap("Goldenrod City Bike Shop")
	elseif not self:isTrainingOver() then
		return moveToMap("Route 34")
	elseif not isNpcOnCell(48,34) then
		return talkToNpcOnCell(50,34)
	elseif hasItem("Basement Key") and not hasItem("SquirtBottle") and dialogs.guardQuestPart2.state then --get Oddish on PC and start leveling
		if not game.hasPokemonWithMove("Sleep Powder") then			
			return moveToMap("Pokecenter Goldenrod")
		else
			return moveToMap("Goldenrod Mart 1")
		end
	elseif isNpcOnCell(48,34) then
		if dialogs.guardQuestPart2.state then
			if hasItem("Basement Key") then
				
			else
				return moveToMap("Goldenrod City House 2")
			end
		elseif dialogs.guardQuestPart1.state then
			return moveToMap("Goldenrod Underground Entrance Top")
		else
			pushDialogAnswer(2)
			return talkToNpcOnCell(48,34)
		end
	else
	end
end

function GoldenrodCityQuest:GoldenrodCityBikeShop()
	if hasItem("Bike Voucher") then
		return talkToNpcOnCell(11,3)
	else
		return moveToMap("Goldenrod City")
	end
end

function GoldenrodCityQuest:GoldenrodUndergroundEntranceTop()
	dialogs.guardQuestPart1.state = false
	if dialogs.directorQuestPart1.state or self.gavin_done then
		return moveToMap("Goldenrod City")
	else
		return moveToMap("Goldenrod Underground Path")
	end
end

function GoldenrodCityQuest:GoldenrodUndergroundPath()
	if isNpcOnCell(7,2) then
		return talkToNpcOnCell(7,2) --Item: TM-46   Psywave
	elseif not isNpcOnCell(17,10) then
		if not self.gavin_done then
			return moveToMap("Goldenrod Underground Basement")
		else
			return moveToMap("Goldenrod Underground Entrance Top")
		end
	elseif dialogs.directorQuestPart1.state then
		return moveToMap("Goldenrod Underground Entrance Top")
	else
		return talkToNpcOnCell(17,10)
	end
end

function GoldenrodCityQuest:GoldenrodCityHouse2()
	if not hasItem("Basement Key") then
		return talkToNpcOnCell(9,5)
	else
		return moveToMap("Goldenrod City")
	end
end

function GoldenrodCityQuest:Route34()
	if self:needPokecenter() or self.registeredPokecenter ~= "Pokecenter Goldenrod" then
		return moveToMap("Goldenrod City")

	elseif not self:isTrainingOver() then
		return moveToGrass()

	elseif hasItem("Basement Key") and not hasItem("SquirtBottle") and dialogs.guardQuestPart2.state then --get Oddish on PC and start leveling
		if not game.hasPokemonWithMove("Sleep Powder") then
			if hasPokemonInTeam("Bellsprout") or hasPokemonInTeam("Weepinbell") then
				if game.getTotalUsablePokemonCount() < getTeamSize() then
					return moveToMap("Goldenrod City") --Bellsprout is low level so, it will die first every time
				else
					return moveToGrass()
				end
			else
				return moveToMap("Goldenrod City")
			end
		else
			return moveToMap("Goldenrod City")
		end
	else
		return moveToMap("Goldenrod City")
	end
end

function GoldenrodCityQuest:GoldenrodMartElevator()
	if not hasItem("Fresh Water") then
		if not dialogs.martElevatorFloor6.state then		
			pushDialogAnswer(5)
			pushDialogAnswer(3)
			return talkToNpcOnCell(1,6)
		else
			dialogs.martElevatorFloor6.state = false
			return moveToCell(3,6)
		end
	elseif hasItem("Basement Key") and not hasItem("SquirtBottle") and game.hasPokemonWithMove("Sleep Powder") and dialogs.guardQuestPart2.state then
		if not dialogs.martElevatorFloorB1F.state then		
			pushDialogAnswer(1)
			return talkToNpcOnCell(1,6)
		else
			dialogs.martElevatorFloorB1F.state = false
			return moveToCell(3,6)
		end
	else
		if not dialogs.martElevatorFloor1.state then
			pushDialogAnswer(2)
			return talkToNpcOnCell(1,6)
		else
			dialogs.martElevatorFloor1.state = false
			return moveToCell(3,6)
		end
	end
end

function GoldenrodCityQuest:GoldenrodMart1()
	if self:needPokemart() then
		return moveToMap("Goldenrod Mart 2")
	elseif not hasItem("Fresh Water") then
		return moveToMap("Goldenrod Mart Elevator")
	elseif hasItem("Basement Key") and not hasItem("SquirtBottle") and game.hasPokemonWithMove("Sleep Powder") and dialogs.guardQuestPart2.state then
		return moveToMap("Goldenrod Mart Elevator")
	else
		return moveToMap("Goldenrod City")
	end
end

function GoldenrodCityQuest:GoldenrodMart2()
	if self:needPokemart() then
		self:pokemart_()
	else
		return moveToMap("Goldenrod Mart 1")
	end
end

function GoldenrodCityQuest:GoldenrodMart6()
	if not hasItem("Fresh Water") then
		if not isShopOpen() then
			return talkToNpcOnCell(11, 3)
		else
			if getMoney() > 1000 then
				return buyItem("Fresh Water", 5)
			else
				return buyItem("Fresh Water",(getMoney()/200))
			end
		end
	else
		return moveToMap("Goldenrod Mart Elevator")
	end
end

function GoldenrodCityQuest:GoldenrodMartB1F()
	--not changed any logic, only simplified code || untested
	local sleepPowderer = team.getPkmWithMove("Sleep Powder")
	if not sleepPowderer then sys.error("Error . - No Bellsprout or Weepinbell in this team")

		if hasItem("Basement Key")
			and not hasItem("SquirtBottle")
			and dialogs.guardQuestPart2.state

		then
			if isNpcOnCell(13,8) then
				-- could this be removed, will the answer be overriden by next statement?
				-- or is this telling the npc, that we have water for him?
				pushDialogAnswer(2)
				pushDialogAnswer(sleepPowderer)

				return talkToNpcOnCell(13,8)

			else return moveToMap("Underground Warehouse") end

		else return moveToMap("Goldenrod Mart Elevator") end
	end
end


function GoldenrodCityQuest:UndergroundWarehouse()
	if not self.checkCrate1 then --Marill Crate
		if getPlayerX() == 23 and getPlayerY() == 12 then
			talkToNpcOnCell(23,13)
			self.checkCrate1 = true
			return
		else
			return moveToCell(23,12)
		end
	elseif not self.checkCrate2 then --Miltank Crate
		if getPlayerX() == 20 and getPlayerY() == 9 then
			talkToNpcOnCell(20,8)
			self.checkCrate2 = true
			return
		else
			return moveToCell(20,9)
		end
	elseif not self.checkCrate3 then --Abra Crate
		if getPlayerX() == 16 and getPlayerY() == 12 then
			talkToNpcOnCell(15,12)
			self.checkCrate3 = true
			return
		else
			return moveToCell(16,12)
		end
	elseif isNpcOnCell(15,17) then--Item: Revive
		return talkToNpcOnCell(15,17)
	elseif not self.checkCrate4 then --Meowth Crate
		if getPlayerX() == 19 and getPlayerY() == 17 then
			talkToNpcOnCell(19,16)
			self.checkCrate4 = true
			return
		else
			return moveToCell(19,17)
		end
	elseif not self.checkCrate5 then --Heracross Crate
		if getPlayerX() == 24 and getPlayerY() == 22 then
			talkToNpcOnCell(24,23)
			self.checkCrate5 = true
			return
		else
			return moveToCell(24,22)
		end
	elseif not self.checkCrate6 then --Snubbull Crate	
		if getPlayerX() == 13 and getPlayerY() == 24 then
			talkToNpcOnCell(12,24)
			self.checkCrate6 = true
			return
		else
			return moveToCell(13,24)
		end
	elseif not self.checkCrate7 then --Item: Great Balls
		if getPlayerX() == 5 and getPlayerY() == 8 then
			talkToNpcOnCell(5,7)
			self.checkCrate7 = true
			return
		else
			return moveToCell(5,8)
		end
	elseif isNpcOnCell(3,16) then --Item: Antidote
		return talkToNpcOnCell(3,16) 
	else
		self.checkCrate1 = false
		self.checkCrate2 = false
		self.checkCrate3 = false
		self.checkCrate4 = false
		self.checkCrate5 = false
		self.checkCrate6 = false
		self.checkCrate7 = false
		return moveToCell(7,18)
	end
end




local Doors = {
	--this syntax is unneeded, but easy to read
	[1] = { x = 18, y = 12 },
	[2] = { x = 22, y = 16 },
	[3] = { x = 18, y = 18 },
	[4] = { x = 9, y = 18 },
	[5] = { x = 9, y = 12 },
	[6] = { x = 13, y = 16 },
	[7] = { x = 4, y = 16 },
	[8] = { x = 4, y = 10 },
}

local gavin = "$Radio Director Gavin"
local lever_name_base = "Lever "
local Lever = {
	A = lever_name_base .. "A",
	B = lever_name_base .. "B",
	C = lever_name_base .. "C",
	D = lever_name_base .. "D",
	E = lever_name_base .. "E",
	F = lever_name_base .. "F",
}

local LeverActivatesDoors = {
	[Lever.A] = {1,6},
	[Lever.B] = {5,7},
	[Lever.C] = {1,4},
	[Lever.D] = {2,5},
	[Lever.E] = {6,8},
	[Lever.F] = {2,3},
}


function GoldenrodCityQuest:GoldenrodUndergroundBasement()
	-- BASEMENT LEVELRS PUZZLE
	log("DEBUG | GoldenRodPuzzle start")

	log("DEBUG | getState: "..tostring(self:getStateRelPos()))

--	for k,v in pairs(getNpcData()) do
--		log(k .."\t"..tostring(v.name))
--	end




	-- Radio Director Gavin is still here
	if isNpcOnCell(5, 4) then

		--calc solution and execute lever order
		self.puzzleSolution = self.puzzleSolution or self:puzzleSolver(gavin)
		for _, npc in ipairs(self.puzzleSolution) do return talkToNpc(npc) end

	-- Radio Director Gavin beaten
	else
		log("DEBUG | director beaten")
		dialogs.guardQuestPart2.state = false
		self.gavin_done = true

		--TM62 - Taunt
		if isNpcOnCell(8, 8) then return talkToNpcOnCell(8, 8) end

		--leaving
		self.leavePuzzle = self.leavePuzzle or self:puzzleSolver(gavin)

		--execute
		for _, npc in ipairs(self.leavePuzzle) do
			--if first room is accessible, leave
			if npc == Lever.A then return moveToMap("Goldenrod Underground Path") end
			--otherwise open doors
			return talkToNpc(npc)
		end
	end

end

function GoldenrodCityQuest:isDoorOpen(doorId)
	local door = Doors[doorId]
	return not isNpcOnCell(door.x, door.y)
end


--get state related position
function GoldenrodCityQuest:getStateRelPos()
	if 		game.inRectangle(19,11, 26,14) 	then return Lever.A --first room
	elseif 	game.inRectangle(19,17, 26,19) 	then return Lever.B --second room
	elseif 	game.inRectangle(10,11, 17,14) 	then return Lever.C --third room
	elseif 	game.inRectangle(10,17, 17,19) 	then return Lever.D --forth room
	elseif 	game.inRectangle(2,11, 8,14) 	then return Lever.F --sixt room
	elseif 	game.inRectangle(2,17, 7,19) 	then return Lever.E --fifth room
	elseif 	game.inRectangle(2,4, 8,8) 		then return gavin	--Gavin

	--first room is reachable from outside
	--simple but:
	--we didn't consider crosspoints in upper state detection, so this might cause issues
	else 										 return Lever.A
	end
end



function GoldenrodCityQuest:getStateTransitions(pos)
	local trs = {} --transitions

	if pos == Lever.A then
		table.insert(trs, {pos=Lever.B, door=2})
		table.insert(trs, {pos=Lever.C, door=1})

	elseif pos == Lever.B then
		table.insert(trs, {pos=Lever.A, door=2})
		table.insert(trs, {pos=Lever.D, door=3})

	elseif pos == Lever.C then
		table.insert(trs, {pos=Lever.A, door=1})
		table.insert(trs, {pos=Lever.D, door=6})
		table.insert(trs, {pos=Lever.F, door=5})

	elseif pos == Lever.D then
		table.insert(trs, {pos=Lever.B, door=3})
		table.insert(trs, {pos=Lever.C, door=6})
		table.insert(trs, {pos=Lever.E, door=4})

	elseif pos == Lever.E then
		table.insert(trs, {pos=Lever.D, door=4})
		table.insert(trs, {pos=Lever.F, door=7})

	elseif pos == Lever.F then
		table.insert(trs, {pos=Lever.C, door=5})
		table.insert(trs, {pos=Lever.E, door=7})
		table.insert(trs, {pos=gavin, door=8})

	elseif pos == gavin then
		table.insert(trs, {pos=Lever.F, door=8})
	end

	return trs
end

function GoldenrodCityQuest:getPossibleStateTransitions(openDoors, pos)
	local pTrs = {}	--possible transitions
	for _, tr in pairs(self:getStateTransitions(pos)) do
		if openDoors[tr.door] then table.insert(pTrs, tr) end
	end

	return pTrs
end


--BFS algorithm: https://de.wikipedia.org/wiki/Breitensuche
function GoldenrodCityQuest:puzzleSolver(targetState)
	--retrieve current door state
	local doorState = {}
	for dId, door in ipairs(Doors) do 					--making it dependendant on Doors table, makes future changes
		sys.debug("dId", dId)
		sys.debug("isDoorOpen", self:isDoorOpen(dId))

		table.insert(doorState, self:isDoorOpen(dId))	--to door number less rework intensive
	end

	--create starting conditions
	local currentNode = {	state = {pos = self:getStateRelPos(), openDoors = doorState},
		  					lever = {}}
	local unvisited = {currentNode}
	local visited = {}

	while #unvisited > 0 do
		--check first unvisited node
		local node = table.remove(unvisited)  --pop
		sys.debug("1. #unvisited", #unvisited)

		table.insert(visited, node)

		--target state reached
		if node.state.pos == targetState then
			sys.debug(">>>>>>>>>>>>>>>Solution<<<<<<<<<<<<<<<<<")
			table.insert(node.lever, node.state.pos)
			return node.lever
		end

		--target state not reached: generate other states

		-- either press lever or not
		for _, press in pairs({true, false}) do
			sys.debug("current state", node.state.pos)
			sys.debug("lever pressed", press)

--			util.tablePrint(node.state.openDoors)

			-- make copy, so changes won't affect other states referencing the same table
			local openDoors = util.copy(node.state.openDoors)
			local pos 		= util.copy(node.state.pos)
			local lever 	= util.copy(node.lever)

			sys.debug("copyPos", pos)
			sys.debug("lever", #lever)

			--modify doors, if lever is pressed
			if press then
				openDoors = self:pressLever(openDoors, pos)	--new door states
				table.insert(lever, pos)					--document lever being pressed
			end

			local path = ""
			for _, l in ipairs(lever) do
				path = path ..", ".. l
			end
			sys.debug("path", path)
			util.tablePrint(openDoors)
			sys.debug("ways:",#self:getPossibleStateTransitions(openDoors, pos))

			--neighbour rooms bot can reach
			for i, trans in pairs(self:getPossibleStateTransitions(openDoors, pos)) do
				local newNode = {	state = {pos = trans.pos, openDoors = openDoors},
									lever = lever}

				--add state if not already tested previouly
				if not self:isVisited(visited, newNode) then
					table.insert(unvisited, newNode)
				end
			end
			sys.debug("2. #unvisited", #unvisited)
			sys.debug("#visited", #visited)


--			if #visited > 1 then return sys.error("testing end") end
--			if #unvisited > 25 then return sys.error("testing end") end

		end
	end

	--no solution = nil
	sys.error("GoldenrodCityQuest.puzzleSolver() couldn't solve the puzzle :(")
end

function GoldenrodCityQuest:pressLever(openDoors, lever)
--	sys.debug("GoldenrodCityQuest:pressLever", "start", true)
--	sys.debug("lever", lever)
--	sys.debug("doors", #LeverActivatesDoors[lever])
--	util.tablePrint(LeverActivatesDoors[lever])

	--copy probably unnecessary, since newNode is already deep copied. But makes this method atomic/independent
	local openDoors = util.copy(openDoors)
	for _, door in pairs(LeverActivatesDoors[lever]) do
		openDoors[door] = not openDoors[door]
	end
--
--	util.tablePrint(openDoors)
--	sys.debug("GoldenrodCityQuest:pressLever", "end", true)
	return openDoors
end


--ignores the lever table, since looping between room a and b would add an element each time, making it a different table
function GoldenrodCityQuest:isVisited(visited, node)
--	sys.debug("GoldenrodCityQuest.isVisited()", "start", true)

	for i, visited_node in pairs(visited) do
--		util.tablePrint(visited_node.state)
--		util.tablePrint(visited_node.state.openDoors)
--		sys.debug("-------", "-------", true)
--		util.tablePrint(node.state)
--		util.tablePrint(node.state.openDoors)
--		sys.debug("-------", "-------", true)
--		sys.debug(">>>opendoorsD"..tostring(i), #node.state.openDoors, true)
--		sys.debug("same tables", util.deepcompare(node.openDoors, visited_node.openDoors))
--		sys.debug("-------", "-------", true)
--		sys.debug("node.pos", node.state.pos)
--		sys.debug("visited_node.state.pos", visited_node.state.pos)
--		sys.debug("sameBotPos", node.state.pos == visited_node.state.pos)
		if node.state.pos == visited_node.state.pos
			and util.deepcompare(node.openDoors, visited_node.openDoors)
		then

--			sys.debug("tables equal", "true")
--			sys.debug("GoldenrodCityQuest.isVisited()", "end", true)
			return true
		end

		sys.debug("tables equal", "false")
	end

--	sys.debug("GoldenrodCityQuest.isVisited()", "end", true)
	return false
end

GoldenrodCityQuest._learningMove = GoldenrodCityQuest.learningMove
function GoldenrodCityQuest:learningMove(moveName, pokemonIndex)
	--don't forget sleep powder, while leveling
	if moveName ~= "Sleep Powder" then return forgetMove(self:chooseForgetMove(moveName, pokemonIndex)) end
end

return GoldenrodCityQuest