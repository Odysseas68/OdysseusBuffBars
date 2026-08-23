# OdysseusBuffBars Architecture

## High-level architecture

OdysseusBuffBars currently retains the legacy production-compatible implementation while running isolated managed BUFFS, DEBUFFS, and ENCHANTMENTS prototypes in parallel for migration testing:

- The legacy compatibility implementation directly scans `C_UnitAuras`, builds addon-owned aura records, renders ordinary custom bars, and uses separate secure cancellation overlays.
- The managed player-BUFFS prototype uses an independent `CustomAuraContainer` with one `HELPFUL` group. Blizzard owns aura identity, duration, sorting, filtering, lifecycle, native tooltip, and native right-click cancellation; the addon owns static styling and the independent position/root frame.
- The isolated managed player-DEBUFFS prototype uses a separate root and `CustomAuraContainer` with `unit="player"` and one broad `HARMFUL` group. Blizzard owns public/private acquisition, presentation updates, sorting, pooling, FlowLayout/self-sizing, and native tooltip behavior. The DEBUFFS prototype does not register cancellation.
- The isolated managed ENCHANTMENTS prototype uses a third chained root and `CustomAuraContainer`. It registers native MainHand and OffHand sources through `AddItemEnchantment` and a separate managed `HelpfulEnhancements` HELPFUL aura group. Blizzard owns those managed rows' presentation state, duration, interaction, provider updates, sorting, and self-sizing. A visually matched ordinary `Fishing Lure` row is anchored below the container as an explicit exception because the managed provider cannot register the fishing profession-tool slot.

The managed player-BUFFS prototype is PTR validated for its core lifecycle, presentation, self-sizing layout, native sorting, whitelist/blacklist filtering, automatic filter-editor synchronization, combat updates, and native interaction. Core managed player-DEBUFFS runtime behavior is validated on Retail Live `12.1.0.69273`. Core managed MainHand lifecycle, dynamic FOOD/FLASK_PHIAL/AUGMENT_RUNE/FISHING_BOBBER routing, and the fishing-lure apply/expire/reapply lifecycle are also validated on Retail Live. Visual parity, live out-of-combat presentation, growth synchronization, supported SCREEN/BELOW placement, SCREEN-root dragging/persistence, and the temporary legacy comparison workflow now cover all three areas; BUFFS/DEBUFFS additionally consume live saved sort and maximum counts. BUFFS and ENCHANTMENTS growth are directly runtime validated, while DEBUFFS retains its narrower test boundary. They remain parallel prototypes rather than production backends.

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

At startup, all three managed groups consume `name`, width, height, spacing, font size, complete bar/background RGBA, icon side, scale, alpha, and growth direction. BUFFS and DEBUFFS also consume compatible saved sort and maximum-bar settings. Managed placement requires BUFFS as SCREEN; DEBUFFS may be SCREEN or BELOW BUFFS, and ENCHANTMENTS may be SCREEN or BELOW DEBUFFS. ENCHANTMENTS deliberately retains its separate prototype sort/cap behavior because one legacy value cannot exactly govern `HelpfulEnhancements`, native item-enchantment rows, and the ordinary fishing-lure row together.

Live out-of-combat synchronization covers `fontSize`, complete `barColor`, complete `barBgColor`, `width`, `height`, `spacing`, `iconSide`, host `scale`, and host `alpha`. Existing and future/reused managed rows use prototype-owned current state. Icon-side changes reanchor retained addon-owned presentation references and recalculate the current height-derived colored boundary without enumerating AuraButtons. Scale and alpha are applied to the ordinary group hosts, so descendants inherit them without changing logical width/height. Replacement layouts preserve current geometry and ENCHANTMENTS native placement.

BUFFS and DEBUFFS live-apply saved sort through Default/Normal, NameOnly/Normal, and ExpirationOnly/Reverse mappings, and live-apply `maxBars` through the public maximum-frame-count setter within the existing 1-80 config range. Their prototype sort buttons remain available as temporary managed overrides but do not write SavedVariables; a later config apply reasserts the saved mode. All three managed containers consume saved `growUp` through TOPLEFT/Right+Down or BOTTOMLEFT/Right+Up FlowLayout while external header/chaining topology stays top-fixed. ENCHANTMENTS participates only in this growth path and remains excluded from global managed sort and maximum synchronization.

Managed placement preserves the same ownership boundary. Every supported SCREEN root's saved `x`/`y` identifies its logical stack top-left; the ordinary host uses `x - 4` and `y + 22`, accounting for four-pixel host padding plus the fixed 18-pixel header and four-pixel first-row gap so the managed container resolves at the saved coordinate. Each supported BELOW child host anchors `TOPLEFT` to the parent managed container's `BOTTOMLEFT` with `saved offsetX - 4` and the saved `offsetY`; there is no 22-pixel vertical subtraction. DEBUFFS and ENCHANTMENTS hosts use `DisableUntrustedLayoutScriptsTemplate` and can switch out of combat between their supported SCREEN roots and BELOW dependencies. Startup and live apply store copied scalar applied state and reanchor only when values change. No scale/pixel conversion branch is used: scale and placement stay independent, and descendant inheritance plus declarative anchors carry growth and scale changes through the chain.

OBB SavedVariables are the sole persistent authority for those ordinary hosts. `StartMoving()` can mark a named frame as user placed, allowing WoW's frame-position cache to restore stale screen anchors over the saved BELOW graph at login. Each host is therefore made movable before `SetUserPlaced(false)` during creation, and successful drag-stop clears user-placed ownership after saving the unchanged inverse-translation coordinates. Safe post-combat restoration clears it again. The movable-first order is required because Retail rejects `SetUserPlaced(false)` on a frame that is not yet movable or resizable. No polling, container inspection, or new placement retry queue is involved.

Only supported states are consumed. BUFFS-as-child graphs, arbitrary `anchorTo` relationships, LEFT/RIGHT/ABOVE placement, and broader cycle parity are left for later design rather than approximated or written back. Each effective SCREEN root can be dragged independently only while out of combat, unlocked, saved as SCREEN, and already applied as SCREEN. Dragging moves the ordinary host; drag-stop applies the inverse translation to real shared `x`/`y`, records copied applied state, and asks the legacy presentation to resynchronize. Anchored groups refuse direct movement with the existing parent-anchor warning. Combat start rejects a new drag; if combat interrupts movement, the host stops without persisting the interrupted position and the previous applied SCREEN point is restored after combat. This restoration is specific to interrupted dragging and does not create a general placement retry queue. `Reset Positions` keeps its prior SavedVariables semantics and normal single `Config:Apply()` path. The known legacy renderer's scale-related reset jump is not a managed placement failure or part of this checkpoint; because the renderers share SavedVariables, managed placement consumes the coordinates left by the legacy path.

### Development-only legacy presentation

`anchorsShown` now controls all three addon-owned managed header Buttons as well as the legacy anchors. `OBB:ToggleAnchors()` retains the existing mutation/legacy update and sends one narrow managed visibility notification; no full managed configuration apply is required. Hiding is visibility-only: it neither moves hosts or containers nor reclaims the fixed header reservation, changes SCREEN/BELOW placement or saved coordinates, alters growth/scale, hides aura rows or Fishing Lure, or touches managed AuraContainers. Hidden Buttons provide no drag input; showing them restores the existing SCREEN-root drag behavior. `locked`, `showLegacyBars`, `legacyComparisonMode`, and Blizzard default-frame visibility remain independent.

`showLegacyBars` defaults to `true` and controls only the addon-owned legacy presentation. The legacy scanner/backend, events, caches, configuration, SavedVariables, and managed prototype continue operating. The visibility gate owns group frames and anchors plus externally parented secure cancel overlays and tooltip cleanup, so normal legacy refresh/aura churn cannot re-show hidden presentation. Blizzard default-frame visibility remains separately owned by `hideBlizzardFrames`/Edit Mode policy.

`legacyComparisonMode` defaults to `false`. When enabled it takes presentation precedence and shows legacy bars regardless of `showLegacyBars`, without changing either setting. Each effective legacy SCREEN root receives a temporary horizontal shift of `settings.width + 24` UI units; dependent legacy children retain their ordinary relative anchors and receive no second shift. Multiple independent roots each receive their own shift. Managed hosts remain at the real authoritative saved position. Legacy drag persistence subtracts the temporary shift before saving, and managed drag persistence writes real shared coordinates before refreshing legacy placement, so comparison coordinates cannot become real `x`/`y`. Reset likewise retains real shared topology: managed uses the reset coordinates while legacy displays at the temporary comparison offset until comparison is disabled. This development infrastructure is not a backend selector and must be removed with final legacy presentation cleanup.

The managed BUFFS filter compiler reuses `groupSettings.filters.whitelist` and `groupSettings.filters.blacklist`. The existing legacy filter editor remains the single editing UI and synchronizes the long-lived managed group out of combat. No managed-only SavedVariables or duplicate filter editor were added.

The managed DEBUFFS group intentionally does not use candidate spell-ID maps or connect the existing DEBUFFS filter editor. Under the Retail 12.1 managed security model, non-`NeverSecret` harmful auras on the assistable player unit skip identity include/exclude maps, so general legacy whitelist/blacklist parity is unavailable. Existing saved numeric IDs remain intact pending a final product-policy decision; this is a deliberate compatibility limitation, not a broken filter implementation.

Managed ENCHANTMENTS uses a deliberate 7+2+1 capacity policy: seven `HelpfulEnhancements`, two registered native providers (MainHand and OffHand), and one ordinary Fishing Lure footer. Fishing Bobber is a HELPFUL aura and consumes one of the seven aura slots; it is not the lure footer. Native enchantments use `AfterAuraGroups` placement and Slot/Normal ordering, producing the DOWN order HelpfulEnhancements, MainHand, OffHand, then Fishing Lure. In UP mode Blizzard reverses spatial progression while preserving logical source sequence, so native rows move toward the header and `HelpfulEnhancements` occupies the lower managed portion. The ordinary lure stays below the container as a fixed footer outside FlowLayout in both directions. Ranged is not registered. Legacy ENCHANTMENTS sort/`maxBars` remain stored for compatibility but are intentionally ignored by the managed policy; no schema change was made.

An empty managed container may collapse to its approximately `1 x 1` managed bound, unlike the legacy renderer's one-row minimum. BELOW follows that actual bound; no fake minimum or manual sizing is added. ENCHANTMENTS is terminal in the supported graph because its ordinary Fishing Lure footer is outside the managed container and therefore outside that container's bounds. A future downstream parent/full-visible-bounds design remains research work.

Visual parity and the expanded configuration checkpoint are runtime validated for live icon side, scale/alpha, BUFFS/DEBUFFS saved sort and maximum counts, BUFFS and ENCHANTMENTS growth direction, supported SCREEN/BELOW combinations, independent SCREEN-root dragging/persistence, managed header visibility, lock/combat handling, reset/reload behavior, and managed-only/overlapping/side-by-side development presentation. Full exit/login validation confirmed all three managed hosts remained `userPlaced=false` and the saved BUFFS SCREEN -> DEBUFFS BELOW -> ENCHANTMENTS BELOW chain followed immediately during BUFFS dragging without dropdown cycling. DEBUFFS uses the same supported growth implementation without equivalent direct real-HARMFUL coverage. LEFT/RIGHT/ABOVE, arbitrary graph/cycle parity, remaining behavior/filter settings, and production integration remain pending.

## Combat restrictions

Managed aura updates, duration presentation, sorting, and already-applied candidate filters continue to operate during combat. Drag start, placement mutation, sort changes, BUFFS filter mutation, HELPFUL enhancement rediscovery, and fishing-lure API refreshes are blocked or deferred during combat. An active managed drag interrupted by combat is stopped without saving and restored to its prior applied SCREEN point after combat. This narrow restoration is separate from pending routing/lure/native-enchantment recovery and is not a general placement queue.

`ManagedPrototype:ApplyConfiguration()` also refuses managed presentation mutation during combat and returns `false, "combat lockdown"`. It does not queue or defer configuration changes. The normal configuration UI already prevents its mutation paths during combat; this is not combat-capable live restyling.

The native-enchantment transition recovery is the narrow exception to the no-deferred-configuration statement: if its one-shot completion reaches combat, that recovery alone may finish after `PLAYER_REGEN_ENABLED`. This does not create a general configuration queue.

Routine automatic HELPFUL-routing diagnostics are silent by default behind a local debug gate. Explicit manual diagnostic helpers and unexpected discovery/filter failures remain visible; no SavedVariables debug setting was added.

The legacy direct scanner becomes unavailable or secret in Retail 12.1 combat. Its `pcall` containment limits repeated failures but cannot restore correct state, and its indexed aura tooltip path is suppressed on Retail 12.1+. These are legacy limitations, not managed-frame failures.

## Retail 12.1 transition

- The managed player-BUFFS prototype is a validated parallel implementation, not a completed production cutover.
- The managed player-DEBUFFS prototype has core Retail Live runtime validation, including all three native sort mappings, native combat tooltip behavior, and dynamic BUFFS-to-DEBUFFS layout propagation, but remains isolated, broadly filtered, and not production-integrated.
- The managed ENCHANTMENTS prototype has validated MainHand behavior, bounded loading/world-transition recovery, FOOD/FLASK_PHIAL/AUGMENT_RUNE/FISHING_BOBBER routing, and the ordinary fishing-lure lifecycle. Native weapon rows support right-click cancellation; the lure footer does not. Direct OffHand-only/simultaneous-slot transition coverage, combat cancellation, permanent/zero-duration behavior, Ranged, final temporary-enchant naming, and broader native enchant coverage remain pending.
- Blizzard-managed default buff icons still reappear when combat begins even when the legacy `Hide Blizzard Icons` option hides them out of combat. This is unresolved and separate from the managed AuraContainer work.
- A known real private harmful aura, optional explicit secrecy/`NeverSecret` tests, the DEBUFFS filtering product decision, broader native item-enchantment/effect coverage, LEFT/RIGHT/ABOVE and arbitrary graph/cycle parity, full ENCHANTMENTS bounds, remaining behavior/filter integration, legacy-only UI cleanup, production cutover, rollback policy, and removal of the temporary comparison infrastructure and legacy scanner remain future work.
- Detailed architectural history, validation evidence, and rollback boundaries are preserved in `MANAGED_AURACONTAINER_MIGRATION.md`.
