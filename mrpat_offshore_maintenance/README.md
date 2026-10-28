# Offshore Maintenance

## Make the ocean pay

**Offshore Maintenance** is a civilian job for Qbox servers that finally gives players a reason to head out to sea. Players take a work vessel to navigation buoys and mooring floats, dive down to equipment and pump stations on the seabed, take a submarine to pipelines, cable junctions and hydraulic units far below, or hunt for leaking wrecks with a sonar. There they figure out what is broken, and fix it. No reskinned delivery route: the money comes from actually diagnosing the fault. Every completed repair earns experience, and higher levels unlock better-paid, deeper work.

## How a job plays

A job takes players from the harbor to open water and back, with a real decision in the middle.

1. **Pick a contract type** at the dock foreman (ox_target). The menu shows the player's level and an XP bar, and a statistics page with their repairs, lost vessels and abandoned contracts. Contract types they have not unlocked yet are greyed out, with the level they need.
2. **Pay the deposit** in cash or by bank. With a deposit of 0, this step is skipped.
3. **Head out** in the work vehicle, which the player is placed in straight away.
   - **Surface (from level 1):** a work vessel and a waypoint to a navigation buoy or a mooring float, which appears as the player approaches.
   - **Seabed (from level 6):** a work vessel, a search zone on the map instead of an exact point, and diving gear (a visible tank and mask). Anchor the vessel, dive down and find the equipment by its marker.
   - **Deep sea (from level 11):** a submarine and a search zone. The equipment sits between 80 and 140 metres down. Go too deep and the submarine warns of crush depth, so careless pilots lose their vehicle and their deposit.
   - **Wreck search (from level 16):** a submarine, a large search zone and a sonar that beeps faster the closer you get to a leaking wreck.
4. **Inspect** the equipment with a quick skill check to discover the symptom. From the vessel or in the water this is an ox_target option on the equipment; from the submarine a key prompt appears once you are close enough ("[E] Inspect equipment").
5. **Run diagnostics.** The tests depend on the equipment: navigation buoys get voltage, lamp and pressure tests, mooring floats get chain tension, buoyancy and mooring line checks, seabed and deep-sea equipment gets voltage, pressure and signal tests, pipelines also get a flow test, pump stations get voltage, pressure, flow and vibration tests, hydraulic units get voltage, pressure, signal and hydraulics tests, and wrecks get a leak trace and a hull scan. Each reading stays visible in the menu, next to the symptom.
6. **Choose the repair** from four options. Three are plausible decoys that only the readings rule out, and each repair has its own minigame. Once the repair is done, the job site disappears from the map.
7. **Wrong guess?** Try again. Every attempt costs real time, so careful players earn faster.
8. **Report back to the foreman** to end the job: pay and experience if the repair was done, plus the deposit if the vessel came back in one piece. Players get a notification when they reach a new level, and any diving gear comes off when the job ends. (Payout always goes to the bank.)

After a completed job, the next contract never sends a player to the same location, or gives them the same fault, twice in a row.

Now and then a contract turns out to be **urgent**. The player finds out right after taking it: finish the repair within the time limit and the job pays a bonus on top. Notifications count down the last minutes, and say whether the repair made it in time.

## Built for server owners

Every decision that touches money or progress is made on the server, so a modified client cannot pay or level itself.

- **Server-authoritative economy.** The server picks the fault, keeps the answer key, checks distances, levels, gear and payments, and pays out. The client only ever sees ids and locale keys.
- **Four tiers of progression.** Surface work on buoys and mooring floats from level 1, diving work on the seabed from level 6, deep-sea work by submarine from level 11, and searching for leaking wrecks with a sonar from level 16, over 20 levels. Every level within your highest tier adds a pay bonus, so experience pays off before the next tier unlocks. Levels, contract types, vehicles, pay and XP are all config, and XP storage is a hook you can point at your own skills resource.
- **Diving gear that just works.** Built-in scuba with a visible tank and mask, no items needed. Want players to bring their own gear, or use a different diving script? Both are a hook away.
- **Works from a submarine.** Contract types can use a key prompt instead of ox_target, so equipment can be inspected without leaving the vehicle. Each contract type can also set its own draw distance, so equipment far below the surface spawns in time.
- **Exploit-resistant by design.** Repairs must be one of the options offered, repairs are rate-limited on the server, locked contract types are refused on the server, and each contract pays out only once.
- **Urgent contracts.** A random share of contracts comes with a time limit and a bonus. The server rolls the chance, keeps the deadline and decides whether the repair was in time, so a modified client cannot claim the bonus.
- **Deposits that mean something.** A sunk, destroyed, crushed or abandoned vehicle keeps the deposit, but a finished repair is still paid out, with its experience. Only the deposit is at risk. Players are warned before they give one up. Refunds always return exactly what was paid, even if the config changes in the meantime. Set the deposit to 0 to turn it off.
- **Startup config checks.** Mistakes in the level curve, contract types, locations, faults, tests, zones, sonar, draw distances, interaction types, repair difficulties, urgent contracts and general settings are reported in the server console when the resource starts, not halfway through a player's job.
- **Clean up after itself.** Vehicles, props, diving gear, prompts and the foreman are removed on job end, logout, disconnect and resource restart.
- **Player statistics.** Every character keeps a record of repairs, lost vessels and abandoned contracts, shown at the foreman. Stored in qbx_core metadata, no database table needed, and one setting turns it off.
- **Logging for owners.** Job starts, repairs, payouts, XP, lost deposits and disconnects are logged through ox_lib's logger, to Fivemanage, Grafana Loki or Datadog. Suspicious actions carry a `suspicious` tag for one-click filtering.
- **Translatable.** Every player-facing text lives in locale files. English and Dutch are included.
- **Pluggable minigames.** Six built-in minigames (voltmeter, bolt sequence, wires, hold steady, water pump, controller reset code) plus ox_lib's skill check. Pick one per repair, or plug in your own or another resource's in `config/client.lua`. Each minigame shows the name of the chosen repair as its heading: every entry in `Config.RepairMinigame` receives that name as `title`, so pass it on with `minigame(name, settings, title)`. Each entry also receives the picked `difficulty` (`'easy'`, `'medium'` or `'hard'`); the built-in entries use it to choose their settings, as in `Config.Voltmeter[difficulty]`. Plugging in your own minigame? Make sure it handles all three levels.
- **Harder work, harder repairs.** Each contract type lists which minigame difficulties its repairs can get, and every repair attempt picks one at random. By default, surface repairs are easy or medium, seabed repairs anything from easy to hard, and deep-sea and wreck repairs medium or hard.

## Configure it your way

Everything that shapes the job lives in three config files:

- `config/server.lua` – job sites, the answer key and the server hooks (logging, fuel, experience storage, diving gear check, admin permissions). Stays on the server.
- `config/shared.lua` – settings both sides need: levels, contract types, tests, deposit, foreman, depot, repair time and interaction distance.
- `config/client.lua` – everything players see and do: minigames, diving gear, keys, currency symbol, blips and markers.

| Setting | File | What it controls | Default |
| --- | --- | --- | --- |
| `Config.Locations` | server | Job sites: label, type, prop models, placement | 34 sites (7 buoys and 4 mooring floats on the surface, 7 seabed sites and 3 pump stations, 7 deep-sea sites and 3 hydraulic units, 3 wrecks) |
| `Config.Faults` | server | Symptoms, readings, correct repair, decoys and which location types they fit | 30 faults |
| `Config.Experience` | server | Where XP is stored (`get` / `set` hook) | qbx_core metadata `offshore_xp` |
| `Config.Gear` | server | Whether a player may take a diving contract (`hasGear` hook); `false` skips the check | everyone, the job provides the gear |
| `Config.Stats` | server | Where player statistics are stored (`get` / `set` hook); `false` turns statistics off | qbx_core metadata `offshore_stats` |
| `Config.Logging` | server | Turn logging on or off | on |
| `Config.AdminPermissions` | server | Which ACE groups may use the `/offshore` admin command | `group.admin`, `group.mod` |
| `Config.Debug` | shared | Turns on the test commands (see [Debug tools](#debug-tools)). Takes effect after a restart; never use it on a live server | off |
| `Config.LevelCurve` | shared | How much XP each level needs: number of levels, XP for the first level-up, and how much more each next level costs | 20 levels, 60 XP, +20% per level |
| `Config.Tiers` | shared | Contract types: required level, location types, vehicle, pay, XP, gear, blip mode, zone radius, draw distance, interaction type, repair difficulties, urgent time limit and an optional own deposit | 4 tiers (surface, seabed, deep sea, wreck search) |
| `Config.Tests` | shared | The diagnostic tests, how long each one takes and which location types they apply to | 12 tests |
| `Config.Deposit` | shared | Default deposit, used when a tier has no `deposit` of its own (0 turns deposits off) | 150 |
| `Config.UrgentContract` | shared | Chance that a contract is urgent, the bonus for finishing in time and the warning moments (see [Urgent contracts](#urgent-contracts)) | 2% chance, 5% bonus, warnings at 5, 2 and 1 minutes left |
| `Config.InteractionDistance` | shared | How close players must be to the equipment, checked by the server and used for the key prompt | 10 m |
| `Config.RepairDuration` | shared | Time a repair attempt takes | 10 s |
| `Config.NPC` | shared | Foreman model, position, blip and interaction distances | dock worker |
| `Config.Depot` | shared | Vehicle spawn point and return radius | 30 m radius |
| `Config.InspectDuration` | client | Time an inspection takes | 2.5 s |
| `Config.InteractKey` | client | Default key for the prompt on contract types with `interactionType = 'prompt'` (players can rebind it) | E |
| `Config.Anchor` | client | Anchor key and maximum speed for anchoring | G |
| `Config.Sonar` | client | Sonar key, the distance ranges with their beep interval, and the beep sound | J, 5 ranges from every 3 s to every 0.25 s |
| `Config.ClientGear` | client | What happens when diving gear goes on and off (`equip` / `unequip` hook); `false` leaves the gear to another resource | built-in scuba with a visible tank and mask |
| `Config.ScubaModels` | client | The mask and tank props | GTA scuba props |
| `Config.Currency` | client | Currency symbol shown in the menus | $ |
| `Config.Minigame` / `Config.RepairMinigame` | client | Which minigame runs for inspecting and for each repair (each repair entry receives the repair's name as `title` and the picked `difficulty`) | skill check to inspect, a minigame per repair |
| `Config.Voltmeter` / `Config.Bolts` / `Config.Wires` / `Config.Steady` / `Config.Pumping` / `Config.Code` / `Config.SkillCheck` | client | Settings per difficulty level of the minigames, including the skill check used for repairs without a minigame of their own | easy / medium / hard |
| `Config.JobSite` / `Config.DrawDistance` | client | Job site blip, zone colour, marker and default draw distance | 100 m |

The answer key (faults, readings, correct repairs) is in the server-only config, so players cannot read it from their game files.

### Levels and contract types

Players earn XP for every completed repair, paid out when they report back to the foreman, even if the vessel was lost. Returning without a repair gives the deposit back, but no pay or XP.

- **`Config.LevelCurve`** decides how much XP each level needs, from three numbers:
  - `maxLevel`, the number of levels
  - `firstLevelXp`, the XP needed to go from level 1 to level 2
  - `growth`, how much more each next level costs than the one before, in percent (`20` means 20% more)

  The XP per level is calculated from these when the resource starts. To make the whole climb longer or shorter, change `firstLevelXp`; to make the top levels harder compared to the first ones, raise `growth`. With `Config.Debug` on, the server console shows the XP for every level and where each tier starts. An invalid value is reported in the server console and replaced by its default.

  With the defaults, the first level-up takes about 6 jobs, and reaching level 20 takes around 320 jobs, about 40 hours of offshore work at 7 to 8 minutes per job.
- **`Config.Tiers`** lists the contract types players can pick. Each tier has:
  - `id` and `label` (a locale key for its name)
  - `level`, the level needed to pick it
  - `types`, the location types that belong to it (one or more)
  - `vehicle`, the vessel or submarine players get
  - `pay` and `xp` for a completed repair
  - `levelBonus` (optional), the percentage of `pay` added for each level above the tier's own `level`. Only the highest tier a player has unlocked gets it; lower tiers pay their base `pay`. Missing means no bonus.
  - `gear`, whether this tier needs diving gear
  - `blip`, how the job site shows on the map: `'exact'` for a point with a waypoint, or `'area'` for a search zone
  - `radius`, the size of the search zone in metres (only for `'area'`)
  - `drawDistance` (optional), how far away the equipment spawns, to override `Config.DrawDistance`
  - `interactionType` (optional), `'target'` (ox_target on the equipment, the default) or `'prompt'` (a key prompt, for working from a vehicle)
  - `difficulties` (optional), the minigame difficulties a repair in this tier can get: `'easy'`, `'medium'` and/or `'hard'`. With more than one, every repair attempt picks one at random. Missing or empty means every repair is `'medium'`; an invalid value is reported at startup and skipped.
  - `deposit` (optional), to override `Config.Deposit` for this tier
  - `sonar` (optional), `true` gives the player a sonar inside the search zone. Needs `blip = 'area'` with a valid `radius`; without a search zone the tier gets no sonar, and the server console warns you at startup.
  - `urgentTimeLimit` (optional), the seconds a player has on an urgent contract of this tier, counted from taking the contract to finishing the repair. Missing means this tier's contracts are never urgent.

A search zone is centred at a random spot near the equipment, so players still have to look for it. Once the repair is done, the zone disappears from the map.

**How the level bonus works.** A level 12 player has unlocked the deep-sea tier, which starts at level 11, so they are 1 level into it. With `levelBonus = 5`, a deep-sea contract pays 675 + 5% = 708 (bonuses are rounded down). At level 15 it pays 810. A surface contract still pays 400 for them, because it is not their highest tier. The menu always shows the amount the player will actually get. Keep the top of each tier below the start of the next one (with the defaults: 480 < 550, 660 < 675 and 810 < 950), so unlocking a new tier always feels like a raise.

### Location types

A location type describes what the equipment is, for example `seabed_cable` or `deepsea_pipeline`. The type decides which tests a player can run and which faults can occur there, so a pipeline never gets a cable fault and a junction box never gets a flow test.

- A **tier** can hold several types: the seabed tier holds `seabed_cable`, `seabed_sensor`, `seabed_pipeline` and `seabed_pump`.
- A **test** or **fault** can list several types, so one fault (such as a flooded housing) can occur on every kind of equipment it fits, at any depth.
- A **location type can belong to only one tier.**

The default types:

| Tier | Types |
| --- | --- |
| surface | `surface` (navigation buoys), `mooring` (mooring floats) |
| seabed | `seabed_cable`, `seabed_sensor`, `seabed_pipeline`, `seabed_pump` |
| deep sea | `deepsea_cable`, `deepsea_pipeline`, `deepsea_hpu` (hydraulic power unit) |
| wreck search | `deepsea_wreck` |

**Adding a contract type or kind of equipment** takes four steps, and no code:

1. Add the type to a tier's `types` in `Config.Tiers`, or add a new tier, for example `types = { 'pier_light' }`.
2. Add locations in `Config.Locations` with `type = 'pier_light'`.
3. Add `'pier_light'` to the `types` of each test in `Config.Tests` that applies to this equipment.
4. Add `'pier_light'` to the `types` of existing faults that fit, or add new faults, with a reading for every test of that type.

The startup checks warn you when a type is in two tiers, when a location type has no tier or no fault, when a tier type has no location, when a fault is missing a reading for one of its tests, when a tier needs a level that does not exist, when a search zone has no valid radius, when a tier has a sonar but no search zone, or when a level curve value, repair difficulty, draw distance, interaction type, deposit, urgent time limit or urgent contract setting is invalid.

**Using your own skills or XP resource?** Replace the bodies of `Config.Experience.get` and `Config.Experience.set` in `config/server.lua`. Everything else keeps working.

### Diving gear

Contract types with `gear = true` give the player diving gear when the contract starts, and take it off again when the job ends.

- **By default** the job provides the gear: a visible tank and mask, and enough air for 15 minutes underwater. No items or other resources needed.
- **Want players to bring their own gear?** Replace the `return true` line in `Config.Gear.hasGear` (`config/server.lua`) with an inventory check. The comment above it has an example for ox_inventory. Players without the item can't start a diving contract, and they don't pay a deposit. Setting `Config.Gear = false` skips the check, the same as the default.
- **Using your own diving script**, such as qbx_divegear? Replace the bodies of `Config.ClientGear.equip` and `Config.ClientGear.unequip` in `config/client.lua`, or set `Config.ClientGear = false` if that script already puts the gear on and takes it off.
- **Want a different mask or tank?** Change the prop names in `Config.ScubaModels`.

### Deep sea and the submarine

The deep-sea and wreck tiers use the `submersible2` submarine, start at the same depot as the vessels, and use `interactionType = 'prompt'`, because ox_target does not work well from inside a vehicle.

- Keep deep-sea and wreck locations between roughly **-80 and -140 metres**. Below about -150 metres the submarine starts warning of crush depth.
- Equipment that deep needs a larger draw distance; both tiers use `drawDistance = 150`.
- Using a different submarine? Change `vehicle` on the tier, and check that it spawns cleanly at your depot.

### Wreck search and the sonar

The wreck tier sends players to a leaking wreck somewhere in a search zone of 300 metres. The zone is too big to search by sight, so the tier has `sonar = true`.

- The sonar starts when the player enters the search zone, and beeps faster the closer they get to the wreck. The ranges and their beep speed are in `Config.Sonar` in `config/client.lua`, from far to close: each range's `distance` is its lower bound and `interval` is the time between beeps in seconds.
- Players can switch the sonar off and on with a key (`J` by default, rebindable in the FiveM key settings). It goes quiet once the repair is done, and starts switched on again with the next contract.
- Any tier with a search zone can get a sonar by adding `sonar = true`. On a tier without a search zone it does nothing, and the server console warns you at startup.
- Keep the whole search zone in mind when placing wrecks: the zone's centre is placed at a random spot up to 70% of the radius away from the wreck.

### Urgent contracts

Any contract can turn out to be urgent. The server rolls the chance when the player takes the contract, and the clock starts right away.

- **The chance and the bonus** are set in `Config.UrgentContract` in `config/shared.lua`. `chance` is a percentage (decimals like `0.5` work, `0` turns urgent contracts off). `bonusPercentage` is a percentage of the tier's base `pay`, without the level bonus, rounded down.
- **The time limit** is set per tier with `urgentTimeLimit`, in seconds. A tier without one never gets urgent contracts. Time a normal run of each tier, from taking the contract to finishing the repair, and set the limit a little above it: the wreck search takes much longer than a buoy near the harbour.
- **What the player sees:** a notification when the contract turns out to be urgent, a warning at each moment in `warnings` (in seconds left; moments that aren't shorter than the tier's limit are skipped), and then either "repaired in time" or "time's up".
- **What counts** is the moment the repair is finished, not the trip back. The bonus is paid when the player reports back to the foreman, together with the pay. A repair finished in time also gets the bonus if the vessel is lost afterwards, just like the pay. When staff end the contract with `/offshore endjob`, a finished repair is paid out with its bonus too. A contract that ends through a disconnect, logout or resource restart is not paid out, so it gets no bonus either.
- **Testing:** set `chance = 100` to make every contract urgent, and set it back afterwards.

### Admin commands

Staff can manage players with one command, from in game or from the server console. Who may use it is set in `Config.AdminPermissions` in `config/server.lua`; add your own staff groups there. Every action is logged.

| Command | What it does |
| --- | --- |
| `/offshore addxp <id> <amount>` | Gives the player XP |
| `/offshore setxp <id> <amount>` | Sets the player's XP to an exact value |
| `/offshore removexp <id> <amount>` | Removes XP, never below 0 |
| `/offshore endjob <id> <1 or 0>` | Ends the player's contract: `1` refunds the deposit, `0` keeps it. A finished repair is always paid out. |

`<id>` is the player's server id. The player is told when staff end their contract.

### Statistics

Every character keeps a record of their offshore work. Players open it from the foreman's menu, under **Statistics**.

| Shown in the menu | Counts |
| --- | --- |
| Repairs | Every finished repair, whether the vessel came back, was lost or was left behind |
| Vessels lost | Every vessel that sank or was destroyed, with or without a finished repair |
| Abandoned contracts | Every contract ended at the foreman without bringing the vessel back |

Contracts that end through a disconnect, a logout, a resource restart or an admin are not counted, and neither is bringing the vessel back without a repair.

- **Storage:** qbx_core metadata (`offshore_stats`), per character. Counters that are added in a later version start at 0 automatically, and characters who never take a contract get no data at all.
- **Your own storage?** Replace the bodies of `Config.Stats.get` and `Config.Stats.set` in `config/server.lua`.
- **Turn it off:** set `Config.Stats = false`. Nothing is counted or stored, and the menu entry disappears.

The counting lives in `server/stats.lua` and uses only the public `jobFinished` event, so it doubles as an example for your own scripts.

### Debug tools

Set `Config.Debug = true` in `config/shared.lua` and restart the resource to get test commands for placing new locations, checking props and tuning minigames. The commands show up as suggestions in the chat while you type, and disappear again when the resource stops. They only affect your own game and never pay out or give XP, but they are meant for a test server: leave `Config.Debug` off on a live server.

| Command | What it does |
| --- | --- |
| `/mycoords` | Prints your position and heading as a `vec4` and copies it to the clipboard |
| `/seabed` | Finds the seabed below you and copies its position as a `vec3`, for seabed and deep-sea locations |
| `/scubaon` / `/scubaoff` | Puts the diving gear on or takes it off |
| `/prop <model> [surface\|seabed]` | Spawns a prop 3 metres in front of you, to see what a model looks like before you use it. On land it is placed on the ground; add `surface` to put it on the water surface, or `seabed` to put it on the bottom the way a job places it (the seabed z is printed in the F8 console). A model that doesn't exist is reported instead of spawned. |
| `/delprop` | Removes the prop from `/prop` (spawning a new one also replaces the old one) |
| `/checkprops` | Checks every model in `Config.Locations` and prints the ones that don't exist in the game, with the location's label, plus a summary in the F8 console. Run it after changing locations. |
| `/volt`, `/bolts`, `/wires`, `/steady`, `/pumping`, `/code` `[difficulty]` | Starts that minigame and prints the result. Add `easy`, `medium` or `hard` to test a difficulty; without it, or with an unknown value, it uses `easy`. |

With debug on, the server console also prints the data of every `jobStarted` and `jobFinished` event, and the XP for every level with the tier that starts there.

## Requirements

It runs on a standard Qbox stack, with no extra frameworks and no custom MLO.

- **qbx_core**, for players, money, vehicle spawning and XP storage
- **qbx_vehiclekeys**, for the vehicle keys
- **ox_lib**, for menus, progress bars, callbacks, keybinds, text UI, locales and logging
- **ox_target**, for the foreman and equipment interactions

## Installation

1. **Install the requirements** listed above, and make sure they start without errors.
2. **Add the resource.** Place the `mrpat_offshore_maintenance` folder in your `resources` directory (any `[category]` folder works).
3. **Start it after its dependencies.** In your `server.cfg`, below the lines for ox_lib, qbx_core, ox_target and qbx_vehiclekeys:

   ```cfg
   ensure mrpat_offshore_maintenance
   ```

4. **Set your locations.** The defaults are a starting point; check them against your map:
   - `config/shared.lua`: `Config.Depot.coords`, where the vehicle spawns (in water deep enough for the submarine, facing out), and `Config.NPC.coords`, where the foreman stands (a `vec4` with heading)
   - `config/server.lua`: `Config.Locations`, the job sites. Surface locations take their height from the water automatically. Seabed and deep-sea locations need the z coordinate of the seabed itself.
5. **Using ox_fuel?** Nothing to do.
   **Using a fuel script with client exports?** Set `Config.SetFuel` in `config/server.lua` to `false` and fill `Config.ClientSetFuel` in `config/client.lua`.
6. **Tune the economy and progression** in `config/shared.lua`: pay and XP per tier in `Config.Tiers`, the default deposit in `Config.Deposit`, and the level curve in `Config.LevelCurve`. Set your currency symbol in `Config.Currency` in `config/client.lua`.
7. **Restart the server**, or run `ensure mrpat_offshore_maintenance` in the server console, and check the console for config warnings.

### Language

The script uses ox_lib's locale system and follows your server's ox_lib language setting, for example:

```cfg
setr ox:locale "nl"
```

English (`en`) and Dutch (`nl`) are included. To add a language, copy `locales/en.json` to `locales/<code>.json` and translate the values. Keep the keys as they are.

### Logging (optional)

Logging uses ox_lib's logger, so logs go wherever your server sends ox_lib logs. Choose a service in your `server.cfg`, for example Fivemanage:

```cfg
set ox:logger "fivemanage"
set fivemanage:key "YOUR_API_KEY"
```

Grafana Loki and Datadog are supported too; see the [ox_lib logger documentation](https://overextended.dev/docs/ox_lib/Modules/Logger/Server). To turn logging off, set `Config.Logging = false` in `config/server.lua`.

Using your own logging tool? Edit `Config.LogCommand` in `config/server.lua`.

### Events (for developers)

Other server scripts can react to jobs through two server events, for example for achievements, statistics or a dispatch board. They are fired with `TriggerEvent` on the server only; clients can't trigger or receive them.

Both events pass one table:

```lua
AddEventHandler('mrpat_offshore_maintenance:jobFinished', function(data)
    print(data.citizenid, data.outcome, data.paidOut)
end)
```

#### `mrpat_offshore_maintenance:jobStarted`

Fires when a contract has started: the deposit is paid, the vessel has spawned and the player is in it.

| Field | Type | Meaning |
| --- | --- | --- |
| `source` | number | The player's server id |
| `citizenid` | string | The character's citizen id |
| `tier` | string | The tier id from `Config.Tiers`, for example `'surface'` |
| `deposit` | number | The deposit paid (can be 0) |
| `pay` | number | What the job pays when it is finished |
| `xp` | number | The XP the job gives when it is finished |
| `vesselNetId` | number | The network id of the job vessel. Only valid while the job runs; the vessel is deleted when it ends. |
| `urgent` | boolean | Whether this is an urgent contract |
| `timeLimit` | number or nil | The seconds the player has to finish the repair. Only present on an urgent contract. |

#### `mrpat_offshore_maintenance:jobFinished`

Fires once whenever a contract ends, however it ends.

| Field | Type | Meaning |
| --- | --- | --- |
| `source` | number | The player's server id |
| `citizenid` | string | The character's citizen id |
| `tier` | string | The tier id from `Config.Tiers` |
| `outcome` | string | How the contract ended (see below) |
| `repaired` | boolean | Whether the repair was finished |
| `paidOut` | number | The pay the player actually received, including any urgent bonus, without the deposit (0 if not paid) |
| `xpGained` | number | The XP the player actually received (0 if none) |
| `depositRefunded` | boolean | Whether the deposit was given back |
| `totalXp` | number | The player's XP after the job |
| `levelUp` | number or nil | The new level. Only present when the player reached a new level. |
| `urgent` | boolean | Whether this was an urgent contract |
| `inTime` | boolean | Whether the repair on an urgent contract was finished in time (always `false` on a normal contract) |
| `urgentBonusPaid` | number | The urgent bonus the player actually received, also included in `paidOut` (0 if none) |

Possible `outcome` values:

| Outcome | When |
| --- | --- |
| `returned` | The player brought the vessel back to the depot |
| `abandoned` | The player ended the contract at the foreman without bringing the vessel back |
| `vessel_lost` | The vessel was destroyed or sank |
| `admin` | Staff ended the contract with `/offshore endjob` |
| `disconnected` | The player left the server |
| `logout` | The player logged out or switched characters |
| `resource_stopped` | The resource stopped; the deposit is refunded |

`outcome` says how the contract ended and `repaired` says whether the work was done, so a lost vessel after a finished repair is `outcome = 'vessel_lost'` with `repaired = true`.

## Coming next

Ideas for future versions:

- A sonar screen next to the beeping

## License

Copyright (C) 2026 MisterPattie

This resource is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for the full text.
