# OdysseusBuffBars Architecture

## High-level architecture

OdysseusBuffBars currently retains the legacy production-compatible implementation while running isolated managed BUFFS and DEBUFFS prototypes in parallel for migration testing:

- The legacy compatibility implementation directly scans `C_UnitAuras`, builds addon-owned aura records, renders ordinary custom bars, and uses separate secure cancellation overlays.
- The managed player-BUFFS prototype uses an independent `CustomAuraContainer` with one `HELPFUL` group. Blizzard owns aura identity, duration, sorting, filtering, lifecycle, native tooltip, and native right-click cancellation; the addon owns static styling and the independent position/root frame.
- The isolated managed player-DEBUFFS prototype uses a separate root and `CustomAuraContainer` with `unit="player"` and one broad `HARMFUL` group. Blizzard owns public/private acquisition, presentation updates, sorting, pooling, FlowLayout/self-sizing, and native tooltip behavior. The DEBUFFS prototype does not register cancellation.

The managed player-BUFFS prototype is PTR validated for its core lifecycle, presentation, self-sizing layout, native sorting, whitelist/blacklist filtering, automatic filter-editor synchronization, combat updates, and native interaction. Core managed player-DEBUFFS runtime behavior is validated on Retail Live `12.1.0.69273`, including simultaneous harmful auras, combat additions/refreshes/removals, all five presentation bindings, all three native sort mappings, native combat tooltips, and simultaneous operation with managed BUFFS. The DEBUFFS host follows the dynamically self-sizing BUFFS container through a one-directional managed-bounds anchor, while retaining independent managed grow/shrink below it. Targeted private-aura and explicit secrecy/restriction tests remain pending. Neither prototype is a production backend; legacy DEBUFFS remains present, and managed ENCHANTMENTS has not been implemented.

## SavedVariables and configuration

The managed BUFFS filter compiler reuses `groupSettings.filters.whitelist` and `groupSettings.filters.blacklist`. The existing legacy filter editor remains the single editing UI and synchronizes the long-lived managed group out of combat. No managed-only SavedVariables or duplicate filter editor were added.

The managed DEBUFFS group intentionally does not use candidate spell-ID maps or connect the existing DEBUFFS filter editor. Under the Retail 12.1 managed security model, non-`NeverSecret` harmful auras on the assistable player unit skip identity include/exclude maps, so general legacy whitelist/blacklist parity is unavailable. Existing saved numeric IDs remain intact pending a final product-policy decision; this is a deliberate compatibility limitation, not a broken filter implementation.

Prototype position and sort selection are not persisted. Full configuration integration remains pending.

## Combat restrictions

Managed aura updates, duration presentation, sorting, and the BUFFS candidate filter continue to operate during combat. Dragging and sort changes are blocked for both prototypes, while BUFFS filter mutation remains blocked during combat; the controls become usable again afterward.

The legacy direct scanner becomes unavailable or secret in Retail 12.1 combat. Its `pcall` containment limits repeated failures but cannot restore correct state, and its indexed aura tooltip path is suppressed on Retail 12.1+. These are legacy limitations, not managed-frame failures.

## Retail 12.1 transition

- The managed player-BUFFS prototype is a validated parallel implementation, not a completed production cutover.
- The managed player-DEBUFFS prototype has core Retail Live runtime validation, including all three native sort mappings, native combat tooltip behavior, and dynamic BUFFS-to-DEBUFFS layout propagation, but remains isolated, broadly filtered, and not production-integrated.
- Blizzard-managed default buff icons still reappear when combat begins even when the legacy `Hide Blizzard Icons` option hides them out of combat. This is unresolved and separate from the managed AuraContainer work.
- A known real private harmful aura, optional explicit secrecy/`NeverSecret` tests, the DEBUFFS filtering product decision, visual parity, persistence, final configuration integration, managed Enhancements/item enchantments, production cutover, and removal of the legacy scanner remain future work.
- Detailed architectural history, validation evidence, and rollback boundaries are preserved in `MANAGED_AURACONTAINER_MIGRATION.md`.
