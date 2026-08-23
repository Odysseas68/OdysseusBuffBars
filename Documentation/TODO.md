# OdysseusBuffBars TODO

## PTR 12.1 Managed Player-BUFFS Milestones

- [x] Implement and PTR validate the isolated managed player-BUFFS architecture prototype.
- [x] PTR validate the managed AuraButton presentation: icon, spell name, application count, duration text, duration StatusBar, timeless clearing, tooltip, and right-click cancellation.
- [x] PTR validate Phase B.2 dynamic self-sizing, including grow/shrink, near-empty collapse, more than ten buffs, thirty-frame capacity, combat updates, drag locking, and reload behavior.
- [x] Implement and PTR validate native managed sorting for Default, Name, and Time Left.
- [x] Implement and PTR validate managed player-BUFFS whitelist/blacklist filtering with legacy whitelist precedence.
- [x] Implement and PTR validate automatic out-of-combat synchronization from the existing BUFFS filter editor.
- [x] Confirm that the managed player-BUFFS validation produced no observed Lua errors, taint, or blocked actions.

### Validated native sorting

- [x] Default uses `AuraContainerSortMethod.Default` with `AuraContainerSortDirection.Normal` and preserves Blizzard-owned default ordering.
- [x] Name uses `AuraContainerSortMethod.NameOnly` with `AuraContainerSortDirection.Normal` and orders timed and timeless auras alphabetically together.
- [x] Time Left uses `AuraContainerSortMethod.ExpirationOnly` with `AuraContainerSortDirection.Reverse`, preserving timeless-first and longest-to-shortest timed ordering.
- [x] Application counts, managed duration presentation, dynamic sizing, and combat updates remain correct across the tested sort modes.
- [x] Sort changes are blocked during combat while the active native sort continues governing updates.

### Validated managed filtering and synchronization

- [x] Reuse `groupSettings.filters.whitelist` and `groupSettings.filters.blacklist` without new SavedVariables.
- [x] One-ID and multi-ID whitelist behavior works.
- [x] Blacklist add/remove behavior works when the whitelist is empty.
- [x] Whitelist takes precedence when the same spell ID appears in both lists.
- [x] Clearing the whitelist activates blacklist semantics.
- [x] Apply complete candidate-filter tables through `SetAuraGroupCandidateFilters(groupKey, candidateFilters)`.
- [x] Keep the existing filter editor as the single editing UI; no separate managed editor or `Apply Filters` button is required.
- [x] Synchronize legacy and managed frames immediately after allowed out-of-combat editor mutations.
- [x] Preserve the current native sort and managed grow/shrink behavior after filter changes.
- [x] Block filter mutation during combat while the active managed filter continues governing aura updates.
- [x] Restore configuration availability after combat and retain correct filter behavior after `/reload`.

### Validated static visual parity

- [x] Runtime-compare managed BUFFS, DEBUFFS, and ENCHANTMENTS against the legacy renderer at `260 x 18` rows, three-pixel spacing, full-coordinate `18 x 18` icons, accepted fonts/text geometry, count/duration placement, and group-specific colors.
- [x] Match legacy-style `260 x 18` group headers, backdrop/border, centered labels, and the four-pixel header-to-first-row gap.
- [x] Centralize managed row presentation in `InitializeManagedBarPresentation(auraButton, style)` and header styling in `StyleManagedGroupHeader(header, style)`.
- [x] Runtime-validate the shared row/header helper extraction on BUFFS without observed regression before applying it to DEBUFFS and ENCHANTMENTS.
- [x] Retain Blizzard-owned AuraButton lifecycle, duration text/bar, tooltips, sorting, supported cancellation, and managed container self-sizing.

### Validated configuration checkpoint

- [x] Complete Phase A.1: defer idempotent `ManagedPrototype:Initialize()` until SavedVariables adoption, defaults, migrations, group normalization, and `OBB.db` readiness; construct no managed UI/event/lure objects at Lua file load.
- [x] Build copied prototype-owned startup presentation state rather than retaining mutable SavedVariables color-table references.
- [x] Runtime-validate startup consumption of name/header, width, height, spacing, font size, full bar/background RGBA, icon side including RIGHT, scale, alpha, and compatible BUFFS/DEBUFFS sort and maximum-bar settings.
- [x] Keep ENCHANTMENTS saved sort/maximum-bar consumption deferred because one legacy value cannot exactly map across `HelpfulEnhancements`, native item-enchantment rows, and the ordinary fishing-lure row.
- [x] Complete the narrow Phase C.1 bridge from `Config:Apply()` to centralized `ManagedPrototype:ApplyConfiguration()` after the existing legacy refresh.
- [x] Runtime-validate live out-of-combat font-size and full bar/background RGBA synchronization without `/reload` across BUFFS, DEBUFFS, ENCHANTMENTS, native item-enchantment rows, and fishing-lure presentation.
- [x] Runtime-validate live width synchronization across existing/future rows, native item-enchantment rows, the fishing lure, headers, `Sync Group Bars`, combat regression, and vertical chaining without manually sizing managed containers.
- [x] Runtime-validate live height synchronization for row roots, square icons, the `height + iconGap` colored boundary, LEFT/RIGHT startup icon sides, fixed 18-pixel headers, future rows, and width/height order independence.
- [x] Runtime-validate live row spacing through `SetAuraGroupLayout` and `SetItemEnchantmentLayout`, including the ordinary lure gap, future rows, `Sync Group Bars`, combat regression, and width/height/spacing order independence.
- [x] Runtime-validate existing `syncGroupBars` fan-out for supported managed properties while keeping fan-out ownership in the existing config layer.
- [x] Apply the current presentation state to existing and future/created/reused rows through initializer-owned weak-key presentation tracking without enumerating active managed children or aura identity.
- [x] Preserve the combat guard: managed live apply returns `false, "combat lockdown"` and does not defer configuration presentation changes.
- [x] Silence routine automatic managed-routing diagnostics by default while preserving explicit manual diagnostics and unexpected discovery/filter failure output without adding SavedVariables.
- [x] Runtime-validate live managed LEFT/RIGHT `iconSide` reanchoring for retained and future/reused rows without enumerating active AuraButtons.
- [x] Runtime-validate live scale and alpha synchronization by applying them to ordinary group hosts, including mixed-scale chaining and inherited ENCHANTMENTS lure presentation.
- [x] Live-apply BUFFS/DEBUFFS saved sort using Default/Normal, NameOnly/Normal, and ExpirationOnly/Reverse; retain prototype sort buttons as temporary non-persistent overrides that a later config apply can replace.
- [x] Live-apply BUFFS/DEBUFFS saved `maxBars` through `SetAuraGroupMaxFrameCount` within the existing 1-80 configuration range.
- [x] Implement BUFFS/DEBUFFS `growUp` through supported FlowLayout anchor/growth settings while preserving the external top-fixed header and chaining topology.
- [x] Runtime-validate BUFFS `growUp` out of combat and through combat aura behavior.
- [ ] Obtain equivalent direct DEBUFFS-specific `growUp` runtime coverage if still useful; current implementation uses the same supported FlowLayout path but is not claimed as directly tested.
- [x] Live-apply and runtime-validate ENCHANTMENTS saved `growUp` through the shared FlowLayout path without enabling its legacy global sort or `maxBars` settings.
- [x] Consume saved BUFFS `SCREEN` coordinates at startup and live out of combat by translating the logical stack top-left to the ordinary host (`x - 4`, `y + 22`) without reanchoring the managed container or applying scale compensation.
- [x] Consume saved DEBUFFS/ENCHANTMENTS BELOW offsets for the exact default `BUFFS SCREEN -> DEBUFFS BELOW BUFFS -> ENCHANTMENTS BELOW DEBUFFS` graph, anchoring child hosts to parent managed-container bounds with `offsetX - 4`, unchanged `offsetY`, and no header-height subtraction.
- [x] Route `Reset Positions` through one `Config:Apply()` call while retaining its existing SavedVariables mutations and legacy refresh behavior.
- [x] Runtime-validate startup/live/repeated placement apply, reset, nondefault offsets, mixed growth and scale, empty managed bounds, combat sizing/chaining, and native weapon-transition recovery without AuraButton enumeration, manual container sizing, placement retry, or container reanchoring.
- [x] Add and runtime-validate DEBUFFS and ENCHANTMENTS SCREEN-root startup/live placement while preserving their supported BELOW dependencies and the exact SCREEN (`x - 4`, `y + 22`) and BELOW (`offsetX - 4`, unchanged `offsetY`) translations.
- [x] Add and runtime-validate independent managed dragging for every effective unlocked SCREEN root, shared-coordinate persistence, legacy position synchronization, anchored-child following/refusal, reload, Reset Positions, mixed supported topologies, and lock behavior.
- [x] Reject drag start in combat; if combat interrupts an active managed drag, stop without persisting the interrupted location and restore the prior applied SCREEN point after combat without adding a general placement retry queue.
- [x] Add and runtime-validate the development-only `showLegacyBars` presentation gate while keeping the legacy backend, scanning/events/caches/configuration/SavedVariables, managed prototype, `anchorsShown`, and Blizzard-frame visibility independent.
- [x] Add and runtime-validate `legacyComparisonMode` precedence and side-by-side presentation: shift each effective legacy SCREEN root by its width plus 24 UI units without mutating real placement, double-shifting children, or introducing drag drift.

## Live 12.1 Isolated Managed Player-DEBUFFS Prototype

- [x] Implement a second independent ordinary root and `CustomAuraContainerTemplate` for player DEBUFFS without changing the validated managed BUFFS group.
- [x] Use one broad `HARMFUL` group with Blizzard's default public-plus-private managed source path.
- [x] Register the five managed presentation bindings for icon, spell name, application count, duration text, and duration bar.
- [x] Keep sorting and dynamic self-sizing Blizzard-managed, with prototype-local Default, Name, and Time Left selection.
- [x] Intentionally omit DEBUFFS candidate spell-ID filters because general player-HARMFUL whitelist/blacklist parity is unavailable for non-`NeverSecret` auras.
- [x] Intentionally omit right-click cancellation and secure cancellation overlays for player HARMFUL auras.
- [x] Anchor the DEBUFFS prototype below the dynamically self-sizing BUFFS container through an ordinary `DisableUntrustedLayoutScriptsTemplate` host with an eight-pixel default gap; later extend the same host to validated SCREEN placement and independent SCREEN-root dragging.
- [x] Validate core managed player-DEBUFFS runtime behavior on Retail Live `12.1.0.69273`, interface `120100`.
- [x] Validate broad player `HARMFUL` display, simultaneous debuffs, combat additions/refreshes/removals, icons, names, application counts, duration text/bars, dynamic grow/shrink, and simultaneous managed BUFFS/DEBUFFS operation.
- [x] Validate Default sorting through `AuraContainerSortMethod.Default` with `AuraContainerSortDirection.Normal` without reinterpreting Blizzard's default ordering.
- [x] Validate Name sorting through `AuraContainerSortMethod.NameOnly` with `AuraContainerSortDirection.Normal`.
- [x] Validate Time Left sorting in combat through `AuraContainerSortMethod.ExpirationOnly` with `AuraContainerSortDirection.Reverse`.
- [x] Validate the native managed DEBUFF tooltip in combat without a custom indexed-aura lookup or fallback.
- [x] Live-validate the BUFFS-to-DEBUFFS anchor chain across BUFFS movement and grow/shrink, independent DEBUFFS grow/shrink, combat layout propagation, anchor-loop detection, taint, and blocked actions.
- [x] Confirm no Lua errors, taint, or blocked actions attributable to OdysseusBuffBars were observed during Live validation.
- [ ] Validate a real private player harmful aura, including presentation, ordering, native tooltip, and add/remove transitions.
- [ ] Run explicit secrecy/restriction classification tests without inferring classifications from observed aura names.
- [ ] Run focused `NeverSecret` behavior/filtering tests if a later product decision requires them.

## Live 12.1 Isolated Managed ENCHANTMENTS Prototype

- [x] Implement a third ordinary `DisableUntrustedLayoutScriptsTemplate` host and independent `CustomAuraContainerTemplate` below the self-sizing DEBUFFS container.
- [x] Register only `AuraContainerItemEnchantmentSlot.MainHand` and `AuraContainerItemEnchantmentSlot.OffHand` through `AddItemEnchantment`, each with `hidePermanent = false`.
- [x] Use the native equipped-item icon/name, application count, duration text, duration StatusBar, inventory-item tooltip, and `RightButtonDown` cancellation paths.
- [x] Supersede the earlier Duration/Reverse experiment with the production policy: place native item enchantments `AfterAuraGroups` and sort them Slot/Normal, with MainHand before OffHand.
- [x] Fix managed ENCHANTMENTS capacity at 7+2+1: seven `HelpfulEnhancements`, two registered native slots, and one ordinary Fishing Lure footer; keep legacy ENCHANTMENTS `maxBars` ignored without changing SavedVariables.
- [x] Keep item-enchantment lifecycle, equipment/enchant refreshes, frame reuse, stale-value clearing, countdowns, and self-sizing Blizzard-managed without addon polling or `OnUpdate`.
- [x] Add no native item-enchantment filtering, enchant-name resolver, independent SavedVariables, or persistence; keep semantic HELPFUL routing as a separate managed aura-group source. Current ENCHANTMENTS configuration support covers presentation geometry, colors/font, icon side, host scale/alpha, and growth direction, but intentionally excludes global sort/max semantics.
- [x] Confirm on Live that pre-existing MainHand PaperDoll enchantment data can be available while the initial managed row is absent, and that one manual `UpdateAllAuras()` immediately populates it.
- [x] Prove through repeated cold-login diagnostics that `PLAYER_ENTERING_WORLD` can precede usable timed enchantment data: the first player `UNIT_INVENTORY_CHANGED` exposed enchantID `8051` with zero remaining time, while a subsequent callback exposed a positive remaining duration.
- [x] Confirm that refreshing on both startup inventory callbacks made the row appear but allowed callback one's incomplete zero-duration snapshot to produce a row without a timer; a later manual `UpdateAllAuras()` after final readiness restored the correct timer.
- [x] Disprove fixed callback-count recovery through Live diagnostics: timed-ready publication occurred on callbacks 69, 105, and 430 across cold logins, so callback ordinal is not stable.
- [x] Confirm that isolating the legacy synthetic weapon-enchantment append path did not change the managed cold-login failure.
- [x] Preserve the earlier initial-login quiet-turn recovery as historical validation, then extend its bounded generation/zero-delay pattern to every `PLAYER_ENTERING_WORLD` transition.
- [x] Reproduce native MainHand row disappearance after loading/world transitions even after PaperDoll state becomes valid; confirm one manual container refresh restores the correct row and duration during diagnosis.
- [x] Arm one transition epoch on every world entry, coalesce player inventory activity to a quiet turn, reject stale callbacks, unregister the temporary listener, and perform exactly one container-wide native refresh.
- [x] Retain one pending transition recovery through combat and complete it after `PLAYER_REGEN_ENABLED` without creating a general deferred configuration queue.
- [x] Keep legitimate no-enchant transitions bounded and terminal; add no polling, repeating timer, native-state reconstruction, or permanent inventory listener.
- [x] Add no fixed delay, callback-count threshold, polling, PaperDoll inspection, synthetic fallback, or permanent inventory-event listener to native item-enchantment recovery; HELPFUL routing uses a separate player-filtered `UNIT_AURA` path.
- [x] Live-validate twice that a MainHand enchant active before cold login appears automatically with its timer through the quiet-turn managed refresh, with no manual refresh, duplicate row, or stale zero-duration state.
- [x] Live-validate MainHand fresh reapplication after login, native equipped-weapon name, native inventory tooltip, and right-click cancellation in the tested non-combat context.
- [x] Preserve the earlier `/reload` MainHand validation as historical evidence; the current recovery subsequently supersedes the initial-login-only listener by arming on every world entry.
- [x] Confirm no OBB-attributable Lua error, taint, or blocked action was observed during the validated MainHand lifecycle tests.
- [x] Record `OBBEnchantDiag` as completed temporary research tooling with no runtime or repository dependency.
- [x] Remove temporary transition trace instrumentation after diagnosis and keep normal runtime silent.
- [x] Runtime-validate MainHand recovery across a Silvermoon portal return, Home teleport in both directions, Stormwind portal, Hearthstone, dungeon entry/exit, Delve/no-loading-screen behavior, legitimate no-enchant transition, and a fresh enchant afterward, with correct duration and no manual refresh.
- [x] Runtime-validate ENCHANTMENTS DOWN/UP live switching, reload persistence, mixed managed sources, width/height/spacing/icon-side changes while UP, loading and no-enchant transitions, native recovery without growth reset, and combat behavior without reported Lua/taint/tooltip/cancellation regression.
- [ ] Live-validate broader MainHand apply/refresh/remove behavior, charge clearing/count formatting, equipment swaps, and empty `1 x 1` collapse.
- [ ] Live-validate OffHand independently and simultaneously with MainHand, including equipment swaps and removing one row without disturbing the other.
- [ ] Live-validate MainHand-before-OffHand Slot/Normal ordering with both native temporary-enchantment rows active.
- [ ] Live-validate combat cancellation and OffHand cancellation; record any restriction, taint, or blocked action without adding a workaround.
- [ ] Live-validate BUFFS -> DEBUFFS -> ENCHANTMENTS anchor propagation, managed grow/shrink, rapid enchant churn, and Blizzard-owned post-login apply/remove updates.
- [ ] Exercise and record permanent/zero-duration behavior with `hidePermanent = false` if a suitable case is available.
- [x] Research and Live-validate semantic classification of readable active HELPFUL spell metadata for Food, Flask/Phial, and Augment Rune effects; use no duration thresholds, item IDs, or hardcoded routing spell-ID table.
- [x] Live-validate paired managed ENCHANTMENTS includes and BUFFS exclusions with no duplicate presentation across initial population, repeated identical discovery, growth, shrink, empty-set clearing, and repopulation.
- [x] Live-validate automatic out-of-combat discovery, membership-based redundant-event suppression, combat deferral, and pending `PLAYER_REGEN_ENABLED` retry without polling or continuous `OnUpdate` scanning.
- [x] Cross-character validate different aura spell IDs, including Well Fed/Hearty Well Fed and Ethereal/Draconic Augmentation, while retaining runtime IDs as evidence rather than a compatibility table.
- [x] Add and runtime-validate `FISHING_BOBBER` through the case-insensitive literal `bobber` semantic marker without a bobber spell-ID table, item/toy identity, or duration rule.
- [x] Validate Limited Edition Rocket Bobber aura spell ID `1222880` moving from managed BUFFS to managed ENCHANTMENTS while remaining an ordinary Blizzard HELPFUL aura.
- [x] Resolve the fishing tool dynamically from `C_TradeSkillUI.GetProfessionSlots(Enum.Profession.Fishing)` and `Enum.InventoryType.IndexProfessionToolType`, with slot 28 accepted only as a source-backed API-returned fallback.
- [x] Add the explicit addon-owned `Fishing Lure` row because managed item-enchantment providers cannot register the fishing profession-tool slot; do not describe it as a managed AuraButton.
- [x] Runtime-validate Bright Baubles apply, visible countdown, natural expiration with one scheduled API recheck, row hiding, and reapplication without presence polling.
- [x] Fix the lure tooltip `UntrustedLayoutScriptExecution` by owning `GameTooltip` from `UIParent` at `ANCHOR_CURSOR`; validate the fishing-tool inventory tooltip without observed taint.
- [x] Keep native weapon-enchant right-click cancellation distinct from the fishing-lure row, which currently performs no cancellation action.
- [ ] Decide final native temporary weapon-enchant naming/presentation between Blizzard's equipped-weapon name, a static slot label, or a supported effect-name source; do not scrape tooltips or hardcode enchant-ID mappings.
- [ ] Evaluate Ranged registration only in a Retail context that can exercise inventory slot 18.

## Remaining Migration Work

- [x] Implement and runtime-validate ENCHANTMENTS `growUp` while keeping Fishing Lure as a fixed footer outside FlowLayout in both directions.
- [x] Implement and runtime-validate RIGHT for DEBUFFS relative to BUFFS and ENCHANTMENTS relative to DEBUFFS using applied parent logical width, including empty/non-empty state, live parent-width changes, offsets, switching, growth/scale, parent dragging, reset, combat, and native enchant/lure behavior.
- [x] Implement and runtime-validate LEFT for the same supported chain using applied child logical width, including empty state, live child-width changes, parent-width independence, offsets, switching, drag following/refusal, reset, comparison/header modes, combat, and native enchant/lure transitions.
- [x] Complete ABOVE research and intentionally defer it for the managed prototype/migration period; do not add dynamic-height reads, polling, private hooks, duplicated row-height logic, or a second content-height authority.
- [ ] At production cutover, remove ABOVE from managed placement choices and require an explicit supported replacement for existing ABOVE users without silently remapping or prematurely discarding the saved legacy value.
- [ ] Decide whether arbitrary `anchorTo` graphs, BUFFS as a child, BELOW/RIGHT/LEFT beyond the supported parent relationships, and broader cycle parity are still desired; do not generalize current validation.
- [ ] Optionally evaluate minor lateral visual-alignment polish without treating the runtime-validated logical geometry as defective.
- [ ] Retain startup/reload-only status for unsupported geometry/layout properties until each live mutation path is explicitly implemented and runtime validated.
- [x] Add and runtime-validate managed `anchorsShown` header visibility without moving hosts, reclaiming reserved header geometry, changing placement, or affecting aura rows; keep lock and development visibility controls independent.
- [x] Keep OBB SavedVariables as the sole managed-host position authority by clearing WoW user-placed ownership after hosts become movable, after successful SCREEN-root drag persistence, and during safe restoration; runtime-validate the saved BELOW chain across two full exit/login cycles without anchor-dropdown repair.
- [ ] Research a future full-bounds ENCHANTMENTS parent if downstream chaining is required; the ordinary Fishing Lure footer remains outside the terminal ENCHANTMENTS container and is not included in its managed bounds.
- [ ] Decide whether the managed empty-container `1 x 1` bound should remain an accepted parity difference from the legacy one-row minimum; do not fake a minimum or manually size the container without new research and validation.
- [x] Centralize complete managed HELPFUL candidate composition across semantic routing, existing hidden/group overrides, BUFF destination filters, and supported BUFF duration state; apply/snapshot both descriptors together.
- [x] Resolve ownership before filtering, preserve hidden/override restoration, and finalize destination whitelist/blacklist as BUFFS-only; every effective-E ID remains eligible for `HelpfulEnhancements`.
- [x] Implement and runtime-validate BUFF ALL/TIMED_ONLY through Blizzard candidate filters; intentionally retain the last supported state for TIMELESS_ONLY/NONE while preserving SavedVariables and using ALL on fresh unsupported initialization.
- [x] Adopt managed DEBUFFS/ENCHANTMENTS ALL-duration policy, remove their duration controls, and make BUFF duration flags group-local rather than part of `Sync Group Bars` fan-out without schema migration.
- [ ] Complete a final managed-vs-legacy parity audit after the now-final group-specific filtering policy.
- [ ] Clean up or relabel legacy-only ENCHANTMENTS sort/maximum controls so the UI reflects the intentional managed 7+2+1 and Slot/Normal policy.
- [x] Finalize managed ENCHANTMENTS as broad/source-owned with no destination per-ID filtering across `HelpfulEnhancements`, MainHand, OffHand, or Fishing Lure; preserve historical filter tables for legacy/rollback.
- [x] Build current active readable B/E HELPFUL ownership projection through the shared resolver and use it for BUFFS `Current group auras`; E no longer exposes a destination-filter editor under the final broad policy.
- [x] Finalize managed DEBUFFS as intentionally broad/unfiltered, remove its Whitelist/Blacklist control, and preserve historical filter tables for legacy/rollback.
- [x] Remove D/E Whitelist/Blacklist controls and place Grow Up directly below Max Bars without changing defaults or SavedVariables schema.
- [ ] Complete broader Live validation of native MainHand/OffHand item-enchantment lifecycle and interaction, then integrate the validated native and semantic HELPFUL sources into production ENCHANTMENTS.
- [ ] Broaden runtime testing across classes, effects, bobbers, profession tools, and lure variants without converting observed IDs into compatibility tables.
- [ ] Investigate the transient observation where ordinary HELPFUL auras with `classification=nil` briefly appeared in ENCHANTMENTS before refresh; observed spell IDs were `1287425`, `1281559`, and `296553`, with no established cause or fix.
- [ ] Optionally research a supported localized temporary-enchant effect name beyond equipped-item/slot presentation.
- [ ] Optionally research safe profession-tool lure cancellation; do not claim slot-28 cancellation until runtime validated.
- [ ] Research supported/Edit Mode handling for Blizzard BuffFrame visibility; do not claim the combat reappearance issue is fixed.
- [ ] Cut over player BUFFS to exactly one production backend and remove its duplicate legacy display.
- [ ] Validate final production configuration, combat behavior, rollback, and SavedVariables compatibility.
- [ ] Remove temporary scanner and tooltip containment only after all required groups complete production migration.
- [ ] Remove obsolete legacy scanner caches, events, ordinary bars, and cancellation overlays only after complete cutover.
- [ ] Remove the temporary legacy visibility/comparison controls and presentation-offset path when the legacy renderer is retired.

The overall Retail 12.1 migration remains incomplete.
