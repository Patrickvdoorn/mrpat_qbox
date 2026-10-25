if not Config.Stats then return end

local counters = {
	vessel_lost = {
		[true] = 'repairsVesselLost',
		[false] = 'vesselsLost',
	},
	returned = {
		[true] = 'repairsReturned',
	},
	abandoned = {
		[true] = 'abandonedRepaired',
		[false] = 'abandonedUnrepaired',
	},
}

AddEventHandler('mrpat_offshore_maintenance:jobFinished', function(data)
	local byRepaired = counters[data.outcome]
	if not byRepaired then return end

	local counter = byRepaired[data.repaired]
	if not counter then return end

	local stats = Config.Stats.get(data.source)
	stats[counter] = stats[counter] + 1
	Config.Stats.set(data.source, stats)
end)