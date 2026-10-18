--!strict
-- Feeds the in-match HUD: Pardner bars, aim crosshair/compass, and the match panel (role, sundown
-- clock, objective checklist, Train status). The worm HUD arrives in Phase 6.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local PardnerConfig = require(ReplicatedStorage.Shared.Config.Pardner)
local Net = require(ReplicatedStorage.Shared.Net)
local PardnerLogic = require(ReplicatedStorage.Shared.PardnerLogic)
local Types = require(ReplicatedStorage.Shared.Types)
local TagDefs = require(ReplicatedStorage.Shared.Util.Tags)
local CameraController = require(script.Parent.CameraController)
local MatchController = require(script.Parent.MatchController)
local PardnerMovementController = require(script.Parent.PardnerMovementController)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local ObjectivesHud = require(script.Parent.UI.ObjectivesHud)
local PardnerHud = require(script.Parent.UI.PardnerHud)
local StyleSample = require(script.Parent.UI.StyleSample)
local WormHud = require(script.Parent.UI.WormHud)
local WormController = require(script.Parent.WormController)
local WormConfig = require(ReplicatedStorage.Shared.Config.Worm)
local Abilities = require(ReplicatedStorage.Shared.Config.Abilities)
local Keybinds = require(ReplicatedStorage.Shared.Config.Keybinds)

local HEADINGS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" } -- north is -Z
local CORE_GUI_RETRIES = 10

-- Short labels for slot key hints (anything not listed uses its KeyCode name).
local KEY_LABELS: { [string]: string } = {
	One = "1",
	Two = "2",
	Three = "3",
	LeftShift = "Shift",
	Space = "Spc",
	MouseButton1 = "LMB",
	MouseButton2 = "RMB",
}

local function shortKey(bind: Enum.KeyCode | Enum.UserInputType): string
	return KEY_LABELS[bind.Name] or bind.Name
end

local HUDController = {}

local player = Players.LocalPlayer

local hud: PardnerHud.Hud
local wormHud: WormHud.Hud
local objectivesHud: ObjectivesHud.Hud

local function formatClock(seconds: number): string
	local whole = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function numberAttribute(instance: Instance, name: string): number?
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else nil
end

local function trainStatus(now: number): string
	local train = CollectionService:GetTagged(TagDefs.Tags.Train)[1]
	if not train then
		return ""
	end
	local phase = train:GetAttribute("Phase")
	local earlyDepartAt = numberAttribute(train, "EarlyDepartAt")
	local departAt = numberAttribute(train, "DepartAt")
	if phase == "Fueling" then
		return "Complete the objectives to unlock the Train's lever"
	elseif phase == "Ready" then
		return "Pull the lever on the Train"
	elseif phase == "Departing" and earlyDepartAt then
		return `All aboard - leaving in {math.max(0, math.ceil(earlyDepartAt - now))}s`
	elseif phase == "Departing" and departAt then
		return `Train departs in {formatClock(departAt - now)} - get on board!`
	end
	return "The Train has left"
end

local function updateMatchPanel()
	local state = MatchController.getState()
	local playing = state.phase == "Playing"
	objectivesHud.gui.Enabled = playing
	if not playing then
		return
	end

	local now = Workspace:GetServerTimeNow()
	local role = MatchController.getRole()
	objectivesHud.setHeader(`{string.upper(if role == "Worm" then "The Worm" else role)} - {state.difficulty}`, role)

	local sundownAt = state.sundownAt
	local sundown = if state.night then "Night" elseif sundownAt then formatClock(sundownAt - now) else "--:--"
	objectivesHud.setSundown(sundown, state.night)
	objectivesHud.setStatus(trainStatus(now))
end

-- The worm's ability bar (§14): key, name and cooldown for the five defaults and the two picks.
local function abilityViews(worm: Model): { WormHud.AbilityView }
	local ids = {}
	for id, def in Abilities do
		if def.kind == "Default" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	local picks = player:GetAttribute("Abilities")
	local pickActions = { "WormAbility1", "WormAbility2" }
	local pickIndex = 0
	local keys: { [string]: string } = {}
	for _, id in ids do
		local action = Abilities[id].action
		local binds = action and Keybinds[action]
		keys[id] = if binds then shortKey(binds[1]) else "?"
	end
	if typeof(picks) == "string" then
		for id in string.gmatch(picks, "[^,]+") do
			pickIndex += 1
			local binds = Keybinds[pickActions[pickIndex] or ""]
			if Abilities[id] then
				table.insert(ids, id)
				keys[id] = if binds then shortKey(binds[1]) else "?"
			end
		end
	end

	local now = Workspace:GetServerTimeNow()
	local nightMult = if MatchController.getState().night then WormConfig.NightCooldownMult else 1
	local views: { WormHud.AbilityView } = {}
	for _, id in ids do
		local left = math.max(0, (numberAttribute(worm, `Cooldown_{id}`) or 0) - now)
		table.insert(views, {
			id = id,
			key = keys[id],
			name = Abilities[id].displayName,
			remaining = left,
			total = math.max(Abilities[id].cooldown * nightMult, left),
		})
	end
	return views
end

local function updateWorm()
	local worm = if MatchController.getRole() == "Worm" then WormController.getLocalWorm() else nil
	local head = worm and worm.PrimaryPart
	wormHud.gui.Enabled = worm ~= nil
	if not worm or not head then
		return
	end

	wormHud.setHealth(numberAttribute(worm, "Health") or WormConfig.MaxHealth, WormConfig.MaxHealth)

	local mode = worm:GetAttribute("Mode")
	local grabbed = worm:GetAttribute("GrabbedUserId") ~= nil
	local disorientedFor = (numberAttribute(worm, "DisorientedUntil") or 0) - Workspace:GetServerTimeNow()
	local modeText = if typeof(mode) == "string" then mode else "?"
	if grabbed then
		modeText ..= "  -  Pardner in mouth"
	end
	if disorientedFor > 0 then
		modeText ..= `  -  DISORIENTED {math.ceil(disorientedFor)}s`
	end
	wormHud.setMode(modeText)

	-- Which healing ring the worm is in (rings are centered on where it was hurt).
	local center = worm:GetAttribute("RingCenter")
	if worm:GetAttribute("BurrowLocked") == true and typeof(center) == "Vector3" then
		local offset = head.Position - center
		local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
		local rings = WormConfig.HealRings
		local index = #rings
		for candidate, ring in rings do
			if distance < ring.radius then
				index = candidate
				break
			end
		end
		wormHud.setRing(`Hurt! Stuck underground - ring {index} of {#rings}; move away to heal faster`)
	else
		wormHud.setRing("")
	end

	wormHud.setAbilities(abilityViews(worm))
end

local function update()
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
	local compact = viewport ~= nil and viewport.X < Theme.Sizes.CompactWidth
	hud.setCompact(compact)
	wormHud.setCompact(compact)
	objectivesHud.setCompact(compact)
	local isPardner = MatchController.isPardner()
	hud.gui.Enabled = isPardner
	if isPardner then
		local stats = PardnerMovementController.getStats()
		hud.setHealth(stats.health, stats.maxHealth)
		hud.setStamina(stats.stamina, PardnerLogic.maxStamina(stats), PardnerConfig.MaxStamina)
		hud.setGrip(stats.grip, PardnerConfig.MaxGrip)

		local aiming = CameraController.isAiming()
		hud.setAiming(aiming)
		local camera = Workspace.CurrentCamera
		if aiming and camera then
			local look = camera.CFrame.LookVector
			local index = math.round(math.atan2(look.X, -look.Z) / (math.pi / 4)) % #HEADINGS
			hud.setHeading(HEADINGS[index + 1])
		end
	end

	updateWorm()
	updateMatchPanel()
end

function HUDController.init()
	local playerGui = player:WaitForChild("PlayerGui")
	hud = PardnerHud.create(playerGui)
	wormHud = WormHud.create(playerGui)
	objectivesHud = ObjectivesHud.create(playerGui)
	if GameConfig.Debug.Enabled and GameConfig.Debug.ShowUiSample then
		StyleSample.create(playerGui)
	end
end

function HUDController.start()
	-- The custom health bar replaces Roblox's. SetCoreGuiEnabled can fail until the CoreGui is ready.
	task.spawn(function()
		for _ = 1, CORE_GUI_RETRIES do
			local ok = pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Health, false)
			if ok then
				break
			end
			task.wait(0.5)
		end
	end)

	Net.event("State_Objectives").OnClientEvent:Connect(function(list: { Types.ObjectiveProgress })
		objectivesHud.setObjectives(list)
	end)
	RunService.RenderStepped:Connect(update)
end

return HUDController
