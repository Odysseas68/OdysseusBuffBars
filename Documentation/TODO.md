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

## Remaining Migration Work

- [ ] Complete visual parity and final managed bar styling.
- [ ] Persist managed prototype position.
- [ ] Persist sort selection and complete final configuration integration.
- [ ] Redesign filter-row discovery for a fully managed backend if supported discovery is still required; do not depend on direct aura identity scanning.
- [ ] Migrate Debuffs after their secret-identity filtering limitations have a supported design.
- [ ] Migrate Enhancements and native item enchantments after routing, ordering, and filtering policy is resolved.
- [ ] Research supported/Edit Mode handling for Blizzard BuffFrame visibility; do not claim the combat reappearance issue is fixed.
- [ ] Cut over player BUFFS to exactly one production backend and remove its duplicate legacy display.
- [ ] Validate final production configuration, combat behavior, rollback, and SavedVariables compatibility.
- [ ] Remove temporary scanner and tooltip containment only after all required groups complete production migration.
- [ ] Remove obsolete legacy scanner caches, events, ordinary bars, and cancellation overlays only after complete cutover.

The overall Retail 12.1 migration remains incomplete.
