local function vter(cvec)
	local i = -1
	local n = cvec:size()
	return function()
		i = i + 1
		if i < n then return cvec[i] end
	end
end

local function get_distance(point1, point2)
	return math.sqrt(((point2.x - point1.x)^ 2)+((point2.y - point1.y) ^ 2))
end

local function worldToPlayerLocation(location)
	local cApp = Hyperspace.App
	local combatControl = cApp.gui.combatControl
	local playerPosition = combatControl.playerShipPosition
	return Hyperspace.Point(location.x - playerPosition.x, location.y - playerPosition.y)
end
local function worldToEnemyLocation(location)
	local cApp = Hyperspace.App
	local combatControl = cApp.gui.combatControl
	local position = combatControl.position
	local targetPosition = combatControl.targetPosition
	local enemyShipOriginX = position.x + targetPosition.x
	local enemyShipOriginY = position.y + targetPosition.y
	return Hyperspace.Point(location.x - enemyShipOriginX, location.y - enemyShipOriginY)
end

-- Get a table for a userdata value by name
local function userdata_table(userdata, tableName)
	if not userdata.table[tableName] then userdata.table[tableName] = {} end
	return userdata.table[tableName]
end

local cursorValid = Hyperspace.Resources:GetImageId("mouse/mouse_aea_ritual_valid.png")
local cursorValid2 = Hyperspace.Resources:GetImageId("mouse/mouse_aea_ritual_valid2.png")
local cursorRed = Hyperspace.Resources:GetImageId("mouse/mouse_aea_ritual_red.png")

local cursorDefault = Hyperspace.Resources:GetImageId("mouse/pointerValid.png")
local cursorDefault2 = Hyperspace.Resources:GetImageId("mouse/pointerInvalid.png")

local weaknessBoost = Hyperspace.StatBoostDefinition()
weaknessBoost.stat = Hyperspace.CrewStat.MAX_HEALTH
weaknessBoost.amount = 0.5
weaknessBoost.duration = -1
weaknessBoost.maxStacks = 99
weaknessBoost.jumpClear = true
weaknessBoost.cloneClear = false
weaknessBoost.boostType = Hyperspace.StatBoostDefinition.BoostType.MULT
weaknessBoost.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
weaknessBoost.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
weaknessBoost.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
weaknessBoost:GiveId()
script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
	if shipManager.iShipId == 0 then
		for crewmem in vter(shipManager.vCrewList) do
			local crewTable = userdata_table(crewmem, "mods.aea.dark_justicier")
			if crewTable.weakened then
				crewTable.weakened = crewTable.weakened - 1
				Hyperspace.playerVariables["aea_crew_weak_"..tostring(crewmem.extend.selfId)] = crewTable.weakened
				if crewTable.weakened <= 0 then
					crewTable.weakened = nil
				end
				Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(weaknessBoost), crewmem)
			end
		end
	end
end)
local setCrew = false
script.on_init(function()
	setCrew = true
end)
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
	if setCrew and Hyperspace.playerVariables.aea_test_variable == 1 then
		--print("VARIABLE SET")
		setCrew = false
		for crewmem in vter(Hyperspace.ships.player.vCrewList) do
			if Hyperspace.playerVariables["aea_crew_weak_"..tostring(crewmem.extend.selfId)] > 0 then
				userdata_table(crewmem, "mods.aea.dark_justicier").weakened = Hyperspace.playerVariables["aea_crew_weak_"..tostring(crewmem.extend.selfId)]
			end
		end
		if Hyperspace.ships.enemy then
			for crewmem in vter(Hyperspace.ships.enemy.vCrewList) do
				if Hyperspace.playerVariables["aea_crew_weak_"..tostring(crewmem.extend.selfId)] > 0 then
					userdata_table(crewmem, "mods.aea.dark_justicier").weakened = Hyperspace.playerVariables["aea_crew_weak_"..tostring(crewmem.extend.selfId)]
				end
			end
		end
	elseif setCrew then
		--print("VARIABLE NOT SET")
	end
end)
local function applyWeakened(crewmem)
	userdata_table(crewmem, "mods.aea.dark_justicier").weakened = 4
	Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(weaknessBoost), crewmem)
	Hyperspace.playerVariables["aea_crew_weak_"..tostring(crewmem.extend.selfId)] = 4
end
local function checkForValidCrew(crewmem)
	local crewTable = userdata_table(crewmem, "mods.aea.dark_justicier")
	if (crewmem.deathTimer and crewmem.deathTimer:Running()) or crewTable.weakened then
		return false
	end
	return true
end

--Stat boosts

local healBoost = Hyperspace.StatBoostDefinition()
healBoost.stat = Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT
healBoost.amount = 10
healBoost.duration = 5
healBoost.maxStacks = 1
healBoost.cloneClear = true
healBoost.boostType = Hyperspace.StatBoostDefinition.BoostType.FLAT
healBoost.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
healBoost.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
healBoost.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
healBoost:GiveId()
local function healRoom(shipManager, crewTarget)
	for crewmem in vter(shipManager.vCrewList) do
		if crewmem.iRoomId == crewTarget.iRoomId and crewmem.iShipId == 0 then
			Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(healBoost), crewmem)
		end
	end
end
local healShipBoost = Hyperspace.StatBoostDefinition()
healShipBoost.stat = Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT
healShipBoost.amount = 15
healShipBoost.duration = 10
healShipBoost.maxStacks = 1
healShipBoost.cloneClear = true
healShipBoost.boostType = Hyperspace.StatBoostDefinition.BoostType.FLAT
healShipBoost.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
healShipBoost.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
healShipBoost.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
healShipBoost:GiveId()
local function healShip(shipManager, crewTarget)
	for crewmem in vter(shipManager.vCrewList) do
		if crewmem.iShipId == 0 then
			Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(healShipBoost), crewmem)
		end
	end
end
local buffDamageBoost = Hyperspace.StatBoostDefinition()
buffDamageBoost.stat = Hyperspace.CrewStat.DAMAGE_MULTIPLIER
buffDamageBoost.amount = 1.5
buffDamageBoost.duration = -1
buffDamageBoost.maxStacks = 1
buffDamageBoost.cloneClear = true
buffDamageBoost.jumpClear = true
buffDamageBoost.boostType = Hyperspace.StatBoostDefinition.BoostType.MULT
buffDamageBoost.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
buffDamageBoost.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
buffDamageBoost.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
buffDamageBoost:GiveId()
local function buffDamage(shipManager, crewTarget)
	for crewmem in vter(shipManager.vCrewList) do
		if crewmem.iShipId == 0 then
			Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(buffDamageBoost), crewmem)
		end
	end
	if Hyperspace.ships(1 - shipManager.iShipId) then
		for crewmem in vter(Hyperspace.ships(1 - shipManager.iShipId).vCrewList) do
			if crewmem.iShipId == 0 then
				Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(buffDamageBoost), crewmem)
			end
		end
	end
end

--Damage enemy

--Transform Race
local function transformStatBoost(eliteName)
	local transformRace = Hyperspace.StatBoostDefinition()
	transformRace.stat = Hyperspace.CrewStat.TRANSFORM_RACE
	transformRace.stringValue = eliteName
	transformRace.value = true
	transformRace.cloneClear = false
	transformRace.jumpClear = false
	transformRace.boostType = Hyperspace.StatBoostDefinition.BoostType.SET
	transformRace.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
	transformRace.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
	transformRace.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
	transformRace:GiveId()
	return transformRace
end

mods.aea.crewToElite = {}
local crewToElite = mods.aea.crewToElite
crewToElite["human"] = transformStatBoost("human_soldier")
crewToElite["human_engineer"] = transformStatBoost("human_technician")
crewToElite["human_soldier"] = transformStatBoost("human_mfk")
crewToElite["human_mfk"] = transformStatBoost("human_legion")
crewToElite["engi"] = transformStatBoost("engi_defender")
crewToElite["zoltan"] = transformStatBoost("zoltan_peacekeeper")
crewToElite["zoltan_devotee"] = transformStatBoost("zoltan_martyr")
crewToElite["mantis"] = transformStatBoost("mantis_suzerain")
crewToElite["mantis_suzerain"] = transformStatBoost("mantis_bishop")
crewToElite["mantis_free"] = transformStatBoost("mantis_warlord")
crewToElite["rock"] = transformStatBoost("rock_crusader")
crewToElite["rock_crusader"] = transformStatBoost("rock_paladin")
crewToElite["crystal"] = transformStatBoost("crystal_sentinel")
crewToElite["orchid"] = transformStatBoost("orchid_praetor")
crewToElite["orchid_vampweed"] = transformStatBoost("orchid_cultivator")
crewToElite["shell"] = transformStatBoost("shell_radiant")
crewToElite["shell_guardian"] = transformStatBoost("shell_radiant")
crewToElite["leech"] = transformStatBoost("leech_ampere")
crewToElite["slug"] = transformStatBoost("slug_saboteur")
crewToElite["slug_saboteur"] = transformStatBoost("slug_knight")
crewToElite["slug_clansman"] = transformStatBoost("slug_ranger")
crewToElite["lanius"] = transformStatBoost("lanius_welder")
crewToElite["cognitive"] = transformStatBoost("cognitive_advanced")
crewToElite["cognitive_automated"] = transformStatBoost("cognitive_advanced_automated")
crewToElite["obelisk"] = transformStatBoost("obelisk_royal")
crewToElite["phantom"] = transformStatBoost("phantom_alpha")
crewToElite["phantom_goul"] = transformStatBoost("phantom_goul_alpha")
crewToElite["phantom_mare"] = transformStatBoost("phantom_mare_alpha")
crewToElite["phantom_wraith"] = transformStatBoost("phantom_wraith_alpha")
crewToElite["spider_hatch"] = transformStatBoost("spider")
crewToElite["spider"] = transformStatBoost("spider_weaver")
crewToElite["pony"] = transformStatBoost("ponyc")
crewToElite["pony_tamed"] = transformStatBoost("ponyc")
crewToElite["beans"] = transformStatBoost("sylvanrick")
crewToElite["siren"] = transformStatBoost("siren_harpy")
crewToElite["aea_acid_soldier"] = transformStatBoost("aea_acid_captain")
crewToElite["aea_necro_engi"] = transformStatBoost("aea_necro_lich")
crewToElite["aea_bird_avali"] = transformStatBoost("aea_bird_illuminant")
crewToElite["aea_cult_wizard"] = transformStatBoost("aea_cult_priest_off")
crewToElite["aea_cult_wizard_a01"] = transformStatBoost("aea_cult_priest_sup")
crewToElite["aea_cult_wizard_a02"] = transformStatBoost("aea_cult_priest_sup")
crewToElite["aea_cult_wizard_s03"] = transformStatBoost("aea_cult_priest_off")
crewToElite["aea_cult_wizard_s04"] = transformStatBoost("aea_cult_priest_off")
crewToElite["aea_cult_wizard_s05"] = transformStatBoost("aea_cult_priest_off")
crewToElite["aea_cult_wizard_s06"] = transformStatBoost("aea_cult_priest_off")
crewToElite["aea_cult_wizard_a07"] = transformStatBoost("aea_cult_priest_bor")
crewToElite["aea_cult_wizard_s08"] = transformStatBoost("aea_cult_priest_bor")
crewToElite["aea_cult_wizard_s09"] = transformStatBoost("aea_cult_priest_bor")
crewToElite["aea_cult_wizard_a10"] = transformStatBoost("aea_cult_priest_bor")
crewToElite["aea_cult_wizard_a11"] = transformStatBoost("aea_cult_priest_off")
crewToElite["aea_cult_wizard_s12"] = transformStatBoost("aea_cult_priest_sup")
crewToElite["aea_cult_wizard_s13"] = transformStatBoost("aea_cult_priest_off")
crewToElite["aea_cult_wizard_s14"] = transformStatBoost("aea_cult_priest_bor")
--[[function aeatest()
	for crewTarget in vter(Hyperspace.ships.player.vCrewList) do
		if crewToElite[crewTarget.type] then
			Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(crewToElite[crewTarget.type]), crewTarget)
		end
	end
end]]
local function promoteCrew(shipManager, crewTarget)
	Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(crewToElite[crewTarget.type]), crewTarget)
	applyWeakened(crewTarget)
end
local function promoteCond(shipManager, crewTarget)
	if crewToElite[crewTarget.type] and checkForValidCrew(crewTarget) then
		return true
	end
	return false
end

-- Give weapons
local function giveWeapon(weapon)
	local commandGui = Hyperspace.App.gui
	local equipment = commandGui.equipScreen
	local artyBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(weapon)
	equipment:AddWeapon(artyBlueprint, true, false)
end
local function constructCrewList(list)
	local tab = {}
	for blueprint in vter(Hyperspace.Blueprints:GetBlueprintList(list)) do
		tab[blueprint] = true
	end
	return tab
end
local function constructWeaponList(list)
	local tab = {}
	for blueprint in vter(Hyperspace.Blueprints:GetBlueprintList(list)) do
		table.insert(tab, blueprint)
	end
	return tab
end
local weaponTable = { 
	{crewList = constructCrewList("LIST_CREW_CRYSTAL_BASIC"), weaponList = constructWeaponList("GIFTLIST_CRYSTAL"), excludeList = {} },
	{crewList = constructCrewList("LIST_CREW_CRYSTAL"), weaponList = constructWeaponList("GIFTLIST_CRYSTAL_ELITE"), excludeList = constructCrewList("LIST_CREW_CRYSTAL_BASIC")},
	{crewList = constructCrewList("LIST_CREW_ROCK"), weaponList = constructWeaponList("GIFTLIST_MISSILES"), excludeList = {} },
	{crewList = constructCrewList("LIST_CREW_ORCHID"), weaponList = constructWeaponList("GIFTLIST_KERNEL"), excludeList = {} },
	{crewList = constructCrewList("LIST_CREW_VAMPWEED"), weaponList = constructWeaponList("GIFTLIST_SPORE"), excludeList = {} },
	{crewList = constructCrewList("LIST_CREW_GHOST"), weaponList = constructWeaponList("GIFTLIST_RUSTY"), excludeList = {} },
	{crewList = constructCrewList("LIST_CREW_LEECH"), weaponList = constructWeaponList("GIFTLIST_FLAK"), excludeList = {} },
	{crewList = constructCrewList("LIST_CREW_ANCIENT"), weaponList = constructWeaponList("GIFTLIST_ANCIENT"), excludeList = {} }
}
local function giveWeaponFunc(shipManager, crewTarget)
	for i, tab in ipairs(weaponTable) do
		--print("crew:"..crewTarget.type.." i:"..i.." list:"..tostring(tab.crewList[crewTarget.type]).." exclude:"..tostring(tab.excludeList[crewTarget.type]).." not exclude:"..tostring(not tab.excludeList[crewTarget.type]))
		if tab.crewList[crewTarget.type] and (not tab.excludeList[crewTarget.type]) then
			local randomSelect = math.random(1, #tab.weaponList)
			giveWeapon(tab.weaponList[randomSelect])
			applyWeakened(crewTarget)
			return
		end
	end
end
local function giveWeaponCond(shipManager, crewTarget)
	for _, tab in ipairs(weaponTable) do
		if tab.crewList[crewTarget.type] and (not tab.excludeList[crewTarget.type]) then
			return true
		end
	end
	return false
end

local function buyItemCond(shipManager, crewTarget)
	if Hyperspace.ships.player.currentScrap >= 10 then
		return true
	end
	return false
end
local function buyFuelFunc(shipManager, crewTarget)
	Hyperspace.ships.player.fuel_count = Hyperspace.ships.player.fuel_count + math.random(4, 5)
	Hyperspace.ships.player:ModifyScrapCount(-10)
end
local function buyMissilesFunc(shipManager, crewTarget)
	Hyperspace.ships.player:ModifyMissileCount(math.random(2,3))
	Hyperspace.ships.player:ModifyScrapCount(-10)
end
local function buyDronesFunc(shipManager, crewTarget)
	Hyperspace.ships.player:ModifyMissileCount(2)
	Hyperspace.ships.player:ModifyScrapCount(-10)
end

local function fireBombFunc(shipManager, crewTarget)
	local worldManager = Hyperspace.App.world
	Hyperspace.CustomEventsParser.GetInstance():LoadEvent(worldManager,"AEA_SURGE_FIRE",false,-1)
	Hyperspace.ships.player:ModifyMissileCount(-3)
end
local function fireBombCond(shipManager, crewTarget)
	if Hyperspace.ships.player.tempMissileCount >= 3 and Hyperspace.ships.enemy and Hyperspace.ships.enemy._targetable.hostile then
		return true
	end
	return false
end

local function spawnDroneFunc(shipManager, crewTarget)
	local worldManager = Hyperspace.App.world
	Hyperspace.CustomEventsParser.GetInstance():LoadEvent(worldManager,"AEA_SURGE_DRONE",false,-1)
	Hyperspace.ships.player:ModifyDroneCount(-3)
end
local function spawnDroneCond(shipManager, crewTarget)
	if Hyperspace.ships.player.tempDroneCount >= 3 and Hyperspace.ships.enemy and Hyperspace.ships.enemy._targetable.hostile then
		return true
	end
	return false
end

local function lockdownFunc(shipManager, crewTarget)
	local worldManager = Hyperspace.App.world
	Hyperspace.CustomEventsParser.GetInstance():LoadEvent(worldManager,"AEA_SURGE_LOCKDOWN",false,-1)
end
local crystalLockdownList = constructCrewList("LIST_CREW_CRYSTAL")
local function lockdownCond(shipManager, crewTarget)
	if crystalLockdownList[crewTarget.type] and Hyperspace.ships.enemy and Hyperspace.ships.enemy._targetable.hostile then
		return true
	end
	return false
end

local function particleFunc(shipManager, crewTarget)
	local worldManager = Hyperspace.App.world
	Hyperspace.CustomEventsParser.GetInstance():LoadEvent(worldManager,"AEA_SURGE_PARTICLE",false,-1)
end
local function particleCond(shipManager, crewTarget)
	if Hyperspace.ships.enemy and Hyperspace.ships.enemy._targetable.hostile then
		return true
	end
	return false
end

local function boardingFunc(shipManager, crewTarget)
	local worldManager = Hyperspace.App.world
	Hyperspace.CustomEventsParser.GetInstance():LoadEvent(worldManager,"AEA_SURGE_BOARDING",false,-1)
	Hyperspace.ships.player:ModifyMissileCount(-1)
	Hyperspace.ships.player:ModifyDroneCount(-1)
end
local function boardingCond(shipManager, crewTarget)
	if Hyperspace.ships.player.tempMissileCount >= 1 and Hyperspace.ships.player.tempDroneCount >= 1 and Hyperspace.ships.enemy and Hyperspace.ships.enemy._targetable.hostile then
		return true
	end
	return false
end

local spellList = {
	heal_room = {func = healRoom, positionList = {} },
	heal_ship = {func = healShip, positionList = {{x = 0, y = 2}, {x = 1, y = -1}} },
	buff_damage = {func = buffDamage, positionList = {{x = 0, y = -2}, {x = -1, y = 1}} },

	buy_fuel = {func = buyFuelFunc, cond = buyItemCond, positionList = {{x = 1, y = 0}} },
	buy_missile = {func = buyMissilesFunc, cond = buyItemCond, positionList = {{x = 1, y = -1}} },
	buy_drone = {func = buyDronesFunc, cond = buyItemCond, positionList = {{x = 1, y = 1}} },

	fire_bomb = {func = fireBombFunc, cond = fireBombCond, positionList = {{x = -1, y = 1}, {x = 3, y = -1}, {x = -3, y = -1}} },
	spawn_drone = {func = spawnDroneFunc, cond = spawnDroneCond, positionList = {{x = -1, y = -1}, {x = 3, y = 1}, {x = -3, y = 1}} },
	lockdown = {func = lockdownFunc, excludeTarget = true, cond = lockdownCond, positionList = {{x = 3, y = 0}, {x = -1, y = 1}, {x = 0, y = -2}} },
	particle = {func = particleFunc, cond = particleCond, positionList = {{x = 3, y = 0}, {x = -1, y = -1}, {x = 0, y = 2}} },
	boarding = {func = boardingFunc, cond = boardingCond, positionList = {{x = 2, y = 0}, {x = 1, y = 1}, {x = 1, y = -1}} },

	promote = {func = promoteCrew, excludeTarget = true, cond = promoteCond, positionList = {{x = 0, y = -2}, {x = 1, y = 4}, {x = -3, y = -3}, {x = 4, y = 0}, {x = -3, y = 3}} },
	give_weapon = {func = giveWeaponFunc, excludeTarget = true, cond = giveWeaponCond, positionList = {{x = 1, y = 1}, {x = 0, y = 2}, {x = 3, y = 0}, {x = 0, y = -2}, {x = 1, y = -1}} }
}


local sacList = {}
local orderList = {}
local targetShip = 0
local activateCursor = false

script.on_internal_event(Defines.InternalEvents.ACTIVATE_POWER, function(power, shipManager)
	local crewmem = power.crew
	if crewmem.type == "aea_dark_justicier" then
		activateCursor = true
        Hyperspace.Mouse.validPointer = cursorValid
        Hyperspace.Mouse.invalidPointer = cursorValid2
	end
	return Defines.Chain.CONTINUE
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x,y)
	if activateCursor and Hyperspace.ships.player then
		local combatControl = Hyperspace.App.gui.combatControl
		local shipManager = Hyperspace.ships.player
		if #orderList <= 0 then
			if combatControl.selectedSelfRoom < 0 and combatControl.selectedRoom < 0 then return Defines.Chain.CONTINUE end
	        if combatControl.selectedSelfRoom >= 0 then
	        	shipManager = Hyperspace.ships.player
	            targetShip = 0
	            --print("ship player")
	        elseif combatControl.selectedRoom >= 0 then
	        	shipManager = Hyperspace.ships.enemy
	            targetShip = 1
	            --print("ship enemy")
	        end
	    else
	    	shipManager = Hyperspace.ships(targetShip)
	    end
        for crewmem in vter(shipManager.vCrewList) do
        	local location = crewmem:GetLocation()
        	local mousePos = Hyperspace.Mouse.position
        	local mousePosRelative = worldToPlayerLocation(mousePos)
        	if targetShip == 1 then
        		mousePosRelative = worldToEnemyLocation(mousePos)
        	end
        	--print("mouse x:"..mousePosRelative.x.." y:"..mousePosRelative.y.." crew "..crewmem.type.." x:"..location.x.." y:"..location.y)
        	if crewmem.iShipId == 0 and get_distance(mousePosRelative, location) <= 17 and crewmem:AtGoal() and not sacList[crewmem.extend.selfId] then
        		local slotX = math.floor((crewmem.currentSlot.worldLocation.x - 17)/35)
        		local slotY = math.floor((crewmem.currentSlot.worldLocation.y - 17)/35)
	            --print("slot x:"..slotX.." y:"..slotY)
        		sacList[crewmem.extend.selfId] = {room = crewmem.iRoomId, slot = crewmem.currentSlot.slotId, x = slotX, y = slotY}
        		table.insert(orderList, crewmem)
        		break
        	elseif get_distance(mousePosRelative, location) <= 17 and sacList[crewmem.extend.selfId] then
        		sacList[crewmem.extend.selfId] = nil
        		break
        	end
        end
	end 
	return Defines.Chain.CONTINUE
end)

local bloodStain = {
	Hyperspace.Resources:CreateImagePrimitiveString("effects/aea_blood_stain_1.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false),
	Hyperspace.Resources:CreateImagePrimitiveString("effects/aea_blood_stain_2.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false),
	Hyperspace.Resources:CreateImagePrimitiveString("effects/aea_blood_stain_3.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false),
	Hyperspace.Resources:CreateImagePrimitiveString("effects/aea_blood_stain_4.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
}
local bloodStainList = {[0] = {}, [1] = {}}
script.on_render_event(Defines.RenderEvents.SHIP_FLOOR, function() end, function(shipManager)
	local list = bloodStainList[shipManager.iShipId]
	for i, bloodTable in ipairs(list) do
		Graphics.CSurface.GL_PushMatrix()
		Graphics.CSurface.GL_Translate(bloodTable.x, bloodTable.y, 0)
		Graphics.CSurface.GL_RenderPrimitive(bloodStain[bloodTable.state])
		Graphics.CSurface.GL_PopMatrix()
	end
end)

local ritualStart = Hyperspace.Resources:CreateImagePrimitiveString("effects/aea_ritual_start.png", -17, -17, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
local ritualStartCond = Hyperspace.Resources:CreateImagePrimitiveString("effects/aea_ritual_start_crew.png", -17, -17, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
local ritual = Hyperspace.Resources:CreateImagePrimitiveString("effects/aea_ritual.png", -17, -17, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

local lastValid = false
local currentValidSpell = nil
local shapeRight = false
local crewCond = false
script.on_render_event(Defines.RenderEvents.SHIP, function() end, function(shipManager)
	if activateCursor and shipManager.iShipId == targetShip then
		local lastX = nil
		local lastY = nil
		local lastRoomX = nil
		local lastRoomY = nil
		local removeI = nil
		local validSpells = {}
		for spell, pos in pairs(spellList) do
			validSpells[spell] = true
		end
		local crewCount = 0
		local crewTarget = nil
		for i, crewmem in ipairs(orderList) do
			if sacList[crewmem.extend.selfId] then
				if crewCount == 0 then
					crewTarget = crewmem
				end
				crewCount = crewCount + 1
				local location = crewmem:GetLocation()
				local colour = 0.5
				local blue = 0
				if lastValid then colour = 1 
				elseif shapeRight then 
					colour = 0.75 
					blue = 1
				end
				if lastX and lastY then
	   				Graphics.CSurface.GL_DrawLine(lastX+1, lastY+1, location.x+1, location.y+1, 5, Graphics.GL_Color(colour, 0, blue, 0.4))
	   				Graphics.CSurface.GL_DrawLine(lastX+1, lastY+1, location.x+1, location.y+1, 3, Graphics.GL_Color(colour, 0, blue, 0.6))
	   				Graphics.CSurface.GL_PushMatrix()
					Graphics.CSurface.GL_Translate(location.x, location.y, 0)
					Graphics.CSurface.GL_RenderPrimitiveWithColor(ritual, Graphics.GL_Color(colour, 0, blue, 0.8))
					Graphics.CSurface.GL_PopMatrix()
		   			if crewCount == 2 then
		   				Graphics.CSurface.GL_PushMatrix()
						Graphics.CSurface.GL_Translate(lastX, lastY, 0)
						if shapeRight and (not lastValid) and crewCond then 
							Graphics.CSurface.GL_RenderPrimitiveWithColor(ritualStartCond, Graphics.GL_Color(colour, 0, blue, 0.8))
						else
							Graphics.CSurface.GL_RenderPrimitiveWithColor(ritualStart, Graphics.GL_Color(colour, 0, blue, 0.8))
						end
						Graphics.CSurface.GL_PopMatrix()
		   			end
		   		elseif crewCount == 1 and #orderList == 1 then
	   				Graphics.CSurface.GL_PushMatrix()
					Graphics.CSurface.GL_Translate(location.x, location.y, 0)
					Graphics.CSurface.GL_RenderPrimitiveWithColor(ritualStart, Graphics.GL_Color(colour, 0, 0, 0.8))
					Graphics.CSurface.GL_PopMatrix()
	   			end
	   			lastX = location.x
	   			lastY = location.y
	   			local sacTable = sacList[crewmem.extend.selfId] 
	   			local roomX = sacTable.x
	   			local roomY = sacTable.y
	   			if lastRoomX and lastRoomY then
		   			for spell, spellTable in pairs(spellList) do
		   				local positionOffset = spellTable.positionList[crewCount - 1]
		   				if validSpells[spell] and positionOffset then
			   				if roomX - lastRoomX ~= positionOffset.x or roomY - lastRoomY ~= positionOffset.y then
			   					validSpells[spell] = nil
			   					--print("spell fail pos:"..spell.." count:"..crewCount)
			   				end
			   			elseif validSpells[spell] then
			   				validSpells[spell] = nil
		   					--print("spell fail count:"..spell.." count:"..crewCount)
			   			end
		   			end
		   		end
	   			lastRoomX = roomX
	   			lastRoomY = roomY
	   		else
	   			removeI = i
			end
		end
		if removeI then
			table.remove(orderList, removeI)
		end
		crewCond = false
		shapeRight = false
		local validSpell = nil
		if crewCount > 0 then
			for spell, spellTable in pairs(spellList) do
				--local positionOffset = spellTable.positionList[crewCount]
				if validSpells[spell] and spellTable.positionList[crewCount] then
   					--print("spell fail low count:"..spell.." count:"..crewCount)
					validSpells[spell] = nil
				elseif validSpells[spell] then
					if spellTable.cond then
						if spellTable.cond(shipManager, crewTarget) then
							validSpell = spell
						else
							--print("cond fail")
							shapeRight = true
							if spellTable.excludeTarget then
								crewCond = true
							end
							validSpells[spell] = nil
						end
					else
						validSpell = spell
					end
				end
			end
		end
		local nowValid = false
		if validSpell then
			nowValid = true
			currentValidSpell = validSpell
		else
			currentValidSpell = nil
		end

		if nowValid ~= lastValid and nowValid == true then
        	Hyperspace.Mouse.validPointer = cursorRed
        	Hyperspace.Mouse.invalidPointer = cursorRed
		elseif nowValid ~= lastValid then
        	Hyperspace.Mouse.validPointer = cursorValid
        	Hyperspace.Mouse.invalidPointer = cursorValid2
		end

		lastValid = nowValid
	end
end)

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crewmem)
	if activateCursor and sacList[crewmem.extend.selfId] then
		local crewTable = sacList[crewmem.extend.selfId]
		crewmem:SetRoomPath(crewTable.slot, crewTable.room)
	end
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
	if activateCursor then
		for crewmem in vter(shipManager.vCrewList) do
			if crewmem.type == "aea_dark_justicier" then
				for power in vter(crewmem.extend.crewPowers) do
					power.temporaryPowerDuration.first = power.temporaryPowerDuration.second
				end
			end
		end
	end
end)

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
	local commandGui = Hyperspace.App.gui
	if activateCursor and (commandGui.event_pause or commandGui.menu_pause) then
		activateCursor = false
	    Hyperspace.Mouse.validPointer = cursorDefault
	    Hyperspace.Mouse.invalidPointer = cursorDefault2
	    sacList = {}
	    orderList = {}
	    for crewmem in vter(Hyperspace.ships.player.vCrewList) do
			if crewmem.type == "aea_dark_justicier" then
				for power in vter(crewmem.extend.crewPowers) do
					power:CancelPower(true)
					power.powerCooldown.first = power.powerCooldown.second - 0.01
				end
			end
		end
	end
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_R_BUTTON_DOWN, function(x,y) 
	if activateCursor then
		activateCursor = false
	    Hyperspace.Mouse.validPointer = cursorDefault
	    Hyperspace.Mouse.invalidPointer = cursorDefault2
	    if currentValidSpell and orderList[1] then
	    	print("ATTEMPTING SPELL:"..currentValidSpell)
	    	spellList[currentValidSpell].func(Hyperspace.ships(targetShip), orderList[1])
	    	for i, crewmem in ipairs(orderList) do
	    		if not spellList[currentValidSpell].excludeTarget or i > 1 then
	    			local x = crewmem.currentSlot.worldLocation.x + math.random(-17, 6)
	    			local y = crewmem.currentSlot.worldLocation.y + math.random(-17, 6)
	    			local random = math.random(1,4)
	    			table.insert(bloodStainList[targetShip], {x = x, y = y, state = random})
	    			x = crewmem.currentSlot.worldLocation.x + math.random(-17, 6)
	    			y = crewmem.currentSlot.worldLocation.y + math.random(-17, 6)
	    			random = math.random(1,4)
	    			table.insert(bloodStainList[targetShip], {x = x, y = y, state = random})
	    			crewmem:Kill(false)
	    			if crewmem then
	    				applyWeakened(crewmem)
	    			end
					Hyperspace.Sounds:PlaySoundMix("mantisSlash", -1, false)
	    		end
	    	end
	    else
	    	for crewmem in vter(Hyperspace.ships.player.vCrewList) do
				if crewmem.type == "aea_dark_justicier" then
					for power in vter(crewmem.extend.crewPowers) do
						power:CancelPower(true)
						power.powerCooldown.first = power.powerCooldown.second - 0.01
					end
				end
			end
	    end
	    sacList = {}
	    orderList = {}
	end
end)

--[[local vter = mods.multiverse.vter

local huskList = {}
huskList["ddsoulplague_husk_human"] = true
huskList["ddsoulplague_husk_crystal"] = true
huskList["ddsoulplague_husk_engi"] = true
huskList["ddsoulplague_husk_zoltan"] = true
huskList["ddsoulplague_husk_orchid"] = true
huskList["ddsoulplague_husk_mantis"] = true
huskList["ddsoulplague_husk_rockman"] = true
huskList["ddsoulplague_husk_slug"] = true
huskList["ddsoulplague_husk_shell"] = true
huskList["ddsoulplague_husk_lanius"] = true
huskList["ddsoulplague_husk_deepone"] = true
huskList["ddsoulplague_husk_ghost"] = true
huskList["ddsoulplague_husk_leech"] = true
huskList["ddsoulplague_husk_obelisk"] = true

script.on_internal_event(Defines.InternalEvents.HAS_EQUIPMENT, function(shipManager, equipment, value)
	if huskList[equipment] and shipManager.iShipId == 0 then
		local count = 0
		for crewmem in vter(Hyperspace.ships.player) do
			if crewmem.type == equipment then
				count = count + 1
			end
		end
		return Defines.Chain.CONTINUE, count
	end
	return Defines.Chain.CONTINUE, value
end)]]