# Managed AuraContainer Migration

Phase A, managed AuraButton presentation, Phase B.2 dynamic self-sizing, and native managed behavior are validated. Retail Live now also validates centralized HELPFUL route/override/filter composition, BUFF duration admission, and current effective-ownership population for the BUFFS/ENCHANTMENTS editor lists. These remain parallel prototypes; DEBUFF identity policy, native item/lure per-ID policy, final parity, and production cutover are not complete.

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
| Isolated managed ENCHANTMENTS implementation | Implements the 7+2+1 policy: seven `HelpfulEnhancements`, MainHand/OffHand native providers, and one ordinary lure footer. MainHand lifecycle and transition recovery, semantic routing, lure behavior, visual parity, and live growth direction are Live validated; direct OffHand/both-slot coverage remains pending. |
| Managed visual parity | Runtime validated for BUFFS, DEBUFFS, and ENCHANTMENTS from the accepted `260 x 18`, three-pixel-spacing baseline, with live OOC font, color, width, height, and spacing synchronization. |
| Phase A.1 startup configuration consumption | Runtime validated. Initialization occurs after SavedVariables adoption/defaults/migrations/normalization and consumes a copied configuration snapshot. |
| Live configuration synchronization | Runtime validated out of combat for font/color/geometry, `iconSide`, host scale/alpha, BUFFS/DEBUFFS sort and `maxBars`, BUFFS/ENCHANTMENTS growth direction, BUFFS SCREEN, DEBUFFS SCREEN/BELOW/RIGHT/LEFT relative to BUFFS, and ENCHANTMENTS SCREEN/BELOW/RIGHT/LEFT relative to DEBUFFS. DEBUFFS growth is implemented through the same supported path without equivalent direct real-HARMFUL coverage. |
| Persistent position and full configuration integration | Partial. Supported placement, managed HELPFUL behavior/filtering, and B/E current effective-ownership editor population are runtime validated. ABOVE retires with legacy. Arbitrary graph/cycle parity, DEBUFF/native-item policy, final audit, cleanup, and production integration remain pending. |
| Development comparison workflow | Runtime validated for legacy presentation hiding, comparison precedence, per-SCREEN-root temporary offset, mixed topologies, dragging without saved-coordinate drift, reset, configuration, and combat. Both backends remain active; this is not production selection. |
| DEBUFFS/ENCHANTMENTS production integration and production cutover | Pending; the validated enhancement-routing policy is still prototype-only. |
| Blizzard BuffFrame visibility during combat | Unresolved and separate from the managed implementation. |

## 1. Current Architecture

The production/legacy path is a standalone custom aura-bar implementation built around direct aura scanning. Parallel managed player-BUFFS, player-DEBUFFS, and ENCHANTMENTS prototypes validate the intended replacement architecture without taking ownership from that legacy path. Managed ENCHANTMENTS contains native item-enchantment sources and a separate managed HELPFUL aura group; HELPFUL entries are not converted into Blizzard item enchantments. A small ordinary fishing-lure row is anchored with ENCHANTMENTS as an explicit exception and is not a managed AuraButton.

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
| Legacy name-based enhancement heuristics | They cannot be carried forward unchanged. The validated prototype instead classifies readable active spell metadata, then applies the resulting spell-ID membership through managed candidate filters. |
| Timed/timeless filtering | No verified general-purpose native selector provides exact parity. `maxDuration` is not a complete replacement. |
| Whitelist and blacklist | Native spell-ID candidate filtering is PTR validated for player BUFFS. General player-DEBUFFS parity is unavailable because non-`NeverSecret` harmful auras on the assistable player unit skip identity maps; product policy remains unresolved. |
| Three independent movable groups | A container has one unit and one coordinated flow surface. Independent placement favors one container per existing group. |
| Custom bar count and host resizing | Managed layout and visibility can be secret-dependent; addon code must not infer active aura counts from provider capacity. |
| Blizzard-frame hiding | Blizzard now reasserts management during combat. Repeated insecure hiding is not a sustainable replacement for supported behavior. |
| Filter discovery cache | The current cache depends on addon-readable aura identity. Its purpose and population method must be redesigned. |
| Runtime configuration | Presentation, placement, growth, centralized HELPFUL composition, BUFF duration policy, and B/E current effective-ownership editor population are validated. DEBUFF/native-item filter policy and final parity remain. |
| Fishing profession-tool lure | Managed item-enchantment slots cover MainHand, OffHand, and Ranged, not the fishing profession-tool slot. OBB uses one event/API-driven ordinary row rather than misrepresenting it as a managed AuraButton. |

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

The current prototype centralizes that static presentation in two helpers:

- `InitializeManagedBarPresentation(auraButton, style)` creates the common row background, DurationBar, Icon, SpellName, DurationText, ApplicationCount, text layer, fonts, anchors, colors, and full icon coordinates, then registers the native AuraButton presentation elements. It does not own sorting, filtering, candidate groups, aura identity, duration calculations, event handling, cancellation policy, or host positioning.
- `StyleManagedGroupHeader(header, style)` applies static header size, backdrop, background, border, and centered label presentation. It does not own dragging, host movement, sorting, group chaining, or configuration.

The shared row/header helper extraction was first applied to BUFFS and runtime validated with no observed BUFFS regression before DEBUFFS and ENCHANTMENTS were switched to the same architecture.

Current static style parity:

| Group | Fill | Background |
|---|---|---|
| BUFFS | `{0.3, 0.5, 1.0, 0.8}` | `{0.0, 0.5, 1.0, 0.1}` |
| DEBUFFS | `{1.0, 0.0, 0.0, 0.8}` | `{1.0, 0.0, 0.0, 0.1}` |
| ENCHANTMENTS | `{0.5, 0.0, 0.5, 0.8}` | `{0.5, 0.0, 0.5, 0.1}` |

All three use `260 x 18` rows, three-pixel row spacing, `18 x 18` icons with `{0, 1, 0, 1}` coordinates, 11-size name/duration text, 10-size outlined count text, and accepted legacy icon/bar/text geometry and placement. Their legacy-style headers use `260 x 18` geometry, the legacy backdrop/border, centered labels, and a four-pixel gap before the first row. Runtime visual comparison passed for all three groups.

This accepted baseline is no longer static after startup. The normal out-of-combat configuration path updates font, bar/background colors, width, height, row spacing, LEFT/RIGHT icon placement, and ordinary-host scale/alpha. Header height remains fixed at 18 pixels, scale does not rewrite logical row dimensions, and Blizzard retains container sizing ownership.

### Configuration synchronization checkpoints

Managed initialization no longer occurs at Lua file-load time. `OBB:OnAddonLoaded()` first adopts SavedVariables, fills defaults, runs migrations, normalizes group fields, and establishes `OBB.db`. It then calls the idempotent `ManagedPrototype:Initialize()`:

```text
ADDON_LOADED
-> SavedVariables adoption/defaults/migrations
-> group normalization and OBB.db readiness
-> ManagedPrototype:Initialize()
-> managed hosts/containers/event frames/fishing-lure row construction
```

No managed frames, containers, event frames, or lure rows are constructed when `OdysseusBuffBars_ManagedPrototype.lua` is loaded. Initialization builds prototype-owned copied configuration/style data. Complete RGBA tables are copied and validated; the managed backend does not retain mutable SavedVariables color-table references.

The startup snapshot consumes the following compatible settings for BUFFS, DEBUFFS, and ENCHANTMENTS:

- `name`
- `width`
- `height`
- `spacing`
- `fontSize`
- complete RGBA `barColor`
- complete RGBA `barBgColor`
- `iconSide`
- `scale`
- `alpha`
- `growUp`

BUFFS and DEBUFFS additionally consume their compatible saved `sort` and `maxBars`. ENCHANTMENTS deliberately retains the validated prototype `TIMELEFT`/capacity behavior rather than claiming an exact mapping. Its displayed area combines the `HelpfulEnhancements` group, native MainHand/OffHand item-enchantment rows, and the ordinary fishing-lure row, so one legacy ENCHANTMENTS sort or cap cannot govern all three sources equivalently.

Startup consumes placement when BUFFS is SCREEN, DEBUFFS is SCREEN/BELOW/RIGHT/LEFT relative to BUFFS, and ENCHANTMENTS is SCREEN/BELOW/RIGHT/LEFT relative to DEBUFFS. Unsupported parent graphs and `ABOVE` remain stored but are not approximated or silently remapped by the managed prototype.

The existing configuration layer remains authoritative for controls, SavedVariables mutation, and `syncGroupBars` fan-out. The managed backend does not duplicate that policy:

```text
existing config mutation / syncGroupBars fan-out
-> SavedVariables update
-> Config:Apply()
   +- OBB:RefreshAll()                         (legacy renderer)
   L- ManagedPrototype:ApplyConfiguration()    (managed presentation/layout)
```

`ApplyConfiguration()` currently reads and live-applies only:

- `fontSize`
- complete RGBA `barColor`
- complete RGBA `barBgColor`
- `width`
- `height`
- `spacing`
- `iconSide`
- `scale`
- `alpha`
- BUFFS/DEBUFFS `sort`
- BUFFS/DEBUFFS `maxBars`
- BUFFS/DEBUFFS/ENCHANTMENTS `growUp`
- BUFFS `SCREEN` coordinates, DEBUFFS `SCREEN`/`BELOW`/`RIGHT`/`LEFT` relative to BUFFS, and ENCHANTMENTS `SCREEN`/`BELOW`/`RIGHT`/`LEFT` relative to DEBUFFS

Font application updates SpellName, DurationText, and ApplicationCount; the count size is `math.max(10, fontSize - 1)`. Color application updates the DurationBar and row background RGBA. Width updates row roots, future/reused rows, and group headers while preserving Blizzard-owned self-sizing. Height updates row roots, square icons, and the `height + iconGap` colored boundary while keeping header height fixed at 18 pixels. Spacing updates `elementSpacing` and the ordinary fishing-lure gap without changing the four-pixel header gap or eight-pixel inter-group gap.

Live `iconSide` reanchors retained addon-owned icon/background references and uses the current height when reserving icon space. Text, count, and StatusBar relationships remain derived from their existing owners. Future/reused rows consume the current prototype-owned style, and no active AuraButton enumeration is used. Live alpha and scale are applied to the ordinary group hosts, so headers, managed rows, native enchantment rows, and the Fishing Lure hierarchy inherit the values; scale does not rewrite logical width or height. Mixed-scale chaining passed runtime validation.

The layout bridge uses the public `SetAuraGroupLayout` path for BUFFS, DEBUFFS, and `HelpfulEnhancements`, plus `SetItemEnchantmentLayout` for native ENCHANTMENTS rows. Replacement layout tables use the current managed width, height, and spacing together, so those three settings remain order-independent. The addon does not enumerate managed children, infer active counts, or manually resize a self-sizing container.

Initializer-created presentation references are retained in prototype-owned weak-key structures. A live apply updates those legitimate references without enumerating managed children, inferring active counts, or inspecting aura identity. The current live presentation state is also used when future rows are assigned, created, or reused.

For BUFFS and DEBUFFS, saved sort maps exactly as follows:

- `default` -> `AuraContainerSortMethod.Default` / `Normal`
- `name` -> `AuraContainerSortMethod.NameOnly` / `Normal`
- `timeleft` -> `AuraContainerSortMethod.ExpirationOnly` / `Reverse`

The existing prototype sort buttons remain available. They can temporarily change managed sort without writing SavedVariables; a later config apply reasserts the saved mode if it differs. Saved `maxBars` uses the public `SetAuraGroupMaxFrameCount` API with the existing 1-80 configuration range and normal/default value 40. ENCHANTMENTS intentionally ignores both legacy global settings.

For BUFFS, DEBUFFS, and ENCHANTMENTS, `growUp=false` uses TOPLEFT with Right+Down and `growUp=true` uses BOTTOMLEFT with Right+Up. This changes progression inside Blizzard's self-sized container; it does not move the saved logical origin or reverse the external top-fixed header/chaining topology. BUFFS and ENCHANTMENTS were directly runtime validated out of combat and through combat behavior. DEBUFFS uses the same supported implementation but is not claimed to have equivalent direct real-HARMFUL runtime coverage. ENCHANTMENTS participates only in the shared growth-state path and remains excluded from saved global sort and `maxBars` synchronization.

Managed placement is a separate ordinary-host layer over those self-sizing containers:

- Saved `x`/`y` for every supported SCREEN root remain the logical stack top-left. Each managed host translates them to `hostX = x - 4` and `hostY = y + 22`, where 22 is the fixed 18-pixel header plus four-pixel first-row gap. The managed container then resolves exactly at the saved `x`/`y`.
- In supported BELOW states, the DEBUFFS host anchors to the BUFFS container's `BOTTOMLEFT` and the ENCHANTMENTS host anchors to the DEBUFFS container's `BOTTOMLEFT`. Each uses `hostOffsetX = saved offsetX - 4` and `hostOffsetY = saved offsetY`; no 22-pixel header subtraction is applied. The default saved `(0, -8)` therefore becomes a host offset of `(-4, -8)`.
- In supported RIGHT states, the host anchors `TOPLEFT` to the parent managed container's `TOPLEFT` at `parentLogicalWidth + offsetX - 4`, `offsetY + 22`. DEBUFFS uses the applied BUFFS logical width; ENCHANTMENTS uses the applied DEBUFFS logical width. Applied placement state retains that parent width so live changes cause reapplication. The initial physical-`TOPRIGHT` approach was rejected because an empty container collapses to approximately `1 x 1`, placing the child near the parent's left edge until a real aura expands it.
- In supported LEFT states, the host anchors `TOPLEFT` to the parent managed container's `TOPLEFT` at `offsetX - 4 - childLogicalWidth`, `offsetY + 22`. DEBUFFS uses its applied DEBUFFS logical width; ENCHANTMENTS uses its applied ENCHANTMENTS logical width. Applied placement state retains that child width so live changes keep the child's logical right edge fixed. Parent-width changes intentionally do not affect LEFT.
- RIGHT and LEFT use no physical `GetWidth()`, AuraButton enumeration, manual sizing, fake managed minimum, or scale compensation. Minor aesthetic alignment polish may be considered later but is not a functional placement defect.
- Startup and live out-of-combat apply use copied scalar applied-state snapshots and clear/reanchor only an ordinary host when eligible values changed. The self-sizing AuraContainers are not externally reanchored, reparented, enumerated, or resized.
- OBB SavedVariables are the sole persistent position authority. Because `StartMoving()` can transfer named hosts to WoW user-placed frame-position persistence, each host is made movable before `SetUserPlaced(false)` during creation; Retail rejects clearing user placement before the frame is movable or resizable. This prevents WoW's cached screen points from competing with saved SCREEN/BELOW topology on later login.
- Placement uses logical coordinates directly, with no pixel/scale conversion or scale-compensation branch. Growth and scale remain independent: Blizzard's calculated container bounds and inherited host scale carry changes through the declarative chain.
- `Reset Positions` preserves its existing SavedVariables mutations but now completes through one `Config:Apply()` call: legacy `RefreshAll()`, one managed apply, then active-page refresh. The known legacy renderer's scale-related reset jump remains outside this managed checkpoint. Because both paths share SavedVariables, the managed prototype consumes the coordinates left by the legacy renderer; this is not a managed placement failure and is not fixed here.

Managed SCREEN-root dragging uses the same ordinary-host boundary:

- Drag eligibility requires out of combat, unlocked settings, saved `anchorTo == nil`, saved `placement == "SCREEN"`, and copied applied managed state that is also SCREEN. Anchored groups refuse direct movement and use the existing `OdysseusBuffBars: move the parent anchor or set this group anchor to Screen first.` warning.
- Dragging moves only the ordinary addon-owned host. Drag-stop obtains the host's real position and applies the inverse host translation: `savedX = hostLeft + 4` and `savedY = hostTopRelativeToUIParent - 22`. It stores those real shared coordinates, copies the applied state, clears WoW user-placed ownership, and refreshes legacy positioning. No scale compensation was introduced.
- If combat begins before drag start, the drag is rejected. If combat begins during an active managed drag, movement is stopped and the interrupted location is not persisted; `PLAYER_REGEN_ENABLED` clears user-placed ownership at the safe out-of-combat restoration point and restores the previous applied SCREEN point. This narrow restoration is not a general placement retry queue and does not establish broader protected-frame safety; this checkpoint does not claim new direct runtime coverage of that interrupted edge.

Managed header visibility is independent of placement ownership:

- The existing `anchorsShown` SavedVariables field controls all three addon-owned managed header Buttons as well as legacy anchors. `OBB:ToggleAnchors()` keeps its existing mutation/legacy path and sends one narrow `ApplyHeaderVisibility()` notification; no full managed configuration apply is required solely for visibility.
- `anchorsShown=true` shows managed headers; `anchorsShown=false` hides them. Hiding does not move hosts or containers, reclaim the fixed header reservation, change SCREEN/BELOW/RIGHT/LEFT placement, coordinates or offsets, growth or scale, hide aura bars or Fishing Lure, or alter managed AuraContainers. Hidden headers naturally provide no drag input; showing them restores existing SCREEN-root dragging. `locked`, `showLegacyBars`, and `legacyComparisonMode` remain independent.
- No new SavedVariables field or schema version was introduced.

### ABOVE decision

Legacy ABOVE places the child stack's `BOTTOMLEFT` against the parent stack's `TOPLEFT`. That model depends on a child stack height that retains at least one row when empty. The managed architecture is externally top-fixed, Blizzard owns its dynamic self-sized vertical extent, an empty container collapses to approximately `1 x 1`, the ordinary host represents only the fixed header reservation, and ENCHANTMENTS Fishing Lure lies outside the container's bounds. ABOVE therefore requires the child's dynamic logical bottom/full visible height to drive its own external host placement.

The completed Live source audit (`live`, `81d15e42f16f3473131880500e7a8c8eb88fa5e6`) found no safe supported public mechanism for that dependency. CustomAuraContainer exposes no suitable post-layout/size callback; `OnSizeChanged` is unavailable under `UntrustedLayoutScriptExecution`; geometry accessors are secret-aware rather than a content-height contract; and no safe active displayed-count scalar was found. Over-constraining the container, forming a host/container/bounds cycle, polling, private hooks, duplicating active-row/height logic, or maintaining a second content-height authority are rejected.

Managed ABOVE is intentionally unsupported for the rest of the prototype/migration period and will retire with the legacy renderer. Production managed placement will support SCREEN, BELOW, RIGHT, and LEFT. Existing `"ABOVE"` values must be preserved for rollback/migration history as appropriate and must not be silently converted; cutover should require the user to choose a supported replacement. This checkpoint does not implement that UI or migration behavior.

### Development-only legacy presentation and comparison

Two defaulted SavedVariables keys support temporary migration work without a schema-version change:

- `showLegacyBars` defaults to `true`. `Show Legacy BuffBars (Development)` gates only addon-owned legacy presentation. The legacy scanner/backend, aura events, caches, configuration, SavedVariables, and managed prototype continue operating. The gate owns legacy group frames/anchors and also clears externally parented secure cancel overlays and legacy tooltip state when hidden, so normal refresh/aura churn cannot re-show hidden presentation. `anchorsShown` remains independent.
- `legacyComparisonMode` defaults to `false`. `Legacy Comparison Mode (Development)` forces legacy presentation visible for parity comparison regardless of `showLegacyBars`; switching comparison does not mutate the visibility setting.

Comparison positioning is presentation-only. Each effective legacy SCREEN root displays at `savedX + settings.width + 24` while retaining its real saved `y`. Chained legacy children keep their normal relative anchors and receive no second shift; multiple independent SCREEN roots each receive their own shift. Managed groups remain at the real authoritative saved coordinates. Legacy drag persistence subtracts the current comparison shift before saving, and managed drag persistence writes the real coordinates before refreshing legacy positioning, so comparison coordinates never become real `x`/`y`, `anchorTo`, `placement`, or offsets. Reset retains the real shared topology: managed uses the reset coordinates while legacy shows at the comparison offset until comparison is disabled.

The effective workflow is:

- `showLegacyBars=false`, comparison off: managed-only presentation while the legacy backend stays active.
- `showLegacyBars=true`, comparison off: managed and legacy presentation at synchronized real positions, potentially overlapping.
- Comparison on, regardless of `showLegacyBars`: managed and legacy side by side for parity work.

`hideBlizzardFrames` remains independent. These controls are temporary development infrastructure and are not production renderer selection.

Earlier runtime validation passed for live presentation/configuration, supported SCREEN/BELOW topology, SCREEN-root dragging, header/comparison modes, SavedVariables-only position ownership, reset, lock/combat restrictions, mixed growth/scale, combat sizing/chaining, and native weapon-transition recovery. RIGHT validation then passed with empty and non-empty parents, stable aura appearance/disappearance, live parent-width changes, offsets, live mode switching, mixed growth/scale, parent dragging, reset, combat, and native enchant/lure behavior. LEFT validation passed with empty children, live child-width changes, parent-width independence, offsets, SCREEN/BELOW/RIGHT/LEFT switching, mixed growth/scale, drag refusal/following, reset, comparison/header modes, combat, and native enchant/lure transitions. No arbitrary graph or ABOVE runtime support is claimed.

`ApplyConfiguration()` is out-of-combat only. It defensively returns `false, "combat lockdown"` during combat and does not defer a configuration presentation update. The existing configuration UI already prevents its normal mutation paths during combat. This checkpoint must not be described as combat-capable live restyling.

Configuration status is therefore deliberately split:

- **Runtime-validated live OOC:** `fontSize`, `barColor`, `barBgColor`, `width`, `height`, `spacing`, `iconSide`, group `scale`, group `alpha`, BUFFS/DEBUFFS `sort`, BUFFS/DEBUFFS `maxBars`, BUFFS/ENCHANTMENTS `growUp`, supported BUFFS/DEBUFFS/ENCHANTMENTS SCREEN roots, supported DEBUFFS/ENCHANTMENTS BELOW/RIGHT/LEFT dependencies, SCREEN-root dragging/persistence and SavedVariables-only host ownership, managed `anchorsShown` visibility, and the development visibility/comparison workflow.
- **Implemented/source-static through the same supported path:** DEBUFFS `growUp`, without an equivalent direct runtime test claim.
- **Intentionally different from legacy:** managed ENCHANTMENTS ignores global legacy sort/`maxBars` and uses its fixed 7+2+1/source-order policy.
- **Intentionally unsupported/retiring:** managed ABOVE. Preserve existing values; remove the managed choice and require an explicit supported replacement at cutover rather than silently remapping.
- **Runtime-validated behavior/filter slice:** centralized complete HELPFUL descriptor composition; hidden and BUFFS/ENCHANTMENTS group overrides; route-before-destination whitelist/blacklist precedence; BUFF and `HelpfulEnhancements` destination filtering; BUFF ALL/TIMED_ONLY duration admission; and intentional D/E ALL-duration behavior.
- **Runtime-validated editor population:** BUFFS/ENCHANTMENTS current rows use active readable managed HELPFUL ownership, react to overrides/hidden state, remain independent of destination visibility filters, and preserve persistent/manual IDs separately.
- **Pending/research:** BUFFS as a child, arbitrary `anchorTo` graphs, broader cycle policy, full ENCHANTMENTS bounds, the empty-container parity decision, DEBUFF filter/override policy, native item-enchantment per-ID filter/hide policy, legacy-only control cleanup, final behavior/filter audit, production cutover, and removal of comparison infrastructure and the legacy renderer.

This synchronization does not change ownership. Blizzard continues to own managed AuraButton assignment, aura identity, SpellName/DurationText content, DurationBar timing, native tooltips, native BUFF and weapon-enchantment cancellation, and managed container sizing/layout. OBB owns only its permitted presentation/configuration layer and the existing ordinary fishing-lure row. The lure's detection, slot resolution, timer, tooltip ownership/anchor, and unsupported cancellation behavior are unchanged.

### Filtering and sorting

Map existing settings to native mechanisms where verified:

- `HELPFUL` and `HARMFUL` > filter strings.
- Managed HELPFUL route/override/filter state > one complete BUFFS + `HelpfulEnhancements` candidate-filter composition, with route resolution before destination filtering.
- Maximum bars > maximum frame count.
- Name sorting > `NameOnly`.
- Remaining-time sorting > `ExpirationOnly` with `Reverse`, preserving timeless-first and longest-to-shortest legacy OBB behavior.
- Default sorting > native default method.
- Growth and spacing > container flow and group layout options.

The BUFFS/DEBUFFS sort, maximum count, and growth mappings above synchronize live out of combat. BUFFS supports ALL by omitting `maxDuration` and TIMED_ONLY through `maxDuration = math.huge`; Blizzard filters zero-duration permanent candidates and the addon does not inspect duration values. TIMELESS_ONLY and NONE remain unsupported and retain the last supported managed descriptor, with ALL as the fresh-session fallback. Managed DEBUFFS and ENCHANTMENTS intentionally ignore saved duration flags and show all eligible sources. ENCHANTMENTS otherwise retains its source-specific policy.

### Enhancements

The validated ENCHANTMENTS presentation combines:

- A long-lived managed `HelpfulEnhancements` aura group capped at seven dynamically discovered Food, Flask/Phial, Augment Rune, and Fishing Bobber HELPFUL auras.
- Native item-enchantment entries for MainHand and OffHand. Ranged remains unregistered and unvalidated.
- One addon-owned fishing profession-tool lure row below the managed container, because that slot is outside the managed provider's MainHand/OffHand/Ranged surface.

This establishes a theoretical maximum of ten displayed entries: 7 HelpfulEnhancements + 2 registered native providers + 1 ordinary lure footer. Fishing Bobber is a HelpfulEnhancements aura and consumes one of the seven; Fishing Lure is the separate ordinary footer. Native item enchantments are placed after aura groups and sorted Slot/Normal, giving the DOWN order HelpfulEnhancements, MainHand, OffHand, Fishing Lure. In UP mode Blizzard reverses spatial progression while preserving logical source sequence: native rows move toward the header and HelpfulEnhancements occupy the lower managed portion. The item-layout builder preserves `AfterAuraGroups` when width, height, or spacing changes later. The ordinary lure stays below the managed container as a fixed footer outside FlowLayout in both directions.

This is an OBB presentation policy, not a Blizzard item-enchantment classification. Legacy ENCHANTMENTS `maxBars` and global sort remain stored for compatibility but are intentionally ignored by managed ENCHANTMENTS. The new path does not reuse the legacy aura-name heuristic: it guards readable active aura spell IDs, classifies `C_Spell` name/description metadata with explicit semantic markers, and applies the same session-only membership as ENCHANTMENTS includes and BUFFS exclusions.

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

- `OdysseusBuffBars_ManagedPrototype.lua` is loaded last by the addon TOC but performs no managed construction at file load. `OBB:OnAddonLoaded()` calls idempotent `ManagedPrototype:Initialize()` only after SavedVariables adoption, defaults, migrations, group normalization, and `OBB.db` readiness.
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

Earlier Phase A lifecycle diagnosis and correction:

- PTR source requires both `IsVisible()` and `IsEnabled()` before dynamic `UNIT_AURA` registration occurs.
- The initial prototype called `SetEnabled(true)` while its host was hidden, so that call itself could not register dynamic events. Its pending full update could still produce the initial six assignments once visible.
- The inspected container Lua does not establish whether showing the parent must invoke the child's intrinsic `OnShow` in this external creation pattern. The lifecycle order is therefore a verified ambiguity, not a conclusively proven sole cause of the static display. The six-aura maximum also limited which changes could become visible.
- The corrected lifecycle explicitly hides the container during construction, shows the host and container, and only then enables the visible container. The verified `SetEnabled` implementation performs event registration and requests the full update, so no addon-owned event handler or additional direct refresh is added.
- The initializer's registered icon remains managed by `CustomAuraButtonTemplate`: assignment and retained-aura updates call the template's native display update path.
- Native cancellation uses the AuraButton's framework-owned unit and aura instance. On `RightButtonDown`, Blizzard calls `C_UnitAuras.CancelAuraByInstanceID` internally; the prototype does not read or copy that identity.

Verified initial Phase A PTR results:

- The corrected visible/enabled lifecycle updates helpful player auras correctly.
- Helpful auras are added and removed through the managed container.
- Up to twenty managed AuraButtons display.
- Native right-click cancellation works through `SetCancelAuraButtons("RightButtonDown")`.
- No Lua errors or observed taint occurred during Phase A validation.
- The prototype remains inert if the 12.1 AuraContainer enum surface is absent.

Rollback: remove or disable the prototype without touching the direct scanner.

### Phase B — Managed bar-presentation prototype

Status: Core managed presentation and lifecycle are implemented and PTR validated. Visual parity and the expanded live configuration bridge are runtime validated through the current checkpoint; broader configuration parity and production integration remain pending.

- The earlier diagnostic group used 250 by 16 rows, two-pixel spacing, and a 22-pixel header. That geometry is preserved as historical prototype context but has been superseded by the runtime-validated legacy-parity style.
- The Phase B.2 validation baseline displayed at most thirty vertically stacked AuraButtons at 260 by 18 pixels with three pixels of spacing and full-coordinate 18 by 18 icons. Current BUFFS/DEBUFFS startup and live configuration use saved `maxBars` with the normal/default value 40 and existing 1-80 range. The ordinary root reserves only the fixed header/gap, never the configured capacity.
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
- The configured maximum remains selection capacity only. Addon code does not count active buttons, enumerate children, poll visibility, or call private layout methods.
- The previous fixed-capacity host background now covers only the persistent header. Stack-wide dynamic chrome is intentionally omitted for this validation phase; each managed AuraButton retains its own background.
- No frame is anchored from the container back to the root, so the hierarchy has no circular size dependency. No `DisableUntrustedLayoutScriptsTemplate` chrome is needed while stack-wide chrome is omitted.
- The container retains its one-pixel initial size before Blizzard's first managed layout.

Phase B.2 PTR validation passed for dynamic grow/shrink, near-empty collapse, more than ten displayed buffs, thirty-frame capacity without permanently reserved empty space, combat updates, duration presentation, timeless clearing, application counts, native tooltip and right-click cancellation, combat drag lock, post-combat dragging, and reload. The header/root remained usable, and no Lua errors, taint, blocked actions, anchor loops, protected-frame errors, or managed-reuse layout failures were observed. Subsequent Retail Live work added real shared-position persistence for every supported managed SCREEN root, SavedVariables-only named-host position ownership, runtime-validated lock/combat behavior, and managed `anchorsShown` visibility.

Subsequent Retail Live visual comparison passed for BUFFS, DEBUFFS, and ENCHANTMENTS with the shared row/header helpers, accepted legacy geometry, fonts, text placement, and group colors. Native AuraButton ownership, managed duration text/bar, native tooltips, native sorting, supported cancellation, and container self-sizing remain Blizzard-owned.

Native managed sorting implementation:

- The prototype supports `DEFAULT`, `NAME`, and `TIMELEFT` through one centralized mapping.
- `DEFAULT` uses `AuraContainerSortMethod.Default` with `AuraContainerSortDirection.Normal`.
- `NAME` uses `AuraContainerSortMethod.NameOnly` with `AuraContainerSortDirection.Normal`.
- `TIMELEFT` uses the verified legacy-compatible `AuraContainerSortMethod.ExpirationOnly` with `AuraContainerSortDirection.Reverse`, producing timeless auras first and timed auras from longest remaining to shortest remaining with descending aura-instance tie ordering.
- Default preserves Blizzard's native default ordering and is not described as duration sorting or timeless grouping.
- Name orders timed and timeless auras together alphabetically while preserving managed application counts and duration presentation.
- A prototype-only header button cycles `TIMELEFT` -> `DEFAULT` -> `NAME` -> `TIMELEFT` at runtime through the verified public `SetAuraGroupSortMethod` method. Changes are blocked during combat; already configured native sorting continues to govern combat aura updates.
- Saved BUFFS/DEBUFFS sort now synchronizes live out of combat through the same native mapping. Prototype buttons remain non-persistent temporary overrides; a later config apply reasserts the saved mode. ENCHANTMENTS intentionally ignores legacy global sort.
- Sorting remains entirely managed: no aura reads, Lua comparator, manual AuraButton reordering, polling, or private layout access is used.

Native sorting passed PTR runtime validation.

Managed HELPFUL behavior/filter composition:

- `RefreshCandidateFilters()` has no routing argument. Prototype-owned semantic membership, existing numeric overrides, BUFF/E filters, and supported BUFF duration state compile into a complete two-group descriptor snapshot. Both public setters run before the copied last-successful snapshot advances.
- Effective ownership is exactly `HIDDEN`, `BUFFS`, or `ENCHANTMENTS`, resolved by hidden -> explicit group override -> semantic enhancement route -> default BUFFS. Destination filters run only after ownership; they can reject/admit within a route but cannot create a route.
- With any enabled numeric BUFF whitelist entry, blacklist is ignored and only whitelisted effective-BUFF IDs are included. Otherwise BUFF blacklist excludes matching effective-BUFF IDs. Effective-E and hidden IDs remain BUFF exclusions in either mode.
- With an active ENCHANTMENTS whitelist, `HelpfulEnhancements` includes effective-E IDs intersected with that whitelist. Otherwise it includes effective-E IDs minus the E blacklist. An explicit E override can populate this group while semantic membership is empty. Hidden IDs are excluded.
- Existing overrides retain their SavedVariables shape: `hidden` or `group = "BUFFS" | "ENCHANTMENTS"`. Removing an override immediately restores semantic/default ownership because semantic source state remains separate. Hidden removes the ID from both managed HELPFUL groups.
- E spell-ID filters do not apply to MainHand, OffHand, or Fishing Lure. Those distinct sources remain intentionally unaffected under the unchanged 7+2+1 architecture.
- BUFF ALL (`true/true`) omits `maxDuration`. TIMED_ONLY (`true/false`) uses `math.huge`; Blizzard rejects zero-duration permanent/timeless candidates while retaining positive finite originals. No managed aura durations are read by addon code.
- BUFF TIMELESS_ONLY and NONE are not mapped. Unsupported saved combinations remain untouched and retain the last successfully applied supported descriptor; before the first successful apply, ALL is the internal managed baseline. Legacy presentation continues consuming the saved flags.
- Managed DEBUFFS and ENCHANTMENTS always include timed and timeless eligible state. D protects meaningful permanent mission/encounter/raid/Mythic+ HARMFUL state; E applies ALL to `HelpfulEnhancements`, MainHand, OffHand, and Fishing Lure. Neither uses `maxDuration` or consumes saved duration flags.
- `showTimed`/`showTimeless` are no longer in `Sync Group Bars` fan-out. Only BUFFS retains the two controls; D/E Grow Up occupies their former position. D/E stored values and the schema remain untouched.
- BUFFS/ENCHANTMENTS `Current group auras` use a fresh runtime-only snapshot built during the existing guarded readable player HELPFUL discovery. The shared route resolver applies hidden -> explicit group override -> semantic E route -> default BUFFS; destination whitelist/blacklist is deliberately absent because it filters visibility after ownership.
- The prototype returns copied rows sorted by numeric spell ID rather than exposing mutable ownership/source tables. BUFFS receives only effective-B IDs; ENCHANTMENTS receives only effective-E HELPFUL AuraGroup IDs. Hidden IDs appear in neither, and E does not include native MainHand/OffHand providers or Fishing Lure.
- Override Save/Delete refreshes an open B/E editor immediately. Runtime testing confirmed ordinary B->E and semantic E->B movement plus deletion restoring natural ownership without reload or aura membership change. Destination filters can hide a renderer row while its owned convenience-list entry remains.
- Current rows disappear when an aura expires or is removed; persistent whitelist/blacklist data is not mutated. Manual Spell ID entry remains available for inactive, hidden, historical, encounter-specific, and test IDs. DEBUFFS stays on the legacy historical cache pending a separate managed HARMFUL policy.
- Editor opening/rendering reads the current snapshot. Existing discovery replaces it on `PLAYER_ENTERING_WORLD`, player `UNIT_AURA`, established post-combat discovery, and semantic routing updates; override Save/Delete re-renders an open B/E editor. Closed editors are not continuously rebuilt. No polling, ticker, new `OnUpdate`, retry queue, AuraButton enumeration, or private collection access is added; combat retains the last safe snapshot until established post-combat discovery.
- DEBUFFS remains broad. General saved DEBUFF identity filters and hidden overrides are not claimed because non-`NeverSecret` player HARMFUL identity restrictions still prevent safe full parity.

Retail Live validation covered active routed Rune while editing BUFF blacklist/whitelist, empty/repopulated routing, unchanged rediscovery, reload/combat/loading, Rune/Flask E->B overrides, ordinary B->E overrides, hidden/delete-restore behavior, destination filter combinations, and the correction preventing BUFF/E whitelists from pulling across ownership. ALL/TIMED_ONLY switching, reload persistence, filter/override composition, and D/E ALL/UI/sync decisions also passed without reported Lua, taint, or blocked-action regressions.

Rollback: existing bars remain authoritative.

### Isolated managed player-DEBUFFS prototype

Status: Core managed player-DEBUFFS runtime behavior validated on Retail Live. Targeted private-aura and optional restriction-focused validation remain pending. This is not a production DEBUFFS backend.

- The DEBUFFS slice retains its own ordinary header/root and `CustomAuraContainerTemplate`, with independent frame names, local sort state, and managed lifecycle. Its restricted ordinary host supports an independent SCREEN root or BELOW/RIGHT/LEFT relative to the BUFFS container.
- The DEBUFFS host is created with `DisableUntrustedLayoutScriptsTemplate` and anchored one-way from its `TOPLEFT` to the BUFFS container's `BOTTOMLEFT`. Its saved BELOW offset is live-applied with the four-pixel horizontal host correction and unchanged vertical value; the default is `(-4, -8)` at the host. No BUFFS frame is anchored back to DEBUFFS, so the dependency remains strictly BUFFS root -> BUFFS container -> DEBUFFS host -> DEBUFFS container.
- When DEBUFFS is an effective SCREEN root, its managed header supports unlocked out-of-combat dragging and shared-coordinate persistence. When BELOW/RIGHT/LEFT of BUFFS, it refuses direct movement and follows BUFFS through the supported dependency.
- The container uses `SetUnit("player")` and one `AddAuraGroup("Harmful", "HARMFUL", options)` declaration. Its saved `maxBars` initializes and live-updates maximum frame count within the existing 1-80 range, normally/defaulting to 40.
- The group is intentionally broad. It supplies no candidate spell-ID filters and does not connect the legacy DEBUFFS whitelist/blacklist editor because non-`NeverSecret` player HARMFUL auras skip managed identity maps.
- Blizzard's default managed source selection supplies the public-plus-private path. The addon does not add a private source/group, enumerate private identities, or copy private aura data.
- Each container-owned AuraButton registers `SetIcon`, `SetSpellName`, `SetApplicationCount`, `SetDurationText`, and `SetDurationBar`; Blizzard owns duration updates, clearing on reuse, and presentation under restrictions.
- Tooltip behavior remains the native managed AuraButton path for ordinary, restricted, and private harmful auras. No indexed, slot, or instance-based addon tooltip lookup is added.
- The DEBUFFS initializer intentionally omits `SetCancelAuraButtons`; no secure cancellation overlay is created.
- Default, Name, and Time Left use the validated native sort mappings through a DEBUFFS-local selector. Sort mutation is blocked during combat, while the configured managed sort continues to govern updates.
- Dynamic sizing, pooling, public/private updates, and combat refreshes remain framework-owned. The addon does not count or enumerate buttons, poll, scan `UNIT_AURA`, read aura identity, or call private managed/layout methods.
- The legacy DEBUFFS scanner, renderer, configuration, SavedVariables, and Blizzard-frame handling remain present. The managed prototype live-consumes supported presentation, sort, maximum count, scale/alpha, growth, SCREEN, BELOW, RIGHT, and LEFT placement settings. Its `growUp` implementation shares the BUFFS FlowLayout path but does not claim equivalent direct DEBUFFS runtime coverage; arbitrary graph shapes and ABOVE remain unsupported.
- Retail Live validation on `12.1.0.69273`, interface `120100`, confirmed broad player/HARMFUL display, multiple simultaneous debuffs, combat additions/refreshes/removals, icons, names, application counts, duration text and StatusBars, dynamic grow/shrink, and simultaneous managed BUFFS/DEBUFFS operation.
- All three DEBUFFS sort mappings are runtime validated: Default uses `AuraContainerSortMethod.Default` with `AuraContainerSortDirection.Normal`, Name uses `AuraContainerSortMethod.NameOnly` with `AuraContainerSortDirection.Normal`, and Time Left uses `AuraContainerSortMethod.ExpirationOnly` with `AuraContainerSortDirection.Reverse`. Blizzard's Default semantic ordering is not reinterpreted beyond that verified mapping, and combat additions/removals/refreshes continued working in all tested modes.
- The native managed DEBUFF tooltip is runtime validated in combat. No custom indexed-aura lookup or fallback is required.
- Observed presentation examples included Temporal Displacement, Creeping Void, and Dusk Frights; Creeping Void exercised application-count presentation. These examples do not establish secret, restricted, `NeverSecret`, or private classification.
- No Lua errors, taint, or blocked actions attributable to OdysseusBuffBars were observed during Live validation.
- Targeted validation remains pending for a known real private harmful aura, explicit secrecy/restriction classification if still useful, and focused `NeverSecret` filtering behavior if a later product decision requires it. Source research supports private harmful auras entering the same default public-plus-private group pipeline, but OBB Live runtime validation of that path has not occurred.
- The layout is runtime validated for BUFFS movement, grow/shrink propagation, DEBUFFS SCREEN/BELOW/RIGHT/LEFT switching, logical-width lateral placement, SCREEN-root dragging, mixed topology/comparison behavior, and combat-driven changes. No anchor-loop errors, OBB-attributable Lua errors, taint, or blocked actions were observed. It uses managed bounds for BELOW and prototype-owned logical widths for RIGHT/LEFT; no aura counting, polling, size callback, or manual height calculation is introduced.

Rollback: remove or disable only the isolated DEBUFFS prototype; the validated managed BUFFS prototype and legacy DEBUFFS backend remain intact.

### Isolated managed ENCHANTMENTS prototype

Status: Core managed MainHand lifecycle, bounded transition recovery, dynamic semantic HELPFUL routing, the fishing-lure exception, visual parity, live presentation synchronization, ENCHANTMENTS growth, SCREEN/BELOW/RIGHT/LEFT placement, SCREEN-root dragging, and comparison interaction are validated on Retail Live. The managed 7+2+1 capacity and source-order policy is implemented. Direct OffHand/both-slot transition coverage, broader native parity, arbitrary placement parity, and production integration remain pending.

- The third ordinary host uses `DisableUntrustedLayoutScriptsTemplate` and supports an independent SCREEN root or BELOW/RIGHT/LEFT relative to the DEBUFFS container. BELOW uses the four-pixel host correction; lateral placement uses the logical-width formulas above.
- In BELOW/RIGHT/LEFT modes the dependency remains DEBUFFS container -> ENCHANTMENTS host. In SCREEN mode ENCHANTMENTS can be dragged and persisted independently. It consumes supported live presentation, icon-side, scale, alpha, `growUp`, SCREEN, BELOW, RIGHT, and LEFT values, but intentionally ignores saved legacy sort/`maxBars` semantics.
- ENCHANTMENTS owns a third independent `CustomAuraContainerTemplate`. It is configured early, shown before enablement, kept long-lived, and left at the managed one-pixel empty minimum until active native item-enchantment or `HelpfulEnhancements` frames establish larger FlowLayout bounds.
- The container calls `AddItemEnchantment(AuraContainerItemEnchantmentSlot.MainHand, options)` and `AddItemEnchantment(AuraContainerItemEnchantmentSlot.OffHand, options)`. Each registration uses the same bar initializer and `hidePermanent = false`. Ranged is not registered.
- The same container owns a long-lived `AddAuraGroup("HelpfulEnhancements", "HELPFUL", options)` group capped at seven rows. Its candidate filter is compiled from effective E ownership plus the E whitelist/blacklist policy; managed BUFFS receives the complementary route exclusions. Fishing Bobber consumes one slot. Native providers and Fishing Lure do not participate in this AuraGroup filter.
- Each fixed container-owned managed frame registers `SetIcon`, `SetSpellName`, `SetApplicationCount`, `SetDurationText`, and `SetDurationBar`. The primary text is Blizzard's equipped-item name. Blizzard owns application-count clearing, the retained duration object, countdown updates, StatusBar progress, equipment/enchant event refreshes, inactive-frame clearing, and frame reuse.
- Native item enchantments use `CustomAuraContainerItemEnchantmentPlacement.AfterAuraGroups` and `AuraContainerItemEnchantmentSortMethod.Slot` with `AuraContainerSortDirection.Normal`. Only MainHand and OffHand are registered; Ranged is absent. In DOWN layout the intended order is HelpfulEnhancements, MainHand, OffHand, then the ordinary Fishing Lure footer. Later width/height/spacing layout replacement preserves `AfterAuraGroups`.
- Tooltip behavior remains the native AuraButton inventory-item path. No addon hover handler, tooltip scraping, tooltip fallback, raw item-link parsing, hardcoded enchant-name map, or `enchantID == spellID` assumption is present.
- Each managed item-enchantment frame registers `SetCancelAuraButtons("RightButtonDown")`. The intrinsic AuraButton targets its own managed inventory slot through `C_PaperDollInfo.CancelTemporaryEnchantment`; no secure overlay or addon-owned cancellation state is added. Combat cancellation remains a required runtime test, not a source-proven claim.
- Managed ENCHANTMENTS has a theoretical 7+2+1 maximum: seven HelpfulEnhancements, two native providers, and one ordinary lure footer. Active managed frames participate in Blizzard FlowLayout and receive the current live presentation. DOWN uses TOPLEFT/Right+Down; UP uses BOTTOMLEFT/Right+Up. Blizzard reverses spatial progression in UP while preserving logical source sequence. The Fishing Lure row remains a fixed footer below the managed container outside FlowLayout in both directions, keeps its existing detection/timing/tooltip/spacing/non-cancellation/combat-deferral behavior, and is neither a managed AuraButton nor the Fishing Bobber aura.
- ENCHANTMENTS is terminal in the supported placement graph. A downstream group would need bounds that include the ordinary Fishing Lure footer, but the current ENCHANTMENTS container excludes that footer by design. No generic ENCHANTMENTS parent/full-bounds abstraction or fake managed minimum is introduced in this checkpoint.
- A Retail Live diagnostic found active MainHand PaperDoll data (`enchantID 8051`, remaining time `1063382`, zero charges, expiring) while the initial managed row was absent. One out-of-combat `enchantmentContainer:UpdateAllAuras()` immediately populated the row, proving an initial lifecycle timing miss rather than a slot, registration, sort, permanence, charge, visibility, or data-availability failure.
- Repeated cold-login diagnostics refined the race: file load, `PLAYER_LOGIN`, and `PLAYER_ENTERING_WORLD` all observed the enchant as absent; the first player `UNIT_INVENTORY_CHANGED` exposed enchantID `8051` with `remainingTimeMs = 0` and expiration enabled; a subsequent callback exposed usable positive remaining times, including `4698000`, `4510000`, and `4349000`. The managed item-enchantment provider does not subscribe to `UNIT_INVENTORY_CHANGED`, so a world-entry refresh alone cannot recover this transition.
- Live testing of the first two-callback recovery made the managed row appear automatically but without a timer. Refreshing on callback one consumed the incomplete zero-duration startup snapshot; after PaperDoll reported a positive remaining time (`3838386` observed), one later manual `enchantmentContainer:UpdateAllAuras()` updated the existing row with the correct timer.
- Later callback-count diagnostics disproved the fixed two-callback policy. Timed-ready publication occurred on callbacks 69, 105, and 430 across cold logins, so callback ordinal is not a readiness contract. Temporarily isolating the legacy synthetic weapon-enchantment append path produced the same managed failure and ruled it out as the cause; the legacy block was restored exactly.
- Later transition testing reproduced the same class of failure after portals, Home teleport, Hearthstone, and other world/loading transitions: `C_PaperDollInfo.GetTemporaryEnchantmentInfo(16)` eventually returned a valid MainHand enchant while the managed row remained absent, and one manual `enchantmentContainer:UpdateAllAuras()` immediately restored it with the correct duration. Diagnostic timing showed that `PLAYER_ENTERING_WORLD` and `LOADING_SCREEN_DISABLED` could both precede usable data, while the first inventory callback could expose an enchant ID with transitional zero remaining time. Neither event was accepted as a reliable direct completion point.
- The production path keeps the immediate best-effort container refresh and also arms recovery on every `PLAYER_ENTERING_WORLD`. Each transition increments an epoch, marks one recovery pending, resets its inventory generation, and temporarily registers player `UNIT_INVENTORY_CHANGED`. Inventory activity is coalesced through the existing zero-delay quiet-turn pattern. An old deferred callback cannot complete a newer transition because both epoch and generation are checked.
- After one quiet turn, the listener is unregistered and exactly one container-wide `enchantmentContainer:UpdateAllAuras()` refresh completes the recovery. If that completion point occurs during combat, one pending native recovery is retained and may complete after `PLAYER_REGEN_ENABLED`. This is separate from configuration synchronization, which still has no deferred queue.
- The bounded recovery adds no positive fixed delay, callback threshold, ticker, `OnUpdate`, polling loop, PaperDoll-based state reconstruction, synthetic native row, or permanent inventory listener. It refreshes all registered native providers while Blizzard retains ownership of MainHand and OffHand state. Legitimate no-enchant transitions terminate normally instead of remaining pending.
- Runtime validation passed for portal return to Silvermoon, Home teleport in both directions, portal to Stormwind, Hearthstone, dungeon entry/exit, Delve/no-loading-screen behavior, legitimate no-enchant state, and fresh enchant application afterward. The restored MainHand row showed the correct duration without a manual refresh. A later loading-screen transition with ENCHANTMENTS configured UP confirmed that the unchanged recovery remains functional and does not reset growth direction; a no-enchant transition while UP also passed where tested. No Lua errors or diagnostic chat spam were observed. MainHand is the directly exercised slot; direct OffHand-only and simultaneous-slot transition coverage are not claimed.
- Temporary transition trace instrumentation was removed after diagnosis. Normal runtime remains silent; pre-existing manual diagnostics and unexpected failure reporting remain available where applicable.
- Native managed primary text displays the equipped weapon name. Retail 12.1 exposes no supported temporary-enchantment-ID-to-localized-name resolver; tooltip scraping, hardcoded mappings, raw item-link parsing, and treating enchant ID as spell ID are rejected. A static slot label remains a later presentation option.
- Native MainHand/OffHand item enchantments and HELPFUL enhancement auras remain separate managed sources even though OBB presents both in ENCHANTMENTS. HELPFUL auras remain managed HELPFUL entries and are never converted into Blizzard item enchantments.

#### Validated semantic HELPFUL enhancement routing

Purpose and classification:

- Food, Flask/Phial, Augment Rune, and Fishing Bobber effects are technically HELPFUL buffs. OBB intentionally presents selected enhancement effects in ENCHANTMENTS for organization; this is an addon routing policy, not a Blizzard taxonomy claim.
- The prototype discovers readable active player HELPFUL aura spell IDs and classifies readable `C_Spell.GetSpellName` and `C_Spell.GetSpellDescription` text with case-insensitive literal markers: `well fed` -> `FOOD`, `flask` or `phial` -> `FLASK_PHIAL`, `augment rune` -> `AUGMENT_RUNE`, and `bobber` -> `FISHING_BOBBER`.
- The bobber rule uses no spell-ID table, item ID, toy ID, or duration requirement. It is a localization-sensitive semantic heuristic, not a formal Blizzard Bobber classification API.
- No documented `C_Spell` API was found that directly categorizes aura spells as Food, Flask, Phial, Augment Rune, or Fishing Bobber. `C_Spell.IsSpellHelpful` and `C_Spell.IsSelfBuff` returned true for the tested consumable effects, while `C_Spell.IsConsumableSpell` returned false and was not useful as a classifier.
- Aura duration is display/runtime state, not a semantic classification property. One-hour or other duration thresholds, minimum/maximum duration, and remaining time are excluded from classification. Runtime testing showed that reapplying Flask of Alchemical Chaos at roughly 37 minutes remaining could extend the displayed remainder to roughly two hours; repeated applications and profession bonuses can alter duration behavior. This conclusion also applies to any future potion or consumable research.

Dynamic managed routing:

- The final prototype has no hardcoded routing spell-ID list. The temporary control route for `1232325` was removed; discovered IDs are session-only, are not persisted, add no SavedVariables, and do not create a historical enhancement database.
- Item IDs are not treated as aura spell IDs. Bloom Skewers item ID `242302` was never used in candidate filters; the observed active Well Fed aura spell ID was `1232325`.
- Discovered membership remains semantic source state. The authoritative compiler combines it with higher-precedence overrides and destination filters to produce both effective descriptors. The auras remain managed HELPFUL entries, move between OBB presentation groups, and are not duplicated.
- Automatic discovery runs on `PLAYER_ENTERING_WORLD` and player-filtered `UNIT_AURA`. Restricted update payloads are not parsed for semantic discovery; the prototype performs a safe full HELPFUL rediscovery. No polling or continuous `OnUpdate` scanner is used. The manual diagnostic remains `/run OdysseusBuffBars.ManagedPrototype.DiscoverAndApplyHelpfulEnhancementRouting()`.
- Semantic membership and the last successfully applied complete candidate descriptor snapshot are retained separately. Equality is membership-based. Unchanged discovery remains silent, but setter suppression occurs only when the complete BUFF/E descriptors already match; an empty semantic set remains meaningful and clears stale semantic ownership without discarding overrides or filters.

Runtime evidence:

- Successfully classified and routed examples were `1232325` Well Fed -> `FOOD`, `432021` Flask of Alchemical Chaos -> `FLASK_PHIAL`, and `1234969` Ethereal Augmentation -> `AUGMENT_RUNE`. Cross-character validation also covered `393438` Draconic Augmentation -> `AUGMENT_RUNE` and `1233712` Hearty Well Fed -> `FOOD`. These are evidence examples, not a permanent supported-ID table.
- Unrelated tested HELPFUL auras returned no enhancement classification, including Soul Leech, Sign of the Emissary, Hellbent Commander, Ula'tek's Gift, Flight Style: Steady, Void-Touched Orbs, and Wild Imp. This sample does not prove zero false positives across all Retail auras.
- A separate transient observation remains uninvestigated: ordinary HELPFUL auras with `classification=nil` briefly appeared in ENCHANTMENTS before refreshing. Observed spell IDs were `1287425` (Void-Touched Orbs), `1281559` (Hellbent Commander), and `296553` (Wild Imp). No root cause or fix is established.
- Initially active Food, Flask, and Rune effects appeared in BUFFS. After discovery and candidate-filter refresh, they moved into ENCHANTMENTS, disappeared from BUFFS, showed no observed duplicates, and retained correct managed timers.
- The discovered set was exercised for initial population, identical rediscovery, growth, shrink, transition to empty, and repopulation. Observed transitions included `2 -> 3`, `3 -> 2`, and `1 -> 0 -> 1 -> 2`; no stale routed row was observed.
- `C_TooltipInfo.GetUnitAuraByAuraInstanceID(unitToken, auraInstanceID, filter)` was verified and used for active-aura diagnostics. Well Fed, Ethereal Augmentation, and Flask of Alchemical Chaos tooltips exposed the active aura name, current effect, and remaining time. Tooltip parsing is possible and was researched, but was not selected as the primary classifier because spell metadata was cleaner for these categories.
- In earlier routing validation, automatic discovery deferred in combat, manual routing was rejected, and no Lua errors occurred. The observed diagnostics confirmed the deferred `PLAYER_REGEN_ENABLED` retry path. The current checkpoint gates routine automatic routing messages behind a local debug flag, so normal gain/removal and unchanged synchronization are silent by default. Explicit manual diagnostics still print, and unexpected discovery/filter failures remain visible; no SavedVariables debug option was added.
- A temporary weapon enchant expired independently during HELPFUL routing tests. No native weapon-enchantment behavior changed. Optional future research may look for a supported temporary-enchant effect name instead of the current equipped-item/slot-oriented presentation; it is not solved here.
- Limited Edition Rocket Bobber was observed as ordinary player HELPFUL aura spell ID `1222880`. It classified as `FISHING_BOBBER`, moved from managed BUFFS to managed ENCHANTMENTS, remained synchronized on a manual rerun, and displayed correctly in ENCHANTMENTS. Blizzard's default BuffFrame also showed it as an ordinary HELPFUL aura; OBB changed only its own managed presentation policy.

#### Fishing profession-tool lure exception

- Fishing lures are temporary enchantments on a profession tool, not bobber HELPFUL auras. Bright Baubles item ID `6532` was the runtime test item, but the item ID is evidence only and is not implementation identity.
- The prototype obtains fishing profession slots through `C_TradeSkillUI.GetProfessionSlots(Enum.Profession.Fishing)`; runtime output contained slots 28, 29, and 30. It identifies the equipped tool through `Enum.InventoryType.IndexProfessionToolType`. Slot 28 is only a source-backed fallback and is accepted only when the profession-slot API also returned it.
- Lure state is read through `C_PaperDollInfo.GetTemporaryEnchantmentInfo(fishingToolSlot)`. Before application it returned no temporary enchant. After Bright Baubles it returned `enchantID = 265`, approximately `590000` remaining milliseconds, zero charges, and `hasExpirationTime = true`. Enchant ID 265 is not hardcoded or treated as stable identity.
- Blizzard's managed item-enchantment provider supports MainHand, OffHand, and Ranged slots only; it cannot register the fishing profession-tool temporary enchant. OBB therefore uses one small addon-owned ordinary row associated with ENCHANTMENTS. This row is an explicit architectural exception, not a managed AuraButton.
- The row visually matches ENCHANTMENTS, uses the fishing-tool icon, the static label `Fishing Lure`, remaining-time text/bar, and meaningful nonzero charges when available. A narrow local `OnUpdate` timer updates presentation only; it does not continuously poll the enchant API. Presence and state remain event/API driven, with one scheduled API recheck at expected expiration.
- The lure remains a fixed footer below managed ENCHANTMENTS in both growth directions. It stays outside Blizzard FlowLayout and does not reverse upward with the managed rows.
- Runtime lifecycle validation passed: no lure kept the row hidden; applying the lure to slot 28 showed the row and countdown; natural expiration reached zero, triggered the scheduled API recheck, and hid the row; reapplication produced a new slot-28 temporary enchant and made the hidden row reappear. No polling loop is used for presence detection.
- The initial tooltip made the ordinary lure row the `GameTooltip` owner and triggered `UntrustedLayoutScriptExecution` because that row's layout depends on the restricted, self-sizing ENCHANTMENTS container. The fix owns the tooltip from `UIParent`, uses `ANCHOR_CURSOR`, and calls `GameTooltip:SetInventoryItem("player", fishingToolSlot)`. Runtime testing then showed the fishing-rod inventory tooltip without observed taint. This is a restricted-layout ownership lesson, not evidence that the original lure item name is available.
- The fishing-tool tooltip represented the effect generically as `Fishing Lure (+7 Fishing Skill) (...)`; it did not expose the original Bright Baubles name.
- Native managed weapon-enchantment rows retain runtime-validated right-click cancellation. The ordinary fishing-lure row has no cancellation action on left or right click. Although `C_PaperDollInfo.CancelTemporaryEnchantment(slot)` is documented/restricted, slot-28 profession-tool cancellation has not been runtime validated and is not claimed as supported.
- `OBBEnchantDiag` was temporary external research tooling used to establish staged startup publication and variable callback ordinals. The validated prototype has no runtime, repository, or TOC dependency on it, and it can now be retired.
- Retail Live validation remains required for OffHand, simultaneous MainHand/OffHand behavior, two-enchant duration ordering, combat cancellation, zero/one/multiple charges, same-ID refreshes, permanent/zero-duration behavior, equipment swaps, empty/one-row/two-row sizing, Ranged where exercisable, broader enchant families, and the full BUFFS-to-DEBUFFS-to-ENCHANTMENTS anchor chain.

Rollback: remove or disable only the isolated ENCHANTMENTS prototype; the existing managed BUFFS/DEBUFFS prototypes and all legacy production behavior remain intact.

### Phase C — One managed Buffs group

- Add an explicit backend choice for the Buffs group.
- When managed mode is active, disable the direct scanner and ordinary bars for that group.
- Do not carry the current development comparison display into production selection; final managed mode must display exactly one production renderer per group.

Rollback: return that group to the contained direct scanner.

### Phase D — Filtering and sorting parity

- The isolated player-BUFFS prototype has validated saved maximum count, native saved sort/growth, centralized HELPFUL route/override/destination-filter composition, and ALL/TIMED_ONLY duration admission.
- Carry those mappings into the production backend without changing the existing SavedVariables schema.
- Preserve the documented BUFF unsupported-state fallback, D/E ALL policies, and current B/E ownership UI; complete DEBUFF/native-item policy and final parity audit before production integration.
- Preserve the PTR-validated sort directions rather than inferring behavior from enum names.

Rollback: preserve existing SavedVariables fields and switch the group backend back.

### Phase E — Multiple groups and units

- Complete targeted validation of the isolated player-DEBUFFS prototype with a known real private harmful aura and any still-useful explicit restriction cases.
- Migrate Debuffs only after the filtering product policy and remaining runtime evidence are accepted.
- Carry the runtime-validated SCREEN/BELOW/RIGHT/LEFT modes into production integration without broadening the supported graph implicitly.
- Exercise target, focus, and pet tokens before treating existing internal support as retained compatibility.
- Preserve chaining through ordinary host frames.

### Phase F — Tooltips and cancellation

- Native managed-button tooltip and player-buff cancellation are PTR validated in the isolated BUFFS prototype.
- Carry native tooltip into each production managed group as it migrates. Register cancellation only for cancellable groups; the player-DEBUFFS prototype intentionally omits it. The isolated item-enchantment prototype's native inventory tooltip and right-click cancellation are Live validated for MainHand in the tested non-combat context; combat cancellation and OffHand interaction remain pending.
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
- Remove ABOVE from managed placement choices and require an explicit supported replacement for existing ABOVE users; do not silently remap or discard the legacy value before rollback/migration needs are resolved.

## 6. Risk Register

| Risk | Severity | Mitigation |
|---|---:|---|
| Secret aura access or taint regression | Critical | Use only the public managed surface and native AuraButton descendants. |
| Carrying development comparison into production cutover | High | Keep visibility/comparison presentation-only during migration; enforce exactly one production renderer/backend per group at cutover. |
| Reparenting or externally recycling AuraButtons | High | Treat buttons as permanently container-owned. |
| Unsafe layout dependencies | High | Keep the movable host independent; prototype restricted layout behavior. |
| Reintroducing ABOVE through unsafe dynamic-height ownership | High | Keep ABOVE unsupported/retiring unless a separate bottom-owned, full-visible-bounds architecture is researched and runtime validated. |
| Stale addon-owned aura caches | High | Stop duplicating managed state as each group migrates. |
| Cancellation regression | High | Use native AuraButton cancellation and validate in combat. |
| Timed/timeless policy regression | High | Keep BUFF limited to ALL/TIMED_ONLY with retained fallback; keep D/E intentionally ALL and avoid addon-side duration reads. |
| Enhancement routing parity failure | High | Retain the validated guarded spell-metadata classifier and paired managed include/exclude filters; broaden categories only with targeted evidence. |
| Restricted-layout tooltip taint | High | Do not own tooltips from ordinary frames whose layout depends on restricted managed bounds; use an independent owner such as `UIParent`. |
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
| E | Buffs, debuffs, enhancements, fishing bobber routing, fishing-lure apply/expire/reapply, independent positioning, chaining, and growth. |
| F | Tooltip behavior, right-click cancellation, non-cancellable debuffs, enchant cancellation, combat interaction. |
| G | Blizzard icons outside combat, during combat, after combat, after Edit Mode, and after reload. |
| H | No remaining direct scanner call sites, containment removed, scanner events removed, caches no longer authoritative. |

Every phase should also include LuaCheck, load/reload testing, Lua error capture, taint-log review, combat transitions, and static diff review when the directory is under Git.

## 8. Open Questions Requiring Research or Runtime Tests

1. Which additional container and group setters, if any, should be exposed through final configuration, and which must remain out-of-combat only?
2. Where must `DisableUntrustedLayoutScriptsTemplate` be applied if future stack-wide chrome depends on managed bounds?
3. What product policy should replace general legacy DEBUFFS spell-ID filtering now that non-`NeverSecret` player HARMFUL auras are known to skip identity maps?
4. Should final UI prevent or explain unsupported BUFF TIMELESS_ONLY/NONE combinations while preserving rollback-compatible SavedVariables?
5. Does combined native item-enchantment and `HelpfulEnhancements` layout remain correct under simultaneous MainHand, OffHand, and routed-aura churn?
6. Does the validated semantic spell-metadata classifier remain sufficiently precise across a broader Retail aura population and any future categories?
7. What supported Retail or Edit Mode mechanism, if any, replaces combat-time hiding of Blizzard aura frames?
8. Should target, focus, and pet support remain part of the product despite not being exposed in the current configuration UI?
9. What safe current-ownership population policy should the DEBUFF editor use if managed HARMFUL identity filtering becomes supportable?
10. Does an actual private player HARMFUL aura traverse the verified default public-plus-private source path with correct presentation, sorting, tooltip, and removal behavior on Retail Live?
11. Is one container per group acceptable under realistic multi-group combat load?
12. Which public names and semantics survive the final PTR-to-Live transition?
13. Can profession-tool lure cancellation be supported safely through a documented public path, and does slot 28 accept `C_PaperDollInfo.CancelTemporaryEnchantment` at runtime?

The permanent direction is clear: the direct scanner should become a temporary compatibility backend, while Blizzard-managed containers and AuraButtons become the authoritative aura lifecycle and presentation model. The unresolved items above should be answered experimentally before implementation is committed to production behavior.
