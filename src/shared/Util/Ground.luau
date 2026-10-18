--!strict
-- "What is under this point?" for worms and detection. Usable on server and client.
-- Sand = parts tagged Sand, or Terrain with the Sand material (§4).

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local WormConfig = require(script.Parent.Parent.Config.Worm)
local TagDefs = require(script.Parent.Tags)

local SAND_TAG = TagDefs.Tags.Sand
-- Runtime folders that never count as ground (loose items, worm heads).
local IGNORED_FOLDERS = { "Items", "Worms" }
local MAX_CHARACTER_SKIPS = 8

local Ground = {}

local sandParams: RaycastParams? = nil
local surfaceParams = RaycastParams.new()
surfaceParams.FilterType = Enum.RaycastFilterType.Exclude
surfaceParams.RespectCanCollide = true

CollectionService:GetInstanceAddedSignal(SAND_TAG):Connect(function()
	sandParams = nil
end)
CollectionService:GetInstanceRemovedSignal(SAND_TAG):Connect(function()
	sandParams = nil
end)

local function getSandParams(): RaycastParams
	local params = sandParams
	if not params then
		local include: { Instance } = CollectionService:GetTagged(SAND_TAG)
		table.insert(include, Workspace.Terrain)
		params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = include
		sandParams = params
	end
	return params
end

function Ground.isSand(result: RaycastResult): boolean
	local instance = result.Instance
	if instance:IsA("Terrain") then
		return result.Material == Enum.Material.Sand
	end
	return CollectionService:HasTag(instance, SAND_TAG)
end

-- Height of the sand surface above/below `position`, ignoring everything that is not sand.
function Ground.sandBelow(position: Vector3): number?
	local origin = position + Vector3.yAxis * WormConfig.SandProbeUp
	local ray = Vector3.yAxis * -(WormConfig.SandProbeUp + WormConfig.GroundProbeLength)
	local result = Workspace:Raycast(origin, ray, getSandParams())
	if result and Ground.isSand(result) then
		return result.Position.Y
	end
	return nil
end

-- Height of whatever solid thing is under `position` (ground, props, structures - not characters,
-- loose items or worms), and whether it is sand. `probeUp` is how far above the point the ray starts.
function Ground.surfaceBelow(position: Vector3, probeUp: number?): (number?, boolean)
	local ignore: { Instance } = {}
	for _, name in IGNORED_FOLDERS do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(ignore, folder)
		end
	end

	local up = probeUp or WormConfig.GroundProbeUp
	local origin = position + Vector3.yAxis * up
	local ray = Vector3.yAxis * -(up + WormConfig.GroundProbeLength)
	for _ = 1, MAX_CHARACTER_SKIPS do
		surfaceParams.FilterDescendantsInstances = ignore
		local result = Workspace:Raycast(origin, ray, surfaceParams)
		if not result then
			return nil, false
		end
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChildOfClass("Humanoid") then
			table.insert(ignore, model)
		else
			return result.Position.Y, Ground.isSand(result)
		end
	end
	return nil, false
end

return Ground
