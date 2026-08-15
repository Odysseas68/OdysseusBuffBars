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

## Live 12.1 Isolated Managed Player-DEBUFFS Prototype

- [x] Implement a second independent ordinary root and `CustomAuraContainerTemplate` for player DEBUFFS without changing the validated managed BUFFS group.
- [x] Use one broad `HARMFUL` group with Blizzard's default public-plus-private managed source path.
- [x] Register the five managed presentation bindings for icon, spell name, application count, duration text, and duration bar.
- [x] Keep sorting and dynamic self-sizing Blizzard-managed, with prototype-local Default, Name, and Time Left selection.
- [x] Intentionally omit DEBUFFS candidate spell-ID filters because general player-HARMFUL whitelist/blacklist parity is unavailable for non-`NeverSecret` auras.
- [x] Intentionally omit right-click cancellation and secure cancellation overlays for player HARMFUL auras.
- [x] Anchor the DEBUFFS prototype below the dynamically self-sizing BUFFS container through an ordinary `DisableUntrustedLayoutScriptsTemplate` host with an eight-pixel gap and remove independent DEBUFFS dragging.
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
- [x] Use ENCHANTMENTS-specific `AuraContainerItemEnchantmentSortMethod.Duration` with `AuraContainerSortDirection.Reverse` for native non-expiring-first, then longest-to-shortest timed ordering; add no selector or other sort mode.
- [x] Keep item-enchantment lifecycle, equipment/enchant refreshes, frame reuse, stale-value clearing, countdowns, and self-sizing Blizzard-managed without addon polling or `OnUpdate`.
- [x] Add no native item-enchantment filtering, enchant-name resolver, SavedVariables, persistence, or configuration integration; keep semantic HELPFUL routing as a separate managed aura-group source.
- [x] Confirm on Live that pre-existing MainHand PaperDoll enchantment data can be available while the initial managed row is absent, and that one manual `UpdateAllAuras()` immediately populates it.
- [x] Prove through repeated cold-login diagnostics that `PLAYER_ENTERING_WORLD` can precede usable timed enchantment data: the first player `UNIT_INVENTORY_CHANGED` exposed enchantID `8051` with zero remaining time, while a subsequent callback exposed a positive remaining duration.
- [x] Confirm that refreshing on both startup inventory callbacks made the row appear but allowed callback one's incomplete zero-duration snapshot to produce a row without a timer; a later manual `UpdateAllAuras()` after final readiness restored the correct timer.
- [x] Disprove fixed callback-count recovery through Live diagnostics: timed-ready publication occurred on callbacks 69, 105, and 430 across cold logins, so callback ordinal is not stable.
- [x] Confirm that isolating the legacy synthetic weapon-enchantment append path did not change the managed cold-login failure.
- [x] Keep the `PLAYER_ENTERING_WORLD` managed refresh, and on fresh `initialLogin` only register player-filtered `UNIT_INVENTORY_CHANGED`; coalesce the inventory burst through generation checks scheduled with `C_Timer.After(0)` and perform one final managed refresh after a quiet turn.
- [x] Unregister the startup inventory listener and clear its generation/pending state before the final refresh.
- [x] Add no fixed delay, callback-count threshold, polling, PaperDoll inspection, synthetic fallback, or permanent inventory-event listener to the native item-enchantment cold-login recovery; HELPFUL routing uses a separate player-filtered `UNIT_AURA` path.
- [x] Live-validate twice that a MainHand enchant active before cold login appears automatically with its timer through the quiet-turn managed refresh, with no manual refresh, duplicate row, or stale zero-duration state.
- [x] Live-validate MainHand fresh reapplication after login, native equipped-weapon name, native inventory tooltip, and right-click cancellation in the tested non-combat context.
- [x] Live-validate `/reload` with the MainHand enchant active without enabling the initial-login inventory listener.
- [x] Confirm no OBB-attributable Lua error, taint, or blocked action was observed during the validated MainHand lifecycle tests.
- [x] Record `OBBEnchantDiag` as completed temporary research tooling with no runtime or repository dependency.
- [ ] Live-validate broader MainHand apply/refresh/remove behavior, charge clearing/count formatting, equipment swaps, and empty `1 x 1` collapse.
- [ ] Live-validate OffHand independently and simultaneously with MainHand, including equipment swaps and removing one row without disturbing the other.
- [ ] Live-validate longest-to-shortest duration sorting and managed reordering with two active temporary enchantments.
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

- [ ] Connect and synchronize legacy configuration with managed presentation and layout; current visual parity is static prototype styling only.
- [ ] Determine a safe runtime restyling/configuration update policy for managed rows and headers.
- [ ] Validate remaining placement and growth options after managed configuration synchronization.
- [ ] Persist managed prototype position.
- [ ] Persist sort selection and complete final configuration integration.
- [ ] Redesign filter-row discovery for a fully managed backend if supported discovery is still required; do not depend on direct aura identity scanning.
- [ ] Decide the DEBUFFS filtering product policy after targeted validation, then integrate and cut over DEBUFFS separately.
- [ ] Complete broader Live validation of native MainHand/OffHand item-enchantment lifecycle and interaction, then integrate the validated native and semantic HELPFUL sources into production ENCHANTMENTS.
- [ ] Broaden runtime testing across classes, effects, bobbers, profession tools, and lure variants without converting observed IDs into compatibility tables.
- [ ] Optionally research a supported localized temporary-enchant effect name beyond equipped-item/slot presentation.
- [ ] Optionally research safe profession-tool lure cancellation; do not claim slot-28 cancellation until runtime validated.
- [ ] Research supported/Edit Mode handling for Blizzard BuffFrame visibility; do not claim the combat reappearance issue is fixed.
- [ ] Cut over player BUFFS to exactly one production backend and remove its duplicate legacy display.
- [ ] Validate final production configuration, combat behavior, rollback, and SavedVariables compatibility.
- [ ] Remove temporary scanner and tooltip containment only after all required groups complete production migration.
- [ ] Remove obsolete legacy scanner caches, events, ordinary bars, and cancellation overlays only after complete cutover.

The overall Retail 12.1 migration remains incomplete.
