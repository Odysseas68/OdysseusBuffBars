# OdysseusBuffBars Architecture

## High-level architecture

OdysseusBuffBars currently retains the legacy production-compatible implementation while running isolated managed BUFFS, DEBUFFS, and ENCHANTMENTS prototypes in parallel for migration testing:

- The legacy compatibility implementation directly scans `C_UnitAuras`, builds addon-owned aura records, renders ordinary custom bars, and uses separate secure cancellation overlays.
- The managed player-BUFFS prototype uses an independent `CustomAuraContainer` with one `HELPFUL` group. Blizzard owns aura identity, duration, sorting, filtering, lifecycle, native tooltip, and native right-click cancellation; the addon owns static styling and the independent position/root frame.
- The isolated managed player-DEBUFFS prototype uses a separate root and `CustomAuraContainer` with `unit="player"` and one broad `HARMFUL` group. Blizzard owns public/private acquisition, presentation updates, sorting, pooling, FlowLayout/self-sizing, and native tooltip behavior. The DEBUFFS prototype does not register cancellation.
- The isolated managed ENCHANTMENTS prototype uses a third chained root and `CustomAuraContainer`. It registers native MainHand and OffHand sources through `AddItemEnchantment` and a separate managed `HelpfulEnhancements` HELPFUL aura group. Blizzard owns those managed rows' presentation state, duration, interaction, provider updates, sorting, and self-sizing. A visually matched ordinary `Fishing Lure` row is anchored below the container as an explicit exception because the managed provider cannot register the fishing profession-tool slot.

The managed player-BUFFS prototype is PTR validated for its core lifecycle, presentation, self-sizing layout, native sorting, whitelist/blacklist filtering, automatic filter-editor synchronization, combat updates, and native interaction. Core managed player-DEBUFFS runtime behavior is validated on Retail Live `12.1.0.69273`. Core managed MainHand lifecycle, dynamic FOOD/FLASK_PHIAL/AUGMENT_RUNE/FISHING_BOBBER routing, and the fishing-lure apply/expire/reapply lifecycle are also validated on Retail Live. Static visual comparison against the legacy renderer now passes for all three managed areas. They remain parallel prototypes rather than production backends.

Cold-login recovery keeps the normal `PLAYER_ENTERING_WORLD` refresh and, on initial login only, temporarily listens for player `UNIT_INVENTORY_CHANGED`. Each event advances an activity generation while at most one `C_Timer.After(0)` check is pending. Continued activity defers another turn; one unchanged turn unregisters the listener, clears startup state, and performs exactly one final item-enchantment refresh. Callback ordinals 69, 105, and 430 were diagnostic evidence, not implementation thresholds.

## Shared managed presentation

`InitializeManagedBarPresentation(auraButton, style)` owns only common static row construction: background, DurationBar, Icon, SpellName, DurationText, ApplicationCount, text layer, fonts, anchors, colors, icon coordinates, and native presentation-element registration. It does not own sorting, filtering, candidate groups, aura identity, duration calculations, events, cancellation policy, or host positioning. The shared presentation/header helper extraction was runtime validated on BUFFS with no observed regression before it was applied to DEBUFFS and ENCHANTMENTS.

`StyleManagedGroupHeader(header, style)` owns static header geometry, backdrop, background, border, and centered label presentation. It does not own dragging, host movement, sorting, chaining, or configuration.

All three styles use `260 x 18` rows, three-pixel spacing, full-coordinate `18 x 18` icons, 11-size name/duration text, 10-size outlined count text, accepted legacy geometry, and `260 x 18` legacy-style headers with a four-pixel first-row gap. BUFFS uses blue `{0.3, 0.5, 1.0, 0.8}` fill over `{0.0, 0.5, 1.0, 0.1}` background; DEBUFFS uses red `{1.0, 0.0, 0.0, 0.8}` over `{1.0, 0.0, 0.0, 0.1}`; ENCHANTMENTS uses purple `{0.5, 0.0, 0.5, 0.8}` over `{0.5, 0.0, 0.5, 0.1}`.

Managed rows retain native AuraButton ownership, duration text/bar, tooltips, sorting, supported cancellation, and container self-sizing. The fishing-lure exception is an ordinary row with a presentation-only local timer; its presence remains event/API driven.

## SavedVariables and configuration

Managed construction begins only after the addon has adopted SavedVariables, filled defaults, completed migrations, normalized every group, and assigned `OBB.db`:

```text
ADDON_LOADED
-> SavedVariables adoption/defaults/migrations
-> ManagedPrototype:Initialize()
-> managed UI/event construction
```

`ManagedPrototype:Initialize()` is idempotent. The managed Lua file does not construct containers, event frames, or the fishing-lure row at file-load time. Initialization builds a prototype-owned startup snapshot with copied style/color values rather than retaining mutable SavedVariables color-table references.

The existing configuration layer remains the only owner of control behavior and `syncGroupBars` fan-out. After it mutates SavedVariables, one centralized apply bridges both renderers:

```text
OdysseusBuffBarsDB
        |
existing config layer
        |
Config:Apply()
        +- legacy RefreshAll()
        L- ManagedPrototype:ApplyConfiguration()
                    |
          managed presentation state
```

At startup, all three managed groups consume `name`, width, height, spacing, font size, complete bar/background RGBA, icon side, scale, and alpha. BUFFS and DEBUFFS also consume compatible saved sort and maximum-bar settings. ENCHANTMENTS deliberately retains its separate prototype sort/cap behavior because one legacy value cannot exactly govern `HelpfulEnhancements`, native item-enchantment rows, and the ordinary fishing-lure row together.

Live out-of-combat synchronization is currently limited to font size and complete bar/background RGBA. It updates tracked presentation descendants for existing rows, while the current presentation state is also used by newly assigned, created, or reused managed rows and by the fishing-lure presentation. It does not enumerate active managed children, infer active counts, or inspect aura identity. Geometry, spacing, icon side, scale, alpha, header text, sort, maximum bars, placement, chaining, and growth remain startup-only or pending as applicable.

The managed BUFFS filter compiler reuses `groupSettings.filters.whitelist` and `groupSettings.filters.blacklist`. The existing legacy filter editor remains the single editing UI and synchronizes the long-lived managed group out of combat. No managed-only SavedVariables or duplicate filter editor were added.

The managed DEBUFFS group intentionally does not use candidate spell-ID maps or connect the existing DEBUFFS filter editor. Under the Retail 12.1 managed security model, non-`NeverSecret` harmful auras on the assistable player unit skip identity include/exclude maps, so general legacy whitelist/blacklist parity is unavailable. Existing saved numeric IDs remain intact pending a final product-policy decision; this is a deliberate compatibility limitation, not a broken filter implementation.

The managed ENCHANTMENTS prototype consumes compatible startup presentation settings and the narrow live font/color slice, but it has no exact combined saved sort/maximum-bar mapping, managed position persistence, or full configuration parity. Native item enchantments remain separate from the `HelpfulEnhancements` managed HELPFUL group and the ordinary fishing-lure exception. Readable active HELPFUL spell metadata is classified through `well fed`, `flask`/`phial`, `augment rune`, and `bobber` markers; the resulting session-only spell-ID membership is applied as ENCHANTMENTS includes and BUFFS exclusions. Duration is not semantic classification. No item IDs, hardcoded routing spell-ID table, duration thresholds, or persisted discovery data are used.

Static visual parity and the Phase A.1/C.1 configuration checkpoint are runtime validated. Live out-of-combat restyling currently covers only font and bar/background colors; broader geometry/layout synchronization, managed position persistence, and production integration remain pending.

## Combat restrictions

Managed aura updates, duration presentation, sorting, and already-applied candidate filters continue to operate during combat. Dragging, sort changes, BUFFS filter mutation, HELPFUL enhancement rediscovery, and fishing-lure API refreshes are blocked or deferred during combat; pending routing/lure refreshes retry after `PLAYER_REGEN_ENABLED`.

`ManagedPrototype:ApplyConfiguration()` also refuses managed presentation mutation during combat and returns `false, "combat lockdown"`. It does not queue or defer configuration changes. The normal configuration UI already prevents its mutation paths during combat; this is not combat-capable live restyling.

The legacy direct scanner becomes unavailable or secret in Retail 12.1 combat. Its `pcall` containment limits repeated failures but cannot restore correct state, and its indexed aura tooltip path is suppressed on Retail 12.1+. These are legacy limitations, not managed-frame failures.

## Retail 12.1 transition

- The managed player-BUFFS prototype is a validated parallel implementation, not a completed production cutover.
- The managed player-DEBUFFS prototype has core Retail Live runtime validation, including all three native sort mappings, native combat tooltip behavior, and dynamic BUFFS-to-DEBUFFS layout propagation, but remains isolated, broadly filtered, and not production-integrated.
- The managed ENCHANTMENTS prototype has validated MainHand Phoenix Oil behavior, quiet-turn cold-login recovery, FOOD/FLASK_PHIAL/AUGMENT_RUNE/FISHING_BOBBER routing, and the ordinary fishing-lure lifecycle. Native weapon rows support right-click cancellation; the fishing-lure row does not. OffHand, simultaneous slots, native duration ordering, combat cancellation, permanent/zero-duration behavior, Ranged, final temporary-enchant naming, and broader native enchant coverage remain pending.
- Blizzard-managed default buff icons still reappear when combat begins even when the legacy `Hide Blizzard Icons` option hides them out of combat. This is unresolved and separate from the managed AuraContainer work.
- A known real private harmful aura, optional explicit secrecy/`NeverSecret` tests, the DEBUFFS filtering product decision, broader native item-enchantment/effect coverage, geometry/layout configuration synchronization, persistence, production cutover, rollback policy, and removal of the legacy scanner remain future work.
- Detailed architectural history, validation evidence, and rollback boundaries are preserved in `MANAGED_AURACONTAINER_MIGRATION.md`.
