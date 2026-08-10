# OdysseusBuffBars Architecture

## High-level architecture

OdysseusBuffBars currently runs two player-BUFFS implementations in parallel for migration testing:

- The legacy compatibility implementation directly scans `C_UnitAuras`, builds addon-owned aura records, renders ordinary custom bars, and uses separate secure cancellation overlays.
- The managed prototype uses a `CustomAuraContainer` with container-owned AuraButtons. Blizzard owns aura identity, duration, sorting, filtering, lifecycle, tooltip, and cancellation; the addon owns only static styling and the independent position/root frame.

The managed player-BUFFS prototype is PTR validated for its core lifecycle, presentation, self-sizing layout, native sorting, whitelist/blacklist filtering, automatic filter-editor synchronization, combat updates, and native interaction. It is not yet the production backend. Debuffs and Enhancements still use the legacy implementation.

## SavedVariables and configuration

The managed BUFFS filter compiler reuses `groupSettings.filters.whitelist` and `groupSettings.filters.blacklist`. The existing legacy filter editor remains the single editing UI and synchronizes the long-lived managed group out of combat. No managed-only SavedVariables or duplicate filter editor were added.

Prototype position and sort selection are not persisted. Full configuration integration remains pending.

## Combat restrictions

Managed aura updates, duration presentation, sorting, and the active candidate filter continue to operate during combat. Dragging, sort changes, and filter mutation remain blocked during combat; the controls become usable again afterward.

The legacy direct scanner becomes unavailable or secret in Retail 12.1 combat. Its `pcall` containment limits repeated failures but cannot restore correct state, and its indexed aura tooltip path is suppressed on Retail 12.1+. These are legacy limitations, not managed-frame failures.

## Retail 12.1 transition

- The managed player-BUFFS prototype is a validated parallel implementation, not a completed production cutover.
- Blizzard-managed default buff icons still reappear when combat begins even when the legacy `Hide Blizzard Icons` option hides them out of combat. This is unresolved and separate from the managed AuraContainer work.
- Visual parity, persistent positioning, final configuration integration, Debuffs, Enhancements/item enchantments, production cutover, and removal of the legacy scanner remain future work.
- Detailed architectural history, validation evidence, and rollback boundaries are preserved in `MANAGED_AURACONTAINER_MIGRATION.md`.
