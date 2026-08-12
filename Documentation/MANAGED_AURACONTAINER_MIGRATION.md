# Managed AuraContainer Migration

Phase A, managed AuraButton presentation, Phase B.2 dynamic self-sizing, native managed sorting, player-BUFFS whitelist/blacklist semantics, and automatic synchronization from the existing BUFFS filter editor are validated on the Retail 12.1 PTR. A second isolated player-DEBUFFS prototype now has core runtime behavior validated on Retail Live `12.1.0.69273`, including all three native sort mappings, native combat tooltips, and dynamic BUFFS-to-DEBUFFS layout propagation; targeted private-aura and optional restriction-focused validation remains pending. Both managed frames remain parallel prototypes; no production aura group uses the managed backend.

Evidence labels used below:

- **Verified:** documented in the supplied PTR analysis and confirmed in Blizzard PTR source.
- **Runtime validated:** observed in the active Retail Live addon during gameplay.
- **Implication:** architectural conclusion derived from verified behavior.
- **Unresolved:** requires further source research, a targeted runtime test, or a product decision.

Current milestone status:

| Area | Status |
|---|---|
| Retail 12.1 AuraContainer architecture research | Complete for the audited Live source snapshot; recheck on API/source changes. |
| Parallel managed player-BUFFS implementation | Implemented and PTR validated for core lifecycle, presentation, sorting, filtering, and existing-editor synchronization. |
| Phase B.2 dynamic self-sizing | PTR validated. |
| Isolated managed player-DEBUFFS implementation | Core runtime behavior validated on Retail Live with a broad `HARMFUL` group, all three sort mappings, native combat tooltips, and dynamic BUFFS-to-DEBUFFS anchoring; targeted private-aura validation and integration pending. |
| Final visual parity, persistent position/sort, and full configuration integration | Pending. |
| Debuffs, Enhancements/item enchantments, and production cutover | Pending. |
| Blizzard BuffFrame visibility during combat | Unresolved and separate from the managed implementation. |

## 1. Current Architecture

The production/legacy path is a standalone custom aura-bar implementation built around direct aura scanning. Parallel managed player-BUFFS and isolated player-DEBUFFS prototypes validate the intended replacement architecture without taking ownership from that legacy path.

Runtime flow:

```text
WoW events
  > OBB:RefreshAll()
  > Engine:Scan()
  > addon-owned Lua aura records
  > Bars:UpdateGroup()
  > ordinary custom bar frames
  > separate secure cancellation overlays
```

Key components:

- [OdysseusBuffBars.lua](<D:/Program Files/Blizzard/World of Warcraft/_retail_/Interface/AddOns/OdysseusBuffBars/OdysseusBuffBars.lua:191>)
  - Owns defaults, SavedVariables initialization, events, refresh dispatch, combat transitions, slash commands, and Blizzard-frame visibility.
  - Refreshes groups on `UNIT_AURA`, weapon enchant events, login, and explicit refreshes.
  - Supports unit tokens such as player, target, focus, and pet internally, although the configuration UI does not currently expose unit selection.
  - Avoids Blizzard-frame visibility changes during combat.

- [OdysseusBuffBars_Auras.lua](<D:/Program Files/Blizzard/World of Warcraft/_retail_/Interface/AddOns/OdysseusBuffBars/OdysseusBuffBars_Auras.lua:368>)
  - Directly scans `C_UnitAuras`.
  - Converts aura results into addon-owned records containing identity, presentation, duration, expiration, routing, and filtering data.
  - Maintains previous-aura and filter-row caches.
  - Synthesizes weapon enchant records.
  - Contains the temporary `pcall` containment for secret-aura failures.

- [OdysseusBuffBars_Bars.lua](<D:/Program Files/Blizzard/World of Warcraft/_retail_/Interface/AddOns/OdysseusBuffBars/OdysseusBuffBars_Bars.lua:276>)
  - Creates ordinary movable group frames and ordinary custom bar frames.
  - Manually applies text, icons, counts, timers, colors, growth, and positioning.
  - Retains bar frames for reuse.
  - Creates separate `SecureActionButtonTemplate` overlays for right-click cancellation outside combat.
  - Preserves index-based `GameTooltip:SetUnitAura` through `pcall` on clients before Retail 12.1, but suppresses that incompatible path on Retail 12.1 and newer.

- [OdysseusBuffBars_Config.lua](<D:/Program Files/Blizzard/World of Warcraft/_retail_/Interface/AddOns/OdysseusBuffBars/OdysseusBuffBars_Config.lua:701>)
  - Edits the three SavedVariables-backed groups.
  - Supports geometry, appearance, anchoring, sorting, maximum bars, timed/timeless selection, filters, and routing overrides.
  - Conservatively prevents configuration mutation in combat.

Current groups are independently positioned:

- Buffs
- Debuffs, chained to Buffs by default
- Enhancements, chained to Debuffs by default

## 2. Verified 12.1 Building Blocks

The verified PTR architecture consists of four layers:

1. Native `AuraContainer`
   - Owns unit assignment, visibility/enabled state, dynamic event registration, and update lifecycle.

2. `ManagedAuraContainerMixin`
   - Parses aura sources.
   - Maintains aura-instance caches.
   - Handles incremental `UNIT_AURA` updates.
   - Filters, sorts, assigns, releases, and reuses frames.
   - Processes public and private aura sources separately.

3. `CustomAuraContainer`
   - Addon-facing configuration surface.
   - Supports aura groups, fixed aura slots, item enchantments, candidate filters, native sorting, flow layout, and processing policy.
   - Creates AuraButtons through a frame provider in batches.
   - Owns its buttons; buttons cannot be freely reparented.

4. `AuraButton`
   - Native aura presentation object.
   - Supports framework-managed icon, name, application count, dispel indicators, duration text, duration bar, tooltips, and cancellation.
   - Applies secret-aura access restrictions after its permitted initialization window.

Additional verified findings:

- Container visibility and enabled state control dynamic aura, private-aura, and weapon-enchantment event registrations.
- Source data is parsed once per exact filter string within a container.
- Stable aura-instance assignments retain their existing frames when ordering changes.
- Item enchantments are native player-owned sources and do not participate in ordinary aura-group candidate filtering.
- Native cancellation uses aura-instance identity or the enchantment inventory slot. A separate secure overlay is unnecessary.
- `ManagedAuraContainer` is separate from the Managed Frame System. Registration with the Managed Frame System is not required unless future Edit Mode integration is intentionally added.
- Container creation is permitted in combat on the examined PTR source, but that does not guarantee unrestricted configuration, layout access, or safe addon interaction during combat.
- `GetAuraGroupFrameCount()` represents owned provider capacity, not necessarily the number of currently visible auras.
- No Blizzard consumer of `CustomAuraContainerTemplate` was found in the examined source. That source-era gap motivated the isolated prototype; its player-BUFFS behavior is now PTR validated.

## 3. Compatibility Gaps

| Current behavior | 12.1 compatibility gap |
|---|---|
| Direct `C_UnitAuras` scan | Cannot reliably access secret aura data in tainted combat execution. |
| Addon-owned aura records | Duplicates state now intended to remain inside the managed container. |
| Previous-aura cache | Can preserve stale information but cannot restore valid combat tracking. |
| Custom bar populated from aura data | Requires extracting data the addon may no longer access. |
| Index-based tooltip | Aura index is fragile and may be restricted; managed buttons provide native identity-aware tooltips. |
| Separate secure cancel overlay | Reimplements behavior already owned by AuraButton and depends on addon-provided identity/index. |
| Name-based enhancement heuristics | Managed candidate filters are based on supported criteria, not unrestricted aura-name inspection. |
| Timed/timeless filtering | No verified general-purpose native selector provides exact parity. `maxDuration` is not a complete replacement. |
| Whitelist and blacklist | Native spell-ID candidate filtering is PTR validated for player BUFFS. General player-DEBUFFS parity is unavailable because non-`NeverSecret` harmful auras on the assistable player unit skip identity maps; product policy remains unresolved. |
| Three independent movable groups | A container has one unit and one coordinated flow surface. Independent placement favors one container per existing group. |
| Custom bar count and host resizing | Managed layout and visibility can be secret-dependent; addon code must not infer active aura counts from provider capacity. |
| Blizzard-frame hiding | Blizzard now reasserts management during combat. Repeated insecure hiding is not a sustainable replacement for supported behavior. |
| Filter discovery cache | The current cache depends on addon-readable aura identity. Its purpose and population method must be redesigned. |
| Runtime configuration | Public setters exist, but post-login and combat accessibility must be tested rather than assumed. |

Verified legacy Retail 12.1 limitations:

- Direct aura scanning becomes unavailable or secret in combat. Temporary `pcall` containment prevents repeated scanner failures but cannot restore correct combat state.
- Legacy timers can become stale or show `0s` during combat.
- The legacy indexed `GameTooltip:SetUnitAura` path is suppressed on Retail 12.1+ because it can invoke forbidden secret-aura access.
- The legacy `Hide Blizzard Icons` option works when toggled out of combat, but Blizzard's default buff icons reappear when combat begins and disappear again after combat. This is an unresolved Blizzard BuffFrame visibility issue, not a managed-frame failure; no fix is claimed.

## 4. Recommended Target Architecture

### Container ownership

Use one long-lived `CustomAuraContainer` per existing Odysseus group for the initial migration.

This best preserves:

- Independent unit tokens.
- Independent movable anchors.
- Current group chaining.
- Independent bar size, spacing, growth, maximum count, sorting, and filtering.
- A clean per-group fallback during incremental migration.

A single container per unit could reduce repeated parsing when groups share a filter, but it would combine those groups into one coordinated layout surface. That conflicts with the current independent-group model and should not be the first migration target.

### Frame hierarchy

```text
Ordinary OBB group host
  +- anchor/title controls
  L- CustomAuraContainer
       L- container-owned AuraButtons
            L- registered visual descendants
```

The ordinary host should remain responsible for SavedVariables position and user movement. The container should be anchored to the host; unrelated addon frames should not be anchored back to the restricted container.

The BUFFS layout omits stack-wide chrome and does not require `DisableUntrustedLayoutScriptsTemplate`. The chained DEBUFFS prototype applies that template to its ordinary host because the host follows restricted managed bounds.

### Presentation

Each managed AuraButton should itself become the bar-sized presentation surface.

Its initializer should construct and register the required descendants:

- Icon
- Spell name
- Application count
- Duration text
- Duration bar
- Optional dispel presentation

The addon may apply static group styling during initialization, but should not mirror managed aura state into a second ordinary-bar model.

### Filtering and sorting

Map existing settings to native mechanisms where verified:

- `HELPFUL` and `HARMFUL` > filter strings.
- Player-BUFFS spell whitelist/blacklist > PTR-validated candidate include/exclude spell-ID filters; other groups remain subject to research and validation.
- Maximum bars > maximum frame count.
- Name sorting > `NameOnly`.
- Remaining-time sorting > `ExpirationOnly` with `Reverse`, preserving timeless-first and longest-to-shortest legacy OBB behavior.
- Default sorting > native default method.
- Growth and spacing > container flow and group layout options.

Timed-only, timeless-only, and enhancement-name routing remain compatibility gaps rather than safe mappings.

### Enhancements

The enhancements container can potentially combine:

- A managed helpful-aura group for explicitly supported enhancement auras.
- Native item-enchantment entries for main hand, off hand, and ranged slots.

The current heuristic classification cannot be carried forward as if it were reliable managed filtering. Exact combined layout and cancellation parity need PTR validation.

### Identity, caching, and events

- Aura-instance IDs should remain framework-owned.
- The addon should not depend on private managed methods to extract identity.
- Managed groups should not maintain `previousByAuraID` or duplicate `OBB.auraData`.
- The container should own aura, private-aura, and enchantment updates.
- The core should retain lifecycle, configuration, positioning, and combat-transition responsibilities.
- Filter-editing history may remain SavedVariables-backed, but live discovery must not depend on forbidden scanning.

### Secure interaction

Use native AuraButton tooltip behavior and native cancellation only for groups where cancellation is meaningful. BUFFS right-click cancellation is validated; the DEBUFFS prototype intentionally registers no cancellation because player harmful auras are not normally cancellable. Do not recreate managed identity in an addon-owned secure overlay.

The current conservative configuration lock can remain initially. Structural or uncertain changes should be queued until out of combat.

## 5. Incremental Migration Plan

### Phase A — Isolated container prototype

Status: Validated on PTR.

- `OdysseusBuffBars_ManagedPrototype.lua` is loaded last by the addon TOC and creates the prototype during addon file loading, before `ADDON_LOADED` and `PLAYER_LOGIN`.
- An ordinary addon-owned host is hidden during setup. It owns a child created with `CreateFrame("AuraContainer", ..., "CustomAuraContainerTemplate")`; the container is anchored to the host, and the host is not anchored to the restricted container.
- The public inbound methods used are `SetEnabled`, `SetUnit`, and `AddAuraGroup`. The group uses `HELPFUL`, `AuraContainerSortMethod.Default`, `AuraContainerSortDirection.Normal`, and a maximum of twenty displayed frames.
- The group initializer runs through Blizzard's custom frame provider. It sizes each container-owned `CustomAuraButtonTemplate` button, creates descendant background and icon textures, registers the icon through `AuraButton:SetIcon`, and registers native cancellation through `AuraButton:SetCancelAuraButtons("RightButtonDown")` before Blizzard applies access restrictions.
- The prototype does not scan `C_UnitAuras`, read provider capacity, reparent AuraButtons, populate `OBB.auraData`, use the production bar renderer, create cancellation overlays, or alter Blizzard aura-frame visibility.
- Adding the group applies `UntrustedLayoutScriptExecution` to the container. Custom AuraButtons receive `DenyTaintedAccessWhenAurasAreSecret` after their initializer and must remain owned by the container.
- The container remains long-lived after creation. It is explicitly hidden and disabled during configuration; the host and container are then shown before `SetEnabled(true)` performs visible-state event registration and requests a full managed update.
- `OBB.ENABLE_MANAGED_AURA_PROTOTYPE` defaults to `true`. No configuration UI or SavedVariables field was added.

Verified initial PTR findings:

- External Lua creation of the PTR intrinsic/template combination succeeded without observed Lua errors or taint.
- The prototype displayed exactly six helpful auras because its initial configured maximum was six; this was display policy, not an observed provider-capacity count.
- The initial icons appeared static and native right-click cancellation was not active.
- Existing OBB bars and Blizzard-frame behavior remained unchanged. Blizzard icon behavior during combat remains a separate unresolved production issue.

Phase A.1 lifecycle diagnosis and correction:

- PTR source requires both `IsVisible()` and `IsEnabled()` before dynamic `UNIT_AURA` registration occurs.
- The initial prototype called `SetEnabled(true)` while its host was hidden, so that call itself could not register dynamic events. Its pending full update could still produce the initial six assignments once visible.
- The inspected container Lua does not establish whether showing the parent must invoke the child's intrinsic `OnShow` in this external creation pattern. The lifecycle order is therefore a verified ambiguity, not a conclusively proven sole cause of the static display. The six-aura maximum also limited which changes could become visible.
- Phase A.1 explicitly hides the container during configuration, shows the host and container, and only then enables the visible container. The verified `SetEnabled` implementation performs event registration and requests the full update, so no addon-owned event handler or additional direct refresh is added.
- The initializer's registered icon remains managed by `CustomAuraButtonTemplate`: assignment and retained-aura updates call the template's native display update path.
- Native cancellation uses the AuraButton's framework-owned unit and aura instance. On `RightButtonDown`, Blizzard calls `C_UnitAuras.CancelAuraByInstanceID` internally; the prototype does not read or copy that identity.

Verified Phase A.1 PTR results:

- The corrected visible/enabled lifecycle updates helpful player auras correctly.
- Helpful auras are added and removed through the managed container.
- Up to twenty managed AuraButtons display.
- Native right-click cancellation works through `SetCancelAuraButtons("RightButtonDown")`.
- No Lua errors or observed taint occurred during Phase A validation.
- The prototype remains inert if the 12.1 AuraContainer enum surface is absent.

Rollback: remove or disable the prototype without touching the direct scanner.

### Phase B — Managed bar-presentation prototype

Status: Core managed presentation and lifecycle are implemented and PTR validated. Final visual parity and production integration remain pending.

- The diagnostic group now displays at most thirty vertically stacked AuraButtons, each 250 by 16 pixels with two pixels of vertical spacing and a 16 by 16 icon.
- The ordinary position root is fixed at the 22-pixel header height; it no longer reserves vertical space from the thirty-button capacity.
- `SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)`, `SetFlowLayoutAnchorPoint("TOPLEFT")`, and `SetFlowLayoutGrowthDirection(...Right, ...Down)` configure the container-owned vertical layout before the aura group is added.
- Each managed button creates addon-styled static background and text-layer descendants while remaining owned by the container.
- `SetIcon` registers the left-side icon texture.
- `SetSpellName` registers the aura-name FontString.
- `SetApplicationCount` registers the count FontString. Blizzard's default managed behavior emits text only when applications exceed one and clears it on assignment changes.
- `SetDurationText` registers the right-aligned duration FontString. Blizzard's retained duration binding and default formatter own countdown updates and disable the binding for zero-duration auras.
- `SetDurationBar` registers a StatusBar with `Enum.StatusBarTimerDirection.RemainingTime`. Blizzard passes its managed duration object to `StatusBar:SetTimerDuration`; addon code does not read expiration or duration values.
- The intrinsic AuraButton scripts continue to provide the native tooltip. No addon tooltip handler is added.
- Validated `SetCancelAuraButtons("RightButtonDown")` cancellation remains registered.
- No cooldown spiral, application bar, dispel decoration, or custom tooltip styling is included. These are unnecessary for the Phase B bar prototype and were not replaced with direct aura reads.

Phase B.1 also contains the confirmed legacy tooltip incompatibility: on Retail 12.1 and newer, production bars hide the tooltip and return before the indexed `GameTooltip:SetUnitAura` call. The original indexed tooltip behavior remains available on older supported clients. This is temporary compatibility containment, not the final production tooltip solution; final managed bars are expected to use native AuraButton tooltip handling. Production aura scanning, bar creation, secure cancellation overlays, and the managed-backend migration remain otherwise untouched.

Phase B.2 dynamic layout implementation:

- The ordinary root owns the screen anchor, header, drag handle, clamping, and combat-locked movement. Its size does not depend on aura state or managed-container geometry.
- The `CustomAuraContainer` has a single top-left anchor below the root header. Blizzard's managed FlowLayout remains solely responsible for resizing the container from its displayed AuraButtons.
- `maxFrameCount = 30` remains selection capacity only. Addon code does not count active buttons, enumerate children, poll visibility, or call private layout methods.
- The previous fixed-capacity host background now covers only the persistent header. Stack-wide dynamic chrome is intentionally omitted for this validation phase; each managed AuraButton retains its own background.
- No frame is anchored from the container back to the root, so the hierarchy has no circular size dependency. No `DisableUntrustedLayoutScriptsTemplate` chrome is needed while stack-wide chrome is omitted.
- The container retains its one-pixel initial size before Blizzard's first managed layout.

Phase B.2 PTR validation passed for dynamic grow/shrink, near-empty collapse, more than ten displayed buffs, thirty-frame capacity without permanently reserved empty space, combat updates, duration presentation, timeless clearing, application counts, native tooltip and right-click cancellation, combat drag lock, post-combat dragging, and reload. The header/root remained usable, and no Lua errors, taint, blocked actions, anchor loops, protected-frame errors, or managed-reuse layout failures were observed. Prototype position is still not persisted.

Native managed sorting implementation:

- The prototype supports `DEFAULT`, `NAME`, and `TIMELEFT` through one centralized mapping.
- `DEFAULT` uses `AuraContainerSortMethod.Default` with `AuraContainerSortDirection.Normal`.
- `NAME` uses `AuraContainerSortMethod.NameOnly` with `AuraContainerSortDirection.Normal`.
- `TIMELEFT` uses the verified legacy-compatible `AuraContainerSortMethod.ExpirationOnly` with `AuraContainerSortDirection.Reverse`, producing timeless auras first and timed auras from longest remaining to shortest remaining with descending aura-instance tie ordering.
- Default preserves Blizzard's native default ordering and is not described as duration sorting or timeless grouping.
- Name orders timed and timeless auras together alphabetically while preserving managed application counts and duration presentation.
- A prototype-only header button cycles `TIMELEFT` -> `DEFAULT` -> `NAME` -> `TIMELEFT` at runtime through the verified public `SetAuraGroupSortMethod` method. Changes are blocked during combat; already configured native sorting continues to govern combat aura updates.
- Sort choice is not stored in SavedVariables and is not connected to legacy configuration. Reload starts the prototype in `TIMELEFT` mode.
- Sorting remains entirely managed: no aura reads, Lua comparator, manual AuraButton reordering, polling, or private layout access is used.

Native sorting passed PTR runtime validation.

Managed player-BUFFS filtering implementation:

- The isolated managed `HELPFUL` group reads the existing BUFFS SavedVariables maps at `groupSettings.filters.whitelist` and `groupSettings.filters.blacklist`; it does not rename, migrate, or mutate those tables.
- One compiler copies only enabled numeric spell-ID keys into a fresh candidate-filter table. If the whitelist has entries, it supplies only `includeSpellIDs`. Otherwise it supplies only `excludeSpellIDs` when the blacklist has entries. Empty lists compile to an empty candidate-filter table.
- This preserves legacy OBB precedence: a non-empty whitelist enables whitelist mode and suppresses the blacklist, so an ID saved in both lists remains included. Passing both maps would incorrectly give Blizzard's exclude-first behavior precedence.
- The prototype applies the complete compiled table to the long-lived group with `SetAuraGroupCandidateFilters(AURA_GROUP_KEY, candidateFilters)`. Blizzard owns the full refresh, candidate admission, sorting, frame reuse, and self-sizing layout; the addon does not recreate the group or manually refresh aura data.
- `OBB.ManagedPrototype:RefreshCandidateFilters()` is the single managed refresh helper. It reads the current BUFFS maps, compiles the validated policy, and calls the public setter without reading aura data or touching sorting/layout.
- The existing BUFFS filter editor remains the only editing UI. Its manual Add, manual Remove, and per-row checkbox mutation paths notify the managed helper after the SavedVariables mutation and the existing legacy `OBB:RefreshAll()` call succeed.
- The temporary prototype `Apply Filters` button was removed and the original header/sort-control layout was restored. Saved filters are still compiled after `ADDON_LOADED` for reload coverage.
- Synchronization is explicit and mutation-driven. It does not poll SavedVariables, use `OnUpdate`, compare tables repeatedly, add a duplicate editor, or add SavedVariables.
- Filter mutation is blocked during combat and is not queued. The active managed filter remains in force until the next allowed out-of-combat refresh.
- This slice is player `HELPFUL` only. It does not migrate DEBUFFS, ENCHANTMENTS, or their legacy filters, and it does not call `C_UnitAuras`, inspect AuraButton identity, enumerate managed buttons, or populate discovery data.
- Managed identity filtering and editor discovery remain separate concerns. The existing editor can retain manual numeric IDs and legacy-known rows, but no supported managed active-identity enumerator exists and no direct scanner was added for discovery.

Managed whitelist/blacklist semantics, native sorting, managed grow/shrink, tooltip, cancellation, and automatic editor synchronization passed PTR validation. Manual add, remove, and checkbox changes immediately updated both frames out of combat; clearing the whitelist activated blacklist mode; the current native sort and self-sizing remained active; and reload retained the compiled policy. In combat, the editor was unavailable and managed filter mutation remained blocked while the already-active filter continued governing managed aura updates. No errors, taint, or blocked actions were observed.

The validated player-BUFFS prototype covers the core managed lifecycle, presentation, timed and timeless transitions, application counts, filtering, sorting, interaction, combat updates, and reload behavior. Final visual parity, persistent position and sort choice, full configuration integration, and production backend cutover remain pending.

Rollback: existing bars remain authoritative.

### Isolated managed player-DEBUFFS prototype

Status: Core managed player-DEBUFFS runtime behavior validated on Retail Live. Targeted private-aura and optional restriction-focused validation remain pending. This is not a production DEBUFFS backend.

- The DEBUFFS slice retains its own ordinary header/root and `CustomAuraContainerTemplate`, with independent frame names, local sort state, and managed lifecycle. Its position is no longer independent: the BUFFS root remains the primary movable root, and the DEBUFFS host follows the bottom of the self-sizing BUFFS container.
- The DEBUFFS host is created with `DisableUntrustedLayoutScriptsTemplate` and anchored one-way from its `TOPLEFT` to the BUFFS container's `BOTTOMLEFT`, horizontally realigned by the existing host padding and separated by an eight-pixel prototype gap. No BUFFS frame is anchored back to DEBUFFS, so the dependency remains strictly BUFFS root -> BUFFS container -> DEBUFFS host -> DEBUFFS container.
- Independent DEBUFFS dragging is removed. Moving the BUFFS root out of combat moves both managed groups through the now-validated anchor propagation; no new SavedVariables persistence is added.
- The container uses `SetUnit("player")` and one `AddAuraGroup("Harmful", "HARMFUL", options)` declaration with a maximum capacity of 30 and the validated vertical 250 by 16 layout with two-pixel spacing.
- The group is intentionally broad. It supplies no candidate spell-ID filters and does not connect the legacy DEBUFFS whitelist/blacklist editor because non-`NeverSecret` player HARMFUL auras skip managed identity maps.
- Blizzard's default managed source selection supplies the public-plus-private path. The addon does not add a private source/group, enumerate private identities, or copy private aura data.
- Each container-owned AuraButton registers `SetIcon`, `SetSpellName`, `SetApplicationCount`, `SetDurationText`, and `SetDurationBar`; Blizzard owns duration updates, clearing on reuse, and presentation under restrictions.
- Tooltip behavior remains the native managed AuraButton path for ordinary, restricted, and private harmful auras. No indexed, slot, or instance-based addon tooltip lookup is added.
- The DEBUFFS initializer intentionally omits `SetCancelAuraButtons`; no secure cancellation overlay is created.
- Default, Name, and Time Left use the validated native sort mappings through a DEBUFFS-local selector. Sort mutation is blocked during combat, while the configured managed sort continues to govern updates.
- Dynamic sizing, pooling, public/private updates, and combat refreshes remain framework-owned. The addon does not count or enumerate buttons, poll, scan `UNIT_AURA`, read aura identity, or call private managed/layout methods.
- The legacy DEBUFFS scanner, renderer, configuration, SavedVariables, and Blizzard-frame handling remain unchanged. Prototype root position and sort selection are not persisted.
- Retail Live validation on `12.1.0.69273`, interface `120100`, confirmed broad player/HARMFUL display, multiple simultaneous debuffs, combat additions/refreshes/removals, icons, names, application counts, duration text and StatusBars, dynamic grow/shrink, and simultaneous managed BUFFS/DEBUFFS operation.
- All three DEBUFFS sort mappings are runtime validated: Default uses `AuraContainerSortMethod.Default` with `AuraContainerSortDirection.Normal`, Name uses `AuraContainerSortMethod.NameOnly` with `AuraContainerSortDirection.Normal`, and Time Left uses `AuraContainerSortMethod.ExpirationOnly` with `AuraContainerSortDirection.Reverse`. Blizzard's Default semantic ordering is not reinterpreted beyond that verified mapping, and combat additions/removals/refreshes continued working in all tested modes.
- The native managed DEBUFF tooltip is runtime validated in combat. No custom indexed-aura lookup or fallback is required.
- Observed presentation examples included Temporal Displacement, Creeping Void, and Dusk Frights; Creeping Void exercised application-count presentation. These examples do not establish secret, restricted, `NeverSecret`, or private classification.
- No Lua errors, taint, or blocked actions attributable to OdysseusBuffBars were observed during Live validation.
- Targeted validation remains pending for a known real private harmful aura, explicit secrecy/restriction classification if still useful, and focused `NeverSecret` filtering behavior if a later product decision requires it. Source research supports private harmful auras entering the same default public-plus-private group pipeline, but OBB Live runtime validation of that path has not occurred.
- The chained layout is runtime validated for BUFFS movement and grow/shrink propagation, independent DEBUFFS grow/shrink below the BUFFS stack, and combat-driven layout changes. No anchor-loop errors, OBB-attributable Lua errors, taint, or blocked actions were observed. It uses only managed container bounds and declarative anchors; no aura counting, capacity-derived offset, polling, size callback, or manual height calculation is introduced.

Rollback: remove or disable only the isolated DEBUFFS prototype; the validated managed BUFFS prototype and legacy DEBUFFS backend remain intact.

### Phase C — One managed Buffs group

- Add an explicit backend choice for the Buffs group.
- When managed mode is active, disable the direct scanner and ordinary bars for that group.
- Never display both implementations for the same group.

Rollback: return that group to the contained direct scanner.

### Phase D — Filtering and sorting parity

- The isolated player-BUFFS prototype has validated maximum capacity, native sorting, whitelist/blacklist mapping, and automatic filter-editor synchronization.
- Carry those mappings into the production backend without changing the existing SavedVariables schema.
- Resolve or explicitly document timed/timeless and enhancement-routing limitations.
- Preserve the PTR-validated sort directions rather than inferring behavior from enum names.

Rollback: preserve existing SavedVariables fields and switch the group backend back.

### Phase E — Multiple groups and units

- Complete targeted validation of the isolated player-DEBUFFS prototype with a known real private harmful aura and any still-useful explicit restriction cases.
- Migrate Debuffs only after the filtering product policy and remaining runtime evidence are accepted.
- Validate separate containers for independently positioned groups.
- Exercise target, focus, and pet tokens before treating existing internal support as retained compatibility.
- Preserve chaining through ordinary host frames.

### Phase F — Tooltips and cancellation

- Native managed-button tooltip and player-buff cancellation are PTR validated in the isolated BUFFS prototype.
- Carry native tooltip into each production managed group as it migrates. Register cancellation only for cancellable groups; the player-DEBUFFS prototype intentionally omits it. Item-enchantment behavior remains future work.
- Remove the separate secure overlay only for groups already using managed buttons.

### Phase G — Blizzard-frame visibility policy

- Determine whether Retail exposes a supported setting or Edit Mode behavior for suppressing the default aura presentation.
- If no supported combat-safe method exists, accept the Blizzard frames during combat rather than fighting managed ownership.

### Phase H — Complete cutover

After all groups pass validation:

- Remove direct aura scanning.
- Remove the temporary error containment.
- Remove redundant aura caches and scanner-owned events.
- Remove legacy cancellation overlays.
- Retain compatible SavedVariables fields until a separate, deliberate schema cleanup.

## 6. Risk Register

| Risk | Severity | Mitigation |
|---|---:|---|
| Secret aura access or taint regression | Critical | Use only the public managed surface and native AuraButton descendants. |
| Running direct and managed backends together | High | Enforce exactly one active backend per group. |
| Reparenting or externally recycling AuraButtons | High | Treat buttons as permanently container-owned. |
| Unsafe layout dependencies | High | Keep the movable host independent; prototype restricted layout behavior. |
| Stale addon-owned aura caches | High | Stop duplicating managed state as each group migrates. |
| Cancellation regression | High | Use native AuraButton cancellation and validate in combat. |
| Timed/timeless parity failure | High | Treat as unresolved product behavior; do not approximate silently. |
| Enhancement routing parity failure | High | Replace heuristics only with verified filters or explicit curated policy. |
| Blizzard frames reappearing in combat | High | Do not repeatedly hide managed frames; identify supported behavior. |
| Post-login setter restrictions | High | Create long-lived structures early and queue uncertain mutations out of combat. |
| Sort-direction mismatch | Medium | Test known aura sets with distinct names and expiration times. |
| Target or unit-token lifecycle gaps | Medium | Test target swaps, unit disappearance, reconnects, and reloads. |
| SavedVariables disruption | Medium | Preserve the current schema during migration and avoid destructive conversion. |
| Provider-capacity information leakage | Medium | Do not interpret owned frame count as visible aura count. |
| PTR-to-Live API drift | High | Re-audit Blizzard source and generated API documentation before release. |

## 7. Validation Matrix

| Phase | Required validation |
|---|---|
| A | Login, reload, combat entry/exit, container enable/disable, no Lua errors, no taint reports. |
| B | Timed and permanent aura application/removal, duration refresh, stack changes, frame retention, layout resizing. |
| C | Buff updates in and out of combat, no duplicate displays, clean backend rollback, reload persistence. |
| D | Name/default/expiration sorting, direction, maximum count, include/exclude IDs, readable and secret auras. |
| E | Buffs, debuffs, enhancements, independent positioning, chaining, growth, target changes, focus and pet lifecycle. |
| F | Tooltip behavior, right-click cancellation, non-cancellable debuffs, enchant cancellation, combat interaction. |
| G | Blizzard icons outside combat, during combat, after combat, after Edit Mode, and after reload. |
| H | No remaining direct scanner call sites, containment removed, scanner events removed, caches no longer authoritative. |

Every phase should also include LuaCheck, load/reload testing, Lua error capture, taint-log review, combat transitions, and static diff review when the directory is under Git.

## 8. Open Questions Requiring Research or Runtime Tests

1. Which additional container and group setters, if any, should be exposed through final configuration, and which must remain out-of-combat only?
2. Where must `DisableUntrustedLayoutScriptsTemplate` be applied if future stack-wide chrome depends on managed bounds?
3. What product policy should replace general legacy DEBUFFS spell-ID filtering now that non-`NeverSecret` player HARMFUL auras are known to skip identity maps?
4. Is exact timed-only or timeless-only selection expressible without reading protected aura data?
5. Can native item enchantments and an ordinary aura group share one Enhancements container with acceptable ordering and layout?
6. How should enhancement consumables be selected without name-based heuristics?
7. What supported Retail or Edit Mode mechanism, if any, replaces combat-time hiding of Blizzard aura frames?
8. Should target, focus, and pet support remain part of the product despite not being exposed in the current configuration UI?
9. How should the filter editor obtain known spell IDs once live aura discovery no longer reads addon-owned aura records?
10. Does an actual private player HARMFUL aura traverse the verified default public-plus-private source path with correct presentation, sorting, tooltip, and removal behavior on Retail Live?
11. Is one container per group acceptable under realistic multi-group combat load?
12. Which public names and semantics survive the final PTR-to-Live transition?

The permanent direction is clear: the direct scanner should become a temporary compatibility backend, while Blizzard-managed containers and AuraButtons become the authoritative aura lifecycle and presentation model. The unresolved items above should be answered experimentally before implementation is committed to production behavior.
