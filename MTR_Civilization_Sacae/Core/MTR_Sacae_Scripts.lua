-- MTR_Sacae_Scripts
-- Author: Martyr
-- DateCreated: 2020-03-28 12:11:06
--------------------------------------------------------------

--At turn start:
	--Reset information on max distances to zero
	--Record positions of all units for the player whose turn it is
--Upon Unit Moving:
	--Calculate Distance from starting position
		--IF greater than previous maxdistance for that unitID then 
			--HEAL
			--Record maxdistance
		--ELSE DO NOTHING

--====================================================================
--UTILITIES
--Credit: Chrisy15 and LeeS
--====================================================================
--------
--Created by Chrisy15, didn't retool as it functions exactly the way I need it
--------
function MTR_getValidPlayersWithTrait(sTrait)
	--print("MTR_getValidPlayersWithTrait");
	local tValidPlayers = {}
	
	for k, v in ipairs(PlayerManager.GetWasEverAliveIDs()) do
		--print("for k, v in ipairs statement");
		local leaderType = PlayerConfigurations[v]:GetLeaderTypeName() --this returns actual String ("LEADER_MTR_LYNDIS")
        for trait in GameInfo.LeaderTraits() do -- the variable trait here is actually a table  THIS PART SCREENS ALL LEADERS IN THE GAME FOR THE TRAITS
			--print("trait");
			--print(trait);
			--print(trait.LeaderType);
			--print(trait.TraitType);
            if trait.LeaderType == leaderType and trait.TraitType == sTrait then 
				--print("Valid Trait!");
                tValidPlayers[v] = true 
            end;
        end
        if not tValidPlayers[v] then --IF v WAS NOT ADDED YET
			--print("if not statement")
            local civType = PlayerConfigurations[v]:GetCivilizationTypeName() --returns actual String
			--print("civType " .. civType);
            for trait in GameInfo.CivilizationTraits() do -- the variable trait here is a table THIS PART SCREENS ALL CIVILIZATIONS IN THE GAME FOR THIS TRAIT
				--print("trait");
				--print(trait);
				--print(trait.CivilizationType);
				--print(trait.TraitType);
                if trait.CivilizationType == civType and trait.TraitType == sTrait then 
					--print("Valid Trait!");
                    tValidPlayers[v] = true 
                end;
            end
        end
    end
	--print("returning...");
    return tValidPlayers
end



----------------------------------------------
--My custom method that generates a table of Unit Types with tags for the Classes it's meant to affect
----------------------------------------------
function MTR_getValidUnits(tTableInput)
	tTableOutput = {}
	for z, c in pairs(tTableInput) do
		local tQuery = DB.Query("SELECT * FROM TypeTags WHERE Type IN (SELECT UnitType FROM Units) AND (Tag = '" .. c .. "')");
		for k, v in ipairs(tQuery) do
			tTableOutput[v.Type] = true;
		end
	end
	return tTableOutput;
end
----------------------------------------------
--====================================================================


--====================================================================
--Constants
--====================================================================

	local sTrait = "TRAIT_CIVILIZATION_MTR_SACAE_UA";
	local tValidPlayerList = MTR_getValidPlayersWithTrait(sTrait); --Key is PlayerID, returns true or nil based on what MTR_getValidPlayersWithTrait returns
	local tValidUnitClassList = 
	{
	"CLASS_LIGHT_CAVALRY",
	"CLASS_RANGED_CAVALRY",
	"CLASS_MTR_SACAE_UAINCLUDE"
	}
	local tValidUnitList = MTR_getValidUnits(tValidUnitClassList); --Table containing all UnitTypes that are a class list in tValidUnitClassList
	
	local tUnitStartPoses = {}; -- [player][unit] -> {X, Y}
	local iUnitMaxDistancesCovered = {}; --array of array of integers [player][unit] -> int 
	
	local iHealPerSpaceBase = 4; --Base Value *a*x^b
	local iHealScaling = 1.5; --Scaling ax^*b*
	local iMaxHeal = 50; --Cap (So you can't just heal to full health by running on a railroad)



--====================================================================
-- Custom Functions
--====================================================================



function MTR_CalculateTraveledDistance(iPlayerID, iUnitID, iX, iY) --Calculates traveled distance from starting position
		local aX = tUnitStartPoses[iPlayerID][iUnitID].X; 
		local aY = tUnitStartPoses[iPlayerID][iUnitID].Y;
		
		local iDistance = Map.GetPlotDistance(iX, iY, aX, aY)--math.sqrt((aX-iX)^2-(aY-iY)^2);
		
		return iDistance;
end


function MTR_ApplyHeal(iPlayerID, iUnitID, iNewDistance, iOldDistance) --Assumes that iNewDistance > iOldDistance
		local iNewHeal = math.floor(iHealPerSpaceBase*(iNewDistance^(iHealScaling)));
		if (iNewHeal > iMaxHeal) then
			iNewHeal = iMaxHeal;
		end
		local iOldHeal = math.floor(iHealPerSpaceBase*(iOldDistance^(iHealScaling)));
		if (iOldHeal > iMaxHeal) then
			iOldHeal = iMaxHeal;
		end
		
		local pUnit = Players[iPlayerID]:GetUnits():FindID(iUnitID);
		pUnit:ChangeDamage(-1*(iNewHeal-iOldHeal)); --negative damage is healing, positive is damage
		iUnitMaxDistancesCovered[iPlayerID][iUnitID] = iNewDistance;--records maxdistance
end


--------
--Based off LeeS' work
--------
function MTR_ResetDistances(iPlayerID)
	if tValidPlayerList[iPlayerID] then
		iUnitMaxDistancesCovered[iPlayerID] = {}
		local pPlayer = Players[iPlayerID]
		for i,pUnit in pPlayer:GetUnits():Members() do
			iUnitMaxDistancesCovered[iPlayerID][pUnit:GetID()] = 0;
		end
	end
end
function MTR_ResetStartPoses(iPlayerID)
	if tValidPlayerList[iPlayerID] then
		tUnitStartPoses[iPlayerID] = {}
		local pPlayer = Players[iPlayerID]
		for i,pUnit in pPlayer:GetUnits():Members() do
			tUnitStartPoses[iPlayerID][pUnit:GetID()] = {X = 0, Y = 0};
		end
	end
end

--------
--Retooled from LeeS, changed to return a table instead of directly setting the values on an existing table
--Can be used like this at multiple stages now, and doesn't need clutter from "bIsFirstTimeThisTurn"
--------
function MTR_GetUnitPositions(iPlayerID)
	local tUnitPoses = {}

	if tValidPlayerList[iPlayerID] then
		tUnitPoses[iPlayerID] = {}
		local pPlayer = Players[iPlayerID]
		for i,pUnit in pPlayer:GetUnits():Members() do
			tUnitPoses[iPlayerID][pUnit:GetID()] = {X = pUnit:GetX(), Y = pUnit:GetY()}
		end
	end
	return tUnitPoses[iPlayerID]--Returns the table for that playerID
end

--For use when a unit is barely trained
function MTR_SetSpecificUnitPosition(iPlayerID, iUnitID)
	if tValidPlayerList[iPlayerID] then
		local pPlayer = Players[iPlayerID];
		local pUnit = pPlayer:GetUnits():FindID(iUnitID);
		if (pUnit == nil) then 
			--print("pUnit is nil)
			return
		end
		if (tUnitStartPoses[iPlayerID] == nil) then
			--print("No table present for that playerID");
			tUnitStartPoses[iPlayerID] = {};
		end
		if (tUnitStartPoses[iPlayerID][iUnitID] == nil) then
			--print("No table present for that unitID");
			tUnitStartPoses[iPlayerID][iUnitID] = {};
		end
		
		tUnitStartPoses[iPlayerID][iUnitID] = {X = pUnit:GetX(), Y = pUnit:GetY()};
	end
end



--====================================================================
--Runs at turn start
--Essentially just calls the Utilities as long as it's not called more than once
--====================================================================
function MTR_SacaeUA_PlayerTurnActivated(iPlayerID, bIsFirstTimeThisTurn)
	if (tValidPlayerList[iPlayerID] ~= true) then return end --abort if not ValidPlayer
	if (bIsFirstTimeThisTurn == false) then return end --abort if not first time this turn
	
	MTR_ResetStartPoses(iPlayerID);--resets values for this player to zero
	MTR_ResetDistances(iPlayerID);--resets values for this player to zero
	tUnitStartPoses[iPlayerID] = MTR_GetUnitPositions(iPlayerID);--SetPlayerPositions (specific for that playerID)
end

--====================================================================
--Runs when player unit moves
--====================================================================
function MTR_SacaeUA_UnitMoved(iPlayerID, iUnitID, iX, iY, locallyVisible, stateChange)
	if (tValidPlayerList[iPlayerID] ~= true) then return end --abort if not ValidPlayer
	local pPlayer = Players[iPlayerID];
	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	local sType = GameInfo.Units[pUnit:GetType()].UnitType
	if (tValidUnitList[sType] ~= true) then return end --abort if not valid UnitType
	
	local iNewDistance = MTR_CalculateTraveledDistance(iPlayerID, iUnitID, iX, iY);
	
	if (iUnitMaxDistancesCovered[iPlayerID][iUnitID] == nil) then --Safety if value doesn't exist
		iUnitMaxDistancesCovered[iPlayerID][iUnitID] = 0;
	end
	iOldDistance = iUnitMaxDistancesCovered[iPlayerID][iUnitID];
	
	if (iNewDistance > iOldDistance) then --getting error for comparing number to nil here
		MTR_ApplyHeal(iPlayerID, iUnitID, iNewDistance, iOldDistance);
	end
	--else do nothing
end

--====================================================================
--Runs at LoadScreenClose (when you reload game)
--This just is a workaround for the fact that the lua table for the unit start poses doesn't get saved/reloaded
--Just calls MTR_SacaeUA_PlayerTurnActivated
--====================================================================
function MTR_SacaeUA_OnLoadScreenClose()
	for k, playerID in ipairs(PlayerManager.GetWasEverAliveIDs()) do
		MTR_SacaeUA_PlayerTurnActivated(playerID, true); -- just setting bIsFirstTimeThisTurn to true
	end
end

--====================================================================
--Runs at UnitAddedToMap
--This just is a workaround for the fact that the lua table for the unit start poses doesn't have an entry for a unit that was barely trained that turn
--Note: has to check if unit spawned dead (happens apparently), aborts if it is
--====================================================================
function MTR_SacaeUA_UnitAddedToMap(iPlayerID, iUnitID)
	if (tValidPlayerList[iPlayerID]~=true) then return end --abort if not ValidPlayer
	
	local pPlayer = Players[iPlayerID]
    local pPlayerUnits = pPlayer:GetUnits()
    local pUnit = pPlayerUnits:FindID(iUnitID)
    if (pUnit == nil) then
        --print("the unit's pUnit object was a nil value")
        return
    end
    local iUnitX, iUnitY = pUnit:GetX(), pUnit:GetY()
    local pPlot = Map.GetPlot(iUnitX, iUnitY)
    if (pPlot == nil) then
        --print("the unit's plot location was nil")
        return
    end
	
	MTR_SetSpecificUnitPosition(iPlayerID, iUnitID);
end

--====================================================================
--Inputting Functions into the Game Events (This is what I think this does)
--====================================================================
Events.PlayerTurnActivated.Add(MTR_SacaeUA_PlayerTurnActivated);
Events.UnitMoved.Add(MTR_SacaeUA_UnitMoved);

Events.LoadScreenClose.Add(MTR_SacaeUA_OnLoadScreenClose)
Events.UnitAddedToMap.Add(MTR_SacaeUA_UnitAddedToMap)