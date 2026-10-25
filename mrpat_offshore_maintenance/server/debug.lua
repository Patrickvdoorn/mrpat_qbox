if not Config.Debug then return end

AddEventHandler('mrpat_offshore_maintenance:jobFinished', function(data)
	print(json.encode(data))
end)

AddEventHandler('mrpat_offshore_maintenance:jobStarted', function(data)
	print(json.encode(data))
end)

lib.callback.register('mrpat_om:debugModels', function(src)
	local list = {}

	for _, location in ipairs(Config.Locations) do
		if type(location.model) == 'string' then
			list[#list + 1] = { label = location.label, model = location.model }
		elseif type(location.model) == 'table' then
			for _, model in ipairs(location.model) do
				list[#list + 1] = { label = location.label, model = model }
			end
		end
	end
	return list
end)