--!strict
-- Picks the objectives for a match (§5.3), tracks their progress and replicates the checklist with
-- State_Objectives. When all are done it unlocks the Train's lever.
--
-- Each objective is a module in server/Objectives named after its id (Types.ObjectiveModule).
-- Objectives with no module yet (Phase 9) are never picked.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Objectives = require(ReplicatedStorage.Shared.Config.Objectives)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local RandomUtil = require(ReplicatedStorage.Shared.Util.Random)
local TrainService = require(script.Parent.TrainService)

type Active = {
	def: Types.ObjectiveDef,
	module: Types.ObjectiveModule,
}

local ObjectiveService = {}

local objectivesRemote: RemoteEvent
local notifyRemote: RemoteEvent
local active: { Active } = {}
local lastSent: { Types.ObjectiveProgress } = {}
local pollTimer = 0
local leverUnlocked = false

local function getModule(id: string): Types.ObjectiveModule?
	local folder = script.Parent.Parent:FindFirstChild("Objectives")
	local module = folder and folder:FindFirstChild(id)
	if module and module:IsA("ModuleScript") then
		return (require :: any)(module) :: Types.ObjectiveModule
	end
	return nil
end

local function wantedCount(context: Types.ObjectiveContext): number
	if context.settings.objectiveCountMode == "Flat" then
		return context.settings.objectiveCountFlat
	end
	local byPardners = GameConfig.ObjectiveCountByPardners
	return byPardners[math.clamp(context.pardnerCount, 1, #byPardners)]
end

local function collectProgress(): { Types.ObjectiveProgress }
	local list = {}
	for _, entry in active do
		local current, target = entry.module.getProgress()
		table.insert(list, {
			id = entry.def.id,
			displayName = entry.def.displayName,
			current = current,
			target = target,
			done = current >= target,
		})
	end
	return list
end

local function changed(list: { Types.ObjectiveProgress }): boolean
	if #list ~= #lastSent then
		return true
	end
	for index, progress in list do
		local previous = lastSent[index]
		if previous.id ~= progress.id or previous.current ~= progress.current or previous.target ~= progress.target then
			return true
		end
	end
	return false
end

local function update(force: boolean?)
	local list = collectProgress()
	if force or changed(list) then
		-- A toast for every objective that just finished (not on the first send of a match).
		if not force then
			for _, progress in list do
				local wasDone = false
				for _, previous in lastSent do
					if previous.id == progress.id then
						wasDone = previous.done
					end
				end
				if progress.done and not wasDone then
					notifyRemote:FireAllClients(`Objective complete: {progress.displayName}`, "Objective")
				end
			end
		end
		lastSent = list
		objectivesRemote:FireAllClients(list)
	end

	if #list > 0 and not leverUnlocked then
		for _, progress in list do
			if not progress.done then
				return
			end
		end
		leverUnlocked = true
		TrainService.unlockLever()
		notifyRemote:FireAllClients("Every objective is done - pull the Train's lever!", "Objective")
	end
end

-- Chooses and sets up this match's objectives. "Fuel the Train" is always in and counts toward the total.
function ObjectiveService.begin(context: Types.ObjectiveContext)
	ObjectiveService.finish()

	local chosen: { string } = {}
	local candidates: { string } = {}
	for id, def in Objectives do
		if not context.settings.enabledObjectives[id] or not def.countsTowardTotal then
			continue -- EscapeBalloon is handled by TrainService/NPCService and never counts (§5.3)
		end
		if def.always then
			table.insert(chosen, id)
		elseif getModule(id) then
			table.insert(candidates, id)
		end
	end
	table.sort(candidates) -- dictionary order is arbitrary; keep the random pick reproducible

	local wanted = wantedCount(context)
	for _, id in RandomUtil.sample(candidates, math.max(0, wanted - #chosen)) do
		table.insert(chosen, id)
	end
	if GameConfig.Debug.Enabled and #chosen < wanted then
		print(`[ObjectiveService] Wanted {wanted} objectives but only {#chosen} are implemented so far`)
	end

	-- Debug: objectives that are always in, so one can be tested solo.
	if GameConfig.Debug.Enabled then
		for _, id in GameConfig.Debug.ForceObjectives do
			if Objectives[id] and not table.find(chosen, id) then
				table.insert(chosen, id)
			end
		end
	end

	for _, id in chosen do
		local module = getModule(id)
		if module then
			module.setup(context)
			table.insert(active, { def = Objectives[id], module = module })
		else
			warn(`[ObjectiveService] Objective "{id}" has no module in server/Objectives`)
		end
	end
	update(true)
end

-- Cleans up every active objective (match over).
function ObjectiveService.finish()
	for _, entry in active do
		entry.module.cleanup()
	end
	table.clear(active)
	leverUnlocked = false
	pollTimer = 0
	lastSent = {}
	objectivesRemote:FireAllClients(lastSent)
end

function ObjectiveService.isActive(id: string): boolean
	for _, entry in active do
		if entry.def.id == id then
			return true
		end
	end
	return false
end

function ObjectiveService.init()
	objectivesRemote = Net.event("State_Objectives")
	notifyRemote = Net.event("Fx_Notify")
end

function ObjectiveService.start()
	Players.PlayerAdded:Connect(function(player)
		objectivesRemote:FireClient(player, lastSent)
	end)

	RunService.Heartbeat:Connect(function(dt)
		if #active == 0 then
			return
		end
		for _, entry in active do
			local step = entry.module.step
			if step then
				step(dt)
			end
		end
		pollTimer += dt
		if pollTimer >= GameConfig.MatchTickSeconds then
			pollTimer = 0
			update()
		end
	end)
end

return ObjectiveService
