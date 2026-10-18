--!strict
-- Minimal pure-Luau signal for module-to-module events.

export type Connection = {
	connected: boolean,
	disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	fire: (self: Signal<T...>, T...) -> (),
	destroy: (self: Signal<T...>) -> (),
}

local SignalUtil = {}

function SignalUtil.new<T...>(): Signal<T...>
	local handlers: { [Connection]: (T...) -> () } = {}

	local function connect(_self: Signal<T...>, handler: (T...) -> ()): Connection
		local connection: Connection
		connection = {
			connected = true,
			disconnect = function(_conn: Connection)
				connection.connected = false
				handlers[connection] = nil
			end,
		}
		handlers[connection] = handler
		return connection
	end

	local signal: Signal<T...>
	signal = {
		connect = connect,
		once = function(self: Signal<T...>, handler: (T...) -> ()): Connection
			local connection: Connection
			connection = connect(self, function(...)
				connection:disconnect()
				handler(...)
			end)
			return connection
		end,
		fire = function(_self: Signal<T...>, ...)
			for _, handler in table.clone(handlers) do
				task.spawn(handler, ...)
			end
		end,
		destroy = function(_self: Signal<T...>)
			for connection in handlers do
				connection.connected = false
			end
			table.clear(handlers)
		end,
	}
	return signal
end

return SignalUtil
