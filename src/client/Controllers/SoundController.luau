--!strict
-- Client side of the sound hooks: plays Config.Sounds[key] when the server says so (Fx_Sound), at a
-- position for positional sounds, everywhere for the rest.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
local Net = require(ReplicatedStorage.Shared.Net)

local CLEANUP_SECONDS = 10 -- a one-shot sound's holder is removed after this long

local SoundController = {}

local function play(key: string, position: Vector3?)
	local def = Sounds[key]
	if not def or def.id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = def.id
	sound.Volume = def.volume
	if def.positional and position then
		local holder = Instance.new("Part")
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanQuery = false
		holder.CanTouch = false
		holder.Transparency = 1
		holder.Size = Vector3.one
		holder.Position = position
		holder.Parent = Workspace.CurrentCamera
		sound.Parent = holder
		sound:Play()
		Debris:AddItem(holder, CLEANUP_SECONDS)
	else
		sound.Parent = SoundService -- non-positional: heard the same everywhere
		sound:Play()
		Debris:AddItem(sound, CLEANUP_SECONDS)
	end
end

function SoundController.start()
	Net.event("Fx_Sound").OnClientEvent:Connect(play)
end

return SoundController
