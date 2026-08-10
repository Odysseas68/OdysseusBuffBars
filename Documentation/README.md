# OdysseusBuffBars

## Project overview

OdysseusBuffBars is a standalone World of Warcraft Retail addon and research implementation for aura presentation, interaction, and combat-sensitive behavior. It is separate from the production Odysseus Utility Suite addon.

The legacy implementation uses direct `C_UnitAuras` scanning, addon-owned aura records, ordinary custom bars, and separate secure cancellation overlays. It remains temporarily available for comparison and compatibility during migration, but its direct scanner is not a reliable Retail 12.1 combat backend.

A parallel player-BUFFS implementation now uses `CustomAuraContainer` with container-owned AuraButtons. On the Retail 12.1 PTR, it has passed validation for the managed lifecycle and presentation, dynamic self-sizing, native sorting, whitelist/blacklist filtering, automatic synchronization with the existing filter editor, native tooltip and right-click cancellation, combat updates, reload behavior, timeless auras, and application counts. No Lua errors, taint, or blocked actions were observed during these tests.

This is a successful migration prototype, not the final production implementation. Visual parity, persistent prototype position and sort choice, final configuration integration, Debuffs, Enhancements, Blizzard BuffFrame visibility, and production cutover remain future work.

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
- `OdysseusBuffBars_ManagedPrototype.lua` — parallel managed player-BUFFS prototype.
- `Reference/` — frozen local reference material; it is not loaded by the addon.
- `Documentation/` — project overview, architecture, roadmap, migration history, and changelog.

## Reference material

Authoritative Retail 12.1 research is maintained separately under:

`D:\WowDEV\Projects\BlizzardResearch\12.1.0\Analysis\`

The local Blizzard source reference is:

`D:\WowDEV\Reference\Blizzard\`

These locations are read-only reference material for addon work.
