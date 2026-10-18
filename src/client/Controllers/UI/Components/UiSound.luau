--!strict
-- Plays a UI sound locally (Config/Sounds keys from Theme.Sounds). Silent while the id is empty.
-- TODO(asset): fill in the Ui* ids in Config/Sounds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)

local UiSound = {}

local cache: { [string]: Sound } = {}
local volumeScale = 1

-- Settings (Phase 13 step 6) scale every UI sound.
function UiSound.setVolume(scale: number)
	volumeScale = math.clamp(scale, 0, 1)
end

function UiSound.play(key: string)
	local def = Sounds[key]
	if not def or def.id == "" then
		return
	end
	local sound = cache[key]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "Ui_" .. key
		sound.SoundId = def.id
		sound.Parent = SoundService
		cache[key] = sound
	end
	sound.Volume = def.volume * volumeScale
	SoundService:PlayLocalSound(sound)
end

return UiSound
