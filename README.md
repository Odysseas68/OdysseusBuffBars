# Odysseus BuffBars

A standalone World of Warcraft Retail addon implementing a modern managed AuraContainer-based BuffBars system for Retail 12.1+.

## Project Status

- ✅ Parallel managed Player BUFFS core
- 🚧 Player DEBUFFS
- 🚧 Managed ENCHANTMENTS parity
- ✅ Managed visual parity
- 🚧 Full configuration parity
- 🚧 Final production migration

The managed Player BUFFS implementation has been validated on the PTR for the AuraContainer lifecycle, dynamic self-sizing, native sorting, native whitelist/blacklist filtering, automatic configuration synchronization, native tooltips, native right-click cancellation, and combat operation.

Core managed MainHand temporary-enchantment lifecycle is validated on Retail Live, including cold login, reload, fresh reapplication, loading/world-transition recovery, native tooltip, and right-click cancellation in the tested non-combat context. Semantic Food/Flask/Phial/Augment Rune/Fishing Bobber routing and the ordinary fishing-lure lifecycle are also validated. Managed ENCHANTMENTS now uses a deliberate 7+2+1 capacity policy: seven `HelpfulEnhancements`, MainHand and OffHand native providers, and one ordinary Fishing Lure footer. OffHand-only/simultaneous-slot coverage, combat cancellation, persistence, and production cutover remain in progress.

The normal out-of-combat configuration path live-synchronizes managed font/color/geometry, `iconSide`, host scale/alpha, group growth direction, saved BUFFS `SCREEN` coordinates, and the exact default `BUFFS SCREEN -> DEBUFFS BELOW -> ENCHANTMENTS BELOW` host chain; BUFFS/DEBUFFS additionally consume saved sort and `maxBars`. BUFFS and ENCHANTMENTS `growUp` are directly runtime validated, while DEBUFFS uses the same supported FlowLayout implementation without equivalent direct real-HARMFUL coverage. Managed placement moves ordinary hosts and follows actual self-sized container bounds; it does not reanchor or manually size AuraContainers. ENCHANTMENTS intentionally ignores legacy global sort/`maxBars`; arbitrary roots/anchors/directions, drag/lock/anchor-visibility parity, remaining behavior/filter settings, UI cleanup, and production cutover remain pending. Routine automatic routing diagnostics are silent by default while manual diagnostics remain available.

The legacy implementation remains temporarily for comparison and migration purposes.

## Repository Structure

- `Documentation/` — Project documentation.
- `Media/` — Artwork.
- `Libs/` — Libraries.
- `Reference/` — Frozen legacy reference implementation, when present.

## Related Projects

- **BlizzardResearch** — Verified Blizzard Retail PTR research repository used during development.
- **OdysseusUtilitySuite** — Production addon that will eventually integrate the validated managed implementation.

## Current Development Roadmap

- Parallel managed Player BUFFS — Core validated; production cutover pending
- Player DEBUFFS — Core managed behavior validated; integration pending
- Managed ENCHANTMENTS — MainHand lifecycle validated; broader parity in progress
- Visual parity — Validated across the three managed areas
- Configuration integration — Live presentation/growth, BUFFS/DEBUFFS sort/maximum counts, and the restricted saved SCREEN/BELOW placement graph are validated; broader parity pending
- Production migration — Planned
