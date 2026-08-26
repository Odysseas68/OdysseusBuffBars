# OdysseusBuffBars - Project Context

## Addon Scope
- Addon name: `OdysseusBuffBars`.
- Game target: WoW Retail 12.1 Live / Midnight aura research and development.
- Language: Lua 5.1 in the WoW addon sandbox.
- Purpose: standalone aura-bar research and development addon, separate from the production Odysseus Utility Suite.
- Keep this addon small and focused on aura scanning, sorting, bar rendering, timer text, icons, and saved frame position.
- Blizzard-managed containers are the sole production renderer authority for BUFFS, DEBUFFS, and ENCHANTMENTS. The ordinary-bar backend, secure cancellation overlays, direct-scanning backend, and synthetic legacy weapon-enchantment scanner are retired.

## Active Files
- `OdysseusBuffBars.toc`
  - Standalone addon manifest and canonical load order.
- `OdysseusBuffBars.lua`
  - Module bootstrap: defaults, SavedVariables migration, events, slash commands, refresh flow, and public addon API.
- `OdysseusBuffBars_Config.lua`
  - Native configuration frame, combat-locked controls, group settings, filters UI, and research/debug commands.
- `OdysseusBuffBars_ManagedPrototype.lua`
  - Production managed BUFFS, DEBUFFS, and ENCHANTMENTS architecture, paired HELPFUL ownership/compiler state, native weapon-enchantment integration, self-contained lure formatting and lure exception, hosts, layout, and managed recovery. Its historical filename may be reconsidered only in a separate cleanup task.

The TOC must load only this addon's active files and bundled libraries. The old local `Reference\ElkBuffBars\` directory is no longer present in this repository; use historical notes and committed research instead of assuming that local reference tree exists.

## Active Development Environment
- Active development/test repository: `D:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\AddOns\OdysseusBuffBars\`.
- This `_retail_` copy is the primary development and runtime-test environment for current Retail 12.1 Live work.
- The former PTR addon copy is frozen historical/validation reference material. Do not edit the PTR addon copy during normal development.
- Current Live Blizzard source mirror: `D:\WowDEV\Reference\Blizzard\wow-ui-source\`; use it as the primary source reference for current Retail behavior.
- PTR Blizzard source mirror: `D:\WowDEV\Reference\Blizzard\wow-ui-source-ptr\`; use it for future/unreleased PTR change monitoring and regression checks.
- Authoritative research repository: `D:\WowDEV\Projects\BlizzardResearch\`.
- Current 12.1 authoritative Analysis directory: `D:\WowDEV\Projects\BlizzardResearch\12.1.0\Analysis\`.
- Completed Live audit commit in BlizzardResearch: `a07fb6de71e915416fe379af9e92565ef7e1df9b` (`Confirm AuraContainer architecture on Live 12.1`).
- The Live audit verified Retail `12.1.0.69273`, interface `120100`, Live source revision `eb941aad0`, final PTR revision `6e348870e`, and no material Live-only aura architecture changes.

## Git Workflow
- OdysseusBuffBars is now a real Git repository with `main` and a GitHub remote.
- Normal static validation may include `git status`, `git diff`, `git diff --check`, and readback verification.
- Do not automatically commit or push after implementation or research tasks.
- Commit and push only when explicitly requested or when a separate repository-maintenance task instructs it.

## Current Working State
- Uses `OdysseusBuffBarsDB` as the canonical global SavedVariables table.
- `OdysseusBuffBarsTestDB` is retained temporarily only for safe rename migration when the canonical table is absent; it is not merged or deleted.
- No profiles for now.
- No LibQTip for now.
- No LibDBIcon/minimap launcher yet.
- LibSharedMedia is intentionally retained. It is currently optional and used only for status bar textures; future managed Config work may add font and status-bar texture selection.
- Default groups:
  - player buffs: `HELPFUL`
  - player debuffs: `HARMFUL`
  - player enchantments/consumables: `ENCHANTMENTS`
- MANAGED is the only runtime renderer authority. There is no mutable mode/per-group authority, STAGED or LEGACY switching, transition transaction, legacy fallback, or same-session renderer reconstruction.
- `OBB:GetRendererAuthorityMode()` is a temporary immutable Config compatibility façade that always returns `"MANAGED"`; it is not authority state. `SetRendererAuthorityMode` and `SetGroupRendererAuthority` no longer exist.
- The managed module object always exists. `ManagedPrototype:IsReady()` reports successful readiness or a retained reason across uninitialized, initializing, ready, and failed internal states. FAILED is terminal for the session; `/reload` is the only reconstruction attempt.
- Startup validates required Retail managed capabilities before construction where possible, then validates required methods on constructed containers and initial AuraButton batches inside one protected initialization boundary. Do not add generic template introspection, polling, or private Blizzard inspection.
- Provisional managed hosts, headers, containers, and Fishing Lure presentation remain hidden; containers remain disabled until the transaction has complete B/D/E infrastructure, a successful initial paired BUFFS/ENCHANTMENTS descriptor application, and a complete applied paired snapshot. Only then may presentation commit and READY be exposed.
- Managed initialization requires effective BUFFS as the SCREEN root, effective BUFF duration ALL or TIMED_ONLY, supported effective D/E SCREEN/BELOW/RIGHT/LEFT topology, initialized managed B/D/E infrastructure, and a successful coupled B/E descriptor application. The former authority-preflight API is retired; its strict effective-state validation now runs inside protected managed initialization. Historical unsupported raw duration/topology is evaluated into copied runtime-only effective settings; raw SavedVariables are never remapped or rewritten.
- Fatal managed failure marks FAILED first, retains the reason, invalidates delayed callbacks, unregisters/gates addon-owned managed events, stops dragging and Fishing Lure timer work, and disables/hides constructed containers and hosts as best effort. Created/named frames may survive the Lua session but must remain inert; they are not destroyed.
- Core consumes `Initialize()` and checks `IsReady()`. READY exposes complete managed B/D/E presentation. Fatal startup fails closed: it reports one clear ERROR, keeps managed presentation inert, attempts no alternate renderer, and leaves failure handling without a destructive SavedVariables rewrite. Config still initializes regardless of readiness.
- Before recursive defaults, startup records raw saved groups that have an explicit placement but no serialized `anchorTo`; after defaults it restores that intentional nil parent. This preserves D/E SCREEN roots without a schema field or generic `CopyDefaults` change. Missing placement plus missing parent still receives the historical D->B / E->D defaults, while unsupported or contradictory explicit state remains raw for the compatibility evaluator.
- The legacy Bars and Auras/Engine backends are removed. Core never calls a legacy scanner and no longer registers the legacy `UNIT_AURA`, `WEAPON_ENCHANT_CHANGED`, or `WEAPON_SLOT_CHANGED` renderer events. No legacy group, header, row, timer, tooltip, secure overlay, positioning, scan/cache refresh path, direct aura scanner, or synthetic weapon-enchantment scanner is loaded or creatable by OBB production code.
- `OBB.Engine` is retired. Managed Fishing Lure formatting is module-local and preserves the historical 1.5-unit thresholds, upward rounding, suffixes, protected call, and empty-string degradation. The obsolete `OBB.groups`, `OBB.bars`, and `OBB.auraData` bootstrap tables are removed; `OBB.filterAuraRows` has no current runtime role, and Config has no legacy cache fallback.
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
- `/obb refresh` uses the managed-only Core compatibility façade. It rejects missing DB or unready/FAILED managed state safely, leaves Blizzard-owned managed aura lifecycle authoritative in combat, and out of combat coordinates managed configuration plus semantic/native/Fishing Lure recovery without Engine or Bars calls.
- `/obbtest` remains a compatibility alias with the same subcommands.
- The native configuration frame has General, BUFFS, DEBUFFS, and ENCHANTMENTS pages, is draggable/resizable, and closes with `Esc`.
- Group pages include Position controls for Anchor target, Placement, Offset X, and Offset Y.
- Anchor target, Placement, Sort, and Icon side use Blizzard dropdown controls, not cycle buttons.
- On the shared group-page construction path, BUFFS keeps Sort and Icon side-by-side. D/E omit the BUFF-only filter controls, so their Icon dropdown is anchored below Sort with the normal vertical gap; do not restore the former Offset Y overlap or globally shift the correct BUFFS layout.
- General includes `Lock anchors`, which keeps title bars visible but prevents dragging them.
- General includes `Toggle Anchors`, which shows/hides managed draggable title bars without moving their hosts or changing reserved header geometry.
- General includes `Reset Positions`, which restores BUFFS to screen placement near center and restores the default BUFFS -> DEBUFFS -> ENCHANTMENTS vertical anchor chain.
- Dragging is allowed only for screen-anchored/root groups. Child groups anchored to another group do not detach by dragging and drag-stop must not mutate them to Screen.
- Managed Config constrains Anchor choices to BUFFS SCREEN, DEBUFFS SCREEN/BUFFS, and ENCHANTMENTS SCREEN/DEBUFFS. Parented D/E offer only BELOW/LEFT/RIGHT; ABOVE and arbitrary targets are not offered.
- Dropdowns should be preferred over cycle buttons for multi-choice position settings.
- While a group title is being dragged, aura refresh/layout updates skip reapplying that group's position so it does not fight the mouse.
- General includes `Sync Group Bars`; when enabled, group bar settings sync across all groups except Anchor, Place, Offset X, and Offset Y.
- General includes `Hide default Blizzard frames`; this is a best-effort legacy convenience toggle that hides/shows Blizzard aura frames out of combat without replacing Blizzard update logic. Blizzard Edit Mode remains the supported owner of default aura-frame visibility.
- Hide default Blizzard frames is reapplied when Blizzard Edit Mode closes, with short delayed retries, because Edit Mode can show the default aura frames again after applying its layout.
- General includes `Override Settings`; overrides are keyed by numeric `spellID`, can hide matching auras, and can route HELPFUL auras between BUFFS and ENCHANTMENTS.
- Override Settings intentionally does not do name-based matching and does not yet route across HELPFUL/HARMFUL filters.
- Managed destination whitelist/blacklist filtering is BUFFS-only. Compose complete BUFFS and `HelpfulEnhancements` descriptors together, but do not apply a destination-filter stage to managed DEBUFFS or ENCHANTMENTS.
- Resolve HELPFUL ownership as hidden, explicit B/E group override, semantic ENCHANTMENTS route, then default BUFFS. Only afterward may the BUFFS destination filter reject/admit BUFF-owned IDs; ownership routing is not destination filtering.
- Populate managed HELPFUL current-aura ownership from current readable source state using the same precedence. Only BUFFS exposes the Whitelist/Blacklist UI; do not interpret internal E ownership rows as destination-filter support.
- Current managed HELPFUL discovery is runtime-only, returns copied UI rows, and must not mutate persistent filter/override tables. Do not enumerate AuraButtons or private managed collections for config population.
- Managed DEBUFFS is intentionally broad/unfiltered. Managed ENCHANTMENTS is intentionally broad across effective `HelpfulEnhancements`, MainHand, OffHand, and Fishing Lure sources. Do not reintroduce partial D/E destination filtering without a new explicit product decision plus source/runtime justification.
- Do not derive temporary-enchantment display names through tooltip scraping, private provider inspection, AuraButton enumeration, hardcoded enchant-ID maps, or by reinterpreting `enchantID` as a spell/item ID. Use only supported public slot/enchant metadata and native weapon-tooltip context; revisit naming only if Blizzard exposes a documented public mapping.
- Preserve historical D/E filter SavedVariables during cleanup. They are dormant compatibility/history data; managed D/E must not expose or consume them.
- When Blizzard candidate filters can own duration admission, do not read managed aura duration values addon-side. Managed BUFFS Config supports only ALL and TIMED_ONLY; historical TIMELESS_ONLY/NONE is preserved raw and interpreted as runtime-only ALL until explicit user correction. Managed DEBUFFS and ENCHANTMENTS intentionally ignore legacy timed/timeless flags and show all eligible durations.
- Numeric slider values also have edit boxes for exact manual entry.
- Group pages include a `Font Size` setting for bar name, duration, and count text.
- The BUFFS page includes a `Whitelist / Blacklist` button; D/E do not. BUFFS current rows come from current readable managed HELPFUL ownership.
- Filter row checkbox hitboxes are intentionally small; the icon and text are display-only beside the checkbox.
- The filter frame is taller and uses a lightweight scrollbar under `Current group auras` for groups with many known spell rows.
- No legacy runtime cache remains. BUFFS current convenience rows come from current readable managed HELPFUL ownership and disappear when the active readable aura disappears; unsupported group current-row requests return no compatibility-cache rows. Stored D/E filter tables remain preserved as compatibility/history data.
- Per-group filters are stored in `OdysseusBuffBarsDB` under each group as `filters.whitelist` and `filters.blacklist`.
- BUFF managed filter matching is spellID-first: an active whitelist suppresses its blacklist; otherwise the blacklist rejects matching BUFF-owned IDs. Historical filter SavedVariables remain preserved without a legacy runtime matcher.
- Manual spellID entries are still supported and persist when the aura is not currently active; they can be changed or removed through manual entry even when no managed current-aura row is present.
- Filter config changes are out-of-combat only; `/obb refresh` can still be used in combat.
- Configuration opening, controls, anchor dragging, and config frame drag/resize are locked during combat; attempts print a chat warning.
- Combat warning chat text is formatted as `OdysseusBuffBars: WARNING:` with `WARNING:` in red.
- If the configuration frame is open when combat starts, it is hidden and restored after combat ends.
- The configuration frame intentionally does not use profiles.
- Managed AuraButtons own native supported tooltip and right-click cancellation behavior. Managed DEBUFFS is non-cancellable; the ordinary Fishing Lure footer has no cancellation path.
- The retired legacy secure overlay, synthetic weapon-enchant bar, tooltip, and ordinary-bar anchoring implementation is no longer loaded or present. Do not replace it; managed cancellation remains Blizzard/native.

## Phase Notes
- The MANAGED-only authority cutover is complete. Normal production validation passed fresh login, `/reload`, B/D/E presentation, many World Quests and Delves, heavy simultaneous aura populations, correct routing, and absence of duplicate legacy presentation or observed OBB Lua errors. An unrelated XML/Lua error was traced to CraftSim.
- Post-cutover cleanup Phase 1 is complete: the show-legacy/comparison Config UI and its SCREEN offset/save compensation are removed, while the defaulted fields remain dormant. The historical LEGACY/STAGED validation remains documentation history, not a current runtime path. The D/E SCREEN startup-normalization correction is also runtime validated.
- Post-cutover cleanup Phase 2 is complete: raw SavedVariables remain history/Config authority; one copied runtime-only effective state interprets unsupported historical duration/topology for MANAGED without persistence; Config exposes only supported duration/topology; synthetic placement cannot be persisted by dragging; and legacy cycle fallback is non-mutating. Historical compatibility injection paths are source/static validated but not deliberately runtime injected.
- Managed capability/readiness and partial-initialization hardening is complete. Historical pre-retirement diagnostics covered CAPABILITY, AFTER_DEBUFF_CONSTRUCTION, and INITIAL_E_DESCRIPTOR containment. After authority retirement, a temporary CAPABILITY injection specifically validated the final fail-closed contract: exactly one ERROR, MANAGED compatibility façade, retained FAILED reason, no managed or legacy aura UI, Config availability, and no observed OBB Lua errors. All temporary code was removed and the exact production blobs were restored before the final clean `/reload`.
- Fishing Lure formatter extraction is complete and runtime validated for fresh login, normal managed presentation, an approximately 10-minute countdown, fishing-pole removal, and restoration without duplicate/stale presentation or an observed Lua error. Exact 90-second, 5400-second, and 129600-second boundaries are static-equivalence coverage, not claimed natural runtime tests.
- The Bars/secure-overlay retirement audit, backend deletion, and fresh-`/reload` runtime matrix are complete. MANAGED B/D/E, normal routing/presentation, native cancellation, placement, and refresh remained functional; `OdysseusBuffBars.Bars` was nil; and no duplicate, Lua error, taint, blocked action, or restricted-layout error was observed.
- The read-only Auras/Engine retirement audit proved there was no production caller, required load-time action, Config dependency, or migration requirement. The Auras file and TOC entry were removed without changing Core, Config, ManagedPrototype, SavedVariables, schema, version, or build metadata. At that historical checkpoint, fresh-`/reload` validation passed normal MANAGED B/D/E presentation, `OdysseusBuffBars.Engine` was nil, `OBB.auraData` remained an empty table, and `OBB.filterAuraRows` remained nil.
- The subsequent Core/bootstrap and Config cache cleanup removed `OBB.groups`, `OBB.bars`, `OBB.auraData`, `CanDisplayFilterText`, and the guarded `filterAuraRows`/`auraData` current-row fallback without changing SavedVariables or managed filtering. Focused runtime validation after `/reload` confirmed `groups`, `bars`, `auraData`, and `filterAuraRows` were all nil; no regression was reported. The immutable renderer-authority Config façade is the next separate cleanup checkpoint.
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
  - `D:\WowDEV\Reference\Blizzard\wow-ui-source\` is the current Retail 12.1 Live Blizzard UI source mirror. Use it as the primary source reference for current Retail behavior and to verify APIs, templates, mixins, layout, secure execution, and lifecycle behavior; do not store project-owned analysis there.
  - `D:\WowDEV\Reference\Blizzard\wow-ui-source-ptr\` is the PTR Blizzard UI source mirror. Use it only for future/unreleased PTR change monitoring and regression checks.
  - `D:\WowDEV\Projects\BlizzardResearch\12.1.0\Analysis\` is the authoritative project-owned research location. Preserve verified findings, historical notes, citations, inferences, and runtime-test requirements there rather than recreating them in the addon or source mirrors.
  - `D:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\AddOns\OdysseusBuffBars\` is the active addon working copy for Retail 12.1 Live development and runtime validation. `ManagedPrototype` remains only as an internal historical name pending a dedicated rename phase.
  - The former PTR addon copy is frozen historical/validation reference material and must not be edited during normal development.
- Required workflow:
  - Inspect current Retail Live Blizzard source -> update or consult the authoritative Analysis document -> derive an implementation plan -> modify the active Retail addon copy -> validate on Retail Live, including combat -> synchronize addon documentation.
  - Use PTR source only when monitoring future/unreleased changes or comparing against historical PTR findings.
  - Research must precede implementation whenever Blizzard architecture or secure behavior is uncertain.
  - Record the exact build, interface, branch, and source revision when available. Cite exact Blizzard files, mixins, functions, and line ranges in the research document.
  - Label verified source facts, inferences, and runtime-test requirements distinctly. Never invent Blizzard APIs or behavior, and preserve historical findings when Blizzard renames or restructures a system.
- Verified Live audit snapshot: Retail `12.1.0.69273`, interface `120100`, Live source revision `eb941aad0`, final PTR revision `6e348870e`, BlizzardResearch commit `a07fb6de71e915416fe379af9e92565ef7e1df9b`. The audit confirmed no material Live-only AuraContainer architecture changes from the final PTR findings.
- Historical PTR evidence snapshot: PTR build `12.1.0.68914`, interface `120100`, branch `ptr`, commit `d3915c78aba77a7a9be76acbfa35c674bbb6abe9`. Preserve this as historical validation context, not as the primary current-behavior reference.
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
- Blizzard BuffFrame/Edit Mode ownership conclusion:
  - The completed Retail 12.1 Live audit verified that Blizzard owns `BuffFrame` visibility through Edit Mode.
  - Combat transitions trigger `PLAYER_IN_COMBAT_CHANGED` -> `UpdateShownState()` -> `SetShown(policy)`, so direct addon `BuffFrame:Hide()` calls can be overwritten by Blizzard on combat transitions.
  - The supported user-facing solution is the Edit Mode Aura Frame visibility setting `Hidden`.
  - Do not invent or recommend an addon API for changing another Edit Mode system's visibility.
- Phase B.2 architectural direction and validated managed-placement constraints:
  - Retain an independent position/root frame and anchor the self-sizing managed container below or within it without circular size dependencies. Let the managed container own its calculated size.
  - Apply managed placement only by reanchoring ordinary addon-owned hosts; never externally reanchor or reparent the self-sizing `AuraContainer`.
  - Supported managed placement keeps BUFFS as a SCREEN root; DEBUFFS may be SCREEN, BELOW, RIGHT, or LEFT of BUFFS, and ENCHANTMENTS may be SCREEN, BELOW, RIGHT, or LEFT of DEBUFFS. Anchor each supported child host only to the preceding managed container.
  - Lateral placement must not use an empty AuraContainer's physical width. RIGHT uses the prototype-owned applied parent logical width; LEFT uses the prototype-owned applied child logical width. Preserve those widths in applied placement state so live configuration changes reapply without button enumeration, physical width reads, or fake minimum sizing.
  - ABOVE is intentionally unsupported in the managed architecture and retired from current Config choices. Do not implement it by reading dynamic managed height/bottom, polling, private layout hooks, or introducing a second content-height authority; reconsider only with a separately researched and runtime-validated bottom-owned/full-visible-bounds architecture.
  - Consume supported raw placement graphs exactly. For historical unsupported raw topology, build copied runtime-only effective placement: invalid B -> SCREEN using usable saved numeric x/y; invalid D -> BELOW B at 0,-8; invalid E -> BELOW D at 0,-8. Preserve every raw placement/parent/offset value until explicit Config correction; no schema field, automatic migration, or exact historical visual-equivalence claim.
  - Preserve serialized SCREEN roots through the narrow startup normalization: record an explicit raw placement with no raw parent before recursive defaults, then restore the intentional nil parent after defaults. Do not add a persistent discriminator, change generic defaults, or silently repair unsupported topology.
  - Managed dragging moves only ordinary addon-owned hosts. Persist the real shared SCREEN coordinates through the inverse host translation and update copied managed applied placement state; it has no legacy Bars positioning dependency. Refuse drag persistence when the current managed SCREEN placement is a synthetic compatibility fallback.
  - OBB SavedVariables are the sole persistent position authority for managed ordinary hosts. Do not allow WoW user-placed frame persistence to compete with them: make a host movable/resizable before calling `SetUserPlaced(false)`, and clear user-placed ownership again after drag persistence or safe post-combat restoration. Do not repair ownership conflicts with polling or managed-container geometry inspection.
  - The retired `showLegacyBars` and `legacyComparisonMode` SavedVariables remain dormant compatibility/history fields. They no longer have Config controls, affect presentation, or participate in renderer authority.
  - If background or chrome must follow the managed bounds, use a separate ordinary chrome frame and apply `DisableUntrustedLayoutScriptsTemplate` where required by the verified secure-layout design.
  - Do not resize the managed container from a custom `OnSizeChanged`, reparent managed AuraButtons, or mirror managed auras into ordinary bars.
  - Blizzard's secure managed pipeline performs layout during combat, but source inspection did not prove arbitrary addon `SetHeight` calls from a callback combat-safe. Combat-time anchoring, protection state, and chrome propagation require PTR validation; call behavior combat-safe only when supported by verified Blizzard source or completed PTR testing.
- The supported SCREEN/BELOW/RIGHT/LEFT combinations, independent SCREEN-root dragging, SavedVariables-only host position ownership, and managed `anchorsShown` visibility have Retail Live validation for startup/live apply, persistence, reset, lock/combat handling, mixed growth/scale, combat sizing/chaining, the historical comparison workflow, empty managed bounds, and weapon-transition recovery. Phase 1 historically validated LEGACY/STAGED presentation and managed-to-legacy synchronization before those paths were retired; preserve that evidence as chronology, not current behavior.
- D/E startup normalization passed reload tests for D SCREEN, E SCREEN, both SCREEN, D BELOW B, E BELOW D, and Reset Positions. Phase 2 historically validated the constrained Config path and the former MANAGED/LEGACY/STAGED transitions. No explicit LEFT/RIGHT reload test or deliberate historical invalid-state injection is claimed. ABOVE, arbitrary/reverse/cyclic graphs, BUFFS-as-child, and future full-bounds chrome remain unsupported raw states handled only by the runtime compatibility bridge.

## Historical Reference Notes
- The old local `Reference\ElkBuffBars\` tree is no longer present in this repository and must not be assumed available for future work.
- Historical ElkBuffBars-derived findings that still matter are preserved in this AGENTS.md and in committed research/docs.
- Do not load, recreate, or depend on a local reference addon tree during normal Retail Live development.

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

## Historical Legacy Aura Engine Notes
- These notes describe the retired direct-scanning implementation and are retained as historical context, not current Retail 12.1 production architecture.
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
- Managed cancellation remains Blizzard/native; do not reintroduce addon-owned secure cancel buttons.
- Run `luacheck OdysseusBuffBars.lua OdysseusBuffBars_Config.lua` after normal Lua changes. The current baseline after Auras retirement is `93 warnings / 0 errors`.
  - The current baseline has many WoW-global warnings, but should report `0 errors`.
