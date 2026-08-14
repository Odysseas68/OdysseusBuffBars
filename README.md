# Odysseus BuffBars

A standalone World of Warcraft Retail addon implementing a modern managed AuraContainer-based BuffBars system for Retail 12.1+.

## Project Status

- ✅ Managed Player BUFFS
- 🚧 Player DEBUFFS
- 🚧 Managed ENCHANTMENTS parity
- 🚧 Visual parity
- 🚧 Final production migration

The managed Player BUFFS implementation has been validated on the PTR for the AuraContainer lifecycle, dynamic self-sizing, native sorting, native whitelist/blacklist filtering, automatic configuration synchronization, native tooltips, native right-click cancellation, and combat operation.

Core managed MainHand temporary-enchantment lifecycle is validated on Retail Live, including cold login, reload, fresh reapplication, native tooltip, and right-click cancellation in the tested non-combat context. OffHand, simultaneous enchants, combat cancellation, Food/Flask HELPFUL routing, final presentation, configuration, persistence, and production cutover remain in progress.

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

- Player BUFFS — ✔ Complete
- Player DEBUFFS — In progress
- Managed ENCHANTMENTS — MainHand lifecycle validated; broader parity in progress
- Visual parity — Planned
- Configuration integration — Planned
- Production migration — Planned
