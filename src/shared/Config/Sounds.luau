--!strict
-- Sound hooks (Phase 12). Game code calls SoundCue.play("<Key>", position?) on the server and every client
-- plays the matching sound here. All sounds are originals synthesized by tools/audio/synth_sfx.py (assets/audio)
-- and uploaded with tools/upload_asset.ps1 -Type Audio. An empty id is silent.

export type SoundDef = {
	id: string,
	volume: number,
	positional: boolean, -- true = plays at the given position (falls off with distance); false = everywhere
}

local Sounds: { [string]: SoundDef } = {
	Explosion = { id = "rbxassetid://103588056267140", volume = 1, positional = true },
	TrainHorn = { id = "rbxassetid://137616711658254", volume = 1, positional = false },
	LeverPulled = { id = "rbxassetid://74850425269650", volume = 0.8, positional = false },
	FurnaceBurn = { id = "rbxassetid://121568812319537", volume = 0.6, positional = true },
	Pounce = { id = "rbxassetid://121546431918345", volume = 0.8, positional = true },
	Grab = { id = "rbxassetid://128369179367230", volume = 1, positional = true },
	MouthEscape = { id = "rbxassetid://133639807161122", volume = 1, positional = true },
	SonarScream = { id = "rbxassetid://126529938415512", volume = 1, positional = true },
	ChestOpen = { id = "rbxassetid://82453744343542", volume = 0.7, positional = true },
	Dig = { id = "rbxassetid://86887523726547", volume = 0.6, positional = true },
	Revive = { id = "rbxassetid://95697742528791", volume = 0.8, positional = true },
	Airdrop = { id = "rbxassetid://80108830880633", volume = 0.8, positional = true },
	BalloonArrives = { id = "rbxassetid://112790396401647", volume = 1, positional = false },
	Sundown = { id = "rbxassetid://72073147037267", volume = 1, positional = false },
	Pickup = { id = "rbxassetid://105003291032266", volume = 0.5, positional = true },
	Throw = { id = "rbxassetid://120965256768004", volume = 0.5, positional = true },

	-- UI (Phase 13): played on the local client only, never sent over the network.
	UiClick = { id = "rbxassetid://116582293269664", volume = 0.5, positional = false },
	UiHover = { id = "rbxassetid://99620127935247", volume = 0.25, positional = false },
	UiError = { id = "rbxassetid://112522141786859", volume = 0.5, positional = false },
	UiObjective = { id = "rbxassetid://95289435631443", volume = 0.7, positional = false },
	UiReveal = { id = "rbxassetid://140191708238475", volume = 0.9, positional = false },
	UiKill = { id = "rbxassetid://108220424265415", volume = 0.6, positional = false },
}

return Sounds
