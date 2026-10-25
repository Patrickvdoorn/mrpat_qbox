lib.locale()

local pendingContracts = {}
local activeContracts = {}
local previousJobs = {}
local allowedPayments = { 'cash', 'bank' }


local function log(src, citizenid, event, message, tag)
	if not Config.Logging then
		return
	end
	Config.LogCommand(src, event, ('%s (%s) %s'):format(GetPlayerName(src), citizenid, message), tag)
end

local function matchTypes(value, expected)
	if type(expected) == 'table' then
		return Utils.contains(expected, type(value))
	else
		return type(value) == expected
	end
end

local function playerIsNear(src, target, maxDistance)
	local coords = GetEntityCoords(GetPlayerPed(src))
	return #(coords - target) <= maxDistance
end

local function jobSite(contract)
	return Config.Locations[contract.location]
end

local function vesselIsLost(contract)
	return not DoesEntityExist(contract.vessel) or GetEntityHealth(contract.vessel) <= 0
end

local function getPlayerContract(src)
	if not exports.qbx_core:GetPlayer(src) then
		return nil, 'no_character_loaded'
	end

	local contract = activeContracts[src]
	if not contract then
		return nil, 'contract_missing'
	end

	return contract
end

local function getWorkContract(src, requiredState)
	local contract, err = getPlayerContract(src)
	if not contract then
		return nil, err
	end

	if contract.state == 'repaired' then
		return nil, 'already_repaired'
	end

	if contract.state ~= requiredState then
		return nil, requiredState == 'assigned' and 'already_inspected' or 'not_inspected'
	end

	if not playerIsNear(src, jobSite(contract).coords, Config.InteractionDistance) then
		return nil, 'too_far_from_issue'
	end

	return contract
end

-- Checks to find possible issues at startup
local function configCheckValue(name, zeroAllowed)
	local value = Config[name]

	if zeroAllowed then
		if type(value) ~= 'number' or value < 0 then
			lib.print.error(('Config.%s is "%s", but should be 0 or higher'):format(name, value))
		end
	else
		if type(value) ~= 'number' or value <= 0 then
			lib.print.error(('Config.%s is "%s", but should be higher than 0'):format(name, value))
		end
	end
end

local function configCheckGeneralSettings()
	configCheckValue('InteractionDistance', false)
	configCheckValue('RepairDuration', false)
	configCheckValue('Deposit', true)
end

local requiredTierFields = { 'id', 'level', 'types', 'vehicle', 'pay', 'xp' }

local function configCheckTiers()
	local seenTypes = {}
	local seenIds = {}

	for index, tier in ipairs(Config.Tiers) do
		local complete = true
		for _, field in ipairs(requiredTierFields) do
			if tier[field] == nil then
				lib.print.error(('tier %s (%s) is missing "%s"'):format(index, tostring(tier.id), field))
				complete = false
			end
		end

		if complete then
			if seenIds[tier.id] then
				lib.print.error(('tier id "%s" is used more than once'):format(tier.id))
			else
				seenIds[tier.id] = true
			end

			if tier.level < 1 or tier.level > #Config.Levels then
				lib.print.error(('tier "%s" needs level "%s", but Config.Levels only has "%s" levels'):format(tier.id, tier.level, #Config.Levels))
			end

			if tier.deposit ~= nil and type(tier.deposit) ~= 'number' then
				lib.print.error(('tier "%s" has a deposit that is not a number'):format(tier.id))
			elseif tier.deposit ~= nil and tier.deposit < 0 then
				lib.print.error(('tier "%s" has a deposit of "%s", but it should be 0 or higher'):format(tier.id, tier.deposit))
			end

			if tier.blip and not Utils.contains({'area','exact'}, tier.blip) then
				lib.print.warn(('tier "%s" has unknown blip "%s" (use "exact" or "area"), so it will use the exact blip instead'):format(tier.id, tier.blip))
			end

			if tier.blip == 'area' and (type(tier.radius) ~= 'number' or tier.radius <= 0) then
				lib.print.warn(('tier "%s" has blip "%s" without valid radius, so it will use the exact blip instead'):format(tier.id, tier.blip))
			end

			local hasZone = tier.blip == 'area' and type(tier.radius) == 'number' and tier.radius > 0
			if tier.sonar and not hasZone then
				lib.print.warn(('tier "%s" has sonar = true but no search zone (needs blip = "area" with a valid radius), so it will have no sonar'):format(tier.id))
			end

			if tier.drawDistance and (type(tier.drawDistance) ~= 'number' or tier.drawDistance <= 0) then
				lib.print.warn(('tier "%s" has invalid drawDistance, so it will use Config.DrawDistance instead'):format(tier.id))
			end

			if tier.interactionType ~= nil and not Utils.contains({'prompt','target'}, tier.interactionType) then
				lib.print.error(('tier "%s" has invalid interactionType "%s" (use "prompt" or "target")'):format(tier.id,tier.interactionType))
			end

			if tier.difficulties == nil or (type(tier.difficulties) == 'table' and #tier.difficulties == 0) then
				lib.print.warn(('tier "%s" has no difficulties, so it will use medium instead'):format(tier.id))
			elseif type(tier.difficulties) ~= 'table' then
				lib.print.error(('tier "%s" has difficulties of type "%s", but it should be a list like { \'medium\' }, so it will use medium instead'):format(tier.id, type(tier.difficulties)))
			else
				for _, difficulty in ipairs(tier.difficulties) do
					if not Utils.contains(Utils.difficulties, difficulty) then
						lib.print.error(('tier "%s" has an invalid difficulty "%s" which will be skipped. Only use %s'):format(tier.id, difficulty, table.concat(Utils.difficulties, ', ')))
					end
				end
			end

			for _, typeName in ipairs(tier.types) do
				if seenTypes[typeName] then
					lib.print.error(('type "%s" is in both tier %s and tier %s'):format(typeName, seenTypes[typeName], tier.id))
				else
					seenTypes[typeName] = tier.id
				end
			end
		end
	end
end

local requiredLocationFields = {
	label = 'string',
	model = { 'table', 'string' },
	placement = 'string',
	coords = 'vector3',
	type = 'string',
}

local allowedPlacements = { 'ground', 'water', 'seabed' }

local function configCheckLocations()
	for index, location in ipairs(Config.Locations) do
		local complete = true
		local name = location.label or index

		for field, expected in pairs(requiredLocationFields) do
			local expectedText = expected
			if location[field] == nil then
				lib.print.error(('location %s (%s) is missing "%s"'):format(index, name, field))
				complete = false
			elseif not matchTypes(location[field], expected) then
				if type(expected) == 'table' then
					expectedText = table.concat(expected, " or ")
				end
				lib.print.error(('field %s in location %s (%s) should be type %s but is type "%s"'):format(field, index, name, expectedText, type(location[field])))
				complete = false
			end
		end

		if complete then
			if not Utils.contains(allowedPlacements, location.placement) then
				lib.print.error(('location %s (%s) has invalid placement "%s" (use %s)'):format(index, name, location.placement, table.concat(allowedPlacements, ", ")))
			end

			if (type(location.model) == 'table' and #location.model == 0) then
				lib.print.error(('location %s (%s) has no model'):format(index, name))
			end
		end
	end
end

local function configCheckTypes()
	local faultTypes = {}
	for _, fault in ipairs(Config.Faults) do
		if fault.types then
			for _, typeName in ipairs(fault.types) do
				faultTypes[typeName] = true
			end
		end
	end

	local tierTypes = {}
	for _, tier in ipairs(Config.Tiers) do
		if type(tier.types) == 'table' then
			for _, typeName in ipairs(tier.types) do
				tierTypes[typeName] = true
			end
		end
	end

	local locationTypes = {}
	for _, location in ipairs(Config.Locations) do
		if location.type then
			locationTypes[location.type] = true
		end
	end

	for index, location in ipairs(Config.Locations) do
		local name = location.label or ('#' .. index)

		if not faultTypes[location.type] then
			lib.print.warn(('location "%s" has type "%s", but no fault uses that type'):format(name, tostring(location.type)))
		end

		if not tierTypes[location.type] then
			lib.print.warn(('location "%s" has type "%s", but no tier includes that type'):format(name, tostring(location.type)))
		end
	end

	for _, tier in ipairs(Config.Tiers) do
		if type(tier.types) == 'table' then
			for _, typeName in ipairs(tier.types) do
				if not locationTypes[typeName] then
					lib.print.warn(('tier "%s" has type "%s", but no location uses that type'):format(tostring(tier.id), typeName))
				end
			end
		end
	end
end

local requiredFaultFields = {
	types = 'table',
	symptom = 'string',
	readings = 'table',
	repair = 'string',
	decoys = 'table',
}

local function configCheckFaults()
	local repairs = {}
	for index, fault in ipairs(Config.Faults) do
		local complete = true
		local name = fault.id or index

		for field, expected in pairs(requiredFaultFields) do
			if fault[field] == nil then
				lib.print.error(('fault %s (%s) is missing "%s"'):format(index, tostring(fault.id), field))
				complete = false
			elseif not matchTypes(fault[field], expected) then
				lib.print.error(('field %s in fault %s (%s) should be type %s but is type "%s"'):format(field, index, tostring(fault.id), expected, type(fault[field])))
				complete = false
			end
		end

		if type(fault.repair) == 'string' then
			repairs[fault.repair] = true
		end

		if complete then
			if Utils.contains(fault.decoys, fault.repair) then
				lib.print.warn(('fault "%s" has its own repair "%s" in its decoys'):format(name, fault.repair))
			end

			for _, test in ipairs(Config.Tests) do
				if Utils.overlaps(test.types, fault.types) and not fault.readings[test.id] then
					lib.print.error(('fault "%s" has no reading for test "%s"'):format(name, test.id))
				end
			end
		end
	end

	for index, fault in ipairs(Config.Faults) do
		local name = fault.id or index

		if type(fault.decoys) == 'table' then
			for _, decoy in ipairs(fault.decoys) do
				if not repairs[decoy] then
					lib.print.error(('fault "%s" has decoy "%s", but no fault uses it as its repair'):format(name, decoy))
				end
			end
		end
	end
end

local function validateConfig()
	configCheckTiers()
	configCheckTypes()
	configCheckFaults()
	configCheckLocations()
	configCheckGeneralSettings()
end

validateConfig()

if Config.Debug then
	local tierAtLevel = {}
	for _, tier in ipairs(Config.Tiers) do
		tierAtLevel[tier.level] = tier.id
	end

	print('[mrpat_om] Level curve:')

	for _, level in ipairs(Config.Levels) do
		print(('level %-10s %-10s %-10s XP'):format(level.level, tierAtLevel[level.level] or '', level.xp))
	end
end

-- End Job (also remember that this is also called when a player disconnects)
local function endJob(src, notifyClient, outcome)
	local contract = activeContracts[src]
	if not contract then
		return
	end

	if DoesEntityExist(contract.vessel) then
		exports.qbx_core:DeleteVehicle(contract.vessel)
	end

	TriggerEvent('mrpat_offshore_maintenance:jobFinished', {
		source = src,
		citizenid = contract.citizenid,
		tier = contract.tier,
		outcome = outcome or 'unknown',
		paidOut = contract.paidOut,
		xpGained = contract.xpGained,
		depositRefunded = contract.depositRefunded,
		totalXp = contract.totalXp,
		levelUp = contract.levelUp,
		repaired = contract.state == 'repaired',
	})

	activeContracts[src] = nil

	if notifyClient then
		TriggerClientEvent('mrpat_om:cleanup', src)
	end
end

local function setPlayerXp(src, xp)
	Config.Experience.set(src, xp)

	local contract = getPlayerContract(src)
	if contract then
		contract.totalXp = xp
	end
end

local function finishJob(src, contract, refundDeposit, outcome)
	local playerXp = Config.Experience.get(src)
	local level = Utils.getLevel(playerXp)
	local totalXp = playerXp + contract.xp
	local levelUp
	local payment

	if refundDeposit and contract.deposit > 0 then
		payment = contract.deposit + contract.pay
	else
		payment = contract.pay
	end

	exports.qbx_core:AddMoney(src, 'bank', payment, locale('offshore_maintenance_pay'))

	local newLevel = Utils.getLevel(totalXp)
	if newLevel > level then
		levelUp = newLevel
	end

	setPlayerXp(src, totalXp)

	contract.levelUp = levelUp

	contract.paidOut = contract.pay
	contract.xpGained = contract.xp
	contract.depositRefunded = refundDeposit

	previousJobs[contract.citizenid] = { location = contract.location, fault = contract.fault }

	if refundDeposit then
		log(src, contract.citizenid, outcome, ('returned the vessel and got deposit (%s), pay (%s) and XP (%s), totalxp is now %s'):format(contract.deposit, contract.pay, contract.xp, totalXp))
	else
		log(src, contract.citizenid, outcome, ('didn\'t return vessel so lost deposit (%s). Received pay (%s) and XP (%s), totalxp is now %s'):format(contract.deposit, contract.pay, contract.xp, totalXp))
	end

	endJob(src, true, outcome)

	return levelUp
end

local function handleLostVessel(src, contract)
	if contract.state == 'repaired' then
		local levelUp = finishJob(src, contract, false, 'vessel_lost')
		return true, 'job_done_vessel_lost', levelUp
	else
		endJob(src, true, 'vessel_lost')
		log(src, contract.citizenid, 'vessel_lost', 'lost or destroyed the vessel')
		return false, 'vessel_lost'
	end
end

local function validateContract(src, citizenid, tierId, moneyType)
	if activeContracts[src] or pendingContracts[src] then
		return nil, 'contract_already_active'
	end

	if not playerIsNear(src, Config.NPC.coords.xyz, Config.NPC.serverDistance) then
		return nil, 'too_far_from_foreman'
	end

	if not Utils.contains(allowedPayments,moneyType) then
		log(src, citizenid, 'invalid_payment', ('sent invalid payment type: %s'):format(tostring(moneyType)), 'suspicious')
		return nil, 'invalid_paymenttype'
	end

	local tier = Utils.getTier(tierId)
	if not tier then
		log(src, citizenid, 'invalid_tier', ('sent invalid tier: %s'):format(tostring(tierId)), 'suspicious')
		return nil, 'invalid_tier'
	end

	if Utils.getLevel(Config.Experience.get(src)) < tier.level then
		log(src, citizenid, 'tier_locked', ('tried to start locked tier %s'):format(tier.id), 'suspicious')
		return nil, 'tier_locked'
	end

	if Config.Gear and (tier.gear and not Config.Gear.hasGear(src)) then
		return nil, 'no_diving_gear'
	end

	return tier
end

local function pickLocation(tier, previous)
	local locationCandidates = {}
	for index, location in ipairs(Config.Locations) do
		if Utils.contains(tier.types, location.type) and index ~= previous.location then
			locationCandidates[#locationCandidates + 1] = index
		end
	end

	if #locationCandidates == 0 and previous.location and Utils.contains(tier.types, Config.Locations[previous.location].type) then
		locationCandidates[1] = previous.location
	end

	if #locationCandidates == 0 then
		return nil, 'no_location_found'
	end

	local locationIndex = locationCandidates[math.random(#locationCandidates)]
	local location = Config.Locations[locationIndex]
	return locationIndex, location
end

local function pickFault(location, previous)
	local faultCandidates = {}
	for index, fault in ipairs(Config.Faults) do
		if fault.types then
			if Utils.contains(fault.types, location.type) and index ~= previous.fault then
				faultCandidates[#faultCandidates + 1] = index
			end
		end
	end

	if #faultCandidates == 0 and previous.fault and Utils.contains(Config.Faults[previous.fault].types or {}, location.type) then
		faultCandidates[1] = previous.fault
	end

	if #faultCandidates == 0 then
		return nil, 'no_issues'
	end

	local faultIndex = faultCandidates[math.random(#faultCandidates)]
	return faultIndex
end

local function pickPropModel(location)
	if not location.model or #location.model == 0 then
		return nil, 'missing_model'
	end

	if type(location.model) == 'string' then
		return location.model
	end

	return location.model[math.random(#location.model)]
end

lib.callback.register('mrpat_om:getProfile', function(src)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then
		return false, 'no_character_loaded', 0
	end

	local playerXp = Config.Experience.get(src)
	local level = Utils.getLevel(playerXp)

	local nextLevel = Config.Levels[level + 1]

	local jobStats

	if Config.Stats then
		local stats = Config.Stats.get(src)

		jobStats = {
			repairs = stats.repairsReturned + stats.repairsVesselLost + stats.abandonedRepaired,
			vesselsLost = stats.repairsVesselLost + stats.vesselsLost,
			abandoned = stats.abandonedRepaired + stats.abandonedUnrepaired,
		}
	end

	return playerXp, level, nextLevel and nextLevel.xp, jobStats
end)

lib.callback.register('mrpat_om:getContract', function(src, tierId, moneyType)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then
		return false, 'no_character_loaded'
	end

	local citizenid = player.PlayerData.citizenid

	local tier, tierErr = validateContract(src, citizenid, tierId, moneyType)
	if not tier then
		return false, tierErr
	end

	local previous = previousJobs[citizenid] or {}

	local locationIndex, location = pickLocation(tier, previous)
	if not locationIndex then
		return false, location
	end

	local faultIndex, faultErr = pickFault(location, previous)
	if not faultIndex then
		return false, faultErr
	end

	local propModel, modelErr = pickPropModel(location)
	if not propModel then
		return false, modelErr
	end

	pendingContracts[src] = true

	local deposit = Utils.getDeposit(tier)

	if deposit > 0 then
		local ok, paid = pcall(function()
			return exports.qbx_core:RemoveMoney(src, moneyType, deposit, locale('offshore_maintenance_deposit'))
		end)

		if not ok then
			pendingContracts[src] = nil
			log(src, citizenid, 'payment_failed', ('RemoveMoney crashed: %s'):format(paid))
			print(('[mrpat_om] RemoveMoney failed: %s'):format(paid))
			return false, 'contract_err'
		end

		if not paid then
			pendingContracts[src] = nil
			return false, 'not_enough_money'
		end
	end

	local ok, netId, vessel = pcall(qbx.spawnVehicle, {
		model = joaat(tier.vehicle),
		spawnSource = Config.Depot.coords,
	})

	pendingContracts[src] = nil

	if not ok then
		if deposit > 0 then
			local refundOk, refundResult = pcall(function()
				return exports.qbx_core:AddMoney(src, moneyType, deposit, locale('offshore_maintenance_deposit'))
			end)

			if not refundOk then
				log(src, citizenid, 'refund_failed', ('Refund of %s to player failed, reason: %s'):format(deposit, refundResult))
				print(('[mrpat_om] Refund of %s to player %s (%s) failed, reason: %s'):format(deposit, GetPlayerName(src), citizenid, refundResult))
			elseif not refundResult then
				log(src, citizenid, 'refund_refused', ('Refund of %s to player refused'):format(deposit))
				print(('[mrpat_om] Refund of %s to player %s (%s) refused'):format(deposit, GetPlayerName(src), citizenid))
			end
		end

		log(src, citizenid, 'vessel_spawn_failed', ('wasn\'t able to get a vessel, reason: %s'):format(netId))
		print(('[mrpat_om] vessel spawn failed: %s'):format(netId))
		return false, 'vessel_spawn_failed'
	end

	local playerStillOnline = exports.qbx_core:GetPlayer(src)
	if not playerStillOnline then
		exports.qbx_core:DeleteVehicle(vessel)

		if DoesEntityExist(vessel) then
			log(src, citizenid, 'vessel_delete_failed', 'vessel couldn\'t be deleted')
		end

		log(src, citizenid, 'player_left_during_spawn', ('went offline while the vessel was spawning. Lost deposit: %s'):format(deposit))
		return false, 'no_character_loaded'
	end

	-- First keys and Fuel, then warp. Otherwise ox_fuel overwrites the fuel level
	exports.qbx_vehiclekeys:GiveKeys(src, vessel)
	SetVehicleDoorsLocked(vessel, 1)
	if Config.SetFuel then Config.SetFuel(vessel) end

	TaskWarpPedIntoVehicle(GetPlayerPed(src), vessel, -1)

	local playerXp = Config.Experience.get(src)

	activeContracts[src] = {
		state = 'assigned',			-- assigned -> inspected -> repaired
		location = locationIndex,
		fault = faultIndex,
		repairOptions = nil,
		lastRepairAt = nil,
		vessel = vessel,
		citizenid = citizenid,
		tier = tier.id,
		deposit = deposit,
		pay = Utils.getPay(tier, Utils.getLevel(playerXp)),
		xp = tier.xp,
		testsDone = {},
		invalidTestLogged = false,
		levelUp = nil,
		paidOut = 0,
		xpGained = 0,
		totalXp = playerXp,
		depositRefunded = false,
	}

	local contract = activeContracts[src]

	TriggerEvent('mrpat_offshore_maintenance:jobStarted', {
		source = src,
		vesselNetId = netId,
		citizenid = contract.citizenid,
		tier = contract.tier,
		deposit = contract.deposit,
		pay = contract.pay,
		xp = contract.xp,
	})

	log(src, citizenid, 'job_started', ('took a tier level %s job at %s, paid %s deposit by %s'):format(tier.level, location.label, deposit, moneyType))
	return true, location.coords, propModel, location.placement, netId, location.type
end)

lib.callback.register('mrpat_om:inspect', function(src)
	local contract, err = getWorkContract(src, 'assigned')
	if not contract then
		return false, err
	end

	local fault = Config.Faults[contract.fault]

	local repairs = { fault.repair }
	for _, decoyId in ipairs(fault.decoys) do
		repairs[#repairs + 1] = decoyId
	end
	Utils.shuffle(repairs)

	contract.state = 'inspected'
	contract.repairOptions = repairs
	contract.lastRepairAt = os.time()

	log(src, contract.citizenid, 'inspection_done', ('finished an inspection at %s'):format(jobSite(contract).label))
	return true, fault.symptom, repairs
end)

lib.callback.register('mrpat_om:runTest', function(src, testId)
	local contract, err = getWorkContract(src, 'inspected')
	if not contract then
		return false, err
	end

	local reading = Config.Faults[contract.fault].readings[testId]
	if not reading then
		if not contract.invalidTestLogged then
			log(src, contract.citizenid, 'invalid_test', ('sent invalid test: %s'):format(tostring(testId)), 'suspicious')
			contract.invalidTestLogged = true
		end
		return false, 'invalid_test'
	end

	if not contract.testsDone[testId] then
		log(src, contract.citizenid, 'test_done', ('finished a test at %s, reading was: %s'):format(jobSite(contract).label, reading))
		contract.testsDone[testId] = true
	end
	return true, reading
end)

lib.callback.register('mrpat_om:repair', function(src, repairId)
	local contract, err = getWorkContract(src, 'inspected')
	if not contract then
		return false, err
	end
	if not Utils.contains(contract.repairOptions, repairId) then
		log(src, contract.citizenid, 'invalid_repair', ('sent invalid repair: %s, while offers were: %s'):format(tostring(repairId), table.concat(contract.repairOptions, ', ')), 'suspicious')
		return false, 'invalid_repair'
	end

	local secondsSinceLast = os.time() - contract.lastRepairAt

	if secondsSinceLast < Config.RepairDuration - 1 then
		log(src, contract.citizenid, 'repair_too_fast', ('tried to repair at alarming speed(%s)'):format(secondsSinceLast), 'suspicious')
		return false, 'repair_too_fast'
	end

	contract.lastRepairAt = os.time()

	if Config.Faults[contract.fault].repair ~= repairId then
		return false, 'repair_wrong'
	end

	contract.state = 'repaired'
	log(src, contract.citizenid, 'repair_done', ('finished a repair at %s'):format(jobSite(contract).label))
	return true, 'repair_success'
end)

lib.callback.register('mrpat_om:returnVessel', function(src)
	local contract, err = getPlayerContract(src)
	if not contract then
		return false, err
	end

	if not playerIsNear(src, Config.NPC.coords.xyz, Config.NPC.serverDistance) then
		return false, 'player_too_far_from_depot'
	end

	if vesselIsLost(contract) then
		return handleLostVessel(src, contract)
	end

	if #(GetEntityCoords(contract.vessel) - Config.Depot.coords.xyz) > Config.Depot.returnDistance then
		return false, 'vessel_too_far_from_depot'
	end

	if contract.state == 'repaired' then
		local levelUp = finishJob(src, contract, true, 'returned')
		return true, 'job_paid', levelUp
	end

	if contract.deposit > 0 then
		exports.qbx_core:AddMoney(src, 'bank', contract.deposit, locale('offshore_maintenance_deposit'))
		contract.depositRefunded = true
	end

	endJob(src, true, 'returned')
	log(src, contract.citizenid, 'returned', ('returned the vessel without finishing the job, only got deposit(%s)'):format(contract.deposit))
	return true, 'vessel_returned'
end)

lib.callback.register('mrpat_om:abandonJob', function(src)
	local contract, err = getPlayerContract(src)
	if not contract then
		return false, err
	end

	if not playerIsNear(src, Config.NPC.coords.xyz, Config.NPC.serverDistance) then
		return false, 'player_too_far_from_depot'
	end

	if vesselIsLost(contract) then
		return handleLostVessel(src, contract)
	end

	if contract.state == 'repaired' then
		local levelUp = finishJob(src, contract, false, 'abandoned')
		return true, 'job_done_vessel_missing', levelUp
	end

	endJob(src, true, 'abandoned')
	log(src, contract.citizenid, 'abandoned', 'abandoned the contract without returning the vessel')
	return true, 'deposit_lost'
end)

-- Client disconnects
AddEventHandler('playerDropped', function()
	local contract = activeContracts[source]
	if contract then
		log(source, contract.citizenid, 'disconnected', 'got disconnected during the contract')
	end
	pendingContracts[source] = nil

	endJob(source, false, 'disconnected')
end)

-- Client logs out (for example when switching characters)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
	local contract = activeContracts[source]
	if contract then
		log(source, contract.citizenid, 'logout', 'logged out during the contract')
	end
	pendingContracts[source] = nil
	
	endJob(source, true, 'logout')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() ~= resourceName then
		return
	end

	for src, contract in pairs(activeContracts) do
		if contract.deposit > 0 then
			contract.depositRefunded = true
			exports.qbx_core:AddMoney(src, 'bank', contract.deposit, locale('offshore_maintenance_deposit'))
			log(src, contract.citizenid, 'resource_stopped', ('got the deposit (%s) back because the resource stopped'):format(contract.deposit))
		end

		endJob(src, false, 'resource_stopped')
	end
end)

-- admin commands
-- Send a message to the admin: a notification in game, or print in the console
local function adminReply(source, message, msgType)
	if source == 0 then
		print(('[mrpat_om] %s'):format(message))
	else
		TriggerClientEvent('ox_lib:notify', source, { description = message, type = msgType or 'inform' })
	end
end

-- Name and citizenid of a player, or of the console
local function identify(src)
	if src == 0 then
		return 'console', 'console'
	end

	local player = exports.qbx_core:GetPlayer(src)
	if not player then
		return nil
	end

	return GetPlayerName(src), player.PlayerData.citizenid
end

local adminActions = {
	addxp = function(source, target, value)
		local targetName, targetCid = identify(target)
		if not targetName then
			adminReply(source, 'That player has no character loaded', 'error')
			return
		end

		if type(value) ~= "number" or value <= 0 then
			adminReply(source, 'Amount must be above 0', 'error')
			return
		end

		local newXp = math.max(0, Config.Experience.get(target) + value)

		setPlayerXp(target, newXp)

		adminReply(source, ('Gave %s XP to %s (%s), total XP now %s'):format(value, targetName, targetCid, newXp), 'success')

		local _, adminCid = identify(source)
		log(source, adminCid, 'admin_offshore_addxp', ('gave %s XP to %s (%s), total XP now %s'):format(value, targetName, targetCid, newXp))
	end,
	setxp = function(source, target, value)
		local targetName, targetCid = identify(target)
		if not targetName then
			adminReply(source, 'That player has no character loaded', 'error')
			return
		end

		if type(value) ~= "number" or value < 0 then
			adminReply(source, 'Amount must be a 0 or higher', 'error')
			return
		end

		setPlayerXp(target, value)

		adminReply(source, ('Set XP value for %s (%s) to %s XP'):format(targetName, targetCid, value), 'success')

		local _, adminCid = identify(source)
		log(source, adminCid, 'admin_offshore_setxp', ('set XP value for %s (%s) to %s XP'):format(targetName, targetCid, value))
	end,
	removexp = function(source, target, value)
		local targetName, targetCid = identify(target)
		if not targetName then
			adminReply(source, 'That player has no character loaded', 'error')
			return
		end

		if type(value) ~= "number" or value <= 0 then
			adminReply(source, 'Amount must be above 0', 'error')
			return
		end

		local newXp = math.max(0, Config.Experience.get(target) - value)

		setPlayerXp(target, newXp)

		adminReply(source, ('Removed %s XP from %s (%s), total XP now %s'):format(value, targetName, targetCid, newXp), 'success')

		local _, adminCid = identify(source)
		log(source, adminCid, 'admin_offshore_removexp', ('removed %s XP from %s (%s), total XP now %s'):format(value, targetName, targetCid, newXp))
	end,
	endjob = function(source, target, value)
		local targetName, targetCid = identify(target)
		if not targetName then
			adminReply(source, 'That player has no character loaded', 'error')
			return
		end

		local contract, err = getPlayerContract(target)
		if not contract then
			adminReply(source, err, 'error')
			return
		end

		if type(value) ~= "number" or not Utils.contains({0,1},value) then
			adminReply(source, 'value must be 1 (to refund deposit) or 0 (to keep deposit)', 'error')
			return
		end

		local payment
		if value == 1 then
			payment = contract.pay + contract.deposit
		else
			payment = contract.pay
		end

		if contract.state == 'repaired' and value == 1 then
			finishJob(target, contract, true, 'admin')
			adminReply(target, locale('admin_ended_paid_deposit'):format(payment), 'success')
			adminReply(source, ('ended offshore job of %s (%s), returned pay and deposit (%s)'):format(targetName, targetCid, payment), 'success')

			local _, adminCid = identify(source)
			log(source, adminCid, 'admin_offshore_endjob', ('ended offshore job of %s (%s), returned pay and deposit (%s)'):format(targetName, targetCid, payment))
			return
		elseif contract.state == 'repaired' and value ~= 1 then
			finishJob(target, contract, false, 'admin')
			adminReply(target, locale('admin_ended_paid'):format(payment), 'success')
			adminReply(source, ('ended offshore job of %s (%s), with pay (%s) but without deposit (%s)'):format(targetName, targetCid, payment, contract.deposit), 'success')

			local _, adminCid = identify(source)
			log(source, adminCid, 'admin_offshore_endjob', ('ended offshore job of %s (%s), with pay (%s) but without deposit (%s)'):format(targetName, targetCid, payment, contract.deposit))
			return
		end

		if value == 1 and contract.deposit > 0 then
			exports.qbx_core:AddMoney(target, 'bank', contract.deposit, locale('offshore_maintenance_deposit'))
			contract.depositRefunded = true
			endJob(target, true, 'admin')
			adminReply(target, locale('admin_ended_deposit'):format(contract.deposit), 'success')
			adminReply(source, ('ended offshore job of %s (%s), without pay but returned deposit (%s)'):format(targetName, targetCid, contract.deposit), 'success')

			local _, adminCid = identify(source)
			log(source, adminCid, 'admin_offshore_endjob', ('ended offshore job of %s (%s), without pay but returned deposit (%s)'):format(targetName, targetCid, contract.deposit))
			return
		end

		endJob(target, true, 'admin')
		adminReply(target, locale('admin_ended'), 'success')
		adminReply(source, ('ended offshore job of %s (%s), without pay and deposit'):format(targetName, targetCid), 'success')

		local _, adminCid = identify(source)
		log(source, adminCid, 'admin_offshore_endjob', ('ended offshore job of %s (%s), without pay and deposit'):format(targetName, targetCid))
	end,
}

lib.addCommand('offshore', {
	help = 'Offshore Maintenance admin tools',
	params = {
		{
			name = 'action',
			type = 'string',
			help = 'addxp, setxp, removexp or endjob',
		},
		{
			name = 'target',
			type = 'playerId',
			help = 'Target player\'s server id',
		},
		{
			name = 'value',
			type = 'number',
			help = 'XP amount, or 1/0 for endjob (refund deposit)', optional = true,
		},
	},
	restricted = Config.AdminPermissions
}, function(source, args)
	local action = adminActions[args.action]
	if not action then
		adminReply(source, 'Unknown action. Use addxp, setxp, removexp or endjob', 'error')
		return
	end

	action(source, args.target, args.value)
end
)