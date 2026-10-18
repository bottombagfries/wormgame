--!strict
-- Weighted Worm roll (Phase 13). Pure logic: MatchService owns the weights (Config.Lobby.RoleRoll) and
-- decides who is eligible (not AFK).

local RoleRoll = {}

-- Draws `count` distinct keys, each with probability proportional to its weight.
function RoleRoll.pick<K>(weights: { [K]: number }, count: number, rng: Random): { K }
	local pool: { { key: K, weight: number } } = {}
	for key, weight in weights do
		table.insert(pool, { key = key, weight = math.max(weight, 0) })
	end
	local picked: { K } = {}
	while #picked < count and #pool > 0 do
		local total = 0
		for _, entry in pool do
			total += entry.weight
		end
		local roll = rng:NextNumber() * total
		local index = #pool
		for candidate, entry in pool do
			roll -= entry.weight
			if roll < 0 then
				index = candidate
				break
			end
		end
		table.insert(picked, pool[index].key)
		table.remove(pool, index)
	end
	return picked
end

-- Chance (0-100) that each key is drawn as one of `count` Worms. Exact for one Worm; for several, a
-- capped share of the total (close enough for the lobby HUD).
function RoleRoll.chances<K>(weights: { [K]: number }, count: number): { [K]: number }
	local total = 0
	for _, weight in weights do
		total += math.max(weight, 0)
	end
	local result: { [K]: number } = {}
	for key, weight in weights do
		local share = if total > 0 then math.max(weight, 0) / total else 0
		result[key] = math.clamp(share * count, 0, 1) * 100
	end
	return result
end

return RoleRoll
