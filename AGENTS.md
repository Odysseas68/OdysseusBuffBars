# OdysseusBuffBars - Project Context

## Addon Scope
- Addon name: `OdysseusBuffBars`.
- Game target: WoW Retail 12.1 / Midnight aura research and development.
- Language: Lua 5.1 in the WoW addon sandbox.
- Purpose: standalone aura-bar research and development addon, separate from the production Odysseus Utility Suite.
- Keep this addon small and focused on aura scanning, sorting, bar rendering, timer text, icons, and saved frame position.
- The mature legacy direct-scanning implementation is the working baseline. Migration to Blizzard-managed 12.1 aura containers is planned architecture work, not completed behavior.

## Active Files
- `OdysseusBuffBars.toc`
  - Standalone addon manifest and canonical load order.
- `OdysseusBuffBars.lua`
  - Module bootstrap: defaults, SavedVariables migration, events, slash commands, refresh flow, and public addon API.
- `OdysseusBuffBars_Auras.lua`
  - Retail aura scanning, secret-safe aura data handling, sorting, filtering, enhancement classification, and duration text preparation.
- `OdysseusBuffBars_Bars.lua`
  - Bar frames, pooling, layout, title anchors, rendering, tooltips, and secure right-click cancel overlays.
- `OdysseusBuffBars_Config.lua`
  - Native configuration frame, combat-locked controls, group settings, filters UI, and research/debug commands.

The TOC must not load the reference addon under `Reference\ElkBuffBars\`.

## Current Working State
- Uses `OdysseusBuffBarsDB` as the canonical global SavedVariables table.
- `OdysseusBuffBarsTestDB` is retained temporarily only for safe rename migration when the canonical table is absent; it is not merged or deleted.
- No profiles for now.
- No LibQTip for now.
- No LibDBIcon/minimap launcher yet.
- LibSharedMedia is optional and used only for status bar textures.
- Default groups:
  - player buffs: `HELPFUL`
  - player debuffs: `HARMFUL`
  - player enchantments/consumables: `ENCHANTMENTS`
- Default vertical anchor chain:
  - BUFFS anchors to the screen.
  - DEBUFFS anchors below BUFFS.
  - ENCHANTMENTS anchors below DEBUFFS.
- Below-group anchoring reserves space for the draggable title bar so chained title bars do not overlap the previous group's last aura bar.
- Default bar height is `18`.
- Default font size is `11`.
- Buff bars use reference-style blue fill over translucent blue background.
- Debuff bars use reference-style red fill over translucent red background.
- Buff and debuff background alpha is currently `0.1`.
- Timeless auras show only the background, with no status fill and no timer text.
- Text is drawn on a child overlay frame above the status bar so spell names, counts, and durations stay readable.
- Saved groups with the older extracted height `22` are migrated to `20` on load.
- Plain `/obb` or `/buffbars` opens the native configuration frame out of combat only.
- `/obb config`, `/obb options`, or plain `/obb` opens the native configuration frame out of combat only.
- `/obb anchors` toggles anchors out of combat only.
- `/obb refresh` forces a scan/update and is allowed in combat.
- `/obbtest` remains a compatibility alias with the same subcommands.
- The native configuration frame has General, BUFFS, DEBUFFS, and ENCHANTMENTS pages, is draggable/resizable, and closes with `Esc`.
- Group pages include Position controls for Anchor target, Placement, Offset X, and Offset Y.
- Anchor target, Placement, Sort, and Icon side use Blizzard dropdown controls, not cycle buttons.
- General includes `Lock anchors`, which keeps title bars visible but prevents dragging them.
- General includes `Toggle Anchors`, which shows/hides the draggable title bars.
- General includes `Reset Positions`, which restores BUFFS to screen placement near center and restores the default BUFFS -> DEBUFFS -> ENCHANTMENTS vertical anchor chain.
- Dragging is allowed only for screen-anchored/root groups. Child groups anchored to another group do not detach by dragging and drag-stop must not mutate them to Screen.
- The Anchor setting can intentionally rewire groups; if selecting a target would create a cycle, the target's old dependency on the current group is detached first.
- Dropdowns should be preferred over cycle buttons for multi-choice position settings.
- While a group title is being dragged, aura refresh/layout updates skip reapplying that group's position so it does not fight the mouse.
- Anchor cycles and self-anchors are guarded before `SetPoint`; invalid chains are reset to screen placement instead of calling into a dependent frame loop.
- General includes `Sync Group Bars`; when enabled, group bar settings sync across all groups except Anchor, Place, Offset X, and Offset Y.
- General includes `Hide default Blizzard frames`; this hides/shows Blizzard aura frames out of combat without hooks or replacing Blizzard update logic.
- Hide default Blizzard frames is reapplied when Blizzard Edit Mode closes, with short delayed retries, because Edit Mode can show the default aura frames again after applying its layout.
- General includes `Override Settings`; overrides are keyed by numeric `spellID`, can hide matching auras, and can route HELPFUL auras between BUFFS and ENCHANTMENTS.
- Override Settings intentionally does not do name-based matching and does not yet route across HELPFUL/HARMFUL filters.
- Numeric slider values also have edit boxes for exact manual entry.
- Group pages include a `Font Size` setting for bar name, duration, and count text.
- Group pages include a `Whitelist / Blacklist` button that opens a small per-group filter frame.
- The filter frame uses the same UI for every group and populates checkbox rows from the selected group's current aura data.
- Filter row checkbox hitboxes are intentionally small; the icon and text are display-only beside the checkbox.
- The filter frame is taller and uses a lightweight scrollbar under `Current group auras` for groups with many known spell rows.
- A small runtime cache keeps currently/previously scanned group spell rows visible even after a whitelist/blacklist changes the displayed bars.
- Per-group filters are stored in `OdysseusBuffBarsDB` under each group as `filters.whitelist` and `filters.blacklist`.
- Filter matching is spellID-first: if a group whitelist has entries, only those spell IDs are shown; otherwise the blacklist hides matching spell IDs.
- Manual spellID entries are still supported and remain visible as saved spell rows even when the aura is not currently active.
- Filter config changes are out-of-combat only; `/obb refresh` can still be used in combat.
- Configuration opening, controls, anchor dragging, and config frame drag/resize are locked during combat; attempts print a chat warning.
- Combat warning chat text is formatted as `OdysseusBuffBars: WARNING:` with `WARNING:` in red.
- If the configuration frame is open when combat starts, it is hidden and restored after combat ends.
- The configuration frame intentionally does not use profiles.
- Right-click cancel uses secure right-click overlay buttons and is configured only while out of combat.
- Right-click cancel is enabled for player buff bars, including timeless class buffs/forms such as Priest Shadowform, and for temporary weapon enchantment bars; debuffs are not cancellable.
- Temporary weapon enchantment bars use slot labels such as `Main-hand Enchant` / `Off-hand Enchant` and a local non-secret seconds formatter; do not use `SecondsToTimeAbbrev` for these synthetic rows.
- Secure cancel overlays are parented to `UIParent` and positioned over bars with UIParent coordinates, not bar-relative anchors, so aura group frames remain movable/resizable by normal layout code.
- Bar-wide hover tooltips use Blizzard tooltip APIs: unit aura tooltips for buff/debuff bars and inventory item tooltips for temporary weapon enchantment bars.
- During combat, group anchor points are not cleared/rebuilt; existing anchors are left intact so chained groups can follow parent height changes without protected `ClearAllPoints()` calls.

## Phase Notes
- The current phase describes the mature direct-scanning implementation. It does not represent a completed migration to the planned Retail 12.1 aura-container architecture.
- Current phase: aura engine, bars, combat safety, config basics, right-click cancel, Blizzard-frame hiding, bar-wide tooltips, per-group spellID whitelist/blacklist filters, and first-pass spellID Override Settings are in place for broader raid testing.
- Next phase: harden Override Settings after in-game testing, then decide whether cross-filter routing is worth a central aura router.
- Override Settings shape:
  - Store global aura overrides in `OdysseusBuffBarsDB`, not profiles.
  - Prefer `spellID` keys for overrides.
  - First pass supports hidden and HELPFUL routing between `BUFFS` and `ENCHANTMENTS`.
  - Do not route BUFFS/DEBUFFS across HELPFUL/HARMFUL filters until a central router is designed.
  - TODO: make Override Settings more user-friendly by populating known aura rows from cached scanned data.
  - TODO: show icon, readable cached name, and spellID in the override list, while saving only numeric spellID keys.
  - TODO: keep manual Spell ID entry as a fallback for auras that are not currently known/visible.
  - TODO: add per-row controls for Default/BUFFS/ENCHANTMENTS and Hidden once the known-aura row UI is stable.
  - Support display-name override later, but keep raw secret aura names out of unsafe string operations.
  - Consider color/icon overrides only after group/name overrides are stable.
- Implementation caution:
  - Do not make name-based matching the primary behavior; aura names can be secret in combat.
  - Apply filters/overrides through cached safe aura data and readable spell IDs where possible.
  - Keep filter/override config changes out of combat.
  - Keep Override Settings staged separately from the now-added whitelist/blacklist path.

## Managed AuraContainer Research and Phase B.2 Rules
- Stable project roots:
  - `D:\WowDEV\Reference\Blizzard\` is the current local Blizzard UI source mirror. Use it to verify APIs, templates, mixins, layout, secure execution, and lifecycle behavior; do not store project-owned analysis there.
  - `D:\WowDEV\Projects\BlizzardResearch\12.1.0\` is the authoritative project-owned research root. Its primary AuraContainer analysis is `D:\WowDEV\Projects\BlizzardResearch\12.1.0\Analysis\AuraContainerArchitecture.md`; preserve verified findings, historical notes, citations, inferences, and runtime-test requirements there rather than recreating them in the addon or source mirror.
  - `D:\Program Files\Blizzard\World of Warcraft\_ptr_\Interface\AddOns\OdysseusBuffBars\` is the isolated addon/prototype working copy for PTR runtime validation. Migrate production behavior only after research and prototype validation.
- Required workflow:
  - Inspect current Blizzard PTR source -> update the authoritative Analysis document -> derive an implementation plan -> modify only the isolated prototype -> validate on PTR, including combat -> migrate production code incrementally -> synchronize addon documentation.
  - Research must precede implementation whenever Blizzard architecture or secure behavior is uncertain.
  - Record the exact build, interface, branch, and source revision when available. Cite exact Blizzard files, mixins, functions, and line ranges in the research document.
  - Label verified source facts, inferences, and runtime-test requirements distinctly. Never invent Blizzard APIs or behavior, and preserve historical findings when Blizzard renames or restructures a system.
- Verified evidence snapshot: PTR build `12.1.0.68914`, interface `120100`, branch `ptr`, commit `d3915c78aba77a7a9be76acbfa35c674bbb6abe9`. The following names and behavior are verified implementation details for that build, not guaranteed permanent public API; recheck them after Blizzard source changes.
- Managed layout ownership and lifecycle:
  - `ManagedAuraContainerPrivateMixin` owns the dirty-phase lifecycle, while `CustomAuraContainerFlowLayoutMixin` delegates layout calculation to `AnchorUtil.FlowLayoutMixin`.
  - Broad lifecycle: aura update -> mark dirty -> one-shot visible `OnUpdate` -> retain/release/acquire managed frames -> commit the dense displayed-frame list -> FlowLayout -> container `SetSize`.
  - The CustomAuraContainer sizes itself from displayed managed frames. A configured maximum is a selection ceiling/capacity, not the current visible count; do not derive height from that maximum or count AuraButtons merely to resize the container.
  - `ResizeToBoundsRect` is not part of the verified AuraContainer sizing path.
- Active-frame and layout boundaries:
  - Blizzard internally tracks dense displayed frames and active managed frames, but no supported public active-count API or displayed-button enumerator was found.
  - The public group frame count reflects provider allocation capacity in batches, not visible aura count. Hidden pooled buttons remain container children but are excluded from FlowLayout input and do not affect calculated bounds.
  - Do not use raw `GetChildren()` or `IsShown()` counts as the primary design. Do not read private collections such as `framesByIndex`, aura-instance maps, or provider `activeFrames`.
  - CustomAuraContainer exposes no supported post-layout callback in the researched build. TargetFrame's callback is private and consumer-specific; CustomAuraContainer does not inherit it.
  - Do not hook private layout methods or collections, call private functions such as `MarkDirty` or `ApplyLayout`, or add polling/countdown/layout `OnUpdate` logic.
- Phase B.2 architectural direction, not completed behavior:
  - Retain an independent position/root frame and anchor the self-sizing managed container below or within it without circular size dependencies. Let the managed container own its calculated size.
  - If background or chrome must follow the managed bounds, use a separate ordinary chrome frame and apply `DisableUntrustedLayoutScriptsTemplate` where required by the verified secure-layout design.
  - Do not resize the managed container from a custom `OnSizeChanged`, reparent managed AuraButtons, or mirror managed auras into ordinary bars.
  - Blizzard's secure managed pipeline performs layout during combat, but source inspection did not prove arbitrary addon `SetHeight` calls from a callback combat-safe. Combat-time anchoring, protection state, and chrome propagation require PTR validation; call behavior combat-safe only when supported by verified Blizzard source or completed PTR testing.
- Phase B.2 runtime validation remains required for non-circular root/container/chrome anchors, combat-time anchor propagation, frame protection state, empty-container one-pixel bounds, and same-frame chrome resizing during managed aura reuse. Do not mark these checks complete without PTR evidence.

## Reference Files
The working reference addon is copied only for research:

- `Reference\ElkBuffBars\ElkBuffBars.lua`
  - Main ElkBuffBars file with mixed Retail/Classic code.
  - Contains the Retail aura scan path based on `C_UnitAuras.GetAuraDataByIndex`.
  - Keeps previous aura data by `auraInstanceID`.
  - Preserves previous `expires` when `expirationTime` becomes unreadable/secret.
- `Reference\ElkBuffBars\EBB_Bar.secrets.lua`
  - Retail secret-safe bar display and timer code.
  - Uses duration objects, safe count/dispel wrappers, cached time-left fallback, and secret-safe text display.
- `Reference\ElkBuffBars\EBB_BarGroup.secrets.lua`
  - Retail secret-safe bar group update/sorting code.
  - Uses `C_UnitAuras.GetUnitAuraInstanceIDs` for aura ordering where possible.
  - Defers unsafe structural work in combat while allowing aura groups to live-update.
- `Reference\ElkBuffBars\AGENTS.md`
  - Reference-addon guidance merged into this file.

## Midnight Secret Aura Rules
- Many aura fields can be secret in combat, dungeons, and raids: names, counts, texture/icon IDs, durations, expiration times, source units, and booleans.
- Do not compare, sort, concatenate, index tables by, format, or do math on possibly secret aura values unless guarded by `issecretvalue` / `canaccessvalue` or handled through safe Blizzard APIs.
- Passing a secret texture token directly to `Texture:SetTexture(...)` can work. Do not require icon/texture to be readable before using it.
- For timer display, prefer Blizzard duration objects and native formatting:
  - `C_UnitAuras.GetAuraDuration(unit, auraInstanceID)`
  - `DurationObject:FormatRemainingDuration(formatter)`
  - `C_StringUtil.CreateNumericRuleFormatter()`
- Avoid `SecondsToTimeAbbrev`, modulo, `math.floor`, comparisons, or `string.format` on secret duration numbers.
- For sorting timed auras in combat, prefer Blizzard ordered aura instance IDs:
  - `C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter, nil, Enum.UnitAuraSortRule.ExpirationOnly, Enum.UnitAuraSortDirection.Reverse)`
  - Do not sort secret expiration fields directly in Lua.

## Mature Legacy Aura Engine Notes
- These notes describe the current direct-scanning implementation, not completed Retail 12.1 aura-container architecture.
- Uses `C_UnitAuras.GetAuraDataByIndex(unit, index, filter)` for scans.
- Uses `C_UnitAuras.GetAuraDuration(unit, auraInstanceID)` for timer duration objects.
- Uses `DurationObject:FormatRemainingDuration(formatter)` for timer text.
- Uses `C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter, nil, sortRule, sortDirection)` for sorting.
- Keeps previous aura data by `unit:filter:auraInstanceID` shape via a per-`unit:filter` cache keyed by `auraInstanceID`.
- Keeps previous values for fallback when combat makes fields unreadable.
- Treats `expirationTime == 0` as timeless, not expired.
- When `expirationTime` is unreadable, reuse `previous.expires` before calling `C_UnitAuras.DoesAuraHaveExpirationTime`.
  - This fixes default timeless login/session buffs showing `0s` after entering combat.
- Filters already-expired timed auras only when `expirationTime` is readable, positive, and `<= GetTime()`.
- Applies per-group whitelist/blacklist filters only from readable numeric `spellID` values.
- Applies first-pass overrides only from readable numeric `spellID` values.
- Hide overrides apply to normal auras and temporary weapon enchant rows; group routing is limited to HELPFUL aura groups.
- Keeps a runtime `OBB.filterAuraRows[groupID]` cache for filter UI display rows before applying whitelist/blacklist visibility.
- Icon fallback order follows the reference approach:
  - pass through non-nil texture directly,
  - previous icon,
  - readable spell-id lookup,
  - question mark fallback.
- ENCHANTMENTS combines temporary weapon enchants with readable helpful buffs whose names look like food/flask/phial/rune/weapon-consumable buffs.
- Enhancement classification also has a small spellID fallback list for tested consumables whose names may not be safely readable on the first raid/combat scan, including Blooming Feast Well Fed spellID `1232585`.
- Enhancement classification is cached by `auraInstanceID` so buffs do not jump groups when names become secret in combat.

## What Not To Reintroduce
- Do not hook, replace, hide-and-harvest, or otherwise depend on Blizzard `BuffFrame` / `DebuffFrame` aura buttons.
- Do not keep Blizzard buff frames transparent to harvest their duration text.
- Do not import `AbstractFramework` as an icon/timer fix.
- Do not use name-based `C_Spell.GetSpellTexture(name)` / `C_Spell.GetSpellInfo(name)` as the primary icon fallback.
- Do not add Classic/MoP compatibility branches.
- Do not add profiles yet.
- Do not add LibQTip yet.
- Do not add LibDBIcon/minimap launcher until the first aura-engine behavior is stable.

## Known Legacy Tested Behavior
- The source ElkBuffBars experiment worked on an open-world training dummy.
- The source ElkBuffBars experiment worked through a full Stockade dungeon run with no Lua errors.
- Icons, names, and durations worked in combat in the source experiment.
- Timeless buffs worked in the source experiment.
- In this addon, the timeless-login-buff `0s` combat bug was fixed by preserving previous `expires`.
- One acceptable edge case from the source experiment: very short combat-generated proc/passive auras, such as Paladin Hammer of Wrath SpellID `1241288`, may briefly show as `0.0s` at top. Do not destabilize the working path just to chase this unless there is a clear, low-risk fix.

## Testing Checklist
After aura-related changes, test at minimum:
- `/reload` on player login: timeless buffs should display immediately.
- Enter combat with default session/login buffs: timeless buffs should stay timeless and should not show `0s`.
- Open-world training dummy combat: icons, names, and timers should remain visible.
- Dungeon/instance combat, such as Stormwind Stockade: no Lua errors on pull, during combat, or after leaving combat.
- Timed buffs and debuffs should count down.
- Buffs should not disappear after leaving combat.
- Bar spell text and duration text should render in front of the bars.
- Timeless buffs should show background only, with no countdown fill.
- Saved frame position should survive reload.
- If errors occur, capture the first full stack trace.

## Development Constraints
- Keep changes minimal and scoped.
- Prefer one-file-at-a-time changes when actively debugging combat behavior.
- Use `pcall` around risky C API calls that may reject secret/tainted input.
- Avoid structural frame work in combat unless known safe.
- Do not create or reconfigure secure cancel buttons during combat; defer those changes until `PLAYER_REGEN_ENABLED`.
- Run `luacheck OdysseusBuffBars.lua OdysseusBuffBars_Auras.lua OdysseusBuffBars_Bars.lua OdysseusBuffBars_Config.lua` after Lua changes.
  - The current baseline has many WoW-global warnings, but should report `0 errors`.
