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

- Added runtime-validated live out-of-combat managed synchronization for font size, complete bar/background colors, width, height, and row spacing through the existing configuration apply path.
- Preserved managed self-sizing while synchronizing AuraGroup and native item-enchantment layouts, row/icon geometry, headers, future/reused rows, and fishing-lure spacing.
- Silenced routine automatic managed-routing diagnostics by default while retaining manual diagnostic helpers and unexpected failure output.
- At the preceding checkpoint, kept managed icon-side changes reload-only and retained scale/alpha, growth, placement/position, remaining behavior/filter settings, and production cutover as pending work.
- Advanced live out-of-combat configuration synchronization with LEFT/RIGHT icon reanchoring, ordinary-host scale/alpha, BUFFS/DEBUFFS saved sorting, managed maximum counts, and BUFFS/DEBUFFS FlowLayout growth direction.
- Established the managed ENCHANTMENTS 7+2+1 policy: seven `HelpfulEnhancements`, MainHand/OffHand native providers placed after aura groups in Slot/Normal order, and one fixed ordinary Fishing Lure footer.
- Added bounded native item-enchantment recovery after every world/loading transition by coalescing player inventory activity to one container refresh, with epoch protection and one post-combat completion when required.
- Runtime-validated live icon/scale/alpha/sort/maximum-count synchronization, BUFFS growth direction, and MainHand transition recovery across portals, Home teleport, Hearthstone, dungeon entry/exit, Delve/no-loading-screen behavior, legitimate no-enchant state, and fresh reapplication.
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
