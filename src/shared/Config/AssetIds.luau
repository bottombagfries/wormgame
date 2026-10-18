--!strict
-- Uploaded Roblox asset ids for the real models (Blender → Open Cloud). The game never reads these at
-- runtime: AssetService clones the Models in ReplicatedStorage/Assets. This file is the record used to
-- rebuild those Models if the place file loses them. See assets/ASSET_STATUS.md.

export type MeshRecord = {
	mesh: number, -- MeshPart.MeshId
	model: number, -- the uploaded FBX (Model asset) the mesh came from
}

return {
	-- The shared palette texture every mesh uses (MeshPart.TextureID).
	PaletteImage = 81576212373708,
	PaletteDecal = 86148081784505,

	Meshes = {
		SmallCoal = { mesh = 125357970700665, model = 96698677008646 },
		BigCoal = { mesh = 92323673507845, model = 121593929184947 },
		Barrel = { mesh = 118945128255384, model = 140235735792006 },
		Dynamite = { mesh = 71837835385387, model = 115428340223156 },
		Lantern = { mesh = 104761163506498, model = 86815227839969 },
		MassiveCoal = { mesh = 117148276570207, model = 124974139692198 },
		Gramophone = { mesh = 133236912473911, model = 77312612981606 },
		Pew = { mesh = 132054673747691, model = 123904611447896 },
		Bench = { mesh = 122101008411725, model = 75058370302979 },
		DutchOven = { mesh = 87796423977176, model = 128151336474148 },
		Pulpit = { mesh = 133370098887782, model = 80327494025723 },
		Table = { mesh = 127184651190371, model = 113519606721833 },
		Chair = { mesh = 119642458351746, model = 139726008723937 },
		Bed = { mesh = 70816773898103, model = 110793882072819 },
		GrainSack = { mesh = 91364001204248, model = 139003056270477 },
		Bucket = { mesh = 82992322148932, model = 137236977892239 },
		CoffeePot = { mesh = 104429985808819, model = 78281093363949 },
		Skillet = { mesh = 71284956684494, model = 125859906363439 },
		Stool = { mesh = 113772995679889, model = 90168294938363 },
		Painting = { mesh = 117355881710273, model = 78693415475334 },
		CactusFruit = { mesh = 84065548798626, model = 76462769332474 },
		Horseshoe = { mesh = 124200699583009, model = 85229762218998 },
		RustyTinCan = { mesh = 130607177884237, model = 85430800975293 },
		TrainKey = { mesh = 119382825257933, model = 92458796697415 },
		Scrap = { mesh = 127439780786166, model = 107780529858887 },
		Tumbleweed = { mesh = 83327054695790, model = 116181149210183 },
		SassparillaCrate = { mesh = 87637579250766, model = 129679808607369 },
		PuzzleMap = { mesh = 123275228419810, model = 134730348931891 },
		TrainManual = { mesh = 84506657774970, model = 124681527552662 },
		Backpack = { mesh = 74332654114504, model = 104320639263764 },
		HeartJar = { mesh = 126069842275169, model = 138623719464649 },
		Ladder = { mesh = 106814995987948, model = 104214320570790 },
		Crate = { mesh = 109042375497300, model = 124419707570849 },
		CursedTrinket = { mesh = 116243236658262, model = 74828224089317 },
		Chest = { mesh = 108913867807182, model = 75806933679570 },
		BullwormRifle = { mesh = 114451351519734, model = 76106049004539 },
		CactusSeedPouch = { mesh = 115728969045449, model = 72162690783314 },
		Canteen = { mesh = 111027158605111, model = 107188124523840 },
		CoffeeTin = { mesh = 74814547421415, model = 108731564622244 },
		CymbalMonkey = { mesh = 86655158066811, model = 87989089587721 },
		DandylionBundle = { mesh = 97773929230344, model = 122734199222657 },
		SpiritBoard = { mesh = 106944956520757, model = 105474377431627 },
		MysteriousConcoction = { mesh = 131313862196668, model = 98122001045434 },
		DeadBook = { mesh = 72054936438741, model = 132672228179030 },
		PogoStick = { mesh = 114660510205701, model = 82532862229000 },
		QuickEscapeKnife = { mesh = 129944764911541, model = 124552827525794 },
		Shovel = { mesh = 101538377720437, model = 101773361827412 },
		Slingshot = { mesh = 118354182828065, model = 105798274577652 },
		SnakeOil = { mesh = 134182757651707, model = 131253571228341 },
		ZiplineCrossbow = { mesh = 119504241710647, model = 90432910705442 },
		Balloon = { mesh = 90026093896863, model = 102114759159123 },
		Cattlebug = { mesh = 77067685309542, model = 126550343697695 },
		Ghost = { mesh = 110904211318473, model = 100121410318883 },
		WormHead = { mesh = 118277399072268, model = 84180656297074 },
		WormSegment = { mesh = 123679613554422, model = 111933302346948 },
		BileBomb = { mesh = 124330872664241, model = 139973941142900 },
		CactusSeed = { mesh = 79465596071647, model = 99604529300757 },
		Crater = { mesh = 99843626991837, model = 76571280066781 },
		Dandylion = { mesh = 136745706676930, model = 124870871301566 },
		DigHole = { mesh = 109225681240080, model = 95125092394476 },
		MagmaPatch = { mesh = 122300292452964, model = 134914562708401 },
		RifleTracer = { mesh = 75703948472638, model = 75225380748445 },
		SandtrapZone = { mesh = 121543072177129, model = 94607455161437 },
		SinkholeZone = { mesh = 70838426390061, model = 123111245010663 },
		TarSpire = { mesh = 88221661465480, model = 94643867974105 },
		Tornado = { mesh = 82185414314312, model = 140561811416888 },
		ZiplineRope = { mesh = 105393776963534, model = 92073840449161 },
		BalloonLadder = { mesh = 125273070008709, model = 80082458830379 },
		CactusSmall = { mesh = 122770933499662, model = 134460054455332 },
		CactusTall = { mesh = 96793561315622, model = 75649776508208 },
		Safe = { mesh = 78689289406050, model = 97462837139757 },
		SafeDigitSign = { mesh = 106436304171708, model = 140191854151807 },
		Skeleton = { mesh = 79056583509185, model = 118865733870659 },
		TrainFurnace = { mesh = 103275726378785, model = 124574606823812 },
		TrainHorn = { mesh = 130174075104700, model = 119383852315759 },
		TrainKeyhole = { mesh = 130845918075405, model = 122365453924700 },
		TrainLever = { mesh = 87766750666386, model = 77514202109228 },
		VendingMachine = { mesh = 73702795187202, model = 109386727824263 },
		-- Lobby station (Phase 13)
		LobbyBench = { mesh = 75648135159826, model = 89643827205478 },
		LobbyGround = { mesh = 122022394204587, model = 127883280147723 },
		LobbyLamp = { mesh = 116556373681543, model = 107570775533141 },
		LobbySteps = { mesh = 130170019305368, model = 72260182790306 },
	} :: { [string]: MeshRecord },

	-- Models made of several named MeshParts (structures): part name -> MeshId. Wall/Roof/Trim/Kindling/Rails
	-- are untextured so game code can recolor them; Detail/Trim do not collide.
	Multi = {
		BrokenTrack = { model = 111219616630458, parts = { Rails = 121281138161442, Ties = 96340354494669 } },
		Church = {
			model = 92900111532125,
			parts = {
				Detail = 130047648072525,
				Floor = 122236133091013,
				Roof = 130602412481196,
				Walls = 115590622177830,
			},
		},
		HouseLarge = {
			model = 138081413844364,
			parts = {
				Detail = 114833923305933,
				Floor = 111529989167412,
				Roof = 136417418749757,
				Trim = 136023384051327,
				Wall = 73585404790372,
			},
		},
		HouseMedium = {
			model = 128970510108992,
			parts = {
				Detail = 117793454164376,
				Floor = 95284340637753,
				Roof = 105980179205654,
				Trim = 100158763424894,
				Wall = 101639287058316,
			},
		},
		HouseSmall = {
			model = 97804381389473,
			parts = {
				Detail = 134734885063703,
				Floor = 122239942782930,
				Roof = 123126271188160,
				Trim = 75938560616255,
				Wall = 88231493447995,
			},
		},
		HouseTall = {
			model = 79260648884685,
			parts = {
				Detail = 95315985540006,
				Floor = 127357502738964,
				Roof = 115278548032318,
				Trim = 115071911667446,
				Wall = 83892910634041,
			},
		},
		HouseTwoStory = {
			model = 105108909282814,
			parts = {
				Detail = 128439590340817,
				Floor = 88847193633529,
				Roof = 124392497421268,
				Trim = 73253436743491,
				Wall = 96324274776018,
			},
		},
		LookoutTower = {
			model = 134466408937950,
			parts = { Deck = 85379613152922, Frame = 128395631424878, Ladder = 71044078723607, Rail = 76455628821133 },
		},
		QuarryMinecart = { model = 138059542318045, parts = { Cart = 84524631757780, Wheels = 129840294101031 } },
		Shelter = {
			model = 72465414191034,
			parts = { Deck = 112030393179683, Detail = 94864425292033, Frame = 75702589813189 },
		},
		SignalFire = {
			model = 86954150859661,
			parts = { Kindling = 81925889884013, Logs = 84924718173184, Stones = 90094198211805 },
		},
		Stagecoach = {
			model = 123077049382837,
			parts = { Body = 101488249049797, Detail = 124488225034114, Wheels = 108893723970318 },
		},
		TownWell = {
			model = 114300114981711,
			parts = { Detail = 134430223457827, Ring = 92528972388050, Roof = 125960187799470 },
		},
		Train = {
			model = 71186679820825,
			parts = { Deck = 115488860060664, Detail = 137567532094738, Frame = 77437758904181 },
		},
		Traincar = {
			model = 106352091486705,
			parts = { Car = 137452862870963, Detail = 131015221042044, Sand = 136863024462489 },
		},
		Watertower = {
			model = 130395105292095,
			parts = {
				Deck = 132393579292265,
				Frame = 120326698079554,
				Ladder = 130199439100026,
				Tank = 128409049898691,
			},
		},
		-- Lobby station (Phase 13): every part textured; Detail does not collide; LobbyBoard.Screen holds the
		-- departures text (SurfaceGui on its Front face).
		LobbyBoard = {
			model = 100961181328186,
			parts = { Detail = 70857325126277, Frame = 72285319738380, Screen = 86099192794400 },
		},
		LobbyDepot = {
			model = 113045279668002,
			parts = { Detail = 115081921873503, Roof = 82245410907499, Wall = 130460289893418 },
		},
		LobbyPlatform = {
			model = 75240283348282,
			parts = { Base = 88642964795908, Deck = 100885071806699, Detail = 74473247410422 },
		},
		LobbyTicketBooth = {
			model = 129243702915770,
			parts = { Detail = 86369668494112, Roof = 115266202407703, Wall = 88534139727081 },
		},
		LobbyTrack = { model = 123769058159554, parts = { Rails = 126588210309214, Ties = 113050319227583 } },
	} :: { [string]: { model: number, parts: { [string]: number } } },
}
