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
- Kept managed icon-side changes reload-only and retained scale/alpha, growth, placement/position, remaining behavior/filter settings, and production cutover as pending work.
