# Rogue Poison and Enhancement Shaman Weapon-Imbue Representation Audit

## 1. Repository Baseline

**VERIFIED SOURCE FACT** — This focused documentation audit was performed in the active Retail addon repository on branch `main` at commit `6215c8b8e46dc81c401458830148357062c8e453`. At the start of the task, `HEAD` matched `origin/main`, ahead/behind was `0/0`, and the working tree was clean.

This audit does not change addon Lua, the TOC, SavedVariables behavior, feature behavior, existing documentation, build metadata, or release metadata.

## 2. Blizzard Source Provenance

**VERIFIED SOURCE FACT** — The primary source mirror was:

- Path: `D:\WowDEV\Reference\Blizzard\wow-ui-source`
- Branch: `live`
- Commit: `8ea15b61e45c0ed4eba01439c90757f86eb78d34`
- Build: `12.1.0.69587`
- Interface generation: Retail 12.1.0

`HEAD` matched `origin/live` with ahead/behind `0/0`. The pre-existing untracked `.codex/` directory in the source mirror was not touched. No PTR or later-build source was mixed into the conclusions.

## 3. Scope and Research Question

This audit asks how current Retail represents two class mechanics that can look like weapon enhancements in gameplay:

- Rogue weapon poisons, with Instant Poison as the source-visible example.
- Enhancement Shaman weapon imbues, with Windfury Weapon and Flametongue Weapon as the gameplay examples.

For each mechanic, the required distinction is whether the active state is exposed as:

1. player `AuraData` through `C_UnitAuras`,
2. temporary equipment state through `C_PaperDollInfo.GetTemporaryEnchantmentInfo`,
3. both representations at once, or
4. a representation that current static source cannot establish.

Gameplay existence, spell capability, tooltip presentation, and API representation are separate questions. Similar names or integer-shaped identifiers do not make spell IDs, aura-instance IDs, enchant IDs, item IDs, or inventory slots interchangeable.

## 4. Evidence Method

This document uses four evidence classes:

- **VERIFIED SOURCE FACT** — directly established by the captured current Blizzard or OBB source.
- **VERIFIED RUNTIME RESULT** — directly observed in a controlled runtime test, with its tested boundary stated.
- **SOURCE-SUPPORTED INFERENCE** — a bounded conclusion supported by source structure but not directly demonstrated by the source or a runtime test.
- **ASSUMPTION / UNKNOWN** — not established by the available source or runtime evidence.

Current gameplay references are used only to establish that the mechanics remain relevant. External spell-database presentation is hypothesis evidence, not proof of a Blizzard Lua API contract.

## 5. Current OBB State Paths

**VERIFIED SOURCE FACT** — OBB has two distinct generic input paths relevant to this audit:

1. Managed player `HELPFUL` auras are discovered with `C_UnitAuras.GetUnitAuras("player", "HELPFUL")`. Effective ownership is resolved as hidden, explicit BUFFS/ENCHANTMENTS override, semantic ENCHANTMENTS route, then default BUFFS.
2. OBB-owned MainHand and OffHand rows query `C_PaperDollInfo.GetTemporaryEnchantmentInfo` for `INVSLOT_MAINHAND` and `INVSLOT_OFFHAND`. A present record produces the corresponding generic ENCHANTMENTS weapon row.

The semantic HELPFUL classifier recognizes the literal English markers `well fed`, `flask` or `phial`, `augment rune`, and `bobber`. It contains no Rogue-poison or Shaman-imbue category and no class-specific route.

## 6. Rogue Poison Findings

**VERIFIED SOURCE FACT** — Current Blizzard Lua contains an Instant Poison spell reference, spell ID `315584`, in `Blizzard_NewPlayerExperience/Blizzard_TutorialData.lua`. The reference describes a Rogue class-quest capability. It does not read or declare the mechanic's active API representation.

**VERIFIED SOURCE FACT** — A bounded search of the current Retail Lua source found no Rogue-poison-specific active-state consumer, provider, AuraContainer group, weapon-enchantment adapter, or class UI subsystem. Generic poison dispel/UI constants and examples do not establish Rogue weapon-poison state.

**SOURCE-SUPPORTED INFERENCE** — Current class guides and the Instant Poison spell page support continued gameplay relevance and make a player-buff representation plausible. That secondary evidence does not prove that `C_UnitAuras.GetUnitAuras("player", "HELPFUL")` returns the applied poison, that PaperDoll temporary-enchantment state exists, or that both exist simultaneously.

**ASSUMPTION / UNKNOWN** — Rogue poison representation is source-inconclusive. It is not verified here as `AuraData`, as temporary equipment state, or as both.

## 7. Enhancement Shaman Imbue Findings

**VERIFIED SOURCE FACT** — Current Blizzard Lua references Flametongue Weapon spell ID `318038` in `Blizzard_NewPlayerExperience/Blizzard_TutorialData.lua`. That tutorial progression reference establishes a spell capability, not an active-state representation. No exact Windfury Weapon reference was found in the searched current Lua source.

**VERIFIED SOURCE FACT** — A bounded search found no Shaman-imbue-specific active-state consumer, provider, AuraContainer group, weapon-enchantment adapter, or class UI subsystem. The generic temporary-enchantment pipeline is not class-specific.

**SOURCE-SUPPORTED INFERENCE** — Current gameplay guides describe Windfury on MainHand and Flametongue on OffHand for Enhancement. The external Flametongue spell page describes a temporary item enchant, which makes PaperDoll state a strong test hypothesis. Neither secondary source proves the current Blizzard Lua return path, slot records, `AuraData` presence, or absence of a second representation.

**ASSUMPTION / UNKNOWN** — Enhancement Shaman weapon-imbue representation is source-inconclusive. It is not verified here as `AuraData`, as temporary equipment state, or as both.

## 8. Gameplay Existence Versus API Representation

| Mechanic | Current gameplay relevance | `AuraData` verified | Temporary-enchantment state verified | Both verified | Static conclusion |
|---|---|---:|---:|---:|---|
| Rogue poisons | Yes, by current secondary gameplay references | No | No | No | **ASSUMPTION / UNKNOWN** — source-inconclusive |
| Enhancement Shaman imbues | Yes, by current secondary gameplay references | No | No | No | **ASSUMPTION / UNKNOWN** — source-inconclusive |

The word “buff,” a spell effect label, or a gameplay statement that an effect is applied to a weapon is not enough to choose a Lua representation path.

## 9. AuraData Findings

**VERIFIED SOURCE FACT** — `C_UnitAuras.GetUnitAuras(unitToken, filter)` returns a table of `AuraData` records. Blizzard's managed AuraContainer treats unit auras and item enchantments as distinct data types. Item enchantments are explicitly not unit aura instances and carry no `auraInstanceID` in the provider-created record.

**VERIFIED SOURCE FACT** — The searched current source contains no spell-ID mapping or class-specific code proving that Instant Poison, Windfury Weapon, or Flametongue Weapon enters the player `HELPFUL` AuraData stream.

**ASSUMPTION / UNKNOWN** — Whether any of these mechanics is readable as current player `AuraData`, including its spell ID, duration, applications, and removal behavior, requires runtime observation.

## 10. Temporary-Enchantment Findings

**VERIFIED SOURCE FACT** — Blizzard's generic item-enchantment path maps MainHand, OffHand, and Ranged provider slots to inventory slots and queries `C_PaperDollInfo.GetTemporaryEnchantmentInfo`. The public record can contain `enchantID`, `remainingTimeMs`, `chargesRemaining`, and `hasExpirationTime`; it does not provide a localized effect name or establish a spell/item identity mapping.

**VERIFIED SOURCE FACT** — The AuraContainer provider creates an `ItemEnchantment` record with `itemEnchantmentSlot`, `inventorySlot`, and `itemEnchantmentID`. Blizzard's BuffFrame has a separate generic `TempEnchant` construction path. Neither path contains class-specific poison or imbue classification.

**ASSUMPTION / UNKNOWN** — Static Lua source does not establish that Rogue poisons or Enhancement Shaman imbues cause a non-nil PaperDoll record on the current client. `enchantID` must not be tested as though it were a spell ID or item ID.

## 11. MainHand / OffHand Findings

**VERIFIED SOURCE FACT** — Blizzard's generic provider and OBB both distinguish MainHand and OffHand by inventory slot. OBB has one structurally symmetric row for each slot.

**SOURCE-SUPPORTED INFERENCE** — Current secondary gameplay guidance identifies Windfury as MainHand and Flametongue as OffHand for Enhancement. This is sufficient to choose the first runtime test arrangement, not to claim PaperDoll results.

**ASSUMPTION / UNKNOWN** — The exact slot behavior of current Rogue poisons, including whether one application produces one slot record, two slot records, no slot record, or some mixed representation, is unknown. The exact PaperDoll result for both Shaman slots is also unknown. Historical OBB MainHand weapon-oil validation does not prove OffHand or dual-slot behavior for these class mechanics.

## 12. Potential Duplicate-Display Analysis

**VERIFIED SOURCE FACT** — OBB's readable `HELPFUL` path and its MainHand/OffHand PaperDoll path are independent. OBB does not deduplicate across a unit-aura identity and a temporary-enchantment slot record.

**SOURCE-SUPPORTED INFERENCE** — If one applied class mechanic is simultaneously exposed through both paths, the current architecture can represent it twice: likely once as a BUFFS aura and once as an ENCHANTMENTS weapon row. This is a conditional architectural risk, not an observed defect.

**ASSUMPTION / UNKNOWN** — No current runtime evidence in this audit establishes that Rogue poisons or Shaman imbues are double-exposed, so no duplicate-display bug is claimed.

## 13. Semantic HELPFUL Routing Interaction

**VERIFIED SOURCE FACT** — The exact inspected English names `Instant Poison`, `Windfury Weapon`, and `Flametongue Weapon` do not match OBB's current semantic markers. The inspected secondary descriptions also do not contain those markers.

**SOURCE-SUPPORTED INFERENCE** — If one of these mechanics appears as readable player `HELPFUL` AuraData, current default ownership should remain BUFFS unless a user hides it or applies an explicit B/E override. The classifier should not automatically route it to ENCHANTMENTS from the inspected English text.

**ASSUMPTION / UNKNOWN** — Localized names/descriptions, every spell variant, and actual current readable spell metadata were not runtime-verified. Therefore zero collision across all locales and variants is not claimed.

## 14. OBB Coverage Mapping

| Observed runtime representation | Existing OBB handling | Coverage assessment |
|---|---|---|
| Readable player `HELPFUL` AuraData only | Managed HELPFUL ownership; normally BUFFS for these inspected names | Generic path already exists |
| MainHand PaperDoll record only | OBB-owned MainHand row in ENCHANTMENTS | Generic path already exists |
| OffHand PaperDoll record only | OBB-owned OffHand row in ENCHANTMENTS | Generic path already exists; direct class-mechanic validation remains opportunistic |
| Both AuraData and PaperDoll record | Both independent paths can render | Potential duplicate; runtime confirmation required before design work |
| Neither exposed through these paths | No current OBB representation | Possible gap, but runtime evidence is required before treating it as one |

**SOURCE-SUPPORTED INFERENCE** — OBB already covers either known generic representation family without class-specific code. The unresolved issue is representation discovery and possible cross-path duplication, not a demonstrated missing implementation.

## 15. Runtime Validation Requirements

These tests are minimal, out-of-combat, and opportunistic when a naturally available class can apply the mechanic. Capture before-application and after-application results, then removal or expiration when practical.

1. Inspect readable player HELPFUL identities and OBB classifications:

   ```lua
   /run OdysseusBuffBars.Managed.DumpHelpfulEnhancementClassifications()
   ```

2. Inspect the two public inventory-slot records without reinterpreting `enchantID`:

   ```lua
   /run for _,s in ipairs({INVSLOT_MAINHAND,INVSLOT_OFFHAND}) do local e=C_PaperDollInfo.GetTemporaryEnchantmentInfo(s); print(s,e and e.enchantID,e and e.remainingTimeMs,e and e.chargesRemaining,e and e.hasExpirationTime) end
   ```

3. Observe BUFFS and ENCHANTMENTS before and after application. Record whether the state appears in BUFFS, the MainHand row, the OffHand row, more than one of those places, or nowhere.
4. Repeat after removal, cancellation, replacement, or natural expiration where the mechanic permits it. Do not infer a general combat-cancellation contract from an out-of-combat test.

The required result record is mechanic, character/spec, client build, spell used, equipped weapon slots, HELPFUL AuraData identity if present, PaperDoll slot record if present, visible OBB destination, and whether duplicate presentation occurred.

## 16. Cases Not Testable by the User

**ASSUMPTION / UNKNOWN** — If an appropriate Rogue or Enhancement Shaman is not naturally available, the corresponding class test is `OPPORTUNISTIC`, not a blocker and not a failed validation. This audit does not require character creation, leveling, gearing, profession acquisition, paid services, or access to a special encounter.

Source-only status should remain explicit until a natural test case becomes available.

## 17. Bounded Unknowns

- Whether each mechanic is returned by player `C_UnitAuras` on build `12.1.0.69587`.
- Whether each mechanic creates a MainHand or OffHand PaperDoll temporary-enchantment record.
- Whether either mechanic is exposed by both systems simultaneously.
- Rogue poison slot cardinality and dual-wield behavior.
- Shaman MainHand/OffHand records for the gameplay-described Windfury/Flametongue arrangement.
- Exact AuraData spell IDs and PaperDoll enchant IDs when active.
- Localized semantic-classifier collision behavior.
- Apply, replace, remove, expire, reload, loading-screen, and combat behavior for these exact mechanics.

These are bounded representation and validation unknowns. They are not evidence of a defect.

## 18. Functional Gaps, If Any

**ASSUMPTION / UNKNOWN** — No genuine OBB functional gap is demonstrated by the current evidence.

**SOURCE-SUPPORTED INFERENCE** — A gap would become concrete only if runtime evidence showed a desired mechanic is exposed by neither existing OBB input path, or if a verified dual representation produced unacceptable duplicate presentation. Neither condition is established here.

No production change is justified from static source alone.

## 19. Engineering Implications

- Do not add class-name, spell-name, or speculative spell-ID routing.
- Do not treat tutorial spell IDs as active-state API contracts.
- Do not reinterpret PaperDoll `enchantID` as a spell or item ID.
- Do not add cross-path deduplication until one exact mechanic is verified in both paths and a stable shared identity or bounded policy is available.
- Preserve the existing generic BUFFS and MainHand/OffHand coverage while collecting runtime evidence.
- Record class/spec, build, slots, and both API paths in the same test session so an apparent absence is interpretable.

## 20. Recommendation

Keep the implementation unchanged. Run the minimal opportunistic class tests when suitable characters are naturally available, then update this evidence record with exact `VERIFIED RUNTIME RESULT` entries. If both representations are observed for the same mechanic, perform a separate narrow design audit before changing routing or deduplication. If only one existing path is observed, record the coverage without adding class-specific code.

## 21. Exact Source References

Primary Blizzard source:

- `Interface/AddOns/Blizzard_NewPlayerExperience/Blizzard_TutorialData.lua:104` — Flametongue Weapon tutorial spell reference (`318038`).
- `Interface/AddOns/Blizzard_NewPlayerExperience/Blizzard_TutorialData.lua:237` — Instant Poison class-quest spell reference (`315584`).
- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerShared.lua:3-27` — distinct Aura and ItemEnchantment data types plus slot mapping.
- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua:156-168` — item-enchantment slot to inventory-slot query path.
- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerEnchantments.lua:190-219` — generic slot refresh and PaperDoll query.
- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerEnchantments.lua:286-353` — item-enchantment cache and provider-created data, including no unit-aura instance identity.
- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua:450-468` — generic `AddItemEnchantment` registration.
- `Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua:667-694` — generic MainHand/OffHand/Ranged temporary-enchant construction.
- `Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua:868-896` — slot-oriented temporary-enchant click and tooltip handling.
- `Interface/AddOns/Blizzard_APIDocumentationGenerated/PaperDollInfoDocumentation.lua:217-230,482-489` — temporary-enchantment query and result structure.
- `Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua:452-469` — `C_UnitAuras.GetUnitAuras` contract.
- `Interface/AddOns/Blizzard_Deprecated/Deprecated_12_1_0.lua:44-65` — generic compatibility wrapper over enchantment slots.

Current OBB source:

- `OdysseusBuffBars_Managed.lua:154-174` — managed HELPFUL group and MainHand/OffHand target definitions.
- `OdysseusBuffBars_Managed.lua:1588-1617` — bounded semantic HELPFUL classifier.
- `OdysseusBuffBars_Managed.lua:1619-1673` — HELPFUL classification diagnostic and routed-category set.
- `OdysseusBuffBars_Managed.lua:2434-2493` — public PaperDoll slot queries and weapon-row refresh.
- `OdysseusBuffBars_Managed.lua:3057-3154` — generic weapon-row creation, tooltip, and cancellation path.
- `OdysseusBuffBars_Managed.lua:3626-3664` — relevant aura, weapon, and lifecycle events.
- `OdysseusBuffBars_Managed.lua:3823-3835` — construction of the two fixed weapon rows.

Secondary current-gameplay references, used only for gameplay relevance and runtime-test hypotheses:

- Wowhead, [Assassination Rogue abilities and talents](https://www.wowhead.com/guide/classes/rogue/assassination/abilities-talents-pve-dps).
- Wowhead, [Outlaw Rogue abilities and talents](https://www.wowhead.com/guide/classes/rogue/outlaw/abilities-talents-pve-dps).
- Wowhead, [Instant Poison](https://www.wowhead.com/spell=315584/instant-poison).
- Wowhead, [Enhancement Shaman abilities and talents](https://www.wowhead.com/guide/classes/shaman/enhancement/abilities-talents-pve-dps).
- Wowhead, [Enhancement Shaman consumables](https://www.wowhead.com/guide/classes/shaman/enhancement/enchants-gems-pve-dps).
- Wowhead, [Flametongue Weapon](https://www.wowhead.com/spell=334294/flametongue-weapon).
- Wowhead, [Windfury Weapon](https://www.wowhead.com/spell=33757/windfury-weapon).

## 22. Exact Files Modified

- Added `Documentation/ROGUE_SHAMAN_REPRESENTATION_AUDIT.md`.

No existing file was modified.

## 23. Validation Results

- Full document readback: passed.
- Evidence-label and overclaim audit: passed.
- Required-term audit for absolute or compatibility-sensitive wording: passed after contextual review.
- LuaCheck: not run because no Lua file changed.

## 24. `git diff --check`

No output. Because this document is untracked, ordinary `git diff --check` does not inspect it. A supplemental `git diff --no-index --check NUL Documentation/ROGUE_SHAMAN_REPRESENTATION_AUDIT.md` check passed.

## 25. `git diff --stat`

No output. The only change is an untracked documentation file, which ordinary `git diff --stat` does not include. Supplemental no-index statistics: `1 file changed, 265 insertions(+)`.

## 26. `git status --short`

Expected final status:

```text
?? Documentation/ROGUE_SHAMAN_REPRESENTATION_AUDIT.md
```

No file was staged, committed, pushed, tagged, or released.
