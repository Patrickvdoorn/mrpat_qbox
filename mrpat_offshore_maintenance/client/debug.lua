if not Config.Debug then return end

local suggestions = {
	{ command = '/mycoords', help = 'Print your position and heading, and copy it' },
	{ command = '/scubaon', help = 'Put scuba on (15 min limit)' },
	{ command = '/scubaoff', help = 'Take scuba off' },
	{ command = '/seabed', help = 'Print your position but replace z with the z from seabed, and copy it' },
	{ command = '/prop', help = 'Spawn a prop in front of you', params = {
		{ name = 'model', help = 'model name, for example prop_dock_float_1' },
		{ name = 'placement', help = 'optional: surface (on the water) or seabed (on the bottom, like a job)' },
	} },
	{ command = '/delprop', help = 'Remove test prop from /prop' },
	{ command = '/checkprops', help = 'Check that all location models exist' },
}

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() ~= resourceName then
		return
	end

	for _, suggestion in ipairs(suggestions) do
		TriggerEvent('chat:removeSuggestion', suggestion.command)
	end
end)

local function minigame(name, settings, title)
	return exports[GetCurrentResourceName()]:minigame(name, settings, title)
end

local testProp

-- print current coords (as well as copy to clipboard)
RegisterCommand('mycoords', function()
	local ped = PlayerPedId()
	local c = GetEntityCoords(ped)
	local h = GetEntityHeading(ped)
	local text = ('vec4(%.2f, %.2f, %.2f, %.2f)'):format(c.x, c.y, c.z, h)
	print(text)
	lib.setClipboard(text)
end, false)

-- put scubagear on
RegisterCommand('scubaon', function()
	Config.ClientGear.equip(PlayerPedId())
end, false)

-- take scubagear off
RegisterCommand('scubaoff', function()
	Config.ClientGear.unequip(PlayerPedId())
end, false)

-- z of the seabed (or ground) below a point, or nil if nothing is found within 300 m
local function findSeabed(x, y, z)
	local ray = StartExpensiveSynchronousShapeTestLosProbe(x, y, z, x, y, z - 300.0, 1, PlayerPedId(), 7)
	local _, hit, endCoords = GetShapeTestResult(ray)

	if hit ~= 1 then
		return nil
	end

	return endCoords.z
end

-- get current coords but replace z with the z from seabed (as well as copy to clipboard)
RegisterCommand('seabed', function()
	local c = GetEntityCoords(PlayerPedId())

	local seabedZ = findSeabed(c.x, c.y, c.z)
	if not seabedZ then
		print('No seabed found within 300 m below you')
		return
	end

	local text = ('vec3(%.2f, %.2f, %.2f)'):format(c.x, c.y, seabedZ)
	print(text)
	lib.setClipboard(text)
end, false)

local function removeTestProp()
	if DoesEntityExist(testProp) then
		DeleteEntity(testProp)
	end
	testProp = nil
end

RegisterCommand('prop', function(source, args)
	local model = args[1]
	local placement = args[2]

	if model == nil or (placement and placement ~= 'surface' and placement ~= 'seabed') then
		lib.notify({ title = '[mrpat prop spawn error]', description = 'Usage: /prop [model] [surface or seabed]', type = 'error' })
		return
	end

	local hash = joaat(model)

	if not IsModelInCdimage(hash) then
		lib.notify({ title = '[mrpat prop spawn error]', description = ('Model "%s" does not exist'):format(model), type = 'error' })
		return
	end

	-- remove old prop before spawning new (also so the seabed search doesn't hit it).
	removeTestProp()

	local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 3.0, 0.0)

	local spawnZ = coords.z
	local foundWater, height = GetWaterHeight(coords.x, coords.y, coords.z)

	if placement == 'seabed' then
		-- the same as a job with placement = 'seabed': the prop's origin on the bottom
		local seabedZ = findSeabed(coords.x, coords.y, coords.z)
		if not seabedZ then
			lib.notify({ title = '[mrpat prop spawn error]', description = 'No seabed found within 300 m below that spot', type = 'error' })
			return
		end
		spawnZ = seabedZ
		print(('seabed z at the prop: %.2f'):format(seabedZ))
	elseif placement == 'surface' and foundWater then
		spawnZ = height
	end

	lib.requestModel(hash)

	testProp = CreateObject(hash, coords.x, coords.y, spawnZ, false, false, false)
	if not placement and not foundWater then
		PlaceObjectOnGroundProperly(testProp)
	end
	FreezeEntityPosition(testProp, true)
	SetModelAsNoLongerNeeded(hash)
end, false)

RegisterCommand('delprop', function()
	removeTestProp()
end, false)

RegisterCommand('checkprops', function()
	local result = lib.callback.await('mrpat_om:debugModels', false)
	local countNotOk = 0
	local totalCount = #result

	for _, entry in ipairs(result) do
		local ok = IsModelInCdimage(joaat(entry.model))
		if not ok then
			print(('location %s has missing model %s (Config.Locations) in config/server.lua'):format(entry.label, entry.model))
			countNotOk = countNotOk + 1
		end
	end
	print(('%s models checked. %s had a missing model (Config.Locations) in config/server.lua'):format(totalCount, countNotOk))
end, false)

-- test minigames
local minigameTests = {
	{ command = 'volt', game = 'voltmeter', settings = Config.Voltmeter },
	{ command = 'bolts', game = 'bolts', settings = Config.Bolts },
	{ command = 'wires', game = 'wires', settings = Config.Wires },
	{ command = 'steady', game = 'steady', settings = Config.Steady },
	{ command = 'pumping', game = 'pumping', settings = Config.Pumping },
	{ command = 'code', game = 'code', settings = Config.Code },
}

for _, entry in ipairs(minigameTests) do
	suggestions[#suggestions+1] = {
		command = '/'..entry.command,
		help = ('Test minigame %s'):format(entry.game),
		params = {
			{ name = 'difficulty', help = 'optional: easy, medium, hard. default easy' },
		}
	}

	RegisterCommand(entry.command, function(source, args)
		local difficulty = args[1] or 'easy'
		if not Utils.contains(Utils.difficulties, difficulty) then
			print(('Invalid difficulty "%s", using default "easy"'):format(args[1]))
			difficulty = 'easy'
		end

		print(minigame(entry.game, entry.settings[difficulty]))
	end, false)
end

for _, suggestion in ipairs(suggestions) do
	TriggerEvent('chat:addSuggestion', suggestion.command, suggestion.help, suggestion.params)
end