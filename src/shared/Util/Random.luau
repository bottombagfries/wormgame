--!strict
-- Helpers on top of the built-in Random. Pass an rng for deterministic results.

local RandomUtil = {}

local shared = Random.new()

function RandomUtil.pick<T>(list: { T }, rng: Random?): T
	return list[(rng or shared):NextInteger(1, #list)]
end

-- Fisher-Yates, in place. Returns the same table.
function RandomUtil.shuffle<T>(list: { T }, rng: Random?): { T }
	local r = rng or shared
	for i = #list, 2, -1 do
		local j = r:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

-- Up to `count` distinct entries, in random order.
function RandomUtil.sample<T>(list: { T }, count: number, rng: Random?): { T }
	local copy = RandomUtil.shuffle(table.clone(list), rng)
	local out = table.create(math.min(count, #copy))
	for i = 1, math.min(count, #copy) do
		out[i] = copy[i]
	end
	return out
end

-- entries: array of anything; getWeight returns each entry's weight.
function RandomUtil.weighted<T>(entries: { T }, getWeight: (T) -> number, rng: Random?): T
	local total = 0
	for _, entry in entries do
		total += getWeight(entry)
	end
	local roll = (rng or shared):NextNumber() * total
	for _, entry in entries do
		roll -= getWeight(entry)
		if roll <= 0 then
			return entry
		end
	end
	return entries[#entries]
end

function RandomUtil.chance(probability: number, rng: Random?): boolean
	return (rng or shared):NextNumber() < probability
end

return RandomUtil
