# Odysseus BuffBars

A standalone World of Warcraft Retail addon implementing a modern managed AuraContainer-based BuffBars system for Retail 12.1+.

## Project Status

- ✅ Managed Player BUFFS production authority
- ✅ Managed Player DEBUFFS production authority
- ✅ Managed ENCHANTMENTS production authority
- ✅ Managed visual parity
- ✅ Managed behavior/filter parity audit
- ✅ All-managed production cutover
- 🚧 Legacy rollback/development cleanup

The managed Player BUFFS implementation has been validated on the PTR for the AuraContainer lifecycle, dynamic self-sizing, native sorting, native whitelist/blacklist filtering, automatic configuration synchronization, native tooltips, native right-click cancellation, and combat operation.

Core managed MainHand temporary-enchantment lifecycle is validated on Retail Live, including a real weapon oil through `/reload`, loading/portal transitions, Fishing Lure coexistence, UP growth, native weapon tooltip, correct duration, right-click cancellation in the tested non-combat context, and automatic recovery without manual refresh. The observed public MainHand data was enchant ID `8051`, expiring, zero charges, and `6798682` milliseconds remaining; those values are runtime evidence only and are not hardcoded. MainHand and OffHand use the same native registration and recovery path, but no suitable active OffHand enchant was available, so OffHand is source-validated and structurally symmetric rather than directly runtime validated; simultaneous-slot behavior remains opportunistic runtime coverage. Semantic Food/Flask/Phial/Augment Rune/Fishing Bobber routing and the ordinary fishing-lure lifecycle are also validated. Managed ENCHANTMENTS uses a deliberate 7+2+1 capacity policy: seven `HelpfulEnhancements`, MainHand and OffHand native providers, and one ordinary Fishing Lure footer.

A Retail `12.1.0.69404` source audit confirmed that supported public temporary-enchantment data supplies slot, enchant ID, remaining time, expiration state, charges, equipped-item tooltip context, native row identity, and cancellation slot, but no clean enchant-effect name or public mapping to a spell or item. The numeric `enchantID` is an internal item-enchantment identifier and must not be passed to `C_Spell` or `C_Item` as though it belonged to those domains. Managed native rows intentionally retain their equipped-weapon/slot presentation, Blizzard's localized inventory tooltip, and native cancellation; the addon does not manufacture a separate name through tooltip parsing, private state, AuraButton enumeration, or hardcoded compatibility data. This is settled product behavior unless Blizzard adds a documented public mapping.

Managed filtering is intentionally group-specific. BUFFS alone exposes destination whitelist/blacklist filtering, current effective-ownership rows, manual Spell ID entry, and ALL/TIMED_ONLY behavior. DEBUFFS is deliberately broad so eligible managed player HARMFUL state remains visible. ENCHANTMENTS is deliberately broad across effective `HelpfulEnhancements` ownership plus its native MainHand/OffHand and Fishing Lure sources. HELPFUL ownership remains separate: hidden, explicit B/E group override, semantic ENCHANTMENTS route, then default BUFFS; only BUFFS applies a destination filter afterward. Historical D/E filter SavedVariables remain preserved for legacy comparison and rollback but are neither exposed nor consumed by managed D/E.

A historical transient observation in which ordinary `classification=nil` HELPFUL auras briefly appeared in ENCHANTMENTS could not be reproduced during focused current-architecture validation. Semantic state, effective ownership, desired descriptors, and applied descriptors remained consistent through ordinary/semantic aura churn, overrides and filters, combat deferral, empty-set reconstruction, and a portal/loading transition. The original cause remains unknown, so the observation is preserved as historical evidence rather than described as definitively fixed; it is no longer a known managed-routing implementation blocker.

Renderer authority is runtime-only and mode-level. Supported startup initializes the safe `STAGED` topology, then the existing non-destructive preflight enters `MANAGED`, making BUFFS, DEBUFFS, and ENCHANTMENTS managed-authoritative together. Unsupported BUFF duration or managed topology leaves startup safely in `STAGED` without rewriting SavedVariables. Session-only, out-of-combat `MANAGED`, `LEGACY`, and `STAGED` switches remain available for rollback/development; unsafe split states and per-group transitions are rejected. While `MANAGED` is authoritative, dormant legacy rows and secure overlays are cleared and comparison cannot resurrect any legacy production group. A normal `/reload` attempts `MANAGED` again.

## Repository Structure

- `Documentation/` — Project documentation.
- `Media/` — Artwork.
- `Libs/` — Libraries.
- `Reference/` — Frozen legacy reference implementation, when present.

## Related Projects

- **BlizzardResearch** — Verified Blizzard Retail PTR research repository used during development.
- **OdysseusUtilitySuite** — Production addon that will eventually integrate the validated managed implementation.

## Current Development Roadmap

- Managed Player BUFFS — Production authority implemented and runtime validated
- Managed Player DEBUFFS — Production authority implemented and runtime validated with rollback
- Managed ENCHANTMENTS — Production authority implemented; MainHand runtime validated, with OffHand/dual-slot direct coverage still opportunistic
- Visual parity — Validated across the three managed areas
- Configuration integration — Managed BUFF destination filtering and the intentional broad/unfiltered D/E policies are runtime validated; the final parity audit and focused HELPFUL-routing investigation found no current routing implementation blocker
- Production migration — All three groups are managed-authoritative on supported startup; legacy rollback/development retirement is the next phase
