# Phase Test Checklist

Tick each box in Studio before moving on. Every phase also needs:
- [ ] No red errors in Output (warnings are ok if you know why)
- [ ] `selene src` passes with no errors
- [ ] Everything from earlier phases still works
- [ ] PROGRESS.md updated, Git commit made

**2P test** = Studio Test tab → Clients and Servers → 2 players → Start.

---

## Phase 1 — Skeleton
- [ ] `rojo serve` runs, Studio connects, files show up in Explorer
- [ ] Editing a file in Zed updates Studio within a second
- [ ] Play → flat sand map spawns
- [ ] A few greybox items spawn with floating name labels
- [ ] Drop a test Model named after an item (e.g. `SmallCoal`) into `ReplicatedStorage/Assets/Items` → it replaces the grey box
- [ ] That test model is still there after Rojo re-syncs (not deleted)
- [ ] `ReplicatedStorage/Remotes` folder exists with remotes inside

## Phase 2 — Pardner basics
- [ ] Walk, sprint, jump work
- [ ] Sprinting drains stamina; can't sprint at 0; refills when stopped
- [ ] Can still jump at 0 stamina
- [ ] Climb a wall; grip drains while climbing
- [ ] Grip at 0 → stamina drains; both at 0 → you fall off
- [ ] Jumping while climbing takes a chunk of grip
- [ ] Aim mode (right-click) switches to over-the-shoulder camera
- [ ] Health, stamina, grip bars show and update
- [ ] Lowering health lowers max stamina, but never below 40%

## Phase 3 — Items & inventory
- [ ] Pick up a size-1 item → goes into bag
- [ ] Bag holds 3 slots; 4th item is refused
- [ ] Size 2/3 items take the right number of slots
- [ ] Size X item (Barrel) can only be held, not bagged
- [ ] Kit item goes into the kit slot; picking another kit swaps them and drops the old one
- [ ] Backpack → bag becomes 5; second backpack → 7; can't drop it
- [ ] Take an item out of the bag and hold it
- [ ] Throw with and without aim; aim shows an arc
- [ ] Climbing while holding something drops it
- [ ] Can stand on items without sliding
- [ ] Hover label shows name / size / fuel
- [ ] 2P: other player sees you holding and throwing items

## Phase 4 — Train & fuel
- [ ] Train and Watertower spawn in the center
- [ ] Throwing a fuel item into the furnace deletes it and adds fuel
- [ ] Non-fuel items don't add fuel
- [ ] Fuel meter shows 0–100 and fills at the right rate
- [ ] Lever is locked until objectives are done
- [ ] Pulling the lever starts a 2:00 timer
- [ ] All living Pardners on the Train for 5s → leaves early
- [ ] On the Train when it leaves = escaped; off = dead
- [ ] Horn plays, then 3 min cooldown; lever locked 12s after the horn
- [ ] 8 shovels, 3 crates, and ladders spawn at the Train

## Phase 5 — Match flow
- [ ] Lobby → roles → worm loadout → playing → end → back to lobby
- [ ] 2P: one player is the Worm, the other a Pardner
- [ ] Worm can pick exactly 2 abilities in the loadout screen
- [ ] Sundown timer counts down and turns it night when it hits 0
- [ ] Changing difficulty changes the numbers (e.g. fuel needed)
- [ ] Objective count matches the player-count table
- [ ] Fuel the Train is always active
- [ ] End screen shows who escaped / died and who won
- [ ] Second match starts clean (no leftover items, timers, UI)

## Phase 6 — Worm core (all 2P)
- [ ] Worm moves underground fast and surfaces/launches
- [ ] Worm can only burrow on sand
- [ ] Segments follow the head smoothly
- [ ] Pardner running on sand → red ping for the Worm
- [ ] Pardner standing still → no ping
- [ ] Pardner moving on a roof, rock, or item → no ping
- [ ] Worm can't see Pardners that aren't pinging
- [ ] Pounce grabs a Pardner → Pardner loses 5 HP, then drains
- [ ] Mouth minigame: right arrows fill the bar, wrong ones drop it, checkpoints hold
- [ ] Drop key → auto-escape in about 5.5s
- [ ] Escaping → Worm takes damage and is forced to burrow; Pardner gets adrenaline
- [ ] Worm heals faster the farther it goes from where it got hurt (3 rings)
- [ ] Pounced items get swallowed
- [ ] Worm can't speed hack (server snaps it back)

## Phase 7 — Death & revive
- [ ] Eaten → heart jar drops after about 60s at the Worm's spot
- [ ] Each cactus fruit eaten before dying adds 20s
- [ ] Any other death → jar drops right away
- [ ] Dead player becomes a ghost and can fly
- [ ] Ghost is invisible to the Worm and living Pardners
- [ ] Ghost push: hold to charge, arrow shows direction, 25s cooldown
- [ ] Two ghosts pushing the same item push it farther
- [ ] Jar dropped in the Church ring → revive at the Church
- [ ] Each revive lowers max HP by 25% (min 10)
- [ ] No Church revives after sundown
- [ ] Revive limit hit → jar turns ossified, Church won't take it
- [ ] Revive resets the Train timer

## Phase 8 — Map population
- [ ] Every marker type spawns its thing (or warns clearly if missing)
- [ ] Houses spawn with random variant, color, and tier loot
- [ ] Ranches have a house + shelter; Pardners spawn at ranches
- [ ] 3 lookout towers, spread out, each with a ladder and 2 chests
- [ ] Chests have 1 kit each; guaranteed kits always show up somewhere
- [ ] Town well: tin can by default; token every 35s (max 2) gives better fuel
- [ ] Quarry dynamite respawns every 90s
- [ ] Dynamite: light it, it explodes, kills Pardners in range, damages Worm
- [ ] Dynamite destroys a house → 1 scrap drops, loot spills out
- [ ] Dynamite chain-lights nearby dynamite
- [ ] Pounce damages structures; traincars can't be hurt by the Worm
- [ ] Collapsing structure kills Pardners inside it
- [ ] Map looks different each match

## Phase 9 — Objectives (test each one alone)
- [ ] **Find Train Key:** metal detector % goes up near the key; horseshoes fool it; dig with shovel or dynamite; key goes in the Train
- [ ] **Signal Fires:** light a tumbleweed at the furnace; it burns out after 80s; carry to a fire to light it; new tumbleweeds respawn
- [ ] **Cattlebugs:** bugs wander; throw dandylions to lead them; max 4 dandylions per player; bug behind caboose counts
- [ ] **Repair Tracks:** 6 traincars spawn; blow them up for 3 scrap each; 2 scrap fixes a track
- [ ] **Sassparilla:** 2 stagecoaches, 2 crates each; dropping breaks bottles; delivering counts bottles; new crate spawns
- [ ] **Safe:** puzzle map shows digits and safe; recording a digit shows on everyone's map; right code opens it; manual completes it
- [ ] Vending machine gives a map / dandylion bundle every 2 min
- [ ] Inactive objectives don't spawn their stuff
- [ ] All objectives done → lever unlocks

## Phase 10 — Kit items (use `/give <id>` in Studio)
- [ ] Bullworm Rifle: one shot, −40% Worm HP, frees grabbed Pardner, recoil
- [ ] Cactus Seed Pouch: 7 cactuses, small near Train
- [ ] Canteen: sprint/jump use less stamina
- [ ] Coffee Tin: 3 uses, speed boost, reveals you to the Worm
- [ ] Cymbal Monkey: Worm loses vision for 12s
- [ ] Spirit Board: see ghosts, speed per ghost, faster ghost pushes
- [ ] Mysterious Concoction: 3 uses, random effects
- [ ] Book of the Dead: revive from a held jar, costs 35 HP
- [ ] Pogo Stick: 5 launches
- [ ] Quick Escape Knife: instant mouth escape, auto-uses at 0 HP
- [ ] Slingshot: throws go 50% farther
- [ ] Snake Oil: +10% speed, heals on escape, one buff per player
- [ ] Zipline Crossbow: makes a rideable zipline
- [ ] Every kit disappears when its uses run out

## Phase 11 — Worm abilities (2P)
- [ ] Cooldowns show on the Worm HUD
- [ ] Sneak: no rumble while moving
- [ ] Sonar Scream: reveals Pardners/props in range for 6s
- [ ] Sinkhole: Pardners inside slowed 80%
- [ ] Sandstorm: tornado flings things, reveals caught Pardners
- [ ] Armored Carapace: blocks one hit, one-shots a structure, sand blast debuff
- [ ] Stealth: totally silent for 20s or until pounce
- [ ] Bodyslam: mid-air only, crater, 10 dmg, digs up buried stuff
- [ ] Tar Wall: Pardners can't pass, Worm can
- [ ] Sandtrap: catches Pardner, minigame, dynamite breaks it
- [ ] Bile Bomb: sticks, explodes after 3.5s for 20 dmg
- [ ] Magma Trail: underground only, burning patches
- [ ] Abilities blocked in the wrong state (e.g. Tar Wall mid-air)

## Phase 12 — Sundown & polish
- [ ] At 66% to sundown, 5 chests drop from the sky
- [ ] After sundown: shorter Worm cooldowns, map-wide scream, faster ring healing
- [ ] Low-HP Pardners get topped up at sundown
- [ ] Balloon (if on): shows up when 1 Pardner is left, ladder = escape
- [ ] Revive while balloon is waiting → it leaves and comes back later
- [ ] Sound hooks fire (even if they're placeholder IDs)
- [ ] Full match with 3+ players from lobby to end screen, no errors

## Phase 13 — Lobby & UI overhaul
**Step 1 — Theme & components**
- [ ] Sample panel, button and bar look like the approved western style
- [ ] Buttons grow on hover, shrink on press, and play a click hook
- [ ] Bar fill tweens, with a ghost fill trailing behind after a drop
- [ ] Text stays readable at phone size and 1080p (Device emulator)

**Step 2 — Round loop & lobby**
- [ ] 1 player: lobby shows "Waiting for players"; 2P: intermission counts down
- [ ] Countdown → roles → reveal → loadout → teleported to the map → match → results → back in the lobby
- [ ] Map is far from the lobby and completely gone after the round (Workspace clean)
- [ ] Lobby train station: platform, benches, ticket booth, big board with countdown + last result
- [ ] Spawn pads work; invisible walls keep you in; no damage or combat in the lobby
- [ ] Someone joining mid-round waits in the lobby

**Step 3 — Role roll & reveal**
- [ ] AFK players are never picked
- [ ] Worm chance goes up each round you aren't the Worm, resets when you are
- [ ] Full-screen role card with color, text, sound and animation
- [ ] Worm gets the ability pick with a timer right after the card

**Step 4 — Lobby HUD, spectate, AFK**
- [ ] HUD shows countdown, player count, your Worm chance %
- [ ] Shop / Inventory / Settings / Spectate / AFK buttons all open or toggle something
- [ ] Spectate cycles living players and shows name + role

**Step 5 — In-match HUD & toasts**
- [ ] Pardner and Worm HUDs use the new theme, nothing overlaps at phone size
- [ ] Toasts: "X was eaten", "Objective complete", "Sundown!"

**Step 6 — Results, settings, shop**
- [ ] Results: winner banner, escaped / died lists, round stats
- [ ] Settings: music + SFX volume, camera sensitivity, worm mouth-view toggle, all saved for the session
- [ ] Shop lists game passes; nothing in it changes Worm chance or gameplay

---

## Final full-game test
- [ ] Play 3 full matches in a row without rejoining
- [ ] Pardners can win; Worm can win
- [ ] Nothing piles up between matches (check Workspace for leftover junk)
- [ ] Server memory stays steady (Developer Console → Memory)
