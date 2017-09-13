-- Copyright © 2016 g0ld <g0ld@tuta.io>
-- This work is free. You can redistribute it and/or modify it under the
-- terms of the Do What The Fuck You Want To Public License, Version 2,
-- as published by Sam Hocevar. See the COPYING file for more details.
-- Quest: @Rympex


local sys    = require "Libs/syslib"
local game   = require "Libs/gamelib"
local pc     = require "Libs/pclib"
local Quest  = require "Quests/Quest"

local name		  = 'Violet City'
local description = ' Badge Quest'
local level = 12
local minTeamSize = 4

local ZephyrBadgeQuest = Quest:new()

function ZephyrBadgeQuest:new()
	return Quest.new(ZephyrBadgeQuest, name, description, level)
end

function ZephyrBadgeQuest:isDoable()
	if self:hasMap() and not hasItem("Hive Badge") then
		return true
	end
	return false
end

function ZephyrBadgeQuest:isDone()
	if getMapName() == "Sprout Tower F1" or getMapName() == "Azalea Town" then
		return true
	end
	return false
end

function ZephyrBadgeQuest:PokecenterVioletCity()
	--Guide BOB
	if isNpcOnCell(11,21) then return talkToNpcOnCell(11,21) end

	local sleepPowderer = "Bellsprout"
	if not hasPokemonInTeam(sleepPowderer) then
		--check for bellsprout:
		-- for goldenrod's guard quest - adv in contrast to old oddish:
		-- 1-- available day and night
		-- 2-- need to level up here anyway
		-- 3-- bellsprout has access to sleeppowder 2 levels earlier
		-- 4-- it can now be leveled with team, instead of doing it an extra training session for oddish only
		local bellSproutId = {069}
		local result, pkmBoxId, slotId, swapTeamId = pc.retrieveFirst{id = bellSproutId, region={"Jotho"}}

		--working 	| then return because of open proShine functions to be resolved
		--			| if not returned, a "can only execute one function per frame" might occur
		if result == pc.result.WORKING then return sys.info("Searching PC")

		--no solution, add bellsprout as a force catch
		elseif  result == pc.result.NO_RESULT then
			self.pokemon = sleepPowderer
			self.forceCaught = false

		--has a bellsprout on the pc
		else
			local pkm = result
			local msg = "Found "..pkm.name.." on BOX: " .. pkmBoxId .. "  Slot: " .. slotId
			if swapTeamId then  msg = msg .. " | Swapping with pokemon in team N: " .. swapTeamId
			else                msg = msg .. " | Added to team." end
			return sys.log(msg)
		end
	end

	--do other pokecenter stuff
	self:pokecenter("Violet City")
end

function ZephyrBadgeQuest:PokecenterRoute32()
	self:pokecenter("Route 32")
end

function ZephyrBadgeQuest:VioletCityPokemart()
	self:pokemart("Violet City")	
end

function ZephyrBadgeQuest:VioletCity()
	if self:needPokecenter()
		or not game.isTeamFullyHealed()
		or self.registeredPokecenter ~= "Pokecenter Violet City"
	then
		return moveToMap("Pokecenter Violet City")
	elseif self:needPokemart() then
		return moveToMap("Violet City Pokemart")
	elseif not self:isTeamReady() then
		return moveToMap("Route 32")
	elseif isNpcOnCell(27,44) then	
		return moveToMap("Sprout Tower F1")
	elseif not hasItem("Zephyr Badge") then
		return moveToMap("Violet City Gym Entrance")
	end

	return moveToMap("Route 32")
end

function ZephyrBadgeQuest:isTeamReady()
	return self:isTrainingOver()
		and getTeamSize() >= minTeamSize
end

function ZephyrBadgeQuest:Route32()
	if not hasItem("Zephyr Badge") then
		if 	self:needPokecenter()
			or self:needPokemart()
			or self.registeredPokecenter ~= "Pokecenter Violet City"
			or self:isTeamReady()
		then return moveToMap("Violet City") end

	elseif hasItem("Zephyr Badge") then
		if 	   isNpcOnCell(26,23)  then return talkToNpcOnCell(26,23)
		elseif isNpcOnCell(25,8)   then return talkToNpcOnCell(25,8)   --Item: Chesto Berry
		elseif isNpcOnCell(26,8)   then return talkToNpcOnCell(26,8)   --Item: Oran Berry
		elseif isNpcOnCell(20,119) then return talkToNpcOnCell(20,119) --Item: Oran Berry
		elseif isNpcOnCell(20,120) then return talkToNpcOnCell(20,120) --Item: Lummy Berry
		elseif isNpcOnCell(20,121) then return talkToNpcOnCell(20,121) --Item: Leppa Berry
		elseif self:needPokecenter()
			or self.registeredPokecenter ~= "Pokecenter Route 32"
		then
			return moveToMap("Pokecenter Route 32")

		else return moveToMap("Union Cave 1F") end
	end

	return moveToGrass()
end

function ZephyrBadgeQuest:VioletCityGymEntrance()
	if not hasItem("Zephyr Badge") then
		return moveToMap("Violet City Gym")
	else
		return moveToMap("Violet City")
	end
end

function ZephyrBadgeQuest:VioletCityGym()
	if not hasItem("Zephyr Badge") then
		return talkToNpcOnCell(7,4)
	else
		return moveToMap("Violet City Gym Entrance")
	end
end

function ZephyrBadgeQuest:UnionCave1F()
	return moveToCell(42,84)
end

function ZephyrBadgeQuest:Route33()
	return moveToMap("Azalea Town")
end

ZephyrBadgeQuest._wildBattle = ZephyrBadgeQuest.wildBattle
function ZephyrBadgeQuest:wildBattle()
	if getTeamSize() < minTeamSize then
		if useItem("Pokeball") or useItem("Great Ball") or useItem("Ultra Ball") then return true end
	end
	return self:_wildBattle()
end

return ZephyrBadgeQuest