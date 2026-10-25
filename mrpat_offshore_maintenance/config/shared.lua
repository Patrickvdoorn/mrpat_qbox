Config = {}

-- Test commands for placing locations and tuning minigames (see README, Debug tools).
-- Takes effect after a restart. Never turn this on on a live server!
Config.Debug = true

-- The foreman who hands out contracts and takes vessels back.
Config.NPC = {
	model = 'mp_m_waremech_01', -- ped model
	coords = vec4(-1201.44, -1800.34, 3.91, 70.85), -- position and heading
	targetDistance = 2.0, -- metres, ox_target reach
	serverDistance = 10.0, -- metres, how close the server requires the player to be
	blip = {
		sprite = 427,
		color = 12,
	},
}

-- Where the work vehicle spawns and must be brought back to.
Config.Depot = {
	coords = vec4(-1273.54, -1854.69, 1.09, 133.15), -- spawn position and heading, in water deep enough for the submarine
	returnDistance = 30.0, -- metres, how close the vehicle must be to count as returned
	blip = {
		sprite = 357,
		color = 1,
	},
	marker = {
		type = 35,
		offsetZ = 2.0,
		color = { r = 255, g = 255, b = 255, a = 255 },
	},
}

Config.Deposit = 150 -- default deposit for tiers without their own; 0 turns deposits off
Config.RepairDuration = 10.0 -- seconds a repair attempt takes
Config.InteractionDistance = 10.0 -- metres, how close a player must be to the equipment (also the key prompt range)

-- Diagnostic tests: id (also its locale key), duration in seconds, and the location types it applies to.
Config.Tests = {
	{ id = 'voltage', duration = 6.0, types = { 'surface', 'seabed_cable', 'seabed_sensor', 'seabed_pipeline', 'seabed_pump', 'deepsea_cable', 'deepsea_pipeline', 'deepsea_hpu' }, },
	{ id = 'pressure', duration = 6.0, types = { 'surface', 'seabed_cable', 'seabed_sensor', 'seabed_pipeline', 'seabed_pump', 'deepsea_cable', 'deepsea_pipeline', 'deepsea_hpu' }, },
	{ id = 'lamp', duration = 3.0, types = { 'surface' }, },
	{ id = 'signal', duration = 6.0, types = { 'seabed_cable', 'seabed_sensor', 'seabed_pipeline', 'deepsea_cable', 'deepsea_pipeline', 'deepsea_hpu' }, },
	{ id = 'flow', duration = 6.0, types = { 'seabed_pipeline', 'seabed_pump', 'deepsea_pipeline' }, },
	{ id = 'tension', duration = 6.0, types = { 'mooring' }, },
	{ id = 'buoyancy', duration = 4.0, types = { 'mooring' }, },
	{ id = 'line_check', duration = 5.0, types = { 'mooring' }, },
	{ id = 'vibration', duration = 5.0, types = { 'seabed_pump' }, },
	{ id = 'hydraulics', duration = 6.0, types = { 'deepsea_hpu' }, },
	{ id = 'leak_trace', duration = 6.0, types = { 'deepsea_wreck' }, },
	{ id = 'hull_scan', duration = 5.0, types = { 'deepsea_wreck' }, },
}

-- The XP needed for each level is calculated from these three numbers at startup.
-- With Config.Debug on, the server console shows the result per level and tier.
Config.LevelCurve = {
	maxLevel = 20, -- number of levels
	firstLevelXp = 60, -- XP needed to go from level 1 to level 2
	growth = 20, -- % more XP per level than the previous one
}

-- Urgent contracts: any contract can turn out to be urgent when it is taken.
-- Finish the repair before the tier's urgentTimeLimit runs out to get a bonus on top of the pay.
Config.UrgentContract = {
	chance = 2, -- % chance that a contract is urgent (0 turns urgent contracts off, decimals like 0.5 work)
	bonusPercentage = 5, -- % of the tier's base pay added when the repair is finished in time
	warnings = { 300, 120, 60 }, -- seconds left at which the player is warned, only used when shorter than the tier's limit
}

-- Contract types. Each tier starts at its own level and has its own location types, vehicle, pay and XP.
-- Players get the level bonus only on the highest tier they have unlocked. See the README for every field.
Config.Tiers = {
	{
		id = 'surface', -- unique id, also sent in the events
		label = 'tier_surface', -- locale key for the name
		level = 1, -- level that unlocks this tier
		deposit = nil, -- optional, overrides Config.Deposit for this tier
		pay = 400, -- base pay for a finished repair
		xp = 10, -- XP for a finished repair
		-- Optional difficulties. Use 'easy', 'medium' and/or 'hard'.
		-- With more than one, every repair attempt picks one at random.
		-- Missing or empty: every repair is 'medium'.
		difficulties = { 'easy', 'medium' },
		types = { 'surface', 'mooring' }, -- location types that belong to this tier
		vehicle = 'dinghy3', -- vehicle model for the contract
		gear = false, -- true gives diving gear for the contract
		blip = 'exact', -- 'exact' (point and route) or 'area' (search zone, needs radius)
		levelBonus = 5, -- % of pay added per level above this tier's start (missing: no bonus)
		urgentTimeLimit = 600, -- optional, seconds from taking the contract to finish the repair on an urgent contract (missing: never urgent)
	},
	{
		id = 'seabed',
		label = 'tier_seabed',
		level = 6,
		deposit = nil,
		pay = 550,
		xp = 20,
		difficulties = { 'easy', 'medium', 'hard' },
		types = { 'seabed_cable', 'seabed_sensor', 'seabed_pipeline', 'seabed_pump' },
		vehicle = 'dinghy4',
		gear = true,
		blip = 'area',
		radius = 75, -- metres, size of the search zone for blip = 'area'
		levelBonus = 5,
		urgentTimeLimit = 600,
	},
	{
		id = 'deepsea',
		label = 'tier_deepsea',
		level = 11,
		deposit = nil,
		pay = 675,
		xp = 30,
		difficulties = { 'medium', 'hard' },
		types = { 'deepsea_cable', 'deepsea_pipeline', 'deepsea_hpu' },
		vehicle = 'submersible2',
		gear = false,
		blip = 'area',
		radius = 75,
		drawDistance = 150, -- optional, metres, overrides Config.DrawDistance
		interactionType = 'prompt', -- optional, 'target' (ox_target, default) or 'prompt' (key prompt, for working from a vehicle)
		levelBonus = 5,
		urgentTimeLimit = 720,
	},
	{
		id = 'wreck',
		label = 'tier_wreck',
		level = 16,
		deposit = nil,
		pay = 950,
		xp = 40,
		difficulties = { 'medium', 'hard' },
		types = { 'deepsea_wreck' },
		vehicle = 'submersible2',
		gear = false,
		blip = 'area',
		radius = 300,
		drawDistance = 150,
		interactionType = 'prompt',
		sonar = true, -- optional, true gives a sonar in the search zone (needs blip = 'area')
		levelBonus = 5,
		urgentTimeLimit = 900,
	},
}