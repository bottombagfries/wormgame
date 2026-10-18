--!strict
-- CollectionService tag names (§4) so nothing hardcodes a tag string.

local Tags = {
	-- Map markers
	Sand = "Sand",
	TrainSpot = "TrainSpot",
	RanchSpot = "RanchSpot",
	TownHouseSpot = "TownHouseSpot",
	TownWell = "TownWell",
	ChurchSpot = "ChurchSpot",
	QuarrySpot = "QuarrySpot",
	LookoutSpot = "LookoutSpot",
	TraincarSpot = "TraincarSpot",
	BrokenTrackSpot = "BrokenTrackSpot",
	StagecoachSpot = "StagecoachSpot",
	SignalFireSpot = "SignalFireSpot",
	DigArea = "DigArea",
	LooseItemArea = "LooseItemArea",
	CactusSpot = "CactusSpot",

	-- Runtime
	Item = "Item",
	Train = "Train",
	Ghost = "Ghost", -- ghost models; attributes: OwnerUserId, PushReadyAt
	SafeDigit = "SafeDigit", -- OpenSafe digit signs; attributes: Digit, Order (0 = not part of the code)
	Cattlebug = "Cattlebug", -- cattlebug NPC models; attribute Penned
	Worm = "Worm", -- worm models; attributes: OwnerUserId, Mode, Health, BurrowLocked, RingCenter, Sneaking, PounceReadyAt
}

-- Every tag MapService expects at least one marker for.
local MapMarkers = {
	Tags.Sand,
	Tags.TrainSpot,
	Tags.RanchSpot,
	Tags.TownHouseSpot,
	Tags.TownWell,
	Tags.ChurchSpot,
	Tags.QuarrySpot,
	Tags.LookoutSpot,
	Tags.TraincarSpot,
	Tags.BrokenTrackSpot,
	Tags.StagecoachSpot,
	Tags.SignalFireSpot,
	Tags.DigArea,
	Tags.LooseItemArea,
	Tags.CactusSpot,
}

-- Tags whose markers are regions rather than points.
local Volumes = {
	[Tags.Sand] = true,
	[Tags.DigArea] = true,
	[Tags.LooseItemArea] = true,
}

return {
	Tags = Tags,
	MapMarkers = MapMarkers,
	Volumes = Volumes,
}
