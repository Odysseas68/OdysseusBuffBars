# Changelog

This changelog records repository history beginning with the creation of the standalone OdysseusBuffBars repository. Earlier development performed before repository creation is intentionally not reconstructed.

## Unreleased

### Added

- Standalone repository.
- Managed AuraContainer Player BUFFS implementation.
- Dynamic self-sizing.
- Native sorting.
- Native filtering.
- Automatic filter synchronization.
- Retail 12.1 PTR validation.
- Isolated managed player-DEBUFFS prototype and Retail 12.1 Live validation.
- Dynamic managed BUFFS-to-DEBUFFS anchoring.
- Isolated managed ENCHANTMENTS prototype with MainHand/OffHand registrations and validated MainHand quiet-turn cold-login recovery on Retail 12.1 Live.
- Project documentation.

### Changed

- Completed the production all-managed renderer cutover. Supported startup now enters runtime-only `MANAGED` authority for BUFFS, DEBUFFS, and ENCHANTMENTS through the validated preflight/transaction path; unsupported saved configuration remains safely `STAGED` without SavedVariables rewriting.
- Added exactly three legal session modes: `STAGED` (legacy B, managed D, legacy E), `MANAGED` (managed B/D/E), and `LEGACY` (legacy B/D/E). Independent per-group mutation and unsafe B/E or D/E split states are rejected.
- Made `/obb refresh` and Config `Refresh Auras` mode-aware through one managed semantic/native/lure recovery coordinator, while leaving Blizzard-owned managed aura lifecycle framework-driven.
- Made MANAGED Config state truthful: ENCHANTMENTS Sort displays `Fixed (Managed)`, ENCHANTMENTS Sort/Maximum Bars are disabled, and comparison cannot resurrect legacy-authoritative rows.
- Runtime-validated supported MANAGED startup, ordinary and semantic HELPFUL routing, managed D/E behavior in available scenarios, immediate Config state, both refresh paths, combat behavior and switch refusal, LEGACY/STAGED rollback, return to MANAGED, reload-after-rollback, and safe STAGED fallback for BUFF duration NONE followed by successful MANAGED restoration after returning to ALL.
- Established the earlier player-DEBUFFS checkpoint with runtime defaults BUFFS `LEGACY`, DEBUFFS `MANAGED`, and ENCHANTMENTS `LEGACY`; this historical staged default is superseded by the all-managed startup transaction above, without a SavedVariables authority field or migration.
- In that earlier staged checkpoint, skipped the legacy DEBUFFS scan/render path while managed D authority was active, cleared stale legacy bars and cancel-overlay state, and prevented comparison from re-showing legacy DEBUFFS.
- In that earlier staged checkpoint, added the DEBUFFS-only out-of-combat switch lifecycle that retained managed structures across rollback. The complete-mode lifecycle above now owns production rollback and restoration.
- Preserved the staged mixed-topology invariant: managed BUFFS stays enabled and layout-active as the geometry source for chained managed DEBUFFS while STAGED leaves legacy BUFFS authoritative.
- Runtime-validated the DEBUFFS cutover across login/reload, combat aura churn, sorting and maximum count, managed presentation settings, SCREEN dragging and persistence, BELOW/RIGHT/LEFT chaining, anchor visibility, reset, loading transitions, rollback in both directions, comparison, and reload-after-rollback without reported Lua, taint, or blocked-action errors. Targeted private-HARMFUL coverage remains a separate optional test.
- Corrected the shared group-page layout so the DEBUFFS and ENCHANTMENTS Icon dropdown sits below Sort with normal spacing instead of overlapping Offset Y; the already-correct BUFFS side-by-side Sort/Icon layout and all control behavior remain unchanged.
- Added runtime-validated live out-of-combat managed synchronization for font size, complete bar/background colors, width, height, and row spacing through the existing configuration apply path.
- Preserved managed self-sizing while synchronizing AuraGroup and native item-enchantment layouts, row/icon geometry, headers, future/reused rows, and fishing-lure spacing.
- Silenced routine automatic managed-routing diagnostics by default while retaining manual diagnostic helpers and unexpected failure output.
- At the preceding checkpoint, kept managed icon-side changes reload-only and retained scale/alpha, growth, placement/position, remaining behavior/filter settings, and production cutover as pending work.
- Advanced live out-of-combat configuration synchronization with LEFT/RIGHT icon reanchoring, ordinary-host scale/alpha, BUFFS/DEBUFFS saved sorting, managed maximum counts, and BUFFS/DEBUFFS FlowLayout growth direction.
- Established the managed ENCHANTMENTS 7+2+1 policy: seven `HelpfulEnhancements`, MainHand/OffHand native providers placed after aura groups in Slot/Normal order, and one fixed ordinary Fishing Lure footer.
- Added bounded native item-enchantment recovery after every world/loading transition by coalescing player inventory activity to one container refresh, with epoch protection and one post-combat completion when required.
- Runtime-validated live icon/scale/alpha/sort/maximum-count synchronization, BUFFS growth direction, and MainHand transition recovery across portals, Home teleport, Hearthstone, dungeon entry/exit, Delve/no-loading-screen behavior, legitimate no-enchant state, and fresh reapplication.
- Documented current native-enchantment runtime coverage: a real MainHand oil passed `/reload`, loading/portal recovery, Fishing Lure coexistence, UP growth, correct duration, native weapon tooltip, and non-combat right-click cancellation without manual refresh. Its observed enchant ID `8051` and PaperDoll values remain evidence only.
- Reclassified OffHand from an implementation gap to opportunistic runtime coverage: it shares the source-validated MainHand registration/recovery path, but no suitable active OffHand test enchant was available and simultaneous-slot behavior remains untested.
- Recorded that supported public temporary-enchantment data does not expose a clean enchant-effect name; tooltip scraping, private-provider inspection, AuraButton enumeration, and hardcoded ID-name maps remain intentionally rejected.
- Completed the Retail `12.1.0.69404` temporary-enchantment naming audit: `enchantID` is an internal item-enchantment identifier with no supported public spell/item/name mapping, while the localized temporary name is exposed only as generic inventory-tooltip text. Native weapon/slot naming plus Blizzard tooltip context is now the final policy rather than an unresolved parity item.
- Removed temporary transition trace instrumentation after diagnosis; normal runtime remains silent.
- Completed live out-of-combat managed ENCHANTMENTS `growUp` synchronization through the shared FlowLayout helper while retaining its separate 7+2+1, Slot/Normal, and legacy-sort/`maxBars` policies.
- Runtime-validated ENCHANTMENTS DOWN/UP switching, reload persistence, mixed managed sources, geometry/icon interactions while UP, loading transitions and native recovery while UP, no-enchant and combat behavior, and the fixed Fishing Lure footer without reported Lua, taint, tooltip, or cancellation regressions.
- Added startup and live out-of-combat managed placement synchronization for saved BUFFS `SCREEN` coordinates and the exact default `BUFFS SCREEN -> DEBUFFS BELOW -> ENCHANTMENTS BELOW` graph. Ordinary hosts are reanchored against actual managed-container bounds; AuraContainers remain self-sizing and externally untouched.
- Routed `Reset Positions` through the existing single `Config:Apply()` bridge after preserving its SavedVariables reset semantics, so legacy refresh, managed apply, and active-page refresh occur together.
- Runtime-validated saved BUFFS placement, DEBUFFS/ENCHANTMENTS offsets, reset, repeated apply, mixed growth/scale, empty managed bounds, combat sizing/chaining, and native weapon-transition recovery. Arbitrary roots/anchors/directions, drag persistence, lock/anchor visibility, and full ENCHANTMENTS bounds remain deferred.
- Expanded managed placement to runtime-validated DEBUFFS and ENCHANTMENTS SCREEN roots while retaining their supported BELOW dependencies, exact SCREEN/BELOW translations, ordinary-host ownership, and out-of-combat-only mutation.
- Added runtime-validated independent dragging and shared-coordinate persistence for all effective managed SCREEN roots, including anchored-child following, anchored-group refusal, lock handling, reload/reset behavior, and combat-interruption restoration without a general placement retry queue.
- Added the development-only `Show Legacy BuffBars` presentation gate and `Legacy Comparison Mode`. The legacy backend stays active; comparison temporarily offsets only effective legacy SCREEN roots by group width plus 24 UI units and never stores the comparison offset in shared placement.
- Runtime-validated managed-only, synchronized overlapping, and side-by-side comparison workflows across supported mixed topologies, dragging, configuration, reset, reload, and combat behavior.
- Extended the existing `anchorsShown` toggle to the three addon-owned managed headers without moving hosts, changing reserved header geometry, or affecting managed containers, aura bars, growth, placement, scale, or development visibility controls.
- Made OBB SavedVariables the sole persistent managed-host position authority by clearing WoW user-placed ownership only after each host is movable, again after successful SCREEN-root drag persistence, and at safe restoration. This fixes stale cached screen anchors replacing saved BELOW dependencies after a full login.
- Runtime-validated managed header visibility and two full exit/login cycles with all three managed hosts reporting `userPlaced=false`; BUFFS dragging immediately carried the configured DEBUFFS/ENCHANTMENTS BELOW chain without anchor-dropdown cycling.
- Added runtime-validated managed RIGHT placement for DEBUFFS relative to BUFFS and ENCHANTMENTS relative to DEBUFFS. RIGHT uses the applied parent logical width rather than an empty managed container's approximately `1 x 1` physical width, so aura appearance/disappearance and live parent-width changes do not cause lateral jumps.
- Added runtime-validated managed LEFT placement for the same supported parent chain. LEFT uses the applied child logical width, keeping the child's logical right edge stable across empty state and live child-width changes without physical width reads or manual container sizing.
- Completed the ABOVE source/architecture decision: managed ABOVE is intentionally unsupported for the prototype/migration period and will retire with the legacy renderer. Existing `ABOVE` values remain preserved rather than silently remapped; explicit cutover handling remains future work.
- At the intermediate behavior/filter checkpoint, centralized complete BUFFS + `HelpfulEnhancements` descriptor composition across semantic routes, overrides, then-active destination filters, and BUFF duration policy.
- At that checkpoint, enforced route-before-destination-filter precedence so destination whitelist membership could not establish ownership.
- At that intermediate checkpoint, applied ENCHANTMENTS spell-ID filters only to `HelpfulEnhancements`; the final policy below subsequently removes managed E destination filtering entirely.
- Added managed BUFF duration policies for ALL and TIMED_ONLY through omission of `maxDuration` or `maxDuration = math.huge`, respectively, without addon-side duration reads. Unsupported TIMELESS_ONLY/NONE combinations retain the last successfully applied supported managed state, with ALL as the fresh-session baseline.
- Made managed DEBUFFS and ENCHANTMENTS intentionally duration-inclusive, removed their Timed/Timeless controls, kept BUFFS controls group-local, and removed both duration flags from `Sync Group Bars` fan-out without migrating or rewriting saved values.
- At the current-ownership checkpoint, replaced historical B/E ownership with a runtime-only readable HELPFUL projection using the shared resolver.
- At that checkpoint, made B/E ownership react immediately to override save/delete and remain independent from then-active destination filtering.
- Kept native MainHand/OffHand and Fishing Lure outside HELPFUL ownership; the final policy below subsequently removes the D/E filter controls.
- Finalized managed destination filtering as BUFFS-only. Managed DEBUFFS and ENCHANTMENTS are intentionally broad/unfiltered, while HELPFUL semantic routing, B/E group overrides, and hidden overrides remain ownership rules rather than destination filters.
- Removed Whitelist/Blacklist controls from D/E and positioned Grow Up directly below Max Bars. Stored D/E filter tables remain unchanged for the legacy renderer, rollback, and historical compatibility.
- Stopped managed `HelpfulEnhancements` eligibility and effective ownership from consuming or being seeded by stored ENCHANTMENTS whitelist/blacklist data; native providers and Fishing Lure remain unaffected.
- Closed the historical transient `classification=nil` HELPFUL-to-ENCHANTMENTS investigation after focused current-architecture diagnostics could not reproduce it across ordinary and semantic aura churn, combat deferral/retry, empty-set reconstruction, descriptor equality, setter application, and a portal/loading transition. The original cause remains unknown, but no current managed-routing implementation blocker was observed.
- Removed the temporary focused HELPFUL-routing instrumentation completely and restored `OdysseusBuffBars_ManagedPrototype.lua` to its exact pre-diagnostic production blob before recording this documentation checkpoint.
