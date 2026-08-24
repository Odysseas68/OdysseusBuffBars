# OdysseusBuffBars

## Project overview

OdysseusBuffBars is a standalone World of Warcraft Retail addon and research implementation for aura presentation, interaction, and combat-sensitive behavior. It is separate from the production Odysseus Utility Suite addon.

The legacy implementation uses direct `C_UnitAuras` scanning, addon-owned aura records, ordinary custom bars, and separate secure cancellation overlays. It now remains only as rollback/development infrastructure. Renderer authority is runtime-only and mode-level: supported startup enters `MANAGED` for BUFFS, DEBUFFS, and ENCHANTMENTS together after non-destructive preflight; unsupported configuration remains safely `STAGED` without rewriting SavedVariables.

The production player-BUFFS implementation uses `CustomAuraContainer` with container-owned AuraButtons. Its managed lifecycle and presentation, dynamic self-sizing, native sorting, whitelist/blacklist filtering, automatic synchronization with the existing filter editor, native tooltip and right-click cancellation, combat updates, reload behavior, timeless auras, and application counts have passed the recorded PTR and production-cutover validation.

The managed player-DEBUFFS `CustomAuraContainer`, using `unit="player"` and one broad `HARMFUL` group, is now the default production authority for DEBUFFS. Its validated lifecycle covers initial login/reload, multiple debuffs and combat churn, the five managed presentation bindings, Default/Name/Time Left sorting, maximum count, native combat tooltips, SCREEN dragging and persistence, BELOW/RIGHT/LEFT placement relative to managed BUFFS, anchor visibility, reset, loading transitions, comparison isolation, rollback in both directions, and reload-after-rollback. No addon-attributable Lua errors, taint, or blocked actions were reported in the supplied tests. A known real private harmful aura and optional explicit secrecy/`NeverSecret` tests remain pending and are not claimed by this checkpoint.

Production ENCHANTMENTS combines a seven-row managed `HelpfulEnhancements` HELPFUL group, MainHand/OffHand native item-enchantment providers, and one ordinary addon-owned fishing profession-tool lure footer: the fixed 7+2+1 policy. Fishing Bobber consumes one of the seven HELPFUL slots; Fishing Lure is the separate footer. Native rows are placed after aura groups and ordered Slot/Normal. A real MainHand weapon oil passed `/reload`, loading/portal recovery, Fishing Lure coexistence, UP growth, correct duration, native weapon tooltip, and non-combat right-click cancellation without a manual diagnostic refresh. OffHand shares the same source-validated registration/recovery path, but no suitable active OffHand enchant was available, so direct OffHand and simultaneous-slot testing remain opportunistic coverage rather than a known implementation gap. The lure row is not a managed AuraButton and still does not support cancellation.

The public temporary-enchantment surface supplies slot, enchant ID, timing/expiration, charges, native row identity, cancellation slot, and equipped-item tooltip context, but no clean supported enchant-effect name. The addon therefore does not scrape tooltips, inspect private provider state, enumerate AuraButtons, or maintain hardcoded enchant-name data.

All three groups pass visual comparison against the legacy renderer, but managed destination filtering is deliberately group-specific. BUFFS retains whitelist/blacklist, current effective-ownership rows, manual Spell ID entry, route-before-filter precedence, shared HELPFUL overrides, and ALL/TIMED_ONLY behavior. DEBUFFS is intentionally broad/unfiltered. ENCHANTMENTS is intentionally broad/source-owned: every effectively E-routed `HelpfulEnhancements` ID is eligible, and native MainHand/OffHand plus Fishing Lure remain separate unaffected sources. D/E destination-filter parity is a closed product decision rather than pending work.

The earlier transient observation of ordinary `classification=nil` HELPFUL auras briefly appearing in ENCHANTMENTS is now classified as historical and unreproduced on the current architecture. Focused Retail diagnostics covered ordinary and semantic aura churn, overrides and BUFF filters, combat deferral and `PLAYER_REGEN_ENABLED` recovery, semantic-set removal/repopulation including an empty set, complete descriptor equality/application, and portal/loading reconstruction. Current semantic membership, effective ownership, desired descriptors, and applied descriptors remained consistent, with no incorrect visible placement. The original cause was not identified and the result does not prove the old observation impossible, but it is no longer a known production-cutover blocker.

Saved SCREEN coordinates continue to describe the logical stack top-left. Every supported managed SCREEN root translates them as `hostX = savedX - 4` and `hostY = savedY + 22`. BELOW uses `hostOffsetX = savedOffsetX - 4` and unchanged `hostOffsetY` against the supported parent managed container; neither path uses scale compensation. Every effective SCREEN root is independently draggable while out of combat and unlocked. Drag-stop applies the inverse host translation to the real shared coordinates, records them in OBB SavedVariables, clears WoW user-placed ownership, then synchronizes legacy positioning. Hosts are made movable before startup clears that ownership; safe post-combat restoration clears it again. This keeps OBB SavedVariables authoritative and prevents stale cached screen anchors from replacing saved BELOW dependencies on login. Anchored groups refuse direct movement and tell the user to move the parent or select Screen. If combat interrupts an active managed drag, movement stops without persisting the interrupted location and the prior applied position is restored after combat; no general retry queue was added. `Reset Positions` continues to use real shared coordinates and the existing `Config:Apply()` path. A managed empty container may collapse to `1 x 1`; chained groups follow that real bound rather than a fabricated legacy minimum. The ordinary Fishing Lure footer remains outside the ENCHANTMENTS container, which is terminal in the supported graph.

RIGHT uses the current applied parent logical width: `parentWidth + offsetX - 4`, with vertical placement `offsetY + 22`. LEFT uses the current applied child logical width: `offsetX - 4 - childWidth`, also with `offsetY + 22`. These formulas remain stable across empty containers and live width changes without `GetWidth()`, AuraButton enumeration, or manual sizing. Runtime validation covers empty/non-empty states, offsets, live width/mode changes, mixed growth/scale, parent dragging, reset, comparison/header modes, combat, and native enchant/lure transitions within the supported chain.

ABOVE is intentionally unsupported in the managed architecture and planned for retirement with the legacy renderer. It requires the child's dynamic bottom/full visible height, but no safe public callback or content-height contract exists for the Blizzard-owned self-sizing container, and Fishing Lure sits outside ENCHANTMENTS container bounds. Existing `ABOVE` SavedVariables must not be silently remapped; explicit user-facing cutover handling remains future work.

`anchorsShown` controls the addon-owned headers in both renderers. Hiding managed headers is visibility-only: hosts, containers, reserved header geometry, SCREEN/BELOW/RIGHT/LEFT topology, saved coordinates, growth, scale, aura bars, and Fishing Lure remain unchanged. Hidden headers provide no drag input; showing them restores the existing SCREEN-root drag behavior. `locked` remains independent.

Two temporary development settings retain rollback comparison support. `Show Legacy BuffBars (Development)` (`showLegacyBars`, default `true`) controls only addon-owned presentation for groups whose current mode permits legacy authority. `Legacy Comparison Mode (Development)` (`legacyComparisonMode`, default `false`) applies the existing presentation-only SCREEN-root offset where eligible, but is disabled in MANAGED and cannot resurrect any managed-authoritative legacy group. These settings remain temporary infrastructure, not renderer authority.

The DEBUFFS/ENCHANTMENTS group pages share their construction path with BUFFS but omit the BUFF-only filter controls. Their Icon dropdown now anchors below Sort with the normal vertical gap, preventing its previous overlap with Offset Y. BUFFS retains its already-correct side-by-side Sort/Icon placement; control ordering, widths, behavior, and SavedVariables are unchanged.

ENCHANTMENTS uses TOPLEFT/Right+Down or BOTTOMLEFT/Right+Up managed FlowLayout. In UP mode Blizzard reverses spatial progression while preserving the logical source sequence: native rows move toward the header and `HelpfulEnhancements` occupies the lower managed portion. The ordinary Fishing Lure remains outside FlowLayout as a fixed footer below the container in both directions.

Every `PLAYER_ENTERING_WORLD` arms a bounded native-enchantment recovery. Player inventory activity is coalesced to one quiet-turn container refresh, stale callbacks are rejected by epoch/generation state, and a completion reached during combat may run once after `PLAYER_REGEN_ENABLED`. This repaired the reproduced transition disappearance across tested portals, Home teleport, Hearthstone, dungeon entry/exit, Delve/no-loading-screen behavior, no-enchant transitions, and fresh reapplication without polling or reconstructing Blizzard-owned native state. Runtime testing with ENCHANTMENTS configured UP confirmed that recovery remains functional and does not reset growth direction.

Routine automatic managed-routing diagnostics are silent by default. Explicit manual diagnostic helpers and unexpected discovery/filter failures remain available. Blizzard still owns managed aura identity, duration presentation, tooltips, sorting, supported cancellation, and self-sizing; the ordinary `Fishing Lure` row remains a narrow addon-owned exception and still does not support cancellation.

Only BUFFS exposes the managed Whitelist/Blacklist editor. Its `Current group auras` represents current active readable BUFF-owned HELPFUL IDs, while manual/saved entries remain available independently. D/E pages expose neither Whitelist/Blacklist nor Timed/Timeless; Grow Up follows Max Bars directly. Existing D/E filter data is not deleted, normalized, migrated, or cleared: legacy D/E may consume it during comparison, while managed D/E intentionally ignores it. Shared HELPFUL hidden/group overrides remain supported ownership policy and are not ENCHANTMENTS destination filters.

## Project boundaries

- Keep the addon small and focused on Retail aura research.
- Preserve verified behavior and distinguish PTR evidence from shipped Live behavior.
- Do not treat the legacy scanner's Retail 12.1 limitations as managed-frame failures.
- Treat the all-managed authority cutover as complete while keeping legacy retirement, file cleanup, and release metadata as separate work.
- Do not add Classic support or unrelated addon systems.

## Repository layout

- `OdysseusBuffBars.toc` — addon manifest and load order.
- `OdysseusBuffBars.lua` — bootstrap, settings, events, and refresh coordination.
- `OdysseusBuffBars_Auras.lua` — legacy direct-scanning compatibility implementation.
- `OdysseusBuffBars_Bars.lua` — legacy ordinary-bar rendering and interaction.
- `OdysseusBuffBars_Config.lua` — native configuration interface and existing filter editor.
- `OdysseusBuffBars_ManagedPrototype.lua` — production-critical managed BUFFS, DEBUFFS, and ENCHANTMENTS architecture, shared static presentation, semantic HELPFUL routing, native weapon enchantments, and the fishing-lure exception. Its historical filename may be evaluated during cleanup; this checkpoint does not rename or split it.
- `Reference/` — frozen local reference material; it is not loaded by the addon.
- `Documentation/` — project overview, architecture, roadmap, migration history, and changelog.

## Reference material

Authoritative Retail 12.1 research is maintained separately under:

`D:\WowDEV\Projects\BlizzardResearch\12.1.0\Analysis\`

The local Blizzard source reference is:

`D:\WowDEV\Reference\Blizzard\wow-ui-source\`

These locations are read-only reference material for addon work.
