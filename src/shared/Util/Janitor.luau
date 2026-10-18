--!strict
-- Collects connections/instances/callbacks/threads and cleans them all up at once.

export type Janitor = {
	add: <T>(self: Janitor, object: T) -> T,
	cleanup: (self: Janitor) -> (),
	destroy: (self: Janitor) -> (),
}

local function cleanupObject(object: any)
	local kind = typeof(object)
	if kind == "RBXScriptConnection" then
		object:Disconnect()
	elseif kind == "Instance" then
		object:Destroy()
	elseif kind == "function" then
		object()
	elseif kind == "thread" then
		pcall(task.cancel, object)
	elseif kind == "table" then
		if type(object.destroy) == "function" then
			object:destroy()
		elseif type(object.Destroy) == "function" then
			object:Destroy()
		elseif type(object.disconnect) == "function" then
			object:disconnect()
		elseif type(object.Disconnect) == "function" then
			object:Disconnect()
		end
	end
end

local JanitorUtil = {}

function JanitorUtil.new(): Janitor
	local objects: { any } = {}

	local function cleanup(_self: Janitor)
		-- Reverse order, and tolerate objects being added during cleanup.
		while #objects > 0 do
			cleanupObject(table.remove(objects))
		end
	end

	local janitor: Janitor = {
		add = function<T>(_self: Janitor, object: T): T
			table.insert(objects, object)
			return object
		end,
		cleanup = cleanup,
		destroy = cleanup,
	}
	return janitor
end

return JanitorUtil
