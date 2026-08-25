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
- 🚧 Legacy rollback/backend cleanup

The managed Player BUFFS implementation has been validated across its historical PTR milestone and current Retail production work for the AuraContainer lifecycle, dynamic self-sizing, native sorting, native whitelist/blacklist filtering, automatic configuration synchronization, native tooltips, native right-click cancellation, and combat operation.

Core managed MainHand temporary-enchantment lifecycle is validated on Retail Live, including a real weapon oil through `/reload`, loading/portal transitions, Fishing Lure coexistence, UP growth, native weapon tooltip, correct duration, right-click cancellation in the tested non-combat context, and automatic recovery without manual refresh. The observed public MainHand data was enchant ID `8051`, expiring, zero charges, and `6798682` milliseconds remaining; those values are runtime evidence only and are not hardcoded. MainHand and OffHand use the same native registration and recovery path, but no suitable active OffHand enchant was available, so OffHand is source-validated and structurally symmetric rather than directly runtime validated; simultaneous-slot behavior remains opportunistic runtime coverage. Semantic Food/Flask/Phial/Augment Rune/Fishing Bobber routing and the ordinary fishing-lure lifecycle are also validated. Managed ENCHANTMENTS uses a deliberate 7+2+1 capacity policy: seven `HelpfulEnhancements`, MainHand and OffHand native providers, and one ordinary Fishing Lure footer.

A Retail `12.1.0.69404` source audit confirmed that supported public temporary-enchantment data supplies slot, enchant ID, remaining time, expiration state, charges, equipped-item tooltip context, native row identity, and cancellation slot, but no clean enchant-effect name or public mapping to a spell or item. The numeric `enchantID` is an internal item-enchantment identifier and must not be passed to `C_Spell` or `C_Item` as though it belonged to those domains. Managed native rows intentionally retain their equipped-weapon/slot presentation, Blizzard's localized inventory tooltip, and native cancellation; the addon does not manufacture a separate name through tooltip parsing, private state, AuraButton enumeration, or hardcoded compatibility data. This is settled product behavior unless Blizzard adds a documented public mapping.

Managed filtering is intentionally group-specific. BUFFS alone exposes destination whitelist/blacklist filtering, current effective-ownership rows, manual Spell ID entry, and ALL/TIMED_ONLY behavior. DEBUFFS is deliberately broad so eligible managed player HARMFUL state remains visible. ENCHANTMENTS is deliberately broad across effective `HelpfulEnhancements` ownership plus its native MainHand/OffHand and Fishing Lure sources. HELPFUL ownership remains separate: hidden, explicit B/E group override, semantic ENCHANTMENTS route, then default BUFFS; only BUFFS applies a destination filter afterward. Historical D/E filter SavedVariables remain preserved for legacy rollback and compatibility but are neither exposed nor consumed by managed D/E.

A historical transient observation in which ordinary `classification=nil` HELPFUL auras briefly appeared in ENCHANTMENTS could not be reproduced during focused current-architecture validation. Semantic state, effective ownership, desired descriptors, and applied descriptors remained consistent through ordinary/semantic aura churn, overrides and filters, combat deferral, empty-set reconstruction, and a portal/loading transition. The original cause remains unknown, so the observation is preserved as historical evidence rather than described as definitively fixed; it is no longer a known managed-routing implementation blocker.

Renderer authority is runtime-only and mode-level. Startup initializes the safe `STAGED` topology, then attempts the existing non-destructive MANAGED preflight/transaction only after the managed backend reports READY, making BUFFS, DEBUFFS, and ENCHANTMENTS managed-authoritative together. Historical unsupported duration/topology no longer forces STAGED by itself: Phase 2 builds a copied runtime-only effective state that satisfies exact managed invariants while leaving raw SavedVariables untouched. Session-only, out-of-combat `MANAGED`, `LEGACY`, and `STAGED` switches remain available as validation/rollback safety nets; unsafe split states and per-group transitions are rejected. While `MANAGED` is authoritative, dormant legacy rows and secure overlays are cleared, and authority-aware visibility cannot expose any legacy production group. A normal `/reload` attempts `MANAGED` again.

The managed module object now always exists and exposes `ManagedPrototype:IsReady()`, which reports READY or retains the failure reason across explicit uninitialized, initializing, ready, and failed lifecycle states. Initialization validates required Retail capabilities, constructs all B/D/E infrastructure hidden and disabled inside one protected boundary, validates constructed methods, applies and snapshots the initial paired BUFFS/ENCHANTMENTS descriptors, and exposes presentation only at commit. FAILED is terminal for the Lua session: delayed callbacks and addon-owned managed event work are invalidated or gated, dragging and Fishing Lure activity stop, and surviving created frames are hidden/disabled as best effort. Core then activates fresh runtime-only LEGACY fallback, reports one ERROR, leaves SavedVariables unchanged, and rejects MANAGED/STAGED until `/reload`; this rollback policy remains a temporary cleanup-stage safety net.

Normal `/reload` returned to MANAGED with unchanged B/D/E presentation and managed-to-legacy position synchronization. Temporary diagnostic injection also runtime-tested missing-capability, failure after DEBUFFS construction, and initial ENCHANTMENTS-descriptor failure paths; each produced one managed-renderer ERROR, retained FAILED readiness, rejected MANAGED/STAGED, and entered LEGACY without reported duplicate managed presentation or unexpected Lua/taint/blocked-action errors. All injection selectors, helpers, branches, APIs, and diagnostic strings were removed before this production checkpoint, then a clean `/reload` returned to MANAGED.

Post-cutover cleanup Phase 1 removed the `Show Legacy BuffBars (Development)` and `Legacy Comparison Mode (Development)` Config controls plus their runtime presentation offset/save compensation. Their existing defaulted SavedVariables remain preserved but dormant; LEGACY/STAGED rollback, transaction-time presentation suspension, and authority-driven legacy visibility remain available. Runtime validation passed normal MANAGED reload, explicit LEGACY/STAGED presentation, return to MANAGED, reload restoration, independent locked legacy positions, unlocked managed-to-legacy rollback-position synchronization, and duplicate-row/regression checks.

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
- Production migration — All three groups are managed-authoritative on normal startup; Phase 1 presentation cleanup, D/E SCREEN reload persistence, Phase 2 runtime-only compatibility/Config constraints, and managed readiness/partial-initialization hardening are complete. STAGED/LEGACY retirement, final fail-closed policy, rollback position synchronization removal, backend/file cleanup, and the internal production rename remain separate future work
