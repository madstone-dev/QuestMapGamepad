# In-game verification / 게임 내 확인

Target: WoW Forever beta Interface 16001. Implementation references Blizzard API definitions
from Gethe/wow-ui-source `forever` commit `bd2470aed543f72697a044e989285b6c83e63f73`.
Definitions are reference material, not bundled code.

**Status: automated Lua mock tests passed; no live client test has been performed.**

1. Install the `QuestMapGamepad` folder under `Interface/AddOns` and restart the client.
2. For the first diagnostic run, enable QuestMap Gamepad alone among quest addons.
   Disable Questie, QuestieDB, Questie Gamepad, QuestieDB Gamepad and Forever Quest Pins through the addon list.
3. Check the current zone, another zone, the continent and the full world overview. Pan and zoom;
   pin positions must remain aligned, clusters separate as you zoom, and pins stay inside the map.
4. Open `/qmg` or the map/minimap Q button. Check each category, master toggle, repeatable/low-level filters,
   size bounds and independence of world-map/minimap options. Reload and confirm persistence.
5. Use the controller cursor to click Q, or assign the **QuestMap Gamepad / Quest pin settings** binding
   in the game's binding UI. No controller binding is assigned or overwritten automatically.
6. With the controller, navigate using D-pad/left stick, confirm with PAD1 (south), cancel with PAD2 (east).
   Test swapping these buttons, pin list pages and size changes. On close, normal game input must resume.
7. Accept, progress, complete, report and abandon quests. Check start/objective/turn-in transitions.
   If a quest lacks a position, `/qmg status` reports it as `missingActive`; do not infer its location.
8. Walk, turn and change minimap zoom indoors/outdoors. Check rotating and nonrotating minimaps.
9. Talk to an NPC using the controller repeatedly, including reward selection. Enter combat while settings
   are open, leave combat, then open the map and settings again. No addon-block popup should occur.
10. Repeat with the user's normal addons enabled. Report conflicts separately from the isolated run.

If blocked: run `/qmg log`, record the popup's addon/action name, client build and reproduction steps.
Remove character/account details before posting. Do not publish SavedVariables or WTF files wholesale.

## Coverage limits

- The bundled DB contains starts only. Objective/turn-in coverage depends on game POIs/waypoints;
  these can be representative locations, not every possible monster spawn.
- Availability data does not encode every reputation, inventory, server-phase or event condition.
  Seasonal/monthly/war-effort/breadcrumb static starts are omitted; confirmed native starts can still appear.
  Missing profession APIs conservatively hide profession-gated static starts.
- Low-level filtering applies when the game supplies an actual quest level; minimum acceptance level
  is not treated as the quest's true level.
- Pin switches affect this addon's overlays; Blizzard's own quest pins remain controlled by the game.
- The minimap overlay uses an inset circular boundary. Custom square minimap skins may have unused corners.
- Model rebuilds are deferred in combat/dialogue. Existing pin positions continue updating while moving;
  quest status refreshes after combat/dialogue ends. Overlays hide during quest dialogue.
- World-map inset submaps are not projected as separate inset canvases.
- No actual donation destination is configured. All functions remain free.
