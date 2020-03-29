-- MTR_Sacae_Scripts
-- Author: Angelo
-- DateCreated: 2020-03-28 12:11:06
--------------------------------------------------------------

--------------------------------------------------------------
--UNIT HEALS BY MOVING
--
--IDEAS:
--  1) As soon as move, heal based on moves used
--	ref: 
--  Lua objects: GetMaxMoves and GetExtraMoves
--  Events: UnitMovementPointsChanged /UnitMovementPointsCleared (not this one)
--		Pros:
--			+Directly visible and apparent, flashy
--			+Easy to implement
--		Cons:
--			-Would have to be insignificant amount or else people would move to heal and come back to same spot and then attack, it'd be really annoying to fight
--
--
--	2) At turn end, heal based on moves used
--	ref: 
--  Lua objects: GetMaxMoves and GetExtraMoves
--  Events: TurnEnd
--		Pros: 
--			+Easy to implement
--			+Could be up-d as it would be less cheesy to happen at the end of the turn
--		Cons:
--			-Loses flashiness, like you might as well just give them the march promotion
--			-**MAJOR**, if attacking reduces units moves to 0, this basically just gives all calvary a heal no matter what action they take, could be stationary and shoot and get the heal
--			-Still cheesy as people could move to use the moves and then just go back to same spot
--
--
--	3) At turn end, heal based on distance covered
--	ref: 
--  Lua objects: GetLocation
--  Events: TurnEnd TurnBegin // UnitMoved, UnitMoveComplete, UnitMovementPointsChanged
--		Pros:
--			+Best reflects what I'm trying to do
--			+Woods and hills wood restrict movement and therefore the healing directly, gives a clear weakness, and because of this can be more impactful on flat terrain
--			+Prevents cheese with moving out and into the same tile to get the heal
--		Cons:
--			-Most difficult to implement
--				Need to figure out how to get starting location at start of turn and then ending location at end of turn and apply heal based on the distance between the two
--			-Cannot be set to whenever you move, otherwise the cheese with "move out two spaces, move back two spaces, get heal" is still an issue
--				+POTENTIALLY, can make it so if it remembers where you started at the start of the turn and if you move X away from it, then it heals you for that amount, but not anymore if you move back closer to it, only if you go farther
--			-Because of above, it loses a bit of flashiness UNLESS that idea can be ironed out, then it reflects the idea even better than idea number 1
--
--
-- GOING WITH IDEA 3
--------------------------------------------------------------------------

