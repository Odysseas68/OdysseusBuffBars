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
- Changed the managed layout to let `CustomAuraContainer` self-size from displayed AuraButtons; the configured maximum of thirty remains capacity only.
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
- Bridged the existing out-of-combat `Config:Apply()` path to centralized managed presentation synchronization for font size and complete bar/background colors without duplicating `syncGroupBars` behavior.

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
- Runtime-validated Phase A.1 startup/reload configuration consumption and the narrow Phase C.1 live out-of-combat font/color slice, including existing and newly assigned/created/reused managed rows, with native interaction and combat behavior retained in the supplied test scope.
- Kept live geometry/layout synchronization, exact ENCHANTMENTS combined sort/cap semantics, broader native enchant/effect coverage, persistence, production cutover, rollback policy, and eventual legacy cleanup pending.
