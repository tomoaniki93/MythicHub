# MythicHub Changelog

## 0.1.6-beta

#### Hub — Great Vault Row Types

- **Fix** — The Great Vault preview no longer guesses which reward type belongs to which row. `DiscoverVaultTypes()` collected every `type` value returned by `C_WeeklyRewards.GetActivities()`, sorted them, and assumed the lowest was dungeons, the middle raids and the highest world content. Any week where one of the three did not appear — or where an auxiliary type showed up alongside them — shifted the whole mapping by one row. Row types are now taken straight from `Enum.WeeklyRewardChestThresholdType` (`Activities` / `MythicPlus`, `Raid`, `World`), with the previous 1 / 3 / 6 values kept only as fallbacks should the enum be unavailable.
- **Fix** — The **Delves** row, the one most often mis-detected by that heuristic, now binds to the correct reward type and shows its real progress instead of coming up empty or mirroring another row's activities.
- **Removed** — `DiscoverVaultTypes()` is gone. It ran on every vault refresh and could only ever re-derive what the client already publishes as an enum.

#### Hub — Great Vault Progress Values

- **Fix** — `RefreshVault()` no longer calls `WeeklyRewardsFrame:FullRefresh()` before reading the API. Blizzard's refresh path deliberately zeroes `activityInfo.progress` while a previous reward is still claimable, so forcing it made completed dungeons, raid bosses and delves display as `0`. MythicHub only ever reads from the `C_WeeklyRewards` API, so nothing in it required the Blizzard frame to be refreshed in the first place.

#### Hub — Great Vault Slot Binding

- **Changed** — Each row now queries `C_WeeklyRewards.GetActivities(rowDef.type)` for its own activities and sorts them by `index`, instead of bucketing one unfiltered `GetActivities()` call into a `byType[type][index]` table. The unfiltered call also returns auxiliary entries (`AlsoReceive`, `Concession`) that could land in a visible slot; the per-row query keeps the three displayed slots bound to Blizzard's actual row data.
- **Internal** — `hasGenerated` (`C_WeeklyRewards.HasGeneratedRewards()`) was read in `RefreshVault()` and never used afterwards. It has been removed along with the now-unused unfiltered activity list.

## 0.1.5-beta

### Fixed

- Removed the extra scripted Blizzard-style gold border from the MythicHub minimap button.
- The minimap button now follows the **actual outer minimap frame** instead of rotating on a fixed inner 80px orbit.
- Drag calculations now use the minimap effective scale for more accurate positioning.

## 0.1.4-beta

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
