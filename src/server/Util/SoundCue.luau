--!strict
-- Server side of the sound hooks: tells every client to play Config.Sounds[key], at `position` if the
-- sound is positional. Silent while the id is empty.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
local Net = require(ReplicatedStorage.Shared.Net)

local SoundCue = {}

function SoundCue.play(key: string, position: Vector3?)
	local def = Sounds[key]
	if not def then
		warn(`[SoundCue] No sound "{key}" in Config/Sounds`)
		return
	end
	if def.id == "" then
		return -- TODO(asset): no sound yet
	end
	Net.event("Fx_Sound"):FireAllClients(key, position)
end

return SoundCue
