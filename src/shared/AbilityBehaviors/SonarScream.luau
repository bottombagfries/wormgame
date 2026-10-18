--!strict
-- Sonar Scream client effect: a ring that sweeps out from the worm to the scream's radius.
-- TODO(asset): scream sound, proper shockwave effect.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Abilities = require(script.Parent.Parent.Config.Abilities)
local Types = require(script.Parent.Parent.Types)

local Params = Abilities.SonarScream.params
local RING_THICKNESS = 0.4
local RING_COLOR = Color3.fromRGB(255, 80, 80)

local SonarScream: Types.AbilityFx = {
	clientFx = function(_wormModel: Model, data: { [string]: any })
		local position = data.position
		if typeof(position) ~= "Vector3" then
			return
		end
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.Material = Enum.Material.Neon
		ring.Color = RING_COLOR
		ring.Transparency = 0.3
		ring.Size = Vector3.new(RING_THICKNESS, 1, 1)
		ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Parent = Workspace.CurrentCamera
		local diameter = (data.radius or Params.Radius) * 2
		TweenService:Create(ring, TweenInfo.new(Params.RingSeconds), {
			Size = Vector3.new(RING_THICKNESS, diameter, diameter),
			Transparency = 1,
		}):Play()
		Debris:AddItem(ring, Params.RingSeconds)
	end,
}

return SonarScream
