lib.locale()

local npc
local foremanBlip

local minigamePromise
local jobVessel
local jobTier
local siteType
local siteProp
local sitePoint
local siteMarker
local siteBlip
local siteZone
local depotPoint
local depotMarker
local depotBlip
local sonarEnabled = true
local sonarToken
local urgentToken

local inspectionSymptom
local jobRepaired = false
local promptInstruction
local interactKey
local sonarKey
local completedReadings = {}
local possibleRepairs = {}

local repairMenuId = 'mrpat_om_repair_menu'
local diagnoseMenuId = 'mrpat_om_diagnose_menu'
local paymentMenuId = 'mrpat_om_payment_menu'
local tierMenuId = 'mrpat_om_tier_menu'
local statsMenuId = 'mrpat_om_stats_menu'

local function notify(description, notifyType)
	lib.notify({
		title = locale('notify_title'),
		description = description,
		type = notifyType or 'inform',
	})
end

local function formatTime(seconds)
	return ('%d:%02d'):format(math.floor(seconds / 60), math.floor(seconds % 60))
end

local function zoneCenter(coords, radius)
	local angle = math.rad(math.random(0, 359))

	local distance = math.random() * radius * 0.7

	local offsetX = math.cos(angle) * distance
	local offsetY = math.sin(angle) * distance

	return vec3(coords.x + offsetX, coords.y + offsetY, coords.z)
end

local function workProgress(duration, label, useCircle)
	local progress = useCircle and lib.progressCircle or lib.progressBar
	return progress({
		duration = duration * 1000,
		label = label,
		canCancel = false,
		disable = { move = true, car = true },
		allowSwimming = true,
	})
end

local function createBlip(coords, settings, route)
	local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite(blip, settings.sprite)
	SetBlipColour(blip, settings.color)
	if route then
		SetBlipRoute(blip, true)
	end
	return blip
end

local function createMarker(coords, settings)
	return lib.marker.new({
		type = settings.type,
		coords = vec3(coords.x, coords.y, coords.z + settings.offsetZ),
		color = settings.color,
	})
end

local function startUrgentTimer(secondsLeft)
	local myToken = {}
	urgentToken = myToken
	local endsAt = GetGameTimer() + secondsLeft * 1000

	-- only valid moments that fit inside this contract's limit, largest first
	local warnings = {}
	for _, seconds in ipairs(Config.UrgentContract.warnings or {}) do
		if type(seconds) == 'number' and seconds > 0 and seconds < secondsLeft then
			warnings[#warnings + 1] = seconds
		end
	end
	table.sort(warnings, function(a, b) return a > b end)

	CreateThread(function()
		for _, seconds in ipairs(warnings) do
			Wait(math.max(0, endsAt - seconds * 1000 - GetGameTimer()))
			if urgentToken ~= myToken or jobRepaired then return end
			notify(locale('urgent_warning', formatTime(seconds)), 'warning')
		end

		Wait(math.max(0, endsAt - GetGameTimer()))
		if urgentToken ~= myToken or jobRepaired then return end
		urgentToken = nil
		notify(locale('urgent_missed'), 'error')
	end)
end

local function removeBlip(blip)
	if blip then
		RemoveBlip(blip)
	end
	return nil
end

local function removeSiteProp()
	if DoesEntityExist(siteProp) then
		exports.ox_target:removeLocalEntity(siteProp)
		DeleteEntity(siteProp)
	end
	siteProp = nil
end

local function removeNPC()
	if DoesEntityExist(npc) then
		DeleteEntity(npc)
	end
	npc = nil
end

local function removeSiteBlips()
	siteBlip = removeBlip(siteBlip)
	siteZone = removeBlip(siteZone)
end

local function hideInstruction()
	if not promptInstruction then
		return
	end

	lib.hideTextUI()
	interactKey:disable(true)
	promptInstruction = nil
end

local function cleanupJob()
	removeSiteBlips()
	depotBlip = removeBlip(depotBlip)
	siteMarker = nil
	depotMarker = nil
	removeSiteProp()
	hideInstruction()

	if sitePoint then
		sitePoint:remove()
		sitePoint = nil
	end
	if depotPoint then
		depotPoint:remove()
		depotPoint = nil
	end

	jobVessel = nil
	siteType = nil
	jobTier = nil
	inspectionSymptom = nil
	jobRepaired = false
	completedReadings = {}
	possibleRepairs = {}
	if Config.ClientGear then Config.ClientGear.unequip(PlayerPedId()) end
	sonarToken = nil
	sonarKey:disable(true)
	sonarEnabled = true
	urgentToken = nil
end

local function buildDiagnoseMenu()
	local menuOptions = {
		{
			title = locale(inspectionSymptom or 'not_inspected'),
			readOnly = true,
		},
	}

	for _, test in ipairs(Config.Tests) do
		if Utils.contains(test.types, siteType) then
			menuOptions[#menuOptions + 1] = {
				title = locale(test.id),
				description = locale(completedReadings[test.id] or 'no_readings'),
				onSelect = function()
					if not inspectionSymptom then
						notify(locale('not_inspected'), 'error')
						return
					end

					if not workProgress(test.duration, locale('diagnosing') .. locale(test.id), true) then
						return
					end

					local ok, result = lib.callback.await('mrpat_om:runTest', false, test.id)
					if not ok then
						notify(locale(result or 'contract_err'), 'error')
						return
					end

					completedReadings[test.id] = result
					notify(locale(result), 'inform')
					buildDiagnoseMenu()
					lib.showContext(diagnoseMenuId)
				end,
			}
		end
	end

	if #possibleRepairs > 0 then
		menuOptions[#menuOptions + 1] = {
			title = locale('repair_title'),
			menu = repairMenuId,
		}
	end

	lib.registerContext({ id = diagnoseMenuId, title = locale('diagnose_title'), options = menuOptions })
end

local function buildRepairMenu()
	local menuOptions = {}

	for _, repairId in ipairs(possibleRepairs) do
		menuOptions[#menuOptions + 1] = {
			title = locale(repairId),
			onSelect = function()
				if jobRepaired then
					notify(locale('already_repaired'), 'error')
					return
				end

				if not workProgress(Config.RepairDuration, locale('repairing')) then
					return
				end

				if jobTier == nil then
					notify(locale('contract_missing'), 'error')
					return
				end
				local tierDifficulties = Utils.getDifficulties(jobTier)
				local difficulty = tierDifficulties[math.random(#tierDifficulties)]

				if not Config.Minigame.repair(repairId, difficulty) then
					notify(locale('skillcheck_failed'), 'error')
					lib.showContext(repairMenuId)
					return
				end

				local ok, result, inTime = lib.callback.await('mrpat_om:repair', false, repairId)
				if not ok then
					notify(locale(result or 'repair_error'), 'error')
					if result == 'repair_wrong' then
						buildRepairMenu()
						lib.showContext(repairMenuId)
					end
					return
				end

				if inTime then
					notify(locale('urgent_in_time'), 'success')
					urgentToken = nil
				elseif urgentToken then
					notify(locale('urgent_missed'), 'error')
					urgentToken = nil
				end

				jobRepaired = true
				removeSiteBlips()
				notify(locale(result), 'success')
			end,
		}
	end

	menuOptions[#menuOptions + 1] = {
		title = locale('back'),
		menu = diagnoseMenuId,
	}

	lib.registerContext({ id = repairMenuId, title = locale('repair_title'), options = menuOptions })
end

local function startDiagnose()
	buildDiagnoseMenu()
	buildRepairMenu()
	lib.showContext(diagnoseMenuId)
end

local function inspect()
	if inspectionSymptom then
		notify(locale('already_inspected'), 'error')
		return
	end

	if not workProgress(Config.InspectDuration, locale('inspection_started')) then
		return
	end

	if not Config.Minigame.inspect() then
		notify(locale('skillcheck_failed'), 'error')
		return
	end

	local ok, result, repairs = lib.callback.await('mrpat_om:inspect', false)
	if not ok then
		notify(locale(result or 'inspection_err'), 'error')
		return
	end

	possibleRepairs = repairs
	inspectionSymptom = result
	notify(locale('issue_found') .. ': ' .. locale(inspectionSymptom))
end

local function spawnSiteProp(coords, model, placement, tier)
	local hash = joaat(model)
	lib.requestModel(hash)

	local spawnZ = coords.z
	if placement == 'water' then
		local foundWater, height = GetWaterHeight(coords.x, coords.y, coords.z)
		if foundWater then
			spawnZ = height
		end
	end

	siteProp = CreateObject(hash, coords.x, coords.y, spawnZ, false, false, false)
	if placement == 'ground' then
		PlaceObjectOnGroundProperly(siteProp)
	end
	FreezeEntityPosition(siteProp, true)
	SetModelAsNoLongerNeeded(hash)

	if tier.interactionType ~= 'prompt' then
		exports.ox_target:addLocalEntity(siteProp, {
			{
				name = 'mrpat_om_inspect',
				icon = 'fa-solid fa-magnifying-glass',
				label = locale('inspect_prompt'),
				distance = Config.JobSite.targetDistance,
				onSelect = inspect,
			},
			{
				name = 'mrpat_om_diagnose',
				icon = 'fa-solid fa-gauge',
				label = locale('diagnose_title'),
				distance = Config.JobSite.targetDistance,
				onSelect = startDiagnose,
			},
		})
	end

	siteMarker = createMarker(vec3(coords.x, coords.y, spawnZ), Config.JobSite.marker)
end

local function findVessel(netId)
	local found, vessel = pcall(lib.waitFor, function()
		if NetworkDoesNetworkIdExist(netId) then
			local entity = NetToVeh(netId)
			if entity ~= 0 then
				return entity
			end
		end
	end, nil, 5000)

	return found and vessel or nil
end

local function toggleAnchor()
	if not jobVessel or GetVehiclePedIsIn(PlayerPedId(), false) ~= jobVessel then
		return
	end

	if GetEntitySpeed(jobVessel) > Config.Anchor.maxSpeed then
		notify(locale('vessel_moving'))
		return
	end

	if IsVesselAnchored(jobVessel) then
		SetVesselAnchor(jobVessel, false)
		notify(locale('anchor_raised'))
	else
		SetVesselAnchor(jobVessel, true)
		SetVesselFrozenWhenAnchored(jobVessel, true)
		notify(locale('anchor_dropped'))
	end
end

-- keybind for anchor
lib.addKeybind({
	name = 'mrpat_om_anchor',
	description = locale('vessel_anchor'),
	defaultKey = Config.Anchor.key,
	onPressed = toggleAnchor,
})

-- keybind for prompt
interactKey = lib.addKeybind({
	name = 'mrpat_om_prompt',
	description = locale('press_to_interact'),
	defaultKey = Config.InteractKey,
	onPressed = function()
		if not inspectionSymptom then
			inspect()
		else
			startDiagnose()
		end
	end,
	disabled = true,
})

-- keybind for sonar
sonarKey = lib.addKeybind({
	name = 'mrpat_om_sonar',
	description = locale('toggle_sonar'),
	defaultKey = Config.Sonar.key,
	onPressed = function()
		sonarEnabled = not sonarEnabled
		notify(locale(sonarEnabled and 'sonar_on' or 'sonar_off'))
	end,
	disabled = true,
})

local function startJob(tierId, moneyType)
	local ok, result, model, placement, netId, locType, urgent, secLeft = lib.callback.await('mrpat_om:getContract', false, tierId, moneyType)
	if not ok then
		notify(locale(result or 'contract_err'), 'error')
		return
	end

	cleanupJob()

	siteType = locType
	jobTier = Utils.getTier(tierId)
	if jobTier.gear then
		if Config.ClientGear then Config.ClientGear.equip(PlayerPedId()) end
	end

	local siteCoords = result
	jobVessel = findVessel(netId)
	if jobVessel then
		if Config.ClientSetFuel then Config.ClientSetFuel(jobVessel) end
	end

	notify(locale('contract_assigned'), 'success')

	if urgent then
		notify(locale('urgent_contract', formatTime(secLeft)), 'inform')
		startUrgentTimer(secLeft)
	end

	if jobTier.blip == 'area' and type(jobTier.radius) == 'number' and jobTier.radius > 0 then
		local center = zoneCenter(siteCoords, jobTier.radius)
		siteZone = AddBlipForRadius(center.x, center.y, center.z, jobTier.radius)
		SetBlipColour(siteZone, Config.JobSite.blip.zoneColor)
		SetBlipAlpha(siteZone, 128)
		if jobTier.sonar then
			local myToken = {}
			sonarToken = myToken
			sonarKey:disable(false)

			CreateThread(function()
				while sonarToken == myToken do
					local playerCoords = GetEntityCoords(PlayerPedId())
					-- one round of the sonar
					if not sonarEnabled or jobRepaired then
						Wait(250)
					elseif #(playerCoords - center) > jobTier.radius then
						Wait(250)
					else
						local distance = #(playerCoords - siteCoords)
						local interval
						for _, range in ipairs(Config.Sonar.ranges) do
							if distance >= range.distance then
								interval = range.interval
								break
							end
						end

						PlaySoundFrontend(-1, Config.Sonar.sound.soundName, Config.Sonar.sound.soundSetName, true)
						Wait(interval * 1000)
					end
				end
			end)
		end
	else
		siteBlip = createBlip(siteCoords, Config.JobSite.blip, true)
	end

	local distance
	if type(jobTier.drawDistance) == 'number' and jobTier.drawDistance > 0 then
		distance = jobTier.drawDistance
	else
		distance = Config.DrawDistance
	end

	sitePoint = lib.points.new({
		coords = siteCoords,
		distance = distance,
		onEnter = function()
			if not siteProp then
				spawnSiteProp(siteCoords, model, placement, jobTier)
			end
		end,
		onExit = function()
			removeSiteProp()
			hideInstruction()
		end,
		nearby = function(self)
			if siteMarker then
				siteMarker:draw()
			end

			if jobTier.interactionType ~= 'prompt' then
				return
			end

			if self.currentDistance > Config.InteractionDistance or jobRepaired then
				hideInstruction()
				return
			end

			local action
			if not inspectionSymptom then
				action = locale('inspect_prompt')
			else
				action = locale('diagnose_title')
			end

			local text = locale('interact'):format(interactKey:getCurrentKey(), action)

			if text == promptInstruction then
				return
			end

			if not promptInstruction then
				interactKey:disable(false)
			end

			lib.showTextUI(text)
			promptInstruction = text
		end,
	})

	local depotCoords = Config.Depot.coords.xyz
	depotBlip = createBlip(depotCoords, Config.Depot.blip)
	depotPoint = lib.points.new({
		coords = depotCoords,
		distance = Config.DrawDistance,
		onEnter = function()
			depotMarker = createMarker(depotCoords, Config.Depot.marker)
		end,
		nearby = function()
			if depotMarker then
				depotMarker:draw()
			end
		end,
	})
end

local function openPaymentMenu(tier)
	local deposit = Utils.getDeposit(tier)
	lib.registerContext({
		id = paymentMenuId,
		title = locale('payment_menu_title'),
		options = {
			{	title = locale('cash_deposit'):format(Config.Currency, deposit),
				onSelect = function()
					startJob(tier.id, 'cash')
				end
			},
			{	title = locale('bank_deposit'):format(Config.Currency, deposit),
				onSelect = function()
					startJob(tier.id, 'bank')
				end
			},
			{	title = locale('back'),
				menu = tierMenuId,
			},
		},
	})

	lib.showContext(paymentMenuId)
end

local function openStatsMenu(jobStats)
	local statOrder = { 'repairs', 'vesselsLost', 'abandoned' }

	local menuOptions = {}
	for _, stat in ipairs(statOrder) do
		menuOptions[#menuOptions + 1] = {
			title = locale('stat_' .. stat .. '_title'),
			description = locale('stat_total'):format(jobStats[stat]),
			readOnly = true,
		}
	end

	menuOptions[#menuOptions + 1] = {
		title = locale('back'),
		menu = tierMenuId,
	}

	lib.registerContext({ id = statsMenuId, title = locale('stats_menu_title'), options = menuOptions })
	lib.showContext(statsMenuId)
end

local function openTierMenu()
	local xp, level, nextThreshold, jobStats = lib.callback.await('mrpat_om:getProfile', false)
	if not xp then
		notify(locale(level), 'error')
		return
	end

	local currentThreshold = Config.Levels[level].xp
	local description
	local progress

	if not nextThreshold then
		description = locale('max_level')
		progress = 100
	else
		description = locale('xp_from_xp'):format(xp, nextThreshold)
		progress = lib.math.clamp((xp - currentThreshold) / (nextThreshold - currentThreshold) * 100, 0, 100)
	end

	local menuOptions = {
		{
			title = locale('current_level'):format(level),
			description = description,
			progress = progress,
			readOnly = true,
		},
	}

	if jobStats then
		menuOptions[#menuOptions + 1] = {
			title = locale('job_stats'),
			description = locale('job_stats_descr'),
			onSelect = function()
				openStatsMenu(jobStats)
			end,
		}
	end

	for _, tier in ipairs(Config.Tiers) do
		local locked
		local menuDescription

		if tier.level > level then
			locked = true
			menuDescription = locale('level_needed'):format(tier.level)
		else
			menuDescription = locale('pay_and_xp'):format(Config.Currency, Utils.getPay(tier, level), tier.xp)
		end

		menuOptions[#menuOptions + 1] = {
			title = locale(tier.label),
			description = menuDescription,
			disabled = locked,
			onSelect = function()
				if Utils.getDeposit(tier) > 0 then
					openPaymentMenu(tier)
				else
					startJob(tier.id, 'bank')
				end
			end,
		}
	end

	lib.registerContext({ id = tierMenuId, title = locale('tier_title'), options = menuOptions })
	lib.showContext(tierMenuId)
end

local function abandonJob()
	local answer = lib.alertDialog({
		header = locale('abandon_job'),
		content = locale('missing_vessel'),
		centered = true,
		cancel = true,
	})

	if answer ~= 'confirm' then
		return
	end

	local ok, result, levelUp = lib.callback.await('mrpat_om:abandonJob', false)

	notify(locale(result or 'return_vessel_went_wrong'), ok and 'success' or 'error')

	if levelUp then
		notify(locale('level_up'):format(levelUp), 'success')
	end
end

local function returnVessel()
	local ok, result, levelUp = lib.callback.await('mrpat_om:returnVessel', false)

	if not ok and result == 'vessel_too_far_from_depot' then
		abandonJob()
		return
	end

	notify(locale(result or 'return_vessel_went_wrong'), ok and 'success' or 'error')

	if levelUp then
		notify(locale('level_up'):format(levelUp), 'success')
	end
end

CreateThread(function()
	local foreman = Config.NPC
	local hash = joaat(foreman.model)
	lib.requestModel(hash)

	npc = CreatePed(4, hash, foreman.coords.x, foreman.coords.y, foreman.coords.z - 1.0, foreman.coords.w, false, false)
	SetModelAsNoLongerNeeded(hash)
	FreezeEntityPosition(npc, true)
	SetEntityInvincible(npc, true)
	SetBlockingOfNonTemporaryEvents(npc, true)

	exports.ox_target:addLocalEntity(npc, {
		{
			name = 'mrpat_om_start',
			icon = 'fa-solid fa-ship',
			label = locale('target_start_contract'),
			distance = foreman.targetDistance,
			onSelect = openTierMenu,
		},
		{
			name = 'mrpat_om_return',
			icon = 'fa-solid fa-key',
			label = locale('target_return_vessel'),
			distance = foreman.targetDistance,
			onSelect = returnVessel,
		},
	})

	foremanBlip = createBlip(foreman.coords, foreman.blip)
	SetBlipAsShortRange(foremanBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(locale('notify_title'))
	EndTextCommandSetBlipName(foremanBlip)
end)

RegisterNetEvent('mrpat_om:cleanup', function()
	cleanupJob()
end)

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() ~= resourceName then
		return
	end

	cleanupJob()
	removeNPC()
	foremanBlip = removeBlip(foremanBlip)
end)

local minigameLabels = {
	voltmeter = { 
		title = 'voltmeter_title',
		hint = 'voltmeter_hint',
		retry = 'minigame_retry',
	},
	bolts = { 
		title = 'bolts_title',
		watch = 'bolts_watch',
		go = 'bolts_go',
		hint = 'bolts_hint',
		retry = 'minigame_retry',
	},
	wires = { 
		title = 'wires_title',
		hint = 'wires_hint',
		retry = 'minigame_retry',
	},
	steady = { 
		title = 'steady_title',
		hint = 'steady_hint',
	},
	pumping = {
		title = 'pumping_title',
		hint = 'pumping_hint',
		jammed = 'pumping_jammed',
	},
	code = {
		title = 'code_title',
		hint = 'code_hint',
		attempts = 'code_attempts',
	}
}

local cursorGames = { bolts = true, wires = true }

local function startMinigame(name, settings, title)
	settings = settings or {}
	local myPromise = promise.new()
	minigamePromise = myPromise
	SetNuiFocus(true, cursorGames[name] == true)

	local labels = {}
	for shortName, localeKey in pairs(minigameLabels[name] or {}) do
		labels[shortName] = locale(localeKey)
	end
	labels.title = title or labels.title

	SendNUIMessage ({ action = 'open', game = name, settings = settings, labels = labels })
	local timeout = (settings.timeout or 60) * 1000
	SetTimeout(timeout, function() 
		if minigamePromise == myPromise then
			minigamePromise:resolve(false)
			minigamePromise = nil
			SetNuiFocus(false, false)
			SendNUIMessage ({ action = 'close' })
		end
	end)
	return Citizen.Await(myPromise)
end

RegisterNUICallback('result', function(data, cb)
	SetNuiFocus(false, false)
	if minigamePromise then
		minigamePromise:resolve(data.success)
		minigamePromise = nil
	end
	cb('ok')
end)

exports('minigame', startMinigame)