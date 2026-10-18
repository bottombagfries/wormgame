--!strict
-- The lobby (Phase 13): a small abandoned desert train station built at Config.Lobby.Origin, far from the
-- map. Every piece comes from AssetService (greybox until a real model is dropped in), plus spawn pads,
-- invisible walls, and the big departures board whose text MatchService keeps up to date.
--
-- Nobody in the lobby is a Pardner or a Worm, so no damage, items or abilities reach them here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetService = require(ReplicatedStorage.Shared.AssetService)
local LobbyConfig = require(ReplicatedStorage.Shared.Config.Lobby)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Geometry = require(ReplicatedStorage.Shared.Util.Geometry)

local FOLDER_NAME = "Lobby"

local Lobby = {}

local folder: Folder? = nil
local statusLabel: TextLabel? = nil
local resultLabel: TextLabel? = nil

local function anchorAll(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
end

local function boardText(parent: Instance, name: string, font: Font, color: Color3, size: UDim2, y: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, y)
	label.Size = size
	label.FontFace = font
	label.TextColor3 = color
	label.TextScaled = true
	label.Text = ""
	label.Parent = parent
	return label
end

local function buildBoard(model: Model)
	local Board = LobbyConfig.Board
	local screen = model:FindFirstChild(Board.ScreenPart, true)
	local part = if screen and screen:IsA("BasePart") then screen else model.PrimaryPart
	if not part then
		return
	end
	-- The greybox's asset label would sit right on top of the board's text.
	local label = part:FindFirstChild("AssetLabel")
	if label then
		label:Destroy()
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = Board.PixelsPerStud
	gui.LightInfluence = 0
	gui.Parent = part

	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Theme.Colors.WoodDark
	back.BorderSizePixel = 0
	back.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Accent
	stroke.Thickness = 12
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = back

	boardText(back, "Title", Theme.Fonts.Display, Theme.Colors.Accent, UDim2.fromScale(0.9, 0.22), 0.06).Text =
		"DEPARTURES"
	statusLabel =
		boardText(back, "Status", Theme.Fonts.Heading, Theme.Colors.TextLight, UDim2.fromScale(0.9, 0.34), 0.32)
	resultLabel =
		boardText(back, "LastResult", Theme.Fonts.BodyBold, Theme.Colors.Paper, UDim2.fromScale(0.9, 0.16), 0.74)
	Lobby.setLastResult(nil)
end

local function buildWalls(parent: Instance, origin: CFrame)
	local Walls = LobbyConfig.Walls
	local size, t = Walls.Size, Walls.Thickness
	local center = origin * CFrame.new(Walls.Center + Vector3.new(0, size.Y / 2, 0))
	local faces = {
		{ CFrame.new(size.X / 2, 0, 0), Vector3.new(t, size.Y, size.Z) },
		{ CFrame.new(-size.X / 2, 0, 0), Vector3.new(t, size.Y, size.Z) },
		{ CFrame.new(0, 0, size.Z / 2), Vector3.new(size.X, size.Y, t) },
		{ CFrame.new(0, 0, -size.Z / 2), Vector3.new(size.X, size.Y, t) },
		{ CFrame.new(0, size.Y / 2, 0), Vector3.new(size.X, t, size.Z) },
	}
	for _, face in faces do
		local wall = Instance.new("Part")
		wall.Name = "InvisibleWall"
		wall.Size = face[2]
		wall.CFrame = center * face[1]
		wall.Anchored = true
		wall.Transparency = 1
		wall.CanQuery = false
		wall.Parent = parent
	end
end

local function buildSpawnPads(parent: Instance, origin: CFrame)
	local Pads = LobbyConfig.SpawnPads
	for index, position in Pads.Positions do
		local pad = Instance.new("SpawnLocation")
		pad.Name = `SpawnPad{index}`
		pad.Size = Pads.Size
		pad.CFrame = origin * CFrame.new(position + Vector3.new(0, Pads.Size.Y / 2, 0))
		pad.Anchored = true
		pad.Neutral = true
		pad.Duration = 0 -- no spawn forcefield
		pad.Color = Pads.Color
		pad.Material = Enum.Material.SmoothPlastic
		pad.Parent = parent
	end
end

-- Builds the station once. Any other SpawnLocation in the place (such as Studio's default one) is
-- switched off for this session, so characters always load on the lobby pads.
function Lobby.build()
	if folder then
		return
	end
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant.Enabled = false
		end
	end

	local root = Instance.new("Folder")
	root.Name = FOLDER_NAME
	local origin = CFrame.new(LobbyConfig.Origin)
	for _, piece in LobbyConfig.Pieces do
		local model = AssetService.get(piece.id)
		anchorAll(model)
		Geometry.placeOnGround(
			model,
			origin * CFrame.new(piece.position) * CFrame.Angles(0, math.rad(piece.yaw or 0), 0)
		)
		model.Parent = root
		if piece.id == LobbyConfig.Board.Id then
			buildBoard(model)
		end
	end
	buildWalls(root, origin)
	buildSpawnPads(root, origin)
	root.Parent = Workspace
	folder = root
end

-- The board's big line (countdown, "Waiting for players", "Train in progress").
function Lobby.setStatus(text: string)
	if statusLabel then
		statusLabel.Text = text
	end
end

function Lobby.setLastResult(text: string?)
	if resultLabel then
		local Board = LobbyConfig.Board
		resultLabel.Text = if text then Board.LastResultPrefix .. text else Board.NoLastResult
	end
end

-- A spot on the platform (for anyone moved back without a reload).
function Lobby.getSpawnCFrame(index: number?): CFrame
	local Pads = LobbyConfig.SpawnPads
	local position = Pads.Positions[((index or 1) - 1) % #Pads.Positions + 1]
	return CFrame.new(LobbyConfig.Origin + position + Vector3.new(0, Pads.Size.Y + 3, 0))
end

-- True if `position` is inside the station's walls.
function Lobby.contains(position: Vector3): boolean
	local Walls = LobbyConfig.Walls
	local center = LobbyConfig.Origin + Walls.Center + Vector3.new(0, Walls.Size.Y / 2, 0)
	return Geometry.isPointInBox(CFrame.new(center), Walls.Size, position)
end

return Lobby
