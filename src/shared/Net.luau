--!strict
-- Every RemoteEvent/RemoteFunction is declared here (§13). Naming: Verb_Noun.
-- Server: Net.init() creates them in ReplicatedStorage.Remotes. Client: Net.init() waits for them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(script.Parent.Config.Game)
local RateLimit = require(script.Parent.Util.RateLimit)

type RemoteKind = "Event" | "Function"

local FOLDER_NAME = "Remotes"

local REMOTES: { [string]: RemoteKind } = {
	-- Client -> server intents (rate-limited per player)
	Request_Pickup = "Event", -- (itemInstance)
	Request_Drop = "Event", -- ()
	Request_Throw = "Event", -- (dir: Vector3, power: number)
	Request_StoreInBag = "Event", -- ()
	Request_Dig = "Event", -- (digging: boolean) hold interact on sand with a Shovel in the kit slot
	Request_UseHeld = "Event", -- () use the item in hands (light dynamite, ...)
	Request_TakeFromBag = "Event", -- (slot: number)
	Request_UseKit = "Event", -- (payload: { direction: Vector3? })
	Request_SafeCode = "Event", -- (code: string) at the safe's keypad
	Request_Interact = "Event", -- (target)
	Request_Ability = "Event", -- (abilityId: string, payload)
	Request_Climb = "Event", -- (state: boolean)
	Request_Sprint = "Event", -- (state: boolean)
	Request_Jump = "Event", -- () a ground jump, or a climb-jump while climbing
	Request_MinigameInput = "Event", -- (arrow)
	Request_GhostPush = "Event", -- (item: Model, direction: Vector3, charge: number 0..1)
	Request_SetDifficulty = "Event", -- (name: string) host only, in the lobby
	Request_SetAfk = "Event", -- (afk: boolean) skip the role roll and stay in the lobby
	Request_SelectAbilities = "Event", -- (abilityIds: { string }) worm only, during WormLoadout

	-- Server -> client state
	State_Pardner = "Event", -- (stats)
	State_Inventory = "Event", -- (Types.InventoryState)
	State_Objectives = "Event", -- ({ Types.ObjectiveProgress })
	State_Match = "Event", -- (Types.MatchState)
	State_Safe = "Event", -- (Types.SafeState) OpenSafe objective: code signs, recorded digits, safe position
	Ui_SafeKeypad = "Event", -- () open the keypad screen for this player
	Pardner_Impulse = "Event", -- (velocity: Vector3) the client adds it to its own character (recoil, pogo)
	State_Minigame = "Event", -- (Types.MinigameState) the grabbed Pardner only
	Worm_Pings = "Event", -- ({ Vector3 }) worm clients only
	Worm_Visible = "Event", -- ({ userId }) worm clients only: Pardners this worm may see
	Worm_Launch = "Event", -- (velocity: Vector3) the pouncing worm's client applies it to its head
	Fx_Play = "Event", -- (effectId: string, cframe: CFrame)
	Fx_Ability = "Event", -- (abilityId: string, wormModel: Model, data) every client runs the ability's clientFx
	Fx_Sound = "Event", -- (soundKey: string, position: Vector3?) every client plays Config.Sounds[soundKey]
	Fx_Notify = "Event", -- (text: string) short on-screen message
}

local Net = {}

local folder: Instance? = nil

local function getFolder(): Instance
	if folder then
		return folder
	end
	if RunService:IsServer() then
		local created = Instance.new("Folder")
		created.Name = FOLDER_NAME
		for name, kind in REMOTES do
			local remote = Instance.new(if kind == "Event" then "RemoteEvent" else "RemoteFunction")
			remote.Name = name
			remote.Parent = created
		end
		created.Parent = ReplicatedStorage
		folder = created
		return created
	end
	local found = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	folder = found
	return found
end

local function getRemote(name: string, kind: RemoteKind): Instance
	if REMOTES[name] ~= kind then
		error(`[Net] "{name}" is not declared as a Remote{kind} in Net.luau`, 3)
	end
	return getFolder():WaitForChild(name)
end

function Net.init()
	getFolder()
end

function Net.event(name: string): RemoteEvent
	return getRemote(name, "Event") :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	return getRemote(name, "Function") :: RemoteFunction
end

function Net.isRequest(name: string): boolean
	return string.sub(name, 1, 8) == "Request_"
end

local limiters: { RateLimit.Limiter } = {}
local cleanupConnected = false

-- Server only. Connects a handler to a Request_* remote behind a per-player token bucket.
function Net.onRequest(name: string, handler: (player: Player, ...any) -> ()): RBXScriptConnection
	assert(RunService:IsServer(), "[Net] onRequest is server-only")
	assert(Net.isRequest(name), `[Net] onRequest expects a Request_* remote, got "{name}"`)

	local limiter = RateLimit.new(GameConfig.RateLimit.PerSecond, GameConfig.RateLimit.Burst)
	table.insert(limiters, limiter)
	if not cleanupConnected then
		cleanupConnected = true
		Players.PlayerRemoving:Connect(function(player)
			for _, each in limiters do
				each:remove(player)
			end
		end)
	end

	return Net.event(name).OnServerEvent:Connect(function(player: Player, ...: any)
		if limiter:check(player) then
			handler(player, ...)
		end
	end)
end

return Net
