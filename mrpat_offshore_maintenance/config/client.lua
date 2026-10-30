-- Shortcut to this resource's minigame export, used by Config.RepairMinigame below.
local function minigame(name, settings, title)
	return exports[GetCurrentResourceName()]:minigame(name, settings, title)
end

-- Fuel hook for fuel scripts with client exports
-- Using ox_fuel? Leave this empty or set it to false, Config.SetFuel in config/server.lua handles it.
Config.ClientSetFuel = function(vehicle)
end

-- Diving gear hook. This runs when a dive contract starts (equip) and ends (unequip).
-- Default: built-in scuba, so the player can breathe underwater for 15 minutes.
-- Using your own diving resource? Replace the body of these functions,
-- or set this to false if that resource already puts the gear on and takes it off.
local scubaGear = {
	mask = 0,
	tank = 0,
	equipped = false,
}

Config.ClientGear = {
	equip = function(ped)
		local maskModel = joaat(Config.ScubaModels.mask)
		local tankModel = joaat(Config.ScubaModels.tank)
		lib.requestModel(maskModel)
		lib.requestModel(tankModel)

		scubaGear.tank = CreateObject(tankModel, 1.0, 1.0, 1.0, true, true, false)
		SetEntityCollision(scubaGear.tank, false, false)
		local bone1 = GetPedBoneIndex(ped, 24818)
		AttachEntityToEntity(scubaGear.tank, ped, bone1, -0.25, -0.25, 0.0, 180.0, 90.0, 0.0, true, true, false, false, 2, true)

		scubaGear.mask = CreateObject(maskModel, 1.0, 1.0, 1.0, true, true, false)
		SetEntityCollision(scubaGear.mask, false, false)
		local bone2 = GetPedBoneIndex(ped, 12844)
		AttachEntityToEntity(scubaGear.mask, ped, bone2, 0.0, 0.0, 0.0, 180.0, 90.0, 0.0, true, true, false, false, 2, true)
		SetModelAsNoLongerNeeded(maskModel)
		SetModelAsNoLongerNeeded(tankModel)
		SetEnableScuba(ped, true)
		SetPedMaxTimeUnderwater(ped, 900.0)
		scubaGear.equipped = true
	end,
	unequip = function(ped)
		if not scubaGear.equipped then return end

		if scubaGear.mask ~= 0 then
			DetachEntity(scubaGear.mask, false, true)
			DeleteEntity(scubaGear.mask)
			scubaGear.mask = 0
		end
		if scubaGear.tank ~= 0 then
			DetachEntity(scubaGear.tank, false, true)
			DeleteEntity(scubaGear.tank)
			scubaGear.tank = 0
		end
		SetEnableScuba(ped, false)
		SetPedMaxTimeUnderwater(ped, 10.0)
		scubaGear.equipped = false
	end,
}

-- Props for the mask and tank of the built-in diving gear.
Config.ScubaModels = {
	mask = 'p_d_scuba_mask_s',
	tank = 'p_s_scuba_tank_s',
}

Config.Currency = '$' -- currency symbol shown in the menus

-- Anchor keybind. Players can rebind the key in their FiveM settings.
Config.Anchor = {
	key = 'G', -- default key
	maxSpeed = 1.0, -- the vessel must be slower than this to drop anchor
}

Config.Sonar = {
	key = 'J', -- default key
	ranges = {
		{ distance = 200, interval = 3, }, -- distance is the lower bound, interval is in seconds
		{ distance = 100, interval = 2, },
		{ distance = 50, interval = 1, },
		{ distance = 25, interval = 0.5, },
		{ distance = 0, interval = 0.25, },
	},
	sound = {soundName = '5_SEC_WARNING', soundSetName = 'HUD_MINI_GAME_SOUNDSET'},
	display = true, -- shows a signal strength meter next to the beep (false: sound only)
}

Config.InteractKey = 'E' -- default key for the prompt on tiers with interactionType = 'prompt' (players can rebind it)

-- How the job site looks: ox_target reach (metres), blip and marker.
Config.JobSite = {
	targetDistance = 3.0,
	blip = {
		sprite = 402,
		color = 18,
		zoneColor = 18, -- colour of the search zone on tiers with blip = 'area'
	},
	marker = {
		type = 0,
		offsetZ = 5.0,
		color = { r = 255, g = 0, b = 0, a = 200 },
	},
}

Config.DrawDistance = 100.0 -- metres, how far away job equipment spawns, unless a tier sets its own drawDistance
Config.InspectDuration = 2.5 -- seconds an inspection takes

-- ox_lib skill check: one entry per round ('easy', 'medium' or 'hard').
-- inspect is used for every inspection; repair is used per difficulty for repairs without a minigame of their own.
Config.SkillCheck = {
	keys = { 'w', 'a', 's', 'd' },
	inspect = { 'medium', },
	repair = {
		easy = { 'easy', 'easy', 'easy', },
		medium = { 'easy', 'medium', 'medium', },
		hard = { 'medium', 'hard', 'hard', 'medium', },
	},
}

-- Minigame settings per difficulty. A repair uses the difficulty its tier picked (difficulties in Config.Tiers).
-- Every minigame also accepts timeout (seconds before it counts as failed, default 60).

-- Voltmeter: stop the needle in the zone. zoneWidth = size of the zone, speed = needle speed, tries = attempts
Config.Voltmeter = {
	easy = { zoneWidth = 20, speed = 48, tries = 3, },
	medium = { zoneWidth = 14, speed = 60, tries = 3, },
	hard = { zoneWidth = 8, speed = 78, tries = 3, },
}

-- Bolts: repeat the shown order. count = number of bolts, showTime = milliseconds each bolt is shown, tries = attempts
Config.Bolts = {
	easy = { count = 4, showTime = 700, tries = 3, },
	medium = { count = 5, showTime = 550, tries = 3, },
	hard = { count = 6, showTime = 400, tries = 3, },
}

-- Wires: connect matching colours. count = number of wires, tries = attempts
Config.Wires = {
	easy = { count = 4, tries = 3, },
	medium = { count = 5, tries = 3, },
	hard = { count = 6, tries = 3, },
}

-- Steady: keep the marker in the moving zone. zoneSize = size of the zone, zoneSpeed = how fast it moves,
-- fillRate / drainRate = progress gained inside / lost outside the zone per second, timeLimit = seconds
Config.Steady = {
	easy = { zoneSize = 32, zoneSpeed = 0.4, fillRate = 10, drainRate = 5, timeLimit = 40 },
	medium = { zoneSize = 26, zoneSpeed = 0.6, fillRate = 12, drainRate = 8, timeLimit = 30 },
	hard = { zoneSize = 18, zoneSpeed = 1.0, fillRate = 12, drainRate = 10, timeLimit = 30 },
}

-- Pumping: pump out the water without overheating. strokePower = water removed per stroke, leakRate = water in per second,
-- pressurePerStroke = heat per stroke, coolRate = heat lost per second, tries = attempts, timeLimit = seconds
Config.Pumping = {
	easy = {strokePower = 6, leakRate = 3, pressurePerStroke = 12, coolRate = 30, tries = 3, timeLimit = 30 },
	medium = {strokePower = 5, leakRate = 4, pressurePerStroke = 14, coolRate = 25, tries = 3, timeLimit = 25 },
	hard = {strokePower = 4, leakRate = 5, pressurePerStroke = 16, coolRate = 22, tries = 3, timeLimit = 20 },
}

-- Code: find the reset code. length = digits (max 6), attempts = guesses, timeout = seconds
Config.Code = {
	easy   = { length = 3, attempts = 6, timeout = 120},
	medium = { length = 4, attempts = 6, timeout = 120},
	hard   = { length = 5, attempts = 6, timeout = 120},
}

-- Minigame per repair id. Each entry receives the repair's name (title) and the picked difficulty,
-- and returns true on success. default is used for repairs without an entry of their own.
Config.RepairMinigame = {
	default = function(title, difficulty)
		return lib.skillCheck(Config.SkillCheck.repair[difficulty], Config.SkillCheck.keys)
	end,
	replace_battery = function(title, difficulty)
		return minigame('voltmeter', Config.Voltmeter[difficulty], title)
	end,
	replace_lamp = function(title, difficulty)
		return minigame('bolts', Config.Bolts[difficulty], title)
	end,
	repair_wiring = function(title, difficulty)
		return minigame('wires', Config.Wires[difficulty], title)
	end,
	insulate_connections = function(title, difficulty)
		return minigame('wires', Config.Wires[difficulty], title)
	end,
	replace_seal = function(title, difficulty)
		return minigame('steady', Config.Steady[difficulty], title)
	end,
	drain_housing = function(title, difficulty)
		return minigame('pumping', Config.Pumping[difficulty], title)
	end,
	reset_controller = function(title, difficulty)
		return minigame('code', Config.Code[difficulty], title)
	end,
	replace_light_sensor = function(title, difficulty)
		return minigame('code', Config.Code[difficulty], title)
	end,
	clean_connector = function(title, difficulty)
		return minigame('bolts', Config.Bolts[difficulty], title)
	end,
	splice_cable = function(title, difficulty)
		return minigame('wires', Config.Wires[difficulty], title)
	end,
	clean_sensor = function(title, difficulty)
		return minigame('steady', Config.Steady[difficulty], title)
	end,
	clear_blockage = function(title, difficulty)
		return minigame('pumping', Config.Pumping[difficulty], title)
	end,
	replace_actuator = function(title, difficulty)
		return minigame('bolts', Config.Bolts[difficulty], title)
	end,
	replace_chain = function(title, difficulty)
		return minigame('steady', Config.Steady[difficulty], title)
	end,
	tighten_shackle = function(title, difficulty)
		return minigame('bolts', Config.Bolts[difficulty], title)
	end,
	patch_float = function(title, difficulty)
		return minigame('pumping', Config.Pumping[difficulty], title)
	end,
	clear_line = function(title, difficulty)
		return minigame('wires', Config.Wires[difficulty], title)
	end,
	replace_impeller = function(title, difficulty)
		return minigame('bolts', Config.Bolts[difficulty], title)
	end,
	reseal_hydraulics = function(title, difficulty)
		return minigame('steady', Config.Steady[difficulty], title)
	end,
	replace_hydraulic_pump = function(title, difficulty)
		return minigame('pumping', Config.Pumping[difficulty], title)
	end,
	patch_fuel_tank = function(title, difficulty)
		return minigame('steady', Config.Steady[difficulty], title)
	end,
	close_fuel_valve = function(title, difficulty)
		return minigame('bolts', Config.Bolts[difficulty], title)
	end,
	cap_tank_vent = function(title, difficulty)
		return minigame('voltmeter', Config.Voltmeter[difficulty], title)
	end,
	seal_cargo_hatch = function(title, difficulty)
		return minigame('pumping', Config.Pumping[difficulty], title)
	end,
}

-- Which minigame runs for inspecting, and how a repair finds its entry in Config.RepairMinigame.
Config.Minigame = {
	inspect = function()
		return lib.skillCheck(Config.SkillCheck.inspect, Config.SkillCheck.keys)
	end,
	repair = function(repairId, difficulty)
		local game = Config.RepairMinigame[repairId] or Config.RepairMinigame.default
		return game(locale(repairId), difficulty)
	end,
}