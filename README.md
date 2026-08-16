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

Core managed MainHand temporary-enchantment lifecycle is validated on Retail Live, including cold login, reload, fresh reapplication, native tooltip, and right-click cancellation in the tested non-combat context. Semantic Food/Flask/Phial/Augment Rune/Fishing Bobber routing and the ordinary fishing-lure lifecycle are also validated. OffHand, simultaneous enchants, combat cancellation, exact combined ENCHANTMENTS policies, persistence, and production cutover remain in progress.

The normal out-of-combat configuration path live-synchronizes managed `fontSize`, `barColor`, `barBgColor`, `width`, `height`, and `spacing`. Managed `iconSide` still requires `/reload`; scale/alpha, growth, placement/position, remaining behavior/filter settings, and production cutover remain pending. Routine automatic routing diagnostics are silent by default while manual diagnostics remain available.

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
- Configuration integration — Live font/color/width/height/spacing validated; broader parity pending
- Production migration — Planned
