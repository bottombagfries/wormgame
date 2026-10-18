--!strict
-- Armored Carapace client effect: the sand blast when the shelled worm surfaces — a burst of sand the
-- size of the blast. TODO(asset): blast sound, shell visuals on the worm.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Types = require(script.Parent.Parent.Types)

local BLAST_SECONDS = 0.5
local BLAST_COLOR = Color3.fromRGB(220, 190, 130)

local ArmoredCarapace: Types.AbilityFx = {
	clientFx = function(_wormModel: Model, data: { [string]: any })
		local position = data.position
		local radius = data.radius
		if typeof(position) ~= "Vector3" or typeof(radius) ~= "number" then
			return
		end
		local blast = Instance.new("Part")
		blast.Shape = Enum.PartType.Ball
		blast.Anchored = true
		blast.CanCollide = false
		blast.CanQuery = false
		blast.CanTouch = false
		blast.Color = BLAST_COLOR
		blast.Material = Enum.Material.Sand
		blast.Transparency = 0.3
		blast.Size = Vector3.one
		blast.Position = position
		blast.Parent = Workspace.CurrentCamera
		TweenService:Create(blast, TweenInfo.new(BLAST_SECONDS), {
			Size = Vector3.one * radius * 2,
			Transparency = 1,
		}):Play()
		Debris:AddItem(blast, BLAST_SECONDS)
	end,
}

return ArmoredCarapace
