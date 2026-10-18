--!strict
-- Server bootstrap: creates remotes, then calls every Service's init(), then every start() (§16).
-- Services listed here but not built yet are skipped, so later phases just drop the file in.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Net = require(ReplicatedStorage.Shared.Net)

type Service = {
	init: (() -> ())?,
	start: (() -> ())?,
}

local SERVICE_ORDER = {
	"MapService",
	"StructureService",
	"ItemService",
	"PardnerService",
	"CosmeticsService",
	"WormService",
	"DetectionService",
	"AbilityService",
	"ExplosionService",
	"DigService",
	"NPCService",
	"ReviveService",
	"TrainService",
	"KitService",
	"ObjectiveService",
	"MatchService",
	"DebugService",
}

local servicesFolder = script:FindFirstChild("Services")
local logging = GameConfig.Debug.Enabled and GameConfig.Debug.LogBootstrap

Net.init()

local loaded: { { name: string, service: Service } } = {}
for _, name in SERVICE_ORDER do
	local module = servicesFolder and servicesFolder:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then
		table.insert(loaded, { name = name, service = (require :: any)(module) })
	end
end

for _, entry in loaded do
	if entry.service.init then
		entry.service.init()
	end
end
for _, entry in loaded do
	if entry.service.start then
		entry.service.start()
	end
end

if logging then
	local names = {}
	for _, entry in loaded do
		table.insert(names, entry.name)
	end
	print(`[Server] Bootstrapped {#loaded}/{#SERVICE_ORDER} services: {table.concat(names, ", ")}`)
end
