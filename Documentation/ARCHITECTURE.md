# OdysseusBuffBars Architecture

## High-level architecture

OdysseusBuffBars currently retains the legacy production-compatible implementation while running isolated managed BUFFS, DEBUFFS, and ENCHANTMENTS prototypes in parallel for migration testing:

- The legacy compatibility implementation directly scans `C_UnitAuras`, builds addon-owned aura records, renders ordinary custom bars, and uses separate secure cancellation overlays.
- The managed player-BUFFS prototype uses an independent `CustomAuraContainer` with one `HELPFUL` group. Blizzard owns aura identity, duration, sorting, filtering, lifecycle, native tooltip, and native right-click cancellation; the addon owns static styling and the independent position/root frame.
- The isolated managed player-DEBUFFS prototype uses a separate root and `CustomAuraContainer` with `unit="player"` and one broad `HARMFUL` group. Blizzard owns public/private acquisition, presentation updates, sorting, pooling, FlowLayout/self-sizing, and native tooltip behavior. The DEBUFFS prototype does not register cancellation.
- The isolated managed ENCHANTMENTS prototype uses a third chained root and `CustomAuraContainer`. It registers native MainHand and OffHand sources through `AddItemEnchantment` and a separate managed `HelpfulEnhancements` HELPFUL aura group. Blizzard owns those managed rows' presentation state, duration, interaction, provider updates, sorting, and self-sizing. A visually matched ordinary `Fishing Lure` row is anchored below the container as an explicit exception because the managed provider cannot register the fishing profession-tool slot.

The managed player-BUFFS prototype is PTR validated for its core lifecycle, presentation, self-sizing layout, native sorting, whitelist/blacklist filtering, automatic filter-editor synchronization, combat updates, and native interaction. Core managed player-DEBUFFS runtime behavior is validated on Retail Live `12.1.0.69273`. Core managed MainHand lifecycle, dynamic FOOD/FLASK_PHIAL/AUGMENT_RUNE/FISHING_BOBBER routing, and the fishing-lure apply/expire/reapply lifecycle are also validated on Retail Live. Visual parity, live out-of-combat presentation, and growth synchronization now cover all three areas; BUFFS/DEBUFFS additionally consume live saved sort and maximum counts. BUFFS and ENCHANTMENTS growth are directly runtime validated, while DEBUFFS retains its narrower test boundary. They remain parallel prototypes rather than production backends.

Native item-enchantment recovery is armed on every `PLAYER_ENTERING_WORLD`, not only initial login. A temporary player `UNIT_INVENTORY_CHANGED` listener coalesces inventory activity through zero-delay generation checks; one quiet turn unregisters the listener and performs exactly one container-wide refresh. Transition epochs reject stale callbacks, and a completion reached during combat is retained for one post-combat attempt. No native enchant state is copied or reconstructed. The unchanged recovery path is runtime validated with ENCHANTMENTS configured UP and does not reset its growth direction.

## Shared managed presentation

`InitializeManagedBarPresentation(auraButton, style)` owns only common static row construction: background, DurationBar, Icon, SpellName, DurationText, ApplicationCount, text layer, fonts, anchors, colors, icon coordinates, and native presentation-element registration. It does not own sorting, filtering, candidate groups, aura identity, duration calculations, events, cancellation policy, or host positioning. The shared presentation/header helper extraction was runtime validated on BUFFS with no observed regression before it was applied to DEBUFFS and ENCHANTMENTS.

`StyleManagedGroupHeader(header, style)` owns static header geometry, backdrop, background, border, and centered label presentation. It does not own dragging, host movement, sorting, chaining, or configuration.

All three styles begin from `260 x 18` rows, three-pixel spacing, full-coordinate `18 x 18` icons, 11-size name/duration text, 10-size outlined count text, accepted legacy geometry, and `260 x 18` legacy-style headers with a four-pixel first-row gap. Width, height, and row spacing can now change live out of combat; header height remains fixed at 18 pixels. BUFFS uses blue `{0.3, 0.5, 1.0, 0.8}` fill over `{0.0, 0.5, 1.0, 0.1}` background; DEBUFFS uses red `{1.0, 0.0, 0.0, 0.8}` over `{1.0, 0.0, 0.0, 0.1}`; ENCHANTMENTS uses purple `{0.5, 0.0, 0.5, 0.8}` over `{0.5, 0.0, 0.5, 0.1}`.

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

At startup, all three managed groups consume `name`, width, height, spacing, font size, complete bar/background RGBA, icon side, scale, alpha, and growth direction. BUFFS and DEBUFFS also consume compatible saved sort and maximum-bar settings. The managed hosts consume saved placement only for the exact supported `BUFFS SCREEN -> DEBUFFS BELOW BUFFS -> ENCHANTMENTS BELOW DEBUFFS` graph. ENCHANTMENTS deliberately retains its separate prototype sort/cap behavior because one legacy value cannot exactly govern `HelpfulEnhancements`, native item-enchantment rows, and the ordinary fishing-lure row together.

Live out-of-combat synchronization covers `fontSize`, complete `barColor`, complete `barBgColor`, `width`, `height`, `spacing`, `iconSide`, host `scale`, and host `alpha`. Existing and future/reused managed rows use prototype-owned current state. Icon-side changes reanchor retained addon-owned presentation references and recalculate the current height-derived colored boundary without enumerating AuraButtons. Scale and alpha are applied to the ordinary group hosts, so descendants inherit them without changing logical width/height. Replacement layouts preserve current geometry and ENCHANTMENTS native placement.

BUFFS and DEBUFFS live-apply saved sort through Default/Normal, NameOnly/Normal, and ExpirationOnly/Reverse mappings, and live-apply `maxBars` through the public maximum-frame-count setter within the existing 1-80 config range. Their prototype sort buttons remain available as temporary managed overrides but do not write SavedVariables; a later config apply reasserts the saved mode. All three managed containers consume saved `growUp` through TOPLEFT/Right+Down or BOTTOMLEFT/Right+Up FlowLayout while external header/chaining topology stays top-fixed. ENCHANTMENTS participates only in this growth path and remains excluded from global managed sort and maximum synchronization.

Managed placement preserves the same ownership boundary. Saved BUFFS `x`/`y` identify the stack top-left; its ordinary host uses `x - 4` and `y + 22`, accounting for four-pixel host padding plus the fixed 18-pixel header and four-pixel first-row gap so the managed container resolves at the saved coordinate. Each supported BELOW child host anchors `TOPLEFT` to the parent managed container's `BOTTOMLEFT` with `saved offsetX - 4` and the saved `offsetY`; there is no 22-pixel vertical subtraction. Startup and live apply store copied scalar applied state and reanchor only when values change. No scale/pixel conversion branch is used: scale and placement stay independent, and descendant inheritance plus declarative anchors carry growth and scale changes through the chain.

Only the exact supported graph is consumed. Unsupported DEBUFFS/ENCHANTMENTS SCREEN roots, arbitrary `anchorTo` relationships, BUFFS-as-child graphs, LEFT/RIGHT/ABOVE placement, and cycles are left for later design rather than approximated or written back. Placement apply is out-of-combat only and has no retry queue. `Reset Positions` keeps its prior SavedVariables semantics and now calls the normal single `Config:Apply()` path, which performs the legacy refresh, one managed apply, and active-page refresh. The known legacy renderer's scale-related reset jump is not a managed placement failure or part of this checkpoint; because the renderers share SavedVariables, managed placement consumes the coordinates left by the legacy path.

The managed BUFFS filter compiler reuses `groupSettings.filters.whitelist` and `groupSettings.filters.blacklist`. The existing legacy filter editor remains the single editing UI and synchronizes the long-lived managed group out of combat. No managed-only SavedVariables or duplicate filter editor were added.

The managed DEBUFFS group intentionally does not use candidate spell-ID maps or connect the existing DEBUFFS filter editor. Under the Retail 12.1 managed security model, non-`NeverSecret` harmful auras on the assistable player unit skip identity include/exclude maps, so general legacy whitelist/blacklist parity is unavailable. Existing saved numeric IDs remain intact pending a final product-policy decision; this is a deliberate compatibility limitation, not a broken filter implementation.

Managed ENCHANTMENTS uses a deliberate 7+2+1 capacity policy: seven `HelpfulEnhancements`, two registered native providers (MainHand and OffHand), and one ordinary Fishing Lure footer. Fishing Bobber is a HELPFUL aura and consumes one of the seven aura slots; it is not the lure footer. Native enchantments use `AfterAuraGroups` placement and Slot/Normal ordering, producing the DOWN order HelpfulEnhancements, MainHand, OffHand, then Fishing Lure. In UP mode Blizzard reverses spatial progression while preserving logical source sequence, so native rows move toward the header and `HelpfulEnhancements` occupies the lower managed portion. The ordinary lure stays below the container as a fixed footer outside FlowLayout in both directions. Ranged is not registered. Legacy ENCHANTMENTS sort/`maxBars` remain stored for compatibility but are intentionally ignored by the managed policy; no schema change was made.

An empty managed container may collapse to its approximately `1 x 1` managed bound, unlike the legacy renderer's one-row minimum. BELOW follows that actual bound; no fake minimum or manual sizing is added. ENCHANTMENTS is terminal in the supported graph because its ordinary Fishing Lure footer is outside the managed container and therefore outside that container's bounds. A future downstream parent/full-visible-bounds design remains research work.

Visual parity and the expanded configuration checkpoint are runtime validated for live icon side, scale/alpha, BUFFS/DEBUFFS saved sort and maximum counts, BUFFS and ENCHANTMENTS growth direction, and the restricted saved SCREEN/BELOW placement graph in addition to the earlier presentation slice. DEBUFFS uses the same supported growth implementation without equivalent direct real-HARMFUL coverage. Arbitrary placement, managed drag persistence, lock/anchor-visibility parity, remaining behavior/filter settings, and production integration remain pending.

## Combat restrictions

Managed aura updates, duration presentation, sorting, and already-applied candidate filters continue to operate during combat. Dragging, sort changes, BUFFS filter mutation, HELPFUL enhancement rediscovery, and fishing-lure API refreshes are blocked or deferred during combat; pending routing/lure refreshes retry after `PLAYER_REGEN_ENABLED`.

`ManagedPrototype:ApplyConfiguration()` also refuses managed presentation mutation during combat and returns `false, "combat lockdown"`. It does not queue or defer configuration changes. The normal configuration UI already prevents its mutation paths during combat; this is not combat-capable live restyling.

The native-enchantment transition recovery is the narrow exception to the no-deferred-configuration statement: if its one-shot completion reaches combat, that recovery alone may finish after `PLAYER_REGEN_ENABLED`. This does not create a general configuration queue.

Routine automatic HELPFUL-routing diagnostics are silent by default behind a local debug gate. Explicit manual diagnostic helpers and unexpected discovery/filter failures remain visible; no SavedVariables debug setting was added.

The legacy direct scanner becomes unavailable or secret in Retail 12.1 combat. Its `pcall` containment limits repeated failures but cannot restore correct state, and its indexed aura tooltip path is suppressed on Retail 12.1+. These are legacy limitations, not managed-frame failures.

## Retail 12.1 transition

- The managed player-BUFFS prototype is a validated parallel implementation, not a completed production cutover.
- The managed player-DEBUFFS prototype has core Retail Live runtime validation, including all three native sort mappings, native combat tooltip behavior, and dynamic BUFFS-to-DEBUFFS layout propagation, but remains isolated, broadly filtered, and not production-integrated.
- The managed ENCHANTMENTS prototype has validated MainHand behavior, bounded loading/world-transition recovery, FOOD/FLASK_PHIAL/AUGMENT_RUNE/FISHING_BOBBER routing, and the ordinary fishing-lure lifecycle. Native weapon rows support right-click cancellation; the lure footer does not. Direct OffHand-only/simultaneous-slot transition coverage, combat cancellation, permanent/zero-duration behavior, Ranged, final temporary-enchant naming, and broader native enchant coverage remain pending.
- Blizzard-managed default buff icons still reappear when combat begins even when the legacy `Hide Blizzard Icons` option hides them out of combat. This is unresolved and separate from the managed AuraContainer work.
- A known real private harmful aura, optional explicit secrecy/`NeverSecret` tests, the DEBUFFS filtering product decision, broader native item-enchantment/effect coverage, unsupported placement graphs/directions, drag/lock/anchor-visibility parity, remaining behavior/filter integration, legacy-only ENCHANTMENTS control cleanup, persistence, production cutover, rollback policy, and removal of the legacy scanner remain future work.
- Detailed architectural history, validation evidence, and rollback boundaries are preserved in `MANAGED_AURACONTAINER_MIGRATION.md`.
