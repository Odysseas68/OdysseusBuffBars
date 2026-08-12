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

## Remaining Migration Work

- [ ] Complete visual parity and final managed bar styling.
- [ ] Persist managed prototype position.
- [ ] Persist sort selection and complete final configuration integration.
- [ ] Redesign filter-row discovery for a fully managed backend if supported discovery is still required; do not depend on direct aura identity scanning.
- [ ] Decide the DEBUFFS filtering product policy after targeted validation, then integrate and cut over DEBUFFS separately.
- [ ] Migrate Enhancements and native item enchantments after routing, ordering, and filtering policy is resolved.
- [ ] Research supported/Edit Mode handling for Blizzard BuffFrame visibility; do not claim the combat reappearance issue is fixed.
- [ ] Cut over player BUFFS to exactly one production backend and remove its duplicate legacy display.
- [ ] Validate final production configuration, combat behavior, rollback, and SavedVariables compatibility.
- [ ] Remove temporary scanner and tooltip containment only after all required groups complete production migration.
- [ ] Remove obsolete legacy scanner caches, events, ordinary bars, and cancellation overlays only after complete cutover.

The overall Retail 12.1 migration remains incomplete.
