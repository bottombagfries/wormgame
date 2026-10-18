--!strict
-- Phase 13 player settings: music / SFX volume, camera sensitivity, the Worm's mouth view. Values live here
-- for the session (Config/Settings defaults); setting one applies it right away. Also plays the lobby / match
-- music through the Music sound group.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SettingsConfig = require(ReplicatedStorage.Shared.Config.Settings)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local MatchController = require(script.Parent.MatchController)
local UiSound = require(script.Parent.UI.Components.UiSound)

export type Values = {
	MusicVolume: number,
	SfxVolume: number,
	CameraSensitivity: number,
	WormMouthView: boolean,
}

local SettingsController = {}

local changed: Signal.Signal<string> = Signal.new()
SettingsController.changed = changed

local values: Values = table.clone(SettingsConfig.Defaults)
local groups: { [string]: SoundGroup } = {}
local tracks: { [string]: Sound } = {}

-- "Music" and "Sfx" sound groups in SoundService (SoundController and UiSound use Sfx).
function SettingsController.getGroup(name: "Music" | "Sfx"): SoundGroup
	local group = groups[name]
	if not group then
		local existing = SoundService:FindFirstChild(name)
		if existing and existing:IsA("SoundGroup") then
			group = existing
		else
			local created = Instance.new("SoundGroup")
			created.Name = name
			created.Parent = SoundService
			group = created
		end
		groups[name] = group
	end
	return group :: SoundGroup
end

local function apply(key: string)
	if key == "MusicVolume" then
		SettingsController.getGroup("Music").Volume = values.MusicVolume
	elseif key == "SfxVolume" then
		SettingsController.getGroup("Sfx").Volume = values.SfxVolume
		UiSound.setVolume(values.SfxVolume)
	elseif key == "CameraSensitivity" then
		UserInputService.MouseDeltaSensitivity = values.CameraSensitivity
	end
end

function SettingsController.get(): Values
	return values
end

function SettingsController.set(key: string, value: any)
	local current = (values :: any)[key]
	if current == nil or typeof(current) ~= typeof(value) or current == value then
		return
	end
	(values :: any)[key] = value
	apply(key)
	changed:fire(key)
end

-- Lobby music while at the station, match music during a round (both silent until ids are set).
local function setMusic(which: string?)
	for name, sound in tracks do
		local target = if name == which then (SettingsConfig.Music :: any)[name].volume else 0
		TweenService:Create(sound, TweenInfo.new(SettingsConfig.Music.FadeSeconds), { Volume = target }):Play()
	end
end

function SettingsController.init()
	for _, key in { "MusicVolume", "SfxVolume", "CameraSensitivity" } do
		apply(key)
	end
	for _, name in { "Lobby", "Match" } do
		local def = (SettingsConfig.Music :: any)[name]
		if def.id ~= "" then
			local sound = Instance.new("Sound")
			sound.Name = `Music_{name}`
			sound.SoundId = def.id
			sound.Looped = true
			sound.Volume = 0
			sound.SoundGroup = SettingsController.getGroup("Music")
			sound.Parent = SoundService
			sound:Play()
			tracks[name] = sound
		end
	end
end

function SettingsController.start()
	if next(tracks) == nil then
		return
	end
	local current: string? = nil
	RunService.Heartbeat:Connect(function()
		local which = if MatchController.getRole() == "None" then "Lobby" else "Match"
		if which ~= current then
			current = which
			setMusic(which)
		end
	end)
end

return SettingsController
