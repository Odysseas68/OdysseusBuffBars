# OdysseusBuffBars

## Project overview

OdysseusBuffBars is a standalone World of Warcraft Retail addon and research implementation for aura presentation, interaction, and combat-sensitive behavior. It is separate from the production Odysseus Utility Suite addon.

The legacy implementation uses direct `C_UnitAuras` scanning, addon-owned aura records, ordinary custom bars, and separate secure cancellation overlays. It remains temporarily available for comparison and compatibility during migration, but its direct scanner is not a reliable Retail 12.1 combat backend.

A parallel player-BUFFS implementation now uses `CustomAuraContainer` with container-owned AuraButtons. On the Retail 12.1 PTR, it has passed validation for the managed lifecycle and presentation, dynamic self-sizing, native sorting, whitelist/blacklist filtering, automatic synchronization with the existing filter editor, native tooltip and right-click cancellation, combat updates, reload behavior, timeless auras, and application counts. No Lua errors, taint, or blocked actions were observed during these tests.

A second isolated managed player-DEBUFFS prototype uses its own `CustomAuraContainer`, `unit="player"`, and one broad `HARMFUL` group. Core runtime behavior is validated on Retail Live `12.1.0.69273`: multiple debuffs, combat additions/refreshes/removals, the five managed presentation bindings, Default/Name/Time Left sorting, native combat tooltips, dynamic grow/shrink, and simultaneous managed BUFFS/DEBUFFS operation worked without observed addon-attributable Lua errors, taint, or blocked actions. Its ordinary host follows the dynamically self-sizing BUFFS container through a one-directional eight-pixel-gap anchor, and combat-driven BUFFS size changes propagate correctly. A known real private harmful aura and optional explicit secrecy/`NeverSecret` tests remain pending.

A third isolated managed ENCHANTMENTS prototype combines native MainHand and OffHand item-enchantment sources with a separate managed `HelpfulEnhancements` HELPFUL group below DEBUFFS. Core managed MainHand temporary-enchantment lifecycle is validated on Retail Live with Thalassian Phoenix Oil, including two cold logins, reload, fresh reapplication, native tooltip, and right-click cancellation in the tested non-combat context. Its initial-login recovery coalesces the player `UNIT_INVENTORY_CHANGED` burst with generation checks and one pending `C_Timer.After(0)` callback, then performs one final managed refresh after a quiet turn. No fixed callback count, positive delay, polling, PaperDoll inspection, or synthetic fallback is used.

These are successful parallel migration prototypes, not final production backends. The legacy production paths remain present. Managed ENCHANTMENTS dynamically classifies readable active Food, Flask/Phial, and Augment Rune spell metadata and applies the same session-only spell-ID membership as ENCHANTMENTS includes and BUFFS exclusions. Those entries remain HELPFUL auras; they are not converted into native item enchantments. No hardcoded routing IDs, item IDs, duration thresholds, persistence, or polling are used. Native temporary-enchantment rows still show Blizzard's equipped-weapon name because Retail 12.1 exposes no supported temporary-enchant-ID-to-localized-name resolver. OffHand, simultaneous slots, native duration ordering, combat cancellation, permanent/zero-duration cases, Ranged behavior, final naming, visual parity, persistence, configuration integration, and production cutover remain pending.

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
- `OdysseusBuffBars_ManagedPrototype.lua` — parallel managed player-BUFFS, player-DEBUFFS, and ENCHANTMENTS prototypes, including native item enchantments and semantic HELPFUL routing.
- `Reference/` — frozen local reference material; it is not loaded by the addon.
- `Documentation/` — project overview, architecture, roadmap, migration history, and changelog.

## Reference material

Authoritative Retail 12.1 research is maintained separately under:

`D:\WowDEV\Projects\BlizzardResearch\12.1.0\Analysis\`

The local Blizzard source reference is:

`D:\WowDEV\Reference\Blizzard\wow-ui-source\`

These locations are read-only reference material for addon work.
