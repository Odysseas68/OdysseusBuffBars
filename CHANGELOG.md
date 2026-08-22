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
