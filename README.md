# MythicHub

**MythicHub** is a standalone World of Warcraft Retail (Midnight 12.x) Mythic+ toolkit created by the author of TomoMod and reorganized around a dedicated Azure Blue + White interface.

## Included modules

- Modern `/mh` configuration window with independent module toggles.
- Mythic+ Tracker with timer segments, enemy forces, bosses, deaths, presets, split/checkpoint data, scale and opacity settings.
- Mythic+ Overview Hub with season score, dungeon rows, best runs, dungeon teleports and Great Vault information.
- TomoScore end-of-run / group scoreboard.
- Built-in KeySync transport for MythicHub users.
- `/mh key` party keystone announcement.
- `/mh kr` Mythic+ keystone roulette.
- Automatic keystone insertion when the Blizzard keystone frame opens.
- Keystone Advisor (`/mh ai`) that highlights the dungeon with the lowest current season score.
- Character Sheet + Inspect skin, item/upgrade information, gems and integrated Mythic+ score widget.
- Standalone Battle Rez counter with pooled charges and recharge display.
- Global `/mh unlock` / `/mh lock` placement mode for movable elements.
- Locales: enUS fallback, frFR, deDE, esES/esMX, itIT and ptBR.

## Slash commands

- `/mh` — settings
- `/mh hub` — Mythic+ overview
- `/mh key` — announce group keystones
- `/mh kr` — key roulette
- `/mh tracker` — tracker preview
- `/mh score` — current group TomoScore
- `/mh score last` — last saved run
- `/mh ai` — Keystone Advisor
- `/mh unlock` / `/mh lock` — layout mode
- `/mh keysync` — KeySync diagnostics
- `/mh reset` — reset supported element positions
- `/mh help` — command list

## Publication

This package is prepared as the public **0.1.0-beta** release. MythicHub is an original standalone addon by the author of TomoMod, using systems adapted from TomoMod into a dedicated Mythic+ project.

## Recommended tests

Before a wide release, test on Retail Midnight with `/reload`, entering/leaving a Mythic+ dungeon, group changes, Character/Inspect opening, Great Vault data, keystone insertion, battle-rez charge changes, and combat lockdown transitions.

Character/Inspect skin changes may require `/reload` because Blizzard frames cannot always be cleanly unskinned at runtime.
