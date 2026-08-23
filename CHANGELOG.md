# MythicHub Changelog

## 0.1.3-beta

### New

- **MythicHub Run History** with persistent Mythic+ runs, duration, key level, completion state, score gain, Blizzard history sync and click-to-open detailed MythicHubScore snapshots when available.
- **Score Planner / Upgrade Finder** that ranks current-season dungeons by estimated upgrade opportunity using the player's own season score/level curve.
- Score Planner target controls for +1, +2 or +3 key-level planning.
- Dungeon teleport shortcuts in the Score Planner when the portal is learned.
- **MythicHub minimap button** with Azure MH icon, drag positioning, left-click settings and right-click quick menu.
- Native **Blizzard AddOn Compartment** integration using the MythicHub quick menu.
- New `/mh history`, `/mh planner` and `/mh minimap` commands.

### Changed

- Midnight Season 2 fallback rotation now uses Altar of Fangs, Murder Row, Den of Nalorakk, The Blinding Vale, Voidscar Arena, Ruby Life Pools, Kings' Rest and Temple of Sethraliss.
- MythicHubScore now saves completed run data even when automatic scoreboard display is disabled, so Run History remains complete.
- MythicHubScore run snapshots now include score before/after, rating gain, death count and completion metadata when available.
- Added a dedicated **Progression** page to `/mh` for Run History, Score Planner and minimap controls.
- Added/updated locale strings for enUS, frFR, deDE, esES/esMX, itIT and ptBR.

### Safety

- Score Planner teleport buttons use secure spell buttons and the planner will not open during combat lockdown.

## 0.1.2-beta

### Fixed

- MythicHubScore can now be moved reliably by dragging its header while unlocked.
- MythicHubScore no longer participates in the special-frame keyboard path and explicitly leaves keyboard input to the game, preventing movement keybinds from being blocked while the scoreboard is visible.
- Scoreboard teleport buttons now listen only for left-click release instead of all mouse button down/up events.
- The addon version shown in `/mh` now reads the `.toc` metadata instead of an old hardcoded alpha version.

### Changed

- TomoScore has been renamed to **MythicHubScore** throughout the standalone addon, with automatic migration of existing settings, position and last-run data.
- MythicHubScore preview data now uses the **Midnight Season 2** dungeon pool, including Altar of Fangs, Murder Row, Den of Nalorakk, The Blinding Vale, Voidscar Arena and Ruby Life Pools examples.
- Added dedicated MythicHubScore lock/unlock controls in the Keys & Score panel.
- Added a live **Character frame scale** slider from 75% to 150%, also applied to Inspect.

## 0.1.1-beta

### New

- First public beta of MythicHub, the standalone Mythic+ toolkit derived from TomoMod.
- Modern Azure Blue + White `/mh` configuration interface.
- Independent enable/disable controls for the main MythicHub modules.
- Global `/mh unlock` and `/mh lock` layout mode for movable elements.
- Mythic+ Tracker with timer, enemy forces, bosses, deaths, presets, splits/checkpoints, scale and opacity options.
- Mythic+ Hub with season score, dungeon progress, best runs, Great Vault information and dungeon teleports.
- MythicHubScore group/end-of-run scoreboard.
- Built-in keystone synchronization between MythicHub users.
- `/mh key` to announce detected party keystones.
- `/mh kr` Mythic+ keystone roulette.
- Automatic keystone insertion support.
- `/mh ai` Keystone Advisor for season progression suggestions.
- Character Sheet + Inspect Azure skin with Mythic+ information, item/upgrade data and gem indicators.
- Standalone Battle Rez counter with shared-charge tracking and movable display.
- Localizations for English, French, German, Spanish (including esMX), Italian and Brazilian Portuguese.
- New MythicHub MH logo and 64x64 TGA addon icon.

### Changed

- Standalone namespace, SavedVariables and slash commands now use MythicHub instead of TomoMod.
- Addon icon now loads from `Textures\Logo.tga`.
- Publication files were updated for a public CurseForge/GitHub beta release.

### Testing

This is a beta release. Please test `/reload`, combat transitions, entering/leaving Mythic+ dungeons, keystone group synchronization, Character/Inspect frames, Great Vault data, Battle Rez charges and all movable elements.
