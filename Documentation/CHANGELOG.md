# Changelog

Historical development prior to the creation of this document is intentionally not reconstructed. Future project changes should be recorded here from this point forward.

## Unreleased

### Added

- Established the initial project documentation structure.
- Added an isolated parallel player-BUFFS `CustomAuraContainer` prototype with container-owned AuraButtons.
- Added managed bar presentation for icon, spell name, application count, duration text, duration StatusBar, timeless auras, native tooltip, and native right-click cancellation.
- Added native Default, Name, and Time Left sorting to the managed prototype.
- Added managed player-BUFFS whitelist/blacklist filtering that reuses the existing SavedVariables fields.

### Changed

- Renamed the addon, manifest, and canonical Lua files from `OdysseusBuffBarsTest` to `OdysseusBuffBars`.
- Adopted `OdysseusBuffBarsDB` as the canonical SavedVariables table.
- Changed the managed layout to let `CustomAuraContainer` self-size from displayed AuraButtons; the configured maximum of thirty remains capacity only.
- Synchronized allowed out-of-combat mutations from the existing BUFFS filter editor to the long-lived managed group without polling, a duplicate editor, or an `Apply Filters` button.
- Added temporary Retail 12.1 containment for legacy direct-scanner failures and suppressed the incompatible legacy indexed-aura tooltip path on Retail 12.1+.

### Compatibility

- Existing `OdysseusBuffBarsTestDB` settings are adopted only when `OdysseusBuffBarsDB` is absent; the legacy table is not merged or deleted.
- Retained `/obbtest` as a compatibility alias alongside `/obb` and `/buffbars`.

### PTR validation

- Validated the parallel managed player-BUFFS architecture and AuraButton presentation on the Retail 12.1 PTR.
- Validated dynamic grow/shrink, more than ten displayed buffs, thirty-frame capacity, near-empty collapse, combat updates, drag locking, reload behavior, timed and timeless auras, and application counts.
- Validated native tooltip and right-click cancellation during combat.
- Validated native Default, Name, and Time Left sorting, including legacy-compatible timeless-first and longest-to-shortest Time Left ordering.
- Validated whitelist/blacklist semantics, whitelist precedence, and automatic synchronization with the existing filter editor.
- Observed no Lua errors, taint, or blocked actions during the managed player-BUFFS validation.
- Debuffs, Enhancements, final configuration integration, Blizzard BuffFrame visibility, and production cutover remain incomplete.
