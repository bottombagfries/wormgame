--!strict
-- Per-player token bucket for Request_* remotes (§13).

export type Limiter = {
	check: (self: Limiter, player: Player) -> boolean,
	remove: (self: Limiter, player: Player) -> (),
}

type Bucket = { tokens: number, last: number }

local RateLimit = {}

-- perSecond: refill rate. burst: bucket size.
function RateLimit.new(perSecond: number, burst: number): Limiter
	local buckets: { [Player]: Bucket } = {}

	local limiter: Limiter = {
		-- True if the request is allowed (and consumes a token).
		check = function(_self: Limiter, player: Player): boolean
			local now = os.clock()
			local bucket = buckets[player]
			if not bucket then
				bucket = { tokens = burst, last = now }
				buckets[player] = bucket
			end
			bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.last) * perSecond)
			bucket.last = now
			if bucket.tokens < 1 then
				return false
			end
			bucket.tokens -= 1
			return true
		end,
		remove = function(_self: Limiter, player: Player)
			buckets[player] = nil
		end,
	}
	return limiter
end

return RateLimit
