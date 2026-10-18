--!strict
-- Sound hooks (Phase 12). Game code calls SoundCue.play("<Key>", position?) on the server and every client
-- plays the matching sound here. Ids are empty until real sounds exist — empty = silent.
-- TODO(asset): fill in every id ("rbxassetid://123456").

export type SoundDef = {
	id: string,
	volume: number,
	positional: boolean, -- true = plays at the given position (falls off with distance); false = everywhere
}

local Sounds: { [string]: SoundDef } = {
	Explosion = { id = "", volume = 1, positional = true },
	TrainHorn = { id = "", volume = 1, positional = false },
	LeverPulled = { id = "", volume = 0.8, positional = false },
	FurnaceBurn = { id = "", volume = 0.6, positional = true },
	Pounce = { id = "", volume = 0.8, positional = true },
	Grab = { id = "", volume = 1, positional = true },
	MouthEscape = { id = "", volume = 1, positional = true },
	SonarScream = { id = "", volume = 1, positional = true },
	ChestOpen = { id = "", volume = 0.7, positional = true },
	Dig = { id = "", volume = 0.6, positional = true },
	Revive = { id = "", volume = 0.8, positional = true },
	Airdrop = { id = "", volume = 0.8, positional = true },
	BalloonArrives = { id = "", volume = 1, positional = false },
	Sundown = { id = "", volume = 1, positional = false },

	-- UI (Phase 13): played on the local client only, never sent over the network. TODO(asset)
	UiClick = { id = "", volume = 0.5, positional = false },
	UiHover = { id = "", volume = 0.25, positional = false },
	UiError = { id = "", volume = 0.5, positional = false },
	UiObjective = { id = "", volume = 0.7, positional = false },
	UiReveal = { id = "", volume = 0.9, positional = false },
	UiKill = { id = "", volume = 0.6, positional = false }, -- TODO(asset): kill-feed sting
}

return Sounds
