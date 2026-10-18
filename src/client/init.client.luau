--!strict
-- Client bootstrap: waits for remotes, then calls every Controller's init(), then every start().
-- Controllers listed here but not built yet are skipped, so later phases just drop the file in.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Net = require(ReplicatedStorage.Shared.Net)

type Controller = {
	init: (() -> ())?,
	start: (() -> ())?,
}

local CONTROLLER_ORDER = {
	"InputController",
	"SettingsController",
	"SoundController",
	"ToastController",
	"MatchController",
	"SpectateController",
	"LobbyController",
	"CameraController",
	"PardnerMovementController",
	"WormController",
	"InventoryController",
	"SafeController",
	"HUDController",
	"WormVisionController",
	"MinigameController",
	"GhostController",
}

local controllersFolder = script:FindFirstChild("Controllers")
local logging = GameConfig.Debug.Enabled and GameConfig.Debug.LogBootstrap

Net.init()

local loaded: { { name: string, controller: Controller } } = {}
for _, name in CONTROLLER_ORDER do
	local module = controllersFolder and controllersFolder:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then
		table.insert(loaded, { name = name, controller = (require :: any)(module) })
	end
end

for _, entry in loaded do
	if entry.controller.init then
		entry.controller.init()
	end
end
for _, entry in loaded do
	if entry.controller.start then
		entry.controller.start()
	end
end

if logging then
	print(`[Client] Bootstrapped {#loaded}/{#CONTROLLER_ORDER} controllers`)
end
