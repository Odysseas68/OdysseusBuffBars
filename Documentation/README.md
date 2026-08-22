# OdysseusBuffBars

## Project overview

OdysseusBuffBars is a standalone World of Warcraft Retail addon and research implementation for aura presentation, interaction, and combat-sensitive behavior. It is separate from the production Odysseus Utility Suite addon.

The legacy implementation uses direct `C_UnitAuras` scanning, addon-owned aura records, ordinary custom bars, and separate secure cancellation overlays. It remains temporarily available for comparison and compatibility during migration, but its direct scanner is not a reliable Retail 12.1 combat backend.

A parallel player-BUFFS implementation now uses `CustomAuraContainer` with container-owned AuraButtons. On the Retail 12.1 PTR, it has passed validation for the managed lifecycle and presentation, dynamic self-sizing, native sorting, whitelist/blacklist filtering, automatic synchronization with the existing filter editor, native tooltip and right-click cancellation, combat updates, reload behavior, timeless auras, and application counts. No Lua errors, taint, or blocked actions were observed during these tests.

A second isolated managed player-DEBUFFS prototype uses its own `CustomAuraContainer`, `unit="player"`, and one broad `HARMFUL` group. Core runtime behavior is validated on Retail Live `12.1.0.69273`: multiple debuffs, combat additions/refreshes/removals, the five managed presentation bindings, Default/Name/Time Left sorting, native combat tooltips, dynamic grow/shrink, and simultaneous managed BUFFS/DEBUFFS operation worked without observed addon-attributable Lua errors, taint, or blocked actions. Its ordinary host follows the dynamically self-sizing BUFFS container through a one-directional eight-pixel-gap anchor, and combat-driven BUFFS size changes propagate correctly. A known real private harmful aura and optional explicit secrecy/`NeverSecret` tests remain pending.

A third isolated ENCHANTMENTS prototype combines a seven-row managed `HelpfulEnhancements` HELPFUL group, MainHand/OffHand native item-enchantment providers, and one ordinary addon-owned fishing profession-tool lure footer: a theoretical 7+2+1 maximum. Fishing Bobber consumes one of the seven HELPFUL slots; Fishing Lure is the separate footer. Native rows are placed after aura groups and ordered Slot/Normal. MainHand lifecycle, semantic routing, lure behavior, and bounded native-row recovery after loading/world transitions are runtime validated. The lure row is not a managed AuraButton and still does not support cancellation.

All three groups pass visual comparison against the legacy renderer. The out-of-combat config bridge now live-synchronizes font/color/geometry, LEFT/RIGHT icon placement, ordinary-host scale/alpha, and saved growth direction. BUFFS and ENCHANTMENTS growth are directly runtime validated; DEBUFFS uses the same supported FlowLayout path without equivalent direct real-HARMFUL coverage. BUFFS and DEBUFFS additionally consume live saved sort and `maxBars`; prototype sort buttons remain temporary overrides until a later config apply reasserts saved sort. ENCHANTMENTS intentionally ignores legacy global sort/`maxBars`; placement/position parity, remaining behavior/filter settings, persistence, and production cutover remain in progress.

ENCHANTMENTS uses TOPLEFT/Right+Down or BOTTOMLEFT/Right+Up managed FlowLayout. In UP mode Blizzard reverses spatial progression while preserving the logical source sequence: native rows move toward the header and `HelpfulEnhancements` occupies the lower managed portion. The ordinary Fishing Lure remains outside FlowLayout as a fixed footer below the container in both directions.

Every `PLAYER_ENTERING_WORLD` arms a bounded native-enchantment recovery. Player inventory activity is coalesced to one quiet-turn container refresh, stale callbacks are rejected by epoch/generation state, and a completion reached during combat may run once after `PLAYER_REGEN_ENABLED`. This repaired the reproduced transition disappearance across tested portals, Home teleport, Hearthstone, dungeon entry/exit, Delve/no-loading-screen behavior, no-enchant transitions, and fresh reapplication without polling or reconstructing Blizzard-owned native state. Runtime testing with ENCHANTMENTS configured UP confirmed that recovery remains functional and does not reset growth direction.

Routine automatic managed-routing diagnostics are silent by default. Explicit manual diagnostic helpers and unexpected discovery/filter failures remain available. Blizzard still owns managed aura identity, duration presentation, tooltips, sorting, supported cancellation, and self-sizing; the ordinary `Fishing Lure` row remains a narrow addon-owned exception and still does not support cancellation.

## Project boundaries

- Keep the addon small and focused on Retail aura research.
- Preserve verified behavior and distinguish PTR evidence from shipped Live behavior.
- Do not treat the legacy scanner's Retail 12.1 limitations as managed-frame failures.
- Do not treat the managed player-BUFFS milestone as completion of the overall 12.1 migration.
- Do not add Classic support or unrelated addon systems.

## Repository layout

- `OdysseusBuffBars.toc` — addon manifest and load order.
- `OdysseusBuffBars.lua` — bootstrap, settings, events, and refresh coordination.
- `OdysseusBuffBars_Auras.lua` — legacy direct-scanning compatibility implementation.
- `OdysseusBuffBars_Bars.lua` — legacy ordinary-bar rendering and interaction.
- `OdysseusBuffBars_Config.lua` — native configuration interface and existing filter editor.
- `OdysseusBuffBars_ManagedPrototype.lua` — parallel BUFFS, DEBUFFS, and ENCHANTMENTS prototypes, shared static presentation, semantic HELPFUL routing, native weapon enchantments, and the fishing-lure exception.
- `Reference/` — frozen local reference material; it is not loaded by the addon.
- `Documentation/` — project overview, architecture, roadmap, migration history, and changelog.

## Reference material

Authoritative Retail 12.1 research is maintained separately under:

`D:\WowDEV\Projects\BlizzardResearch\12.1.0\Analysis\`

The local Blizzard source reference is:

`D:\WowDEV\Reference\Blizzard\wow-ui-source\`

These locations are read-only reference material for addon work.
