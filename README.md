# AutoMarker 1.29.0
AutoMarker for [SuperWoW](https://github.com/balakethelock/SuperWoW/) or [nampower](https://gitea.com/avitasia/nampower) 2.39+ on the 1.12 client.

* Default values are (so far) calibrated for Turtle WoW specifically.
___

* Hold `shift then ctrl or alt` and mouseover a mob to mark the group.  
* Enables setting marks on units without needing to be in a party.  

### Keybinds:
* Automark moused over group or target - synonymous with `/am mark`
* Clear all marks - synonmous with `/am clearmarks`
* Mark next pack (based on default order from NPCList.lua) - synonymous with `/am next`

Many pre-defined groups exists already in the addon but can be customized with the following commands.  
### Commands:  

- `/am set <packname> - Set the current pack name.` `Alias: /am s`
- `/am get - Get the current pack name and information about the targeted mob.` `Alias: /am g`
- `/am clear - Clear all mobs in the current pack.` `Alias: /am c`
- `/am add [packname] - Add the targeted mob to a specified pack. If no pack name is provided, use the current 'set' pack name.` `Alias: /am a`
- `/am sweep [packname] - Toggle sweep mode to add multiple mobs to a specified pack. If no pack name is provided, use the current 'set' pack name.`
- `/am remove - Remove the targeted mob from its current pack.` `Alias: /am r`
- `/am clearmarks - Remove all active marks.`
- `/am next - Mark next pack based on default order from NPCList.lua`
- `/am mark - Mark pack of current target or mouseover.`
- `/am markname <unit name> - Mark all units of a given name.`

- `/am debug - Toggle debug mode.`

### Pack editor
* `/am ui`, the minimap button or the *Toggle pack editor* key binding opens a window showing the pack of your target.
  * Click an icon to change a mob's mark (shift-click also applies it in game right away).
  * Click a name to target the mob if it is loaded. Green = nearby, red = dead, grey = out of range, `!` = mark used twice in the pack.
  * Arrows: browse the zone's packs in `NPCList.lua` order. *Follow target*: the window follows your target's pack.
  * Buttons: *Mark*, *Clear*, *+ Target* (moves the target into this pack), *New*, *Sweep* (mouseover capture), *Rename*, *Reset* / *Delete*.
* Minimap button: left-click opens the editor, right-click enables / disables automatic marking, drag to move it. `/am minimap` shows / hides it.
* Editing a default pack creates an editable copy of it; *Reset* goes back to the `NPCList.lua` values.

### Auto-adding unknown mobs
* Inside a raid instance (not in dungeons or the open world), targeting a mob that is in no pack puts it in a new `new_NN` pack with the UNMARKED value,
  together with the unknown mobs standing within 10 yards (requires UnitXP). These packs can then be edited in the pack editor.
* The instance type comes from ClassicAPI's `GetInstanceInfo` when you enter it, and is remembered per map id
  in the configuration file (`mapInfo = { [409] = { name = "Molten Core", type = "raid" }, ... }`).
* `/am autoadd` toggles it, `/am autoradius <yd>` sets the radius (0 = target only).


### Ignored mobs (blacklist)

Summons and script adds (e.g. Lava Spawn) get a new GUID every time, so they are useless in a pack. Names listed in the `ignoredNames = { ... }` block of `AutoMarker_Config.txt` are never auto-added (case insensitive, `Lava Spawn` is there by default).
`/am ignore [name]` (target if no name), `/am unignore [name]`, `/am ignorelist` (opens the list window: add a typed name or the target, remove with the x), or the **Ignore target** / **Ignore list** buttons of the editor. The **Clean config** button of the list window removes from the configuration every UNMARKED mob whose name is ignored (marked mobs are kept) and the auto-created packs left empty.

### Locations and world markers (WeirdUtils)
* A pack can have named positions ("locations") that are not tied to a mob. Each one can get a WeirdUtils world marker (1-5):
  they are placed with the pack (`/am next`, marking a pack from a target, the editor's Mark button) when `worldmarkers.dll` of
  [WeirdUtils](https://codeberg.org/MarcelineVQ/WeirdUtils) is loaded and you are leader/assist, on the same map only.
  They are independent of the raid marks on mobs: a pack can have both.
* In game: editor > **Locations** window. "Add here" stores your current position (not marked), the left button picks its world marker
  (left / right click = next / previous, one location per marker), the box renames it, "Here" moves it to where you stand, x deletes it.
* Commands: `/am wm` lists them, `/am wm add [name]`, `/am wm <1-5> [target]` (world marker N at your / the target's position),
  `/am wm <1-5> clear`, `/am wm place`, `/am wm on|off`. `/am clearmarks` also clears the placed world markers.
* Config: `["location:1"] = { name = "Tank spot", worldmark = 2, map = 533, x = .., y = .., z = .. },` inside the pack (`worldmark = 0`: no marker).
* The out-of-game editor shows them as diamonds (number = world marker, drag to move) and lets you add, rename, set the icon, move and delete them.

### Mob positions
* Each mob of `NPCList.lua` carries its name and spawn position: `{ mark = SKULL, name = "Venom Stalker", map = 0, x = 0, y = 0 }`
  (map = `Map.dbc` id, e.g. 533 = Naxxramas, x / y = world coordinates in yards, 0 = unknown), to identify it again later.
* The first time a mob of a pack is targeted out of combat, its position is recorded in the configuration file.
  `/am setpos` records the target's position again.
* Only mobs that are alive and out of combat are recorded (in combat, players can pull them away from their spawn).
* Patrols: if the same mob is later seen out of combat at least 12 yd from every known point, the new spot is added as a
  waypoint (up to 60) and written as `path = "x,y;x,y"`. The editor draws it as a dashed line that follows the mob when moved.
* The editor shows it in the mob tooltip (with the distance to you); the mob id is green once its position is known.
* Positions come from `UnitPosition` (ClassicAPI or SuperWoW) and the map id from ClassicAPI's `GetInstanceInfo`.

### Global settings
* Custom packs are saved to `<WoW folder>\Imports\AutoMarker_Config.txt` (SuperWoW / nampower ExportFile & ImportFile):
  the same file is used by every account and character, and can be shared with other players.
* The file uses the same layout as `NPCList.lua`: one `addToCustomNpcsToMark("zone", "pack", { ... })` block per pack, with
  `["guid"] = { mark = SKULL, name = "...", map = 0, x = 0, y = 0 },` entries. It can be edited by hand (keep one entry per line,
  then `/am reload`) and its blocks can be copied into `NPCList.lua` (rename the function to `addToDefaultNpcsToMark`).
* When the file is missing or empty, it is created from every pack of `NPCList.lua`. `/am populate` adds the `NPCList.lua`
  packs that are missing from an existing file (e.g. after an addon update).
* A pack that differs from `NPCList.lua` shows as *modified* in the editor; *Reset* restores the `NPCList.lua` version.
* Files written by older versions are still read and converted right away.
* The file is written 2 seconds after each change and on logout. `/am save` forces a write, `/am reload` reads the file again.
* The first time an account logs in, its previous custom packs (SavedVariables) are merged into the file.
* Avoid editing packs from two game clients at once: the last one to write wins.

### Automatic Features:  
* Marks highest health corehound in a fight with a Skull
* Re-marks Buru eggs as they respawn
* Marks Flame Keepers in Blackrock Depths
* Marks soldiers that are getting too close during KT Fight
* Marks Fankriss worms as they spawn
* Marks Solinus adds when they spawn based on best kill prio
* Marks Rupturan fragments when they spawn
* Marks Mephistroph double-doomguards when they spawn
* Informs you of Jed Runewatcher being present in Blackrock Spire

___
* Made by and for Weird Vibes of Turtle Wow  
