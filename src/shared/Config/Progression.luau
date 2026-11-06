--!strict
-- Saved player data (DataService): Settings-window values, the chosen worm skin and lifetime stats. All TUNE.

return {
	DataStoreName = "PlayerData_v1", -- change the suffix to start everyone fresh
	KeyPrefix = "player_",
	SchemaVersion = 1,
	AutosaveSeconds = 120,
	LoadRetries = 4,
	RetryBaseSeconds = 1.5, -- doubles each retry
	-- Another server that saved within this long is treated as still holding the player's data (session
	-- lock); after LockWaitTries waits the lock is taken over (that server likely crashed).
	LockSeconds = 300,
	LockWaitTries = 3,
	LockWaitSeconds = 4,
	SettingsSaveDelay = 1.5, -- the client waits this long after the last settings change before sending them
}
