--!strict
-- Phase 13 player settings (the lobby's Settings window). Saved per player (DataService).

return {
	Defaults = {
		MusicVolume = 0.6, -- 0..1, scales the Music sound group
		SfxVolume = 1, -- 0..1, scales game and UI sounds
		CameraSensitivity = 1, -- multiplies UserInputService.MouseDeltaSensitivity
		WormMouthView = false, -- the Worm's camera sits in its mouth (first person)
	},
	CameraSensitivityMin = 0.2,
	CameraSensitivityMax = 2.5,
	SliderStep = 0.05, -- sliders snap to this

	-- The Worm's first-person "mouth view".
	MouthView = {
		Zoom = 0.5, -- camera zoom distance (Roblox goes first person under ~0.5)
		ForwardOffset = 5.5, -- studs in front of the head's center, so the camera isn't inside the head
		UpOffset = 1,
	},

	-- Background music (looped, silent while the id is empty). Match = the synthesized desert wind.
	Music = {
		Lobby = { id = "", volume = 0.5 },
		Match = { id = "rbxassetid://72752124980275", volume = 0.4 },
		FadeSeconds = 1.5,
	},
}
