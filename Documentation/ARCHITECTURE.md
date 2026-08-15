# OdysseusBuffBars Architecture

## High-level architecture

OdysseusBuffBars currently retains the legacy production-compatible implementation while running isolated managed BUFFS, DEBUFFS, and ENCHANTMENTS prototypes in parallel for migration testing:

- The legacy compatibility implementation directly scans `C_UnitAuras`, builds addon-owned aura records, renders ordinary custom bars, and uses separate secure cancellation overlays.
- The managed player-BUFFS prototype uses an independent `CustomAuraContainer` with one `HELPFUL` group. Blizzard owns aura identity, duration, sorting, filtering, lifecycle, native tooltip, and native right-click cancellation; the addon owns static styling and the independent position/root frame.
- The isolated managed player-DEBUFFS prototype uses a separate root and `CustomAuraContainer` with `unit="player"` and one broad `HARMFUL` group. Blizzard owns public/private acquisition, presentation updates, sorting, pooling, FlowLayout/self-sizing, and native tooltip behavior. The DEBUFFS prototype does not register cancellation.
- The isolated managed ENCHANTMENTS prototype uses a third chained root and `CustomAuraContainer`. It registers native MainHand and OffHand sources through `AddItemEnchantment` and a separate managed `HelpfulEnhancements` HELPFUL aura group. Blizzard owns managed presentation, duration, interaction, provider updates, sorting, and self-sizing. Ranged is intentionally not registered.

The managed player-BUFFS prototype is PTR validated for its core lifecycle, presentation, self-sizing layout, native sorting, whitelist/blacklist filtering, automatic filter-editor synchronization, combat updates, and native interaction. Core managed player-DEBUFFS runtime behavior is validated on Retail Live `12.1.0.69273`, including simultaneous harmful auras, combat additions/refreshes/removals, all five presentation bindings, all three native sort mappings, native combat tooltips, and simultaneous operation with managed BUFFS. Core managed MainHand temporary-enchantment lifecycle and dynamic semantic Food, Flask/Phial, and Augment Rune routing are also validated on Retail Live. All three managed areas remain parallel prototypes rather than production backends.

Cold-login recovery keeps the normal `PLAYER_ENTERING_WORLD` refresh and, on initial login only, temporarily listens for player `UNIT_INVENTORY_CHANGED`. Each event advances an activity generation while at most one `C_Timer.After(0)` check is pending. Continued activity defers another turn; one unchanged turn unregisters the listener, clears startup state, and performs exactly one final item-enchantment refresh. Callback ordinals 69, 105, and 430 were diagnostic evidence, not implementation thresholds.

## SavedVariables and configuration

The managed BUFFS filter compiler reuses `groupSettings.filters.whitelist` and `groupSettings.filters.blacklist`. The existing legacy filter editor remains the single editing UI and synchronizes the long-lived managed group out of combat. No managed-only SavedVariables or duplicate filter editor were added.

The managed DEBUFFS group intentionally does not use candidate spell-ID maps or connect the existing DEBUFFS filter editor. Under the Retail 12.1 managed security model, non-`NeverSecret` harmful auras on the assistable player unit skip identity include/exclude maps, so general legacy whitelist/blacklist parity is unavailable. Existing saved numeric IDs remain intact pending a final product-policy decision; this is a deliberate compatibility limitation, not a broken filter implementation.

The managed ENCHANTMENTS prototype has no SavedVariables, persistence, or configuration integration. Native item enchantments remain separate from the `HelpfulEnhancements` managed HELPFUL group. Readable active HELPFUL spell metadata is classified with explicit semantic markers, and the resulting session-only spell-ID membership is applied as ENCHANTMENTS includes and BUFFS exclusions. No item IDs, hardcoded routing spell-ID table, duration thresholds, or persisted discovery data are used.

Prototype position and sort selection are not persisted. Full configuration integration remains pending.

## Combat restrictions

Managed aura updates, duration presentation, sorting, and already-applied candidate filters continue to operate during combat. Dragging, sort changes, BUFFS filter mutation, and HELPFUL enhancement rediscovery are blocked or deferred during combat; pending routing discovery retries after `PLAYER_REGEN_ENABLED`.

The legacy direct scanner becomes unavailable or secret in Retail 12.1 combat. Its `pcall` containment limits repeated failures but cannot restore correct state, and its indexed aura tooltip path is suppressed on Retail 12.1+. These are legacy limitations, not managed-frame failures.

## Retail 12.1 transition

- The managed player-BUFFS prototype is a validated parallel implementation, not a completed production cutover.
- The managed player-DEBUFFS prototype has core Retail Live runtime validation, including all three native sort mappings, native combat tooltip behavior, and dynamic BUFFS-to-DEBUFFS layout propagation, but remains isolated, broadly filtered, and not production-integrated.
- The managed ENCHANTMENTS prototype has a validated MainHand Phoenix Oil lifecycle, quiet-turn cold-login recovery, and dynamic semantic `HelpfulEnhancements` routing with paired BUFFS de-duplication. OffHand, simultaneous slots, native duration ordering, combat cancellation, permanent/zero-duration behavior, Ranged, final temporary-enchant naming, and broader native enchant coverage remain pending.
- Blizzard-managed default buff icons still reappear when combat begins even when the legacy `Hide Blizzard Icons` option hides them out of combat. This is unresolved and separate from the managed AuraContainer work.
- A known real private harmful aura, optional explicit secrecy/`NeverSecret` tests, the DEBUFFS filtering product decision, broader native item-enchantment parity, visual parity, persistence, final configuration integration, production cutover, and removal of the legacy scanner remain future work.
- Detailed architectural history, validation evidence, and rollback boundaries are preserved in `MANAGED_AURACONTAINER_MIGRATION.md`.
