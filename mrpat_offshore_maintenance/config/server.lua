-- ACE groups that may use the /offshore admin command. Add your own staff groups here.
Config.AdminPermissions = { 'group.admin', 'group.mod' }

Config.Logging = true -- turn logging on or off (see README, Logging)

-- Logging hook. Replace the body to use your own logging tool.
Config.LogCommand = function(src, event, message, tag)
	lib.logger(src, event, message, tag)
end

-- Fuel hook, default for ox_fuel. Using a fuel script with client exports?
-- Set this to false and use Config.ClientSetFuel in config/client.lua
Config.SetFuel = function (vehicle)
	Entity(vehicle).state.fuel = 100.0
end

-- Experience storage hook. Default: qbx_core metadata, per character.
-- Replace the bodies of these functions to use your own skills or XP resource.
Config.Experience = {
	get = function(src)
		return exports.qbx_core:GetMetadata(src, 'offshore_xp') or 0
	end,
	set = function(src, xp)
		exports.qbx_core:SetMetadata(src, 'offshore_xp', xp)
	end,
}

-- Diving gear check. Default: the job provides the gear, so everyone may dive.
-- Set to false to skip the check (same result).
-- Want players to bring their own item? Replace the return line with, for example:
-- return exports.ox_inventory:GetItemCount(src, 'diving_gear') > 0
Config.Gear = {
	hasGear = function (src)
		return true
	end,
}

-- Job sites.
--   label: name used in the logs
--   model: one prop model, or a list to pick from at random
--   placement: 'water' (floats on the surface), 'ground' (placed on the ground) or 'seabed' (uses the z as given)
--   coords: vec3; for seabed and deep-sea locations, the z of the seabed itself (use /seabed with Config.Debug on)
--   type: the location type, which decides the tier, the tests and the faults
Config.Locations = {
	-- surface locations
	{
		label = 'Vespucci harbour entrance buoy',
		model = { 'prop_dock_bouy_1', 'prop_dock_bouy_2', 'prop_dock_bouy_3' },
		placement = 'water',
		coords = vec3(-1484.00, -1972.80, 0.20),
		type = 'surface',
	},
	{
		label = 'Vespucci south channel buoy',
		model = { 'prop_dock_bouy_1', 'prop_dock_bouy_2', 'prop_dock_bouy_3' },
		placement = 'water',
		coords = vec3(-1800.60, -2035.00, -0.1),
		type = 'surface',
	},
	{
		label = 'Vespucci Beach swim zone buoy',
		model = { 'prop_dock_bouy_1', 'prop_dock_bouy_2', 'prop_dock_bouy_3' },
		placement = 'water',
		coords = vec3(-1673.41, -1748.61, -0.52),
		type = 'surface',
	},
	{
		label = 'Vespucci Beach north buoy',
		model = { 'prop_dock_bouy_1', 'prop_dock_bouy_2', 'prop_dock_bouy_3' },
		placement = 'water',
		coords = vec3(-1841.50, -1568.30, -0.40),
		type = 'surface',
	},
	{
		label = 'Vespucci offshore marker buoy',
		model = { 'prop_dock_bouy_1', 'prop_dock_bouy_2', 'prop_dock_bouy_3' },
		placement = 'water',
		coords = vec3(-2130.89, -1828.90, 0.42),
		type = 'surface',
	},
	{
		label = 'Del Perro approach buoy',
		model = { 'prop_dock_bouy_1', 'prop_dock_bouy_2', 'prop_dock_bouy_3' },
		placement = 'water',
		coords = vec3(-2180.90, -1563.84, -0.21),
		type = 'surface',
	},
	{
		label = 'Vespucci southwest marker buoy',
		model = { 'prop_dock_bouy_1', 'prop_dock_bouy_2', 'prop_dock_bouy_3' },
		placement = 'water',
		coords = vec3(-2123.41, -2092.51, -0.54),
		type = 'surface',
	},
	-- mooring floats (surface tier). Positions are offset from the buoys above; check them in game
	{
		label = 'Vespucci south channel mooring',
		model = { 'prop_dock_float_1' },
		placement = 'water',
		coords = vec3(-1860.00, -2075.00, 0.00),
		type = 'mooring',
	},
	{
		label = 'Vespucci offshore mooring',
		model = { 'prop_dock_float_1' },
		placement = 'water',
		coords = vec3(-2190.00, -1870.00, 0.00),
		type = 'mooring',
	},
	{
		label = 'Del Perro offshore mooring',
		model = { 'prop_dock_float_1' },
		placement = 'water',
		coords = vec3(-2240.00, -1600.00, 0.00),
		type = 'mooring',
	},
	{
		label = 'Vespucci southwest mooring',
		model = { 'prop_dock_float_1' },
		placement = 'water',
		coords = vec3(-2180.00, -2140.00, 0.00),
		type = 'mooring',
	},
	-- seabed (shallow) locations
	{
		label = 'Del Perro seabed junction box',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-1801.62, -1365.40, -43.95),
		type = 'seabed_cable',
	},
	{
		label = 'Vespucci Beach data relay',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-1748.38, -1597.17, -29.5),
		type = 'seabed_sensor',
	},
	{
		label = 'Vespucci outer sensor',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-1747.27, -2012.65, -54.95),
		type = 'seabed_sensor',
	},
	{
		label = 'Vespucci southwest pipeline valve',
		model = { 'prop_byard_pipe_01' },
		placement = 'seabed',
		coords = vec3(-1913.41, -2308.79, -45.51),
		type = 'seabed_pipeline',
	},
	{
		label = 'LSIA north outfall monitor',
		model = { 'prop_byard_pipe_01' },
		placement = 'seabed',
		coords = vec3(-1899.10, -2638.00, -20.39),
		type = 'seabed_pipeline',
	},
	{
		label = 'LSIA offshore cable terminal',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-2111.43, -2803.45, -32.01),
		type = 'seabed_cable',
	},
	{
		label = 'Vespucci harbour power cable',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-1596.10, -1925.90, -30.70),
		type = 'seabed_cable',
	},
	-- seabed pump stations. Positions are offset from the seabed sites above with the same z; check them in game
	{
		label = 'LSIA north intake pump',
		model = { 'prop_byard_machine02' },
		placement = 'seabed',
		coords = vec3(-1885.00, -2650.00, -19.42),
		type = 'seabed_pump',
	},
	{
		label = 'Vespucci southwest pump station',
		model = { 'prop_byard_machine02' },
		placement = 'seabed',
		coords = vec3(-1928.00, -2320.00, -42.35),
		type = 'seabed_pump',
	},
	{
		label = 'Vespucci harbour cooling water pump',
		model = { 'prop_byard_machine02' },
		placement = 'seabed',
		coords = vec3(-1610.00, -1938.00, -30.70),
		type = 'seabed_pump',
	},
	-- deep-sea locations
	{
		label = 'Del Perro deep cable junction',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-2188.98, -1241.56, -124.96),
		type = 'deepsea_cable',
	},
	{
		label = 'Vespucci offshore telecom repeater',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-1886.07, -1517.93, -102.41),
		type = 'deepsea_cable',
	},
	{
		label = 'Vespucci deep pipeline manifold',
		model = { 'prop_byard_pipe_01' },
		placement = 'seabed',
		coords = vec3(-1730.00, -1835.00, -101.24),
		type = 'deepsea_pipeline',
	},
	{
		label = 'LSIA deep outfall valve',
		model = { 'prop_byard_pipe_01' },
		placement = 'seabed',
		coords = vec3(-2332.87, -2512.20, -130.49),
		type = 'deepsea_pipeline',
	},
	{
		label = 'Pacific Bluffs deep cable terminal',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-2391.53, -982.82, -113.10),
		type = 'deepsea_cable',
	},
	{
		label = 'LSIA offshore pipeline junction',
		model = { 'prop_byard_pipe_01' },
		placement = 'seabed',
		coords = vec3(-2330.00, -2890.00, -109.89),
		type = 'deepsea_pipeline',
	},
	{
		label = 'Vespucci deep-sea sensor array',
		model = { 'prop_elecbox_10' },
		placement = 'seabed',
		coords = vec3(-1900.00, -2050.00, -110.44),
		type = 'deepsea_cable',
	},
	-- deep-sea hydraulic power units. Positions are offset from the deep-sea pipeline sites above with the same z; check them in game
	{
		label = 'Vespucci deep hydraulic unit',
		model = { 'prop_byard_machine03' },
		placement = 'seabed',
		coords = vec3(-1767.04, -1857.71, -130.46),
		type = 'deepsea_hpu',
	},
	{
		label = 'LSIA deep valve power unit',
		model = { 'prop_byard_machine03' },
		placement = 'seabed',
		coords = vec3(-2279.00, -2559.00, -89.80),
		type = 'deepsea_hpu',
	},
	{
		label = 'LSIA offshore hydraulic unit',
		model = { 'prop_byard_machine03' },
		placement = 'seabed',
		coords = vec3(-2365.00, -2912.00, -125.86),
		type = 'deepsea_hpu',
	},
	-- deep-sea wrecks (sonar tier). Offset about 30 m towards the coast from measured deep-sea sites, same z; measure them in game
	{
		label = 'Vespucci leaking wreck',
		model = { 'tr_prop_tr_boat_wreck_01a' },
		placement = 'seabed',
		coords = vec3(-1866.68, -1512.86, -93.30),
		type = 'deepsea_wreck',
	},
	{
		label = 'LSIA offshore leaking wreck',
		model = { 'tr_prop_tr_boat_wreck_01a' },
		placement = 'seabed',
		coords = vec3(-2321.96, -2893.52, -104.89),
		type = 'deepsea_wreck',
	},
	{
		label = 'Pacific Bluffs leaking wreck',
		model = { 'tr_prop_tr_boat_wreck_01a' },
		placement = 'seabed',
		coords = vec3(-2186.24, -1107.09, -120.69),
		type = 'deepsea_wreck',
	},
}

-- The answer key. Each fault:
--   id: unique name
--   types: the location types it can occur on
--   symptom: locale key shown after inspecting
--   readings: locale key per test id, needed for every test of its types
--   repair: locale key of the correct repair
--   decoys: wrong repairs offered next to it; each must be another fault's repair
Config.Faults = {
	-- surface
	{
		id = 'loose_connection',
		types = {'surface'},
		symptom = 'symptom_failed_connect',
		readings = {
			voltage = 'reading_voltage_unstable',
			lamp = 'reading_lamp_ok',
			pressure = 'reading_pressure_normal',
		},
		repair = 'repair_wiring',
		decoys = { 'replace_lamp', 'replace_battery', 'replace_seal' },
	},
	{
		id = 'dead_battery',
		types = {'surface'},
		symptom = 'symptom_dark_beacon',
		readings = {
			voltage = 'reading_voltage_low',
			lamp = 'reading_lamp_ok',
			pressure = 'reading_pressure_normal',
		},
		repair = 'replace_battery',
		decoys = { 'replace_lamp', 'repair_wiring', 'insulate_connections' },
	},
	{
		id = 'broken_lamp',
		types = {'surface'},
		symptom = 'symptom_led_blinking',
		readings = { voltage = 'reading_voltage_normal', lamp = 'reading_lamp_broken', pressure = 'reading_pressure_normal', },
		repair = 'replace_lamp',
		decoys = {
			'replace_battery',
			'repair_wiring',
			'reset_controller'
		},
	},
	{
		id = 'damaged_seal',
		types = {'surface'},
		symptom = 'symptom_damaged_seal',
		readings = {
			voltage = 'reading_voltage_normal',
			lamp = 'reading_lamp_ok',
			pressure = 'reading_pressure_low',
		},
		repair = 'replace_seal',
		decoys = { 'repair_wiring', 'insulate_connections', 'replace_battery' },
	},
	{
		id = 'faulty_light_sensor',
		types = {'surface'},
		symptom = 'symptom_light_daytime',
		readings = {
			voltage = 'reading_voltage_normal',
			lamp = 'reading_lamp_ok',
			pressure = 'reading_pressure_normal',
		},
		repair = 'replace_light_sensor',
		decoys = { 'reset_controller', 'replace_lamp', 'repair_wiring' },
	},
	{
		id = 'controller_fault',
		types = { 'surface' },
		symptom = 'symptom_wrong_pattern',
		readings = {
			voltage = 'reading_voltage_normal',
			lamp = 'reading_lamp_ok',
			pressure = 'reading_pressure_normal',
		},
		repair = 'reset_controller',
		decoys = { 'replace_light_sensor', 'replace_lamp', 'repair_wiring' },
	},
	{
		id = 'moisture_short',
		types = { 'surface' },
		symptom = 'symptom_fails_in_waves',
		readings = {
			voltage = 'reading_voltage_unstable',
			lamp = 'reading_lamp_ok',
			pressure = 'reading_pressure_normal',
		},
		repair = 'insulate_connections',
		decoys = { 'repair_wiring', 'replace_seal', 'replace_battery' },
	},
	-- mooring floats
	{
		id = 'worn_chain',
		types = { 'mooring' },
		symptom = 'symptom_buoy_drifted',
		readings = {
			tension = 'reading_tension_low',
			buoyancy = 'reading_buoyancy_normal',
			line_check = 'reading_line_clear',
		},
		repair = 'replace_chain',
		decoys = { 'tighten_shackle', 'patch_float', 'clear_line' },
	},
	{
		id = 'loose_shackle',
		types = { 'mooring' },
		symptom = 'symptom_buoy_rattling',
		readings = {
			tension = 'reading_tension_erratic',
			buoyancy = 'reading_buoyancy_normal',
			line_check = 'reading_line_clear',
		},
		repair = 'tighten_shackle',
		decoys = { 'replace_chain', 'patch_float', 'clear_line' },
	},
	{
		id = 'leaking_float',
		types = { 'mooring' },
		symptom = 'symptom_buoy_low',
		readings = {
			tension = 'reading_tension_normal',
			buoyancy = 'reading_buoyancy_low',
			line_check = 'reading_line_clear',
		},
		repair = 'patch_float',
		decoys = { 'clear_line', 'replace_chain', 'tighten_shackle' },
	},
	{
		id = 'fouled_line',
		types = { 'mooring' },
		symptom = 'symptom_buoy_tilted',
		readings = {
			tension = 'reading_tension_high',
			buoyancy = 'reading_buoyancy_low',
			line_check = 'reading_line_fouled',
		},
		repair = 'clear_line',
		decoys = { 'patch_float', 'tighten_shackle', 'replace_chain' },
	},
	-- seabed
	{
		id = 'corroded_connector',
		types = { 'seabed_cable', 'seabed_sensor', 'seabed_pipeline', 'deepsea_cable', 'deepsea_pipeline' },
		symptom = 'symptom_signal_dropouts',
		readings = {
			voltage = 'reading_voltage_unstable',
			pressure = 'reading_pressure_normal',
			signal = 'reading_signal_weak',
			flow = 'reading_flow_normal',
		},
		repair = 'clean_connector',
		decoys = { 'splice_cable', 'drain_housing', 'replace_seal' },
	},
	{
		id = 'flooded_housing',
		types = { 'seabed_cable', 'seabed_sensor', 'seabed_pipeline', 'deepsea_cable', 'deepsea_pipeline' },
		symptom = 'symptom_station_offline',
		readings = {
			voltage = 'reading_voltage_low',
			pressure = 'reading_pressure_high',
			signal = 'reading_signal_lost',
			flow = 'reading_flow_normal',
		},
		repair = 'drain_housing',
		decoys = { 'replace_seal', 'splice_cable', 'clean_connector' },
	},
	{
		id = 'damaged_cable',
		types = { 'seabed_cable', 'seabed_sensor', 'seabed_pipeline', 'deepsea_cable', 'deepsea_pipeline' },
		symptom = 'symptom_station_offline',
		readings = {
			voltage = 'reading_voltage_none',
			pressure = 'reading_pressure_normal',
			signal = 'reading_signal_lost',
			flow = 'reading_flow_normal',
		},
		repair = 'splice_cable',
		decoys = { 'clean_connector', 'drain_housing', 'replace_seal' },
	},
	{
		id = 'fouled_sensor',
		types = { 'seabed_sensor' },
		symptom = 'symptom_bad_data',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_normal',
			signal = 'reading_signal_weak',
		},
		repair = 'clean_sensor',
		decoys = { 'clean_connector', 'splice_cable', 'replace_seal' },
	},
	{
		id = 'seal_failure',
		types = { 'seabed_cable', 'seabed_sensor', 'seabed_pipeline', 'deepsea_cable', 'deepsea_pipeline' },
		symptom = 'symptom_water_ingress',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_low',
			signal = 'reading_signal_normal',
			flow = 'reading_flow_normal',
		},
		repair = 'replace_seal',
		decoys = { 'drain_housing', 'splice_cable', 'clean_connector' },
	},
	-- seabed pump stations
	{
		id = 'clogged_intake',
		types = { 'seabed_pump' },
		symptom = 'symptom_pump_output_dropped',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_normal',
			flow = 'reading_flow_low',
			vibration = 'reading_vibration_normal',
		},
		repair = 'clear_blockage',
		decoys = { 'replace_impeller', 'drain_housing', 'splice_cable' },
	},
	{
		id = 'worn_impeller',
		types = { 'seabed_pump' },
		symptom = 'symptom_pump_rough',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_normal',
			flow = 'reading_flow_low',
			vibration = 'reading_vibration_heavy',
		},
		repair = 'replace_impeller',
		decoys = { 'clear_blockage', 'drain_housing', 'splice_cable' },
	},
	{
		id = 'flooded_pump_motor',
		types = { 'seabed_pump' },
		symptom = 'symptom_pump_moisture',
		readings = {
			voltage = 'reading_voltage_unstable',
			pressure = 'reading_pressure_high',
			flow = 'reading_flow_low',
			vibration = 'reading_vibration_normal',
		},
		repair = 'drain_housing',
		decoys = { 'replace_impeller', 'clear_blockage', 'splice_cable' },
	},
	{
		id = 'pump_power_cut',
		types = { 'seabed_pump' },
		symptom = 'symptom_pump_stopped',
		readings = {
			voltage = 'reading_voltage_none',
			pressure = 'reading_pressure_normal',
			flow = 'reading_flow_none',
			vibration = 'reading_vibration_none',
		},
		repair = 'splice_cable',
		decoys = { 'clear_blockage', 'replace_impeller', 'drain_housing' },
	},
	-- deep sea
	{
		id = 'pipeline_blockage',
		types = { 'seabed_pipeline', 'deepsea_pipeline' },
		symptom = 'symptom_low_throughput',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_normal',
			signal = 'reading_signal_normal',
			flow = 'reading_flow_none',
		},
		repair = 'clear_blockage',
		decoys = { 'splice_cable', 'replace_seal', 'drain_housing' },
	},
	{
		id = 'valve_actuator_failure',
		types = { 'seabed_pipeline', 'deepsea_pipeline' },
		symptom = 'symptom_valve_unresponsive',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_normal',
			signal = 'reading_signal_normal',
			flow = 'reading_flow_low',
		},
		repair = 'replace_actuator',
		decoys = { 'clear_blockage', 'splice_cable', 'clean_connector' },
	},
	-- deep-sea hydraulic power units
	{
		id = 'hydraulic_leak',
		types = { 'deepsea_hpu' },
		symptom = 'symptom_hpu_pressure_dropping',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_normal',
			signal = 'reading_signal_normal',
			hydraulics = 'reading_hydraulics_low',
		},
		repair = 'reseal_hydraulics',
		decoys = { 'replace_hydraulic_pump', 'splice_cable', 'drain_housing' },
	},
	{
		id = 'hydraulic_pump_failure',
		types = { 'deepsea_hpu' },
		symptom = 'symptom_hpu_valves_stuck',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_normal',
			signal = 'reading_signal_normal',
			hydraulics = 'reading_hydraulics_none',
		},
		repair = 'replace_hydraulic_pump',
		decoys = { 'reseal_hydraulics', 'splice_cable', 'drain_housing' },
	},
	{
		id = 'hpu_link_lost',
		types = { 'deepsea_hpu' },
		symptom = 'symptom_hpu_no_contact',
		readings = {
			voltage = 'reading_voltage_normal',
			pressure = 'reading_pressure_normal',
			signal = 'reading_signal_lost',
			hydraulics = 'reading_hydraulics_normal',
		},
		repair = 'splice_cable',
		decoys = { 'reseal_hydraulics', 'replace_hydraulic_pump', 'drain_housing' },
	},
	{
		id = 'flooded_hpu',
		types = { 'deepsea_hpu' },
		symptom = 'symptom_hpu_tripping',
		readings = {
			voltage = 'reading_voltage_unstable',
			pressure = 'reading_pressure_high',
			signal = 'reading_signal_weak',
			hydraulics = 'reading_hydraulics_normal',
		},
		repair = 'drain_housing',
		decoys = { 'reseal_hydraulics', 'replace_hydraulic_pump', 'splice_cable' },
	},
	-- deep-sea wrecks
	{
		id = 'cracked_fuel_tank',
		types = { 'deepsea_wreck' },
		symptom = 'symptom_wreck_slick',
		readings = {
			leak_trace = 'reading_leak_streaming',
			hull_scan = 'reading_hull_cracked',
		},
		repair = 'patch_fuel_tank',
		decoys = { 'close_fuel_valve', 'cap_tank_vent', 'seal_cargo_hatch' },
	},
	{
		id = 'open_fuel_valve',
		types = { 'deepsea_wreck' },
		symptom = 'symptom_wreck_slick',
		readings = {
			leak_trace = 'reading_leak_streaming',
			hull_scan = 'reading_hull_intact',
		},
		repair = 'close_fuel_valve',
		decoys = { 'patch_fuel_tank', 'cap_tank_vent', 'seal_cargo_hatch' },
	},
	{
		id = 'loose_vent_cap',
		types = { 'deepsea_wreck' },
		symptom = 'symptom_wreck_sheen',
		readings = {
			leak_trace = 'reading_leak_seeping',
			hull_scan = 'reading_hull_intact',
		},
		repair = 'cap_tank_vent',
		decoys = { 'seal_cargo_hatch', 'close_fuel_valve', 'patch_fuel_tank' },
	},
	{
		id = 'open_cargo_hatch',
		types = { 'deepsea_wreck' },
		symptom = 'symptom_wreck_sheen',
		readings = {
			leak_trace = 'reading_leak_seeping',
			hull_scan = 'reading_hull_hatch_open',
		},
		repair = 'seal_cargo_hatch',
		decoys = { 'cap_tank_vent', 'patch_fuel_tank', 'close_fuel_valve' },
	},
}

-- Counters every character starts with. A counter added later starts at 0 for existing players too.
local defaultStats = {
	repairsReturned = 0,
	repairsVesselLost = 0,
	vesselsLost = 0,
	abandonedRepaired = 0,
	abandonedUnrepaired = 0,
}

-- Statistics storage hook. Default: qbx_core metadata, per character.
-- Replace the bodies to store them elsewhere, or set this to false to turn statistics off.
Config.Stats = {
	get = function(src)
		local stats = exports.qbx_core:GetMetadata(src, 'offshore_stats') or {}

		for name, value in pairs(defaultStats) do
			if stats[name] == nil then
				stats[name] = value
			end
		end

		return stats
	end,
	set = function(src, stats)
		exports.qbx_core:SetMetadata(src, 'offshore_stats', stats)
	end,
}