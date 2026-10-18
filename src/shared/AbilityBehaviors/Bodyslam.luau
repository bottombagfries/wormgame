--!strict
-- Bodyslam client effect: a dust shockwave the size of the impact, and a camera shake for anyone near.
-- TODO(asset): impact sound, dust particles.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Types = require(script.Parent.Parent.Types)

local WAVE_SECONDS = 0.6
local WAVE_THICKNESS = 0.6
local WAVE_COLOR = Color3.fromRGB(200, 170, 120)

local Bodyslam: Types.AbilityFx = {
	clientFx = function(_wormModel: Model, data: { [string]: any })
		local position = data.position
		local radius = data.radius
		if typeof(position) ~= "Vector3" or typeof(radius) ~= "number" then
			return
		end
		local wave = Instance.new("Part")
		wave.Shape = Enum.PartType.Cylinder
		wave.Anchored = true
		wave.CanCollide = false
		wave.CanQuery = false
		wave.CanTouch = false
		wave.Color = WAVE_COLOR
		wave.Material = Enum.Material.Sand
		wave.Size = Vector3.new(WAVE_THICKNESS, 1, 1)
		wave.CFrame = CFrame.new(position + Vector3.yAxis * 0.5) * CFrame.Angles(0, 0, math.pi / 2)
		wave.Parent = Workspace.CurrentCamera
		TweenService:Create(wave, TweenInfo.new(WAVE_SECONDS), {
			Size = Vector3.new(WAVE_THICKNESS, radius * 2, radius * 2),
			Transparency = 1,
		}):Play()
		Debris:AddItem(wave, WAVE_SECONDS)
	end,
}

return Bodyslam
