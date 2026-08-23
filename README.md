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

The normal out-of-combat configuration path live-synchronizes managed font/color/geometry, `iconSide`, host scale/alpha, group growth direction, header visibility through `anchorsShown`, and the validated placement set: BUFFS as SCREEN; DEBUFFS as SCREEN, BELOW, RIGHT, or LEFT of BUFFS; and ENCHANTMENTS as SCREEN, BELOW, RIGHT, or LEFT of DEBUFFS. RIGHT and LEFT use prototype-owned logical widths so lateral placement remains stable when a managed container is empty; no physical container sizing or fake minimum is used. All effective SCREEN roots support independent unlocked out-of-combat dragging with shared-coordinate persistence; anchored groups follow their supported parent and refuse direct movement. Managed ABOVE is intentionally unsupported and planned for retirement with the legacy renderer because the current architecture has no safe public child-bottom/full-visible-bounds contract. Arbitrary graph/cycle parity, remaining behavior/filter settings, UI cleanup, and production cutover remain pending.

The legacy backend remains active during migration. `Show Legacy BuffBars (Development)` can hide only its addon-owned presentation, while `Legacy Comparison Mode (Development)` temporarily forces that presentation visible and shifts each effective legacy SCREEN root by its width plus 24 UI units for side-by-side parity work. Comparison never changes real saved placement; disabling it returns legacy bars to the managed-authoritative shared coordinates. Blizzard default-frame visibility remains independent. This temporary workflow is not production renderer selection.

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
- Configuration integration — Live presentation/growth, BUFFS/DEBUFFS sort/maximum counts, supported SCREEN/BELOW/RIGHT/LEFT placement, SCREEN-root dragging, managed header visibility, and the development comparison workflow are validated; broader parity pending
- Production migration — Planned
