Utils = {}

-- Shuffles a list in place (Fisher-Yates).
Utils.shuffle = function(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

-- True when the list contains the value.
Utils.contains = function(list, value)
	for _, item in ipairs(list) do
		if value == item then
			return true
		end
	end
	return false
end

-- The tier from Config.Tiers with this id, or nil when there is none.
Utils.getTier = function(id)
	for _, tier in ipairs(Config.Tiers) do
		if tier.id == id then
			return tier
		end
	end
end

-- The level that belongs to this amount of XP.
Utils.getLevel = function(xp)
	local level = 1
	for i, needed in ipairs(Config.Levels) do
		if xp >= needed.xp then
			level = i
		end
	end
	return level
end

-- True when the two lists have at least one value in common.
Utils.overlaps = function(listA, listB)
	for _, value in ipairs(listA) do
		if Utils.contains(listB, value) then
			return true
		end
	end
	return false
end

-- The tier's own deposit, or Config.Deposit when the tier has none.
Utils.getDeposit = function(tier)
	return tier.deposit or Config.Deposit
end

-- Every valid repair difficulty.
Utils.difficulties = { 'easy', 'medium', 'hard' }

-- The tier's valid difficulties, skipping invalid ones; { 'medium' } when none are left.
Utils.getDifficulties = function(tier)
	local difficulties = {}
	if type(tier.difficulties) == 'table' then
		for _, value in ipairs(tier.difficulties) do
			if Utils.contains(Utils.difficulties, value) then
				difficulties[#difficulties + 1] = value
			end
		end
	end

	if #difficulties == 0 then
		difficulties[1] = 'medium'
	end

	return difficulties
end

-- Prints a warning on the server only, so shared code doesn't warn twice.
local serverWarningOnly = function(msg, ...)
	if IsDuplicityVersion() then
		lib.print.warn((msg):format(...))
	end
end

local defaultLevelCurve = { maxLevel = 20, firstLevelXp = 60, growth = 20 }

-- Builds the XP needed per level from a level curve; invalid values fall back to the defaults.
Utils.buildLevels = function(curve)
	curve = curve or {}

	local maxLevel = curve.maxLevel

	if type(maxLevel) ~= 'number' or maxLevel < 2 or maxLevel % 1 ~= 0 then
		serverWarningOnly('the maxLevel value of Config.LevelCurve should be >= 2 and a whole number, using default %s', defaultLevelCurve.maxLevel)
		maxLevel = defaultLevelCurve.maxLevel
	end

	local firstLevelXp = curve.firstLevelXp
	if type(firstLevelXp) ~= 'number' or firstLevelXp <= 0 then
		serverWarningOnly('the firstLevelXp value of Config.LevelCurve should be > 0, using default %s', defaultLevelCurve.firstLevelXp)
		firstLevelXp = defaultLevelCurve.firstLevelXp
	end

	local growth = curve.growth
	if type(growth) ~= 'number' or growth < 0 then
		serverWarningOnly('the growth value of Config.LevelCurve should be >= 0, using default %s', defaultLevelCurve.growth)
		growth = defaultLevelCurve.growth
	end

	local levels = { { level = 1, xp = 0 } }
	local step = firstLevelXp
	local total = 0

	for level = 2, maxLevel do
		total = total + step
		levels[level] = { level = level, xp = math.floor(total) }
		step = step * (1 + growth/100)
	end

	return levels
end

Config.Levels = Utils.buildLevels(Config.LevelCurve)

-- The highest tier a player of this level has unlocked, or nil when there is none.
Utils.getHighestTier = function(level)
	local highest
	for _, tier in ipairs(Config.Tiers) do
		if tier.level <= level and (highest == nil or tier.level > highest.level) then
			highest = tier
		end
	end
	return highest
end

-- The pay for a tier at this level: base pay, plus the level bonus only on the player's highest tier.
Utils.getPay = function(tier, level)
	local highestTier = Utils.getHighestTier(level)

	if highestTier == nil or tier.id ~= highestTier.id then
		return tier.pay
	end

	local levelsAboveStart = level - tier.level
	local bonusPercentage = tier.levelBonus or 0
	local bonus = tier.pay * bonusPercentage/100 * levelsAboveStart
	local finalPay = tier.pay + math.floor(bonus)

	return finalPay
end

-- The tier's urgent time limit in seconds, or nil when the tier can't get urgent contracts.
Utils.getUrgentTimeLimit = function(tier)
	local limit = tier.urgentTimeLimit
	if type(limit) == 'number' and limit > 0 then
		return limit
	end
	return nil
end
