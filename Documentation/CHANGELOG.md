# Changelog

Historical development prior to the creation of this document is intentionally not reconstructed. Future project changes should be recorded here from this point forward.

## Unreleased

### Added

- Established the initial project documentation structure.
- Added an isolated parallel player-BUFFS `CustomAuraContainer` prototype with container-owned AuraButtons.
- Added managed bar presentation for icon, spell name, application count, duration text, duration StatusBar, timeless auras, native tooltip, and native right-click cancellation.
- Added native Default, Name, and Time Left sorting to the managed prototype.
- Added managed player-BUFFS whitelist/blacklist filtering that reuses the existing SavedVariables fields.
- Added a second isolated managed player-DEBUFFS `CustomAuraContainer` prototype with an independent root and one broad player `HARMFUL` group.
- Added a third isolated managed ENCHANTMENTS container with native MainHand and OffHand item-enchantment registrations.
- Added a long-lived managed ENCHANTMENTS `HelpfulEnhancements` HELPFUL group for semantic Food, Flask/Phial, and Augment Rune routing.
- Added `FISHING_BOBBER` semantic routing through readable spell metadata without bobber spell-ID, item/toy, or duration tables.
- Added an event/API-driven ordinary `Fishing Lure` row for fishing profession-tool temporary enchants, which are outside the managed MainHand/OffHand/Ranged provider surface.

### Changed

- Renamed the addon, manifest, and canonical Lua files from `OdysseusBuffBarsTest` to `OdysseusBuffBars`.
- Adopted `OdysseusBuffBarsDB` as the canonical SavedVariables table.
- At the Phase B.2 checkpoint, changed the managed layout to let `CustomAuraContainer` self-size from displayed AuraButtons; the configured maximum of thirty remained capacity only.
- Synchronized allowed out-of-combat mutations from the existing BUFFS filter editor to the long-lived managed group without polling, a duplicate editor, or an `Apply Filters` button.
- Added temporary Retail 12.1 containment for legacy direct-scanner failures and suppressed the incompatible legacy indexed-aura tooltip path on Retail 12.1+.
- Anchored the managed DEBUFFS host below the dynamically self-sizing BUFFS container with a one-directional eight-pixel gap and removed independent DEBUFFS dragging.
- Anchored managed ENCHANTMENTS below DEBUFFS and added initial-login inventory-burst coalescing with one pending zero-delay generation check and one final quiet-turn refresh.
- Replaced the temporary hardcoded HELPFUL route with session-only discovery from readable active spell metadata and paired ENCHANTMENTS include/BUFFS exclude candidate filters.
- Unified managed BUFFS, DEBUFFS, and ENCHANTMENTS row construction through `InitializeManagedBarPresentation` and group headers through `StyleManagedGroupHeader`.
- Matched all three prototype groups to the accepted legacy static presentation: `260 x 18` rows and headers, three-pixel spacing, full-coordinate icons, legacy text geometry/backdrop, and group-specific colors.
- Fixed fishing-lure tooltip taint by owning `GameTooltip` from `UIParent` at `ANCHOR_CURSOR` instead of the ordinary row whose layout depends on restricted managed bounds.
- Moved idempotent managed prototype initialization into `OBB:OnAddonLoaded()` after SavedVariables adoption, defaults, migrations, group normalization, and `OBB.db` readiness; managed frames and event objects are no longer constructed at Lua file load.
- Added copied startup consumption of existing group name, geometry, spacing, font, complete bar/background colors, icon side, scale, and alpha, plus compatible BUFFS/DEBUFFS sort and maximum-bar settings.
- Bridged the existing out-of-combat `Config:Apply()` path to centralized managed presentation/layout synchronization for font size, complete bar/background colors, width, height, and row spacing without duplicating `syncGroupBars` behavior.
- Silenced routine automatic managed-routing diagnostics by default behind a local debug gate while retaining explicit manual diagnostics and unexpected discovery/filter failure output.
- Added live out-of-combat managed `iconSide` reanchoring for retained and future/reused rows while preserving current height-derived icon space and addon-owned presentation relationships.
- Applied live group alpha and scale to the ordinary BUFFS, DEBUFFS, and ENCHANTMENTS hosts so headers, managed descendants, native item-enchantment rows, and the Fishing Lure hierarchy inherit the configured state without rewriting logical dimensions.
- Connected BUFFS/DEBUFFS saved sort and `maxBars` to the public managed setters; prototype sort buttons remain temporary overrides and later config apply reasserts the saved mode.
- Added BUFFS/DEBUFFS `growUp` through supported FlowLayout anchor/growth settings while keeping the external header and inter-group chain topology fixed.
- Adopted the managed ENCHANTMENTS 7+2+1 capacity policy and changed native item-enchantment placement/sorting to AfterAuraGroups with Slot/Normal order; legacy ENCHANTMENTS global sort and `maxBars` remain intentionally ignored.
- Replaced initial-login-only native enchant recovery with a bounded every-world-transition quiet-turn recovery protected by epochs/generations and able to complete once after combat.
- Removed temporary transition trace instrumentation after diagnosis; no trace command or routine diagnostic chat output remains.
- Extended the shared managed growth-state/helper path to ENCHANTMENTS while keeping its global sort and `maxBars` semantics intentionally separate.
- Added startup and live out-of-combat managed placement synchronization for saved BUFFS `SCREEN` coordinates and the exact default `BUFFS SCREEN -> DEBUFFS BELOW BUFFS -> ENCHANTMENTS BELOW DEBUFFS` graph. Only ordinary hosts move; managed containers retain Blizzard-owned sizing and anchors.
- Changed `Reset Positions` to finish through the existing single `Config:Apply()` bridge after preserving the same SavedVariables reset values.
- Expanded the supported managed placement set to BUFFS SCREEN, DEBUFFS SCREEN or BELOW BUFFS, and ENCHANTMENTS SCREEN or BELOW DEBUFFS. DEBUFFS/ENCHANTMENTS restricted hosts can switch live out of combat between their supported SCREEN and BELOW states.
- Added independent managed SCREEN-root dragging with inverse-translation persistence, legacy position synchronization, anchored-group refusal, lock/combat guards, and post-combat restoration of interrupted movement without a general placement retry queue.
- Added development-only legacy presentation controls. `showLegacyBars` hides presentation without disabling the legacy backend; `legacyComparisonMode` forces legacy visible and offsets each effective SCREEN root by group width plus 24 UI units without changing shared placement.
- Extended `anchorsShown` to the three managed addon-owned header Buttons through one narrow notification from the existing toggle path. Header hiding is visibility-only and remains independent from lock, legacy visibility/comparison, host placement, reserved geometry, aura rows, and managed containers.
- Established OBB SavedVariables as the sole persistent authority for named managed hosts. Hosts become movable before user-placed ownership is cleared, and drag-stop/safe restoration clear it again without changing coordinate formulas, adding scale compensation, polling, container inspection, or a general retry queue.
- Added RIGHT placement for DEBUFFS relative to BUFFS and ENCHANTMENTS relative to DEBUFFS using applied parent logical width. This avoids dependence on the approximately `1 x 1` physical width of an empty managed container and re-applies placement when the parent logical width changes.
- Added LEFT placement for the same supported chain using applied child logical width, keeping the child's logical right edge fixed across empty state and live child-width changes without physical width reads, AuraButton enumeration, or manual sizing.
- Recorded the source-backed ABOVE decision: it is intentionally unsupported in the managed architecture and planned for retirement with the legacy renderer; existing saved ABOVE values require explicit, non-silent cutover handling later.
- Replaced independent routing/filter refreshes with one authoritative managed HELPFUL compiler that resolves semantic routes, existing hidden/group overrides, destination filters, and BUFF duration state into complete BUFFS and `HelpfulEnhancements` descriptors, applies both, and snapshots only successful complete state.
- Corrected destination-filter precedence so ownership resolves before filtering. BUFF or ENCHANTMENTS whitelist membership cannot pull an aura across routes; hidden, explicit group override, semantic route, default BUFFS, then destination filtering is the fixed order.
- Connected ENCHANTMENTS whitelist/blacklist to `HelpfulEnhancements` only. Native MainHand/OffHand and Fishing Lure remain intentionally unfiltered by those spell-ID maps under the unchanged 7+2+1 source policy.
- Added managed BUFF ALL/TIMED_ONLY duration admission using omitted `maxDuration` or `math.huge` without addon-side duration reads; unsupported TIMELESS_ONLY/NONE preserve SavedVariables and retain the last supported managed state.
- Adopted deliberate ALL-duration policy for managed DEBUFFS and ENCHANTMENTS, removed their duration checkboxes, and removed duration flags from `Sync Group Bars` fan-out while preserving stored values and schema.
- Replaced BUFFS/ENCHANTMENTS `Current group auras` historical legacy ownership with a runtime-only snapshot of active readable player HELPFUL numeric spell IDs resolved through the same ownership precedence as candidate compilation.
- Added copied, spell-ID-sorted B/E current rows, immediate open-editor refresh after override Save/Delete, and current-aura removal without persistent whitelist/blacklist mutation. Destination filters remain visibility-only for ownership purposes.
- Kept DEBUFFS current population legacy-backed and excluded native MainHand/OffHand plus Fishing Lure from the ENCHANTMENTS HELPFUL ownership list.

### Compatibility

- Existing `OdysseusBuffBarsTestDB` settings are adopted only when `OdysseusBuffBarsDB` is absent; the legacy table is not merged or deleted.
- Retained `/obbtest` as a compatibility alias alongside `/obb` and `/buffbars`.

### PTR validation

- Validated the parallel managed player-BUFFS architecture and AuraButton presentation on the Retail 12.1 PTR.
- Validated dynamic grow/shrink, more than ten displayed buffs, thirty-frame capacity, near-empty collapse, combat updates, drag locking, reload behavior, timed and timeless auras, and application counts.
- Validated native tooltip and right-click cancellation during combat.
- Validated native Default, Name, and Time Left sorting, including legacy-compatible timeless-first and longest-to-shortest Time Left ordering.
- Validated whitelist/blacklist semantics, whitelist precedence, and automatic synchronization with the existing filter editor.
- Observed no Lua errors, taint, or blocked actions during the managed player-BUFFS validation.
- Managed DEBUFFS/ENCHANTMENTS production integration, final configuration parity, Blizzard BuffFrame visibility, and production cutover remain incomplete.

### Live validation

- Validated core managed player-DEBUFFS behavior on Retail Live `12.1.0.69273`, interface `120100`.
- Validated multiple simultaneous harmful auras, combat additions/refreshes/removals, icons, names, application counts, duration text and StatusBars, and dynamic grow/shrink.
- Validated Default (`Default`/`Normal`), Name (`NameOnly`/`Normal`), and Time Left (`ExpirationOnly`/`Reverse`) sorting without reinterpreting Blizzard's default ordering.
- Validated the native managed DEBUFF tooltip in combat without a custom indexed-aura lookup or fallback.
- Validated dynamic BUFFS-to-DEBUFFS anchoring, combat layout propagation, independent DEBUFFS grow/shrink, and the absence of observed anchor-loop errors.
- Confirmed the isolated managed BUFFS and DEBUFFS prototypes operate simultaneously without observed Lua errors, taint, or blocked actions attributable to OdysseusBuffBars.
- Preserved targeted validation as pending for a known real private harmful aura, explicit secrecy/restriction classification if useful, and focused `NeverSecret` behavior if later required.
- Kept the legacy DEBUFFS backend authoritative for production. The managed prototype remains broad and intentionally does not connect legacy spell-ID filters or register right-click cancellation.
- Validated the managed MainHand Thalassian Phoenix Oil lifecycle across two genuine cold logins, `/reload`, fresh reapplication, native inventory tooltip, and right-click cancellation in the tested non-combat context.
- Validated that quiet-turn coalescing repairs cold-login startup without a fixed callback count, positive delay, polling, PaperDoll inspection, per-event full refresh, or synthetic fallback. Diagnostic readiness ordinals 69, 105, and 430 remain evidence only.
- Observed no OBB-attributable Lua error, taint, or blocked action during the validated MainHand lifecycle tests.
- Validated semantic Food, Flask/Phial, and Augment Rune classification and dynamic de-duplicated routing across initial population, unchanged rediscovery, grow/shrink, empty-set clearing, and repopulation, including cross-character spell-ID variants.
- Validated automatic out-of-combat event-driven discovery, redundant-event suppression, combat deferral, and `PLAYER_REGEN_ENABLED` retry without polling, continuous `OnUpdate`, hardcoded routing IDs, item-ID assumptions, duration classification, SavedVariables, or persisted discovery.
- Validated Limited Edition Rocket Bobber spell ID `1222880` as an ordinary HELPFUL aura routed to ENCHANTMENTS through `FISHING_BOBBER`, including unchanged-set synchronization.
- Validated Bright Baubles fishing-lure detection through the dynamically resolved profession-tool slot, visible countdown, natural expiration and scheduled API recheck, row hiding, and reapplication without presence polling.
- Validated the fishing-tool inventory tooltip after the restricted-layout ownership fix; it exposes a generic lure effect rather than the original lure item name.
- Confirmed native weapon-enchant right-click cancellation remains available while the ordinary fishing-lure row intentionally performs no cancellation action.
- Runtime-validated Phase A.1 startup/reload configuration consumption and the Phase C.1 live out-of-combat font/color/width/height/spacing slice across existing and newly assigned/created/reused rows, headers, `Sync Group Bars`, and width/height/spacing change ordering.
- Runtime-validated square icon resizing, `height + iconGap` boundaries for LEFT and RIGHT startup icon sides, public AuraGroup/item-enchantment layout replacement, fishing-lure spacing, group chaining, and combat regression without manual container sizing or managed-child enumeration.
- Runtime-validated routine diagnostic silence for normal aura/rune gain and removal while preserving semantic routing and explicit manual diagnostic output.
- Runtime-validated live LEFT/RIGHT icon changes, host alpha/scale, BUFFS/DEBUFFS saved sorting and maximum counts, mixed-scale chaining, and BUFFS growth direction; DEBUFFS growth uses the same supported implementation without an equivalent direct test claim.
- Runtime-validated MainHand native-row recovery after portal, Home teleport, Hearthstone, dungeon, Delve/no-loading-screen, and legitimate no-enchant transitions, followed by fresh enchant application, without manual refresh, Lua errors, or trace spam.
- Runtime-validated ENCHANTMENTS DOWN/UP switching, reload persistence, mixed-source presentation, geometry/icon changes while UP, loading and no-enchant transitions, unchanged native recovery without growth reset, and combat behavior; the Fishing Lure remained a fixed footer outside FlowLayout.
- Runtime-validated saved BUFFS screen placement, DEBUFFS/ENCHANTMENTS BELOW offsets, reset, repeated apply, mixed growth/scale, empty managed bounds, combat sizing/chaining, and native weapon-transition recovery without container reanchoring, manual sizing, or placement retry.
- Runtime-validated supported B/D/E SCREEN and BELOW combinations, live SCREEN/BELOW switching, independent SCREEN-root dragging/persistence, anchored-child following and movement refusal, reset/reload, lock/combat behavior, legacy synchronization, and comparison-mode interaction.
- Runtime-validated managed anchor visibility and the stale-login ownership repair across two full exit/login cycles: BUFFS, DEBUFFS, and ENCHANTMENTS each reported `userPlaced=false`, and dragging BUFFS immediately carried the saved DEBUFFS/ENCHANTMENTS BELOW chain without dropdown cycling.
- Runtime-validated RIGHT and LEFT across empty/non-empty containers, live parent/child width changes, offsets, SCREEN/BELOW/RIGHT/LEFT switching, mixed growth/scale, dragging/following/refusal, reset, comparison/header modes, combat, and native enchant/lure transitions within the supported chain.
- Runtime-validated managed-only, synchronized overlapping, and side-by-side legacy comparison presentation, including both development options enabled, mixed root/dependent topology, dragging without persistent drift, secure-overlay/tooltip cleanup, and refresh/configuration behavior.
- Kept arbitrary graph/cycle parity, BUFFS-as-child, future full ENCHANTMENTS bounds, ABOVE cutover handling, DEBUFF/native-item filter policy, final behavior/filter audit, legacy-only ENCHANTMENTS control cleanup, direct OffHand/both-slot coverage, production cutover, rollback policy, and eventual comparison/legacy cleanup pending.
- Runtime-validated centralized HELPFUL composition across routed Rune plus BUFF blacklist/whitelist edits, whitelist clearing, empty/repopulated routing, reload, combat, and loading behavior.
- Runtime-validated hidden and BUFFS/ENCHANTMENTS group overrides, deletion restoring semantic/default ownership, destination-filter combinations, and the correction preventing either destination whitelist from becoming a routing source.
- Runtime-validated BUFF ALL/TIMED_ONLY switching and reload persistence, composition with filters/overrides, D/E ALL-duration decisions, duration removal from `Sync Group Bars`, and the D/E page cleanup without reported backend regressions.
- Runtime-validated natural B/E ownership, semantic Rune ownership, both override directions and deletion restoration, hidden exclusion, whitelist/blacklist ownership independence, active-aura removal with persistent filter retention, reload reconstruction, and unchanged legacy-backed DEBUFF editor behavior without a reported Lua/runtime problem.
