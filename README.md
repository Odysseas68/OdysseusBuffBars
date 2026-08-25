# Odysseus BuffBars

A standalone World of Warcraft Retail addon implementing a modern managed AuraContainer-based BuffBars system for Retail 12.1+.

## Project Status

- ✅ Managed Player BUFFS production authority
- ✅ Managed Player DEBUFFS production authority
- ✅ Managed ENCHANTMENTS production authority
- ✅ Managed visual parity
- ✅ Managed behavior/filter parity audit
- ✅ All-managed production cutover
- ✅ Post-cutover cleanup Phase 1
- ✅ Post-cutover cleanup Phase 2
- ✅ Managed readiness and partial-initialization hardening
- ✅ MANAGED-only authority retirement and fail-closed startup
- 🚧 Dormant legacy backend/file cleanup

The managed Player BUFFS implementation has been validated across its historical PTR milestone and current Retail production work for the AuraContainer lifecycle, dynamic self-sizing, native sorting, native whitelist/blacklist filtering, automatic configuration synchronization, native tooltips, native right-click cancellation, and combat operation.

Core managed MainHand temporary-enchantment lifecycle is validated on Retail Live, including a real weapon oil through `/reload`, loading/portal transitions, Fishing Lure coexistence, UP growth, native weapon tooltip, correct duration, right-click cancellation in the tested non-combat context, and automatic recovery without manual refresh. The observed public MainHand data was enchant ID `8051`, expiring, zero charges, and `6798682` milliseconds remaining; those values are runtime evidence only and are not hardcoded. MainHand and OffHand use the same native registration and recovery path, but no suitable active OffHand enchant was available, so OffHand is source-validated and structurally symmetric rather than directly runtime validated; simultaneous-slot behavior remains opportunistic runtime coverage. Semantic Food/Flask/Phial/Augment Rune/Fishing Bobber routing and the ordinary fishing-lure lifecycle are also validated. Managed ENCHANTMENTS uses a deliberate 7+2+1 capacity policy: seven `HelpfulEnhancements`, MainHand and OffHand native providers, and one ordinary Fishing Lure footer.

A Retail `12.1.0.69404` source audit confirmed that supported public temporary-enchantment data supplies slot, enchant ID, remaining time, expiration state, charges, equipped-item tooltip context, native row identity, and cancellation slot, but no clean enchant-effect name or public mapping to a spell or item. The numeric `enchantID` is an internal item-enchantment identifier and must not be passed to `C_Spell` or `C_Item` as though it belonged to those domains. Managed native rows intentionally retain their equipped-weapon/slot presentation, Blizzard's localized inventory tooltip, and native cancellation; the addon does not manufacture a separate name through tooltip parsing, private state, AuraButton enumeration, or hardcoded compatibility data. This is settled product behavior unless Blizzard adds a documented public mapping.

Managed filtering is intentionally group-specific. BUFFS alone exposes destination whitelist/blacklist filtering, current effective-ownership rows, manual Spell ID entry, and ALL/TIMED_ONLY behavior. DEBUFFS is deliberately broad so eligible managed player HARMFUL state remains visible. ENCHANTMENTS is deliberately broad across effective `HelpfulEnhancements` ownership plus its native MainHand/OffHand and Fishing Lure sources. HELPFUL ownership remains separate: hidden, explicit B/E group override, semantic ENCHANTMENTS route, then default BUFFS; only BUFFS applies a destination filter afterward. Historical D/E filter SavedVariables remain preserved as compatibility/history data but are neither exposed nor consumed by managed D/E.

A historical transient observation in which ordinary `classification=nil` HELPFUL auras briefly appeared in ENCHANTMENTS could not be reproduced during focused current-architecture validation. Semantic state, effective ownership, desired descriptors, and applied descriptors remained consistent through ordinary/semantic aura churn, overrides and filters, combat deferral, empty-set reconstruction, and a portal/loading transition. The original cause remains unknown, so the observation is preserved as historical evidence rather than described as definitively fixed; it is no longer a known managed-routing implementation blocker.

MANAGED is now the sole production renderer authority for BUFFS, DEBUFFS, and ENCHANTMENTS. Startup is READY-or-FAILED: it preserves the existing SavedVariables/default/normalization path, initializes the managed backend, verifies `IsReady()`, and commits the complete managed presentation only after successful protected initialization. There is no STAGED/LEGACY runtime switching, per-group authority, transition transaction, direct-scanner fallback, or same-session reconstruction. The temporary immutable `GetRendererAuthorityMode()` compatibility façade returns `"MANAGED"` only so unchanged Config code can identify the active renderer; it is not mutable authority state.

The managed module object always exists and exposes `ManagedPrototype:IsReady()`, which reports READY or retains the failure reason across explicit uninitialized, initializing, ready, and failed lifecycle states. Initialization validates required Retail capabilities and strict copied effective B/D/E state, constructs all infrastructure hidden and disabled inside one protected boundary, validates constructed methods, applies and snapshots the initial paired BUFFS/ENCHANTMENTS descriptors, and exposes presentation only at commit. FAILED is terminal for the Lua session: delayed callbacks and addon-owned managed event work are invalidated or gated, dragging and Fishing Lure activity stop, and surviving created frames are hidden/disabled as best effort. Core reports one fail-closed ERROR and leaves aura presentation disabled for the session; `/reload` is the only reconstruction attempt. Failure handling does not migrate or destructively rewrite SavedVariables.

Final production testing passed fresh login, `/reload`, normal managed B/D/E presentation, many World Quests and Delves, simultaneous buffs/debuffs, correct routing, and duplicate-legacy suppression without observed OBB Lua errors. An unrelated XML/Lua error was traced to CraftSim. The retired `SetRendererAuthorityMode` and `SetGroupRendererAuthority` APIs were verified absent. A temporary post-cutover CAPABILITY injection then verified exactly one fail-closed startup ERROR, retained FAILED readiness, no managed or legacy aura UI, Config availability, and no observed OBB Lua errors. The hook was removed completely, the exact tested production blobs were restored, and a final clean `/reload` restored normal managed B/D/E presentation without failure, legacy display, duplicates, or errors.

Post-cutover cleanup Phase 1 removed the `Show Legacy BuffBars (Development)` and `Legacy Comparison Mode (Development)` Config controls plus their runtime presentation offset/save compensation. Their existing defaulted SavedVariables remain preserved but dormant. Historical LEGACY/STAGED rollback and position-synchronization validation remains recorded in the migration history, but those operational paths are now retired.

Post-cutover cleanup Phase 2 added the runtime-only managed compatibility bridge and constrained Config to the production topology. Raw SavedVariables remain the historical/configuration authority; managed rendering consumes deep-copied effective settings. BUFF Config exposes only ALL and TIMED_ONLY. Historical TIMELESS_ONLY/NONE execute as runtime-only ALL until the user explicitly selects a supported replacement. BUFFS offers SCREEN only; DEBUFFS offers SCREEN or BELOW/LEFT/RIGHT of BUFFS; ENCHANTMENTS offers SCREEN or BELOW/LEFT/RIGHT of DEBUFFS. Unsupported historical placement remains stored unchanged and executes through a marked canonical fallback; dragging cannot persist a synthetic fallback. General, group-page, and one-per-session chat warnings identify compatibility use without a modal, automatic Config opening, or Apply button.

Startup preserves intentional independent DEBUFFS/ENCHANTMENTS SCREEN roots across serialization. Before recursive defaults fill missing fields, it records raw groups with an explicit placement and no saved parent, then restores that intentional nil `anchorTo` after defaults. This adds no persistent discriminator or schema field and does not change generic default filling. Runtime validation passed D SCREEN, E SCREEN, both SCREEN, D BELOW B, E BELOW D, and Reset Positions across reload. The supported topology remains B as the SCREEN root; D may be SCREEN or BELOW/LEFT/RIGHT of B; E may be SCREEN or BELOW/LEFT/RIGHT of D. Reverse, arbitrary, cyclic, ABOVE, and B-as-child graphs remain unsupported but are now interpreted only in copied managed runtime state rather than written back; deliberate injection of those historical states remains unperformed.

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
- Production migration — MANAGED is the sole runtime renderer; READY-or-FAILED startup, fail-closed failure handling, mode/API retirement, managed-only refresh, legacy event/scan/render retirement, and managed-drag rollback synchronization removal are complete
- Backend cleanup — Move the Fishing Lure formatter, then remove dormant Auras/Bars backends and TOC entries in separate reviewed stages
- Compatibility cleanup — Remove temporary Config façades only when Config no longer needs them; preserve historical SavedVariables until a deliberate schema decision
- Production naming, Config polish, library review, licensing, and release metadata remain separate future work
