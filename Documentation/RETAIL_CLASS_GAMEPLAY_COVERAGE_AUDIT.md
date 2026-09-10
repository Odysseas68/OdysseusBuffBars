# Retail Class and Gameplay Coverage Audit

Phase 1: scope, coverage inventory, and test matrix. This is a research and planning artifact; it does not authorize implementation.

## 1. Repository baseline

- Repository: `D:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\AddOns\OdysseusBuffBars`
- Branch: `main`
- `HEAD`: `9489ad94ebaf8178b58ebe3ed0159c7e8726ba58`
- `origin/main`: `9489ad94ebaf8178b58ebe3ed0159c7e8726ba58`
- Ahead/behind at audit start: `0 / 0`
- Worktree at audit start: clean

## 2. OBB architecture relevant to class and gameplay mechanics

`VERIFIED SOURCE FACT` — Current OBB has two distinct state paths:

- Blizzard-managed AuraContainers render player `HELPFUL` and `HARMFUL` AuraData. OBB composes BUFFS and `HelpfulEnhancements` ownership; only BUFFS has destination whitelist/blacklist filtering.
- Two OBB-owned ordinary rows independently query `C_PaperDollInfo.GetTemporaryEnchantmentInfo()` for `INVSLOT_MAINHAND` and `INVSLOT_OFFHAND`. A nil result hides that row. The rows use stable hidden-override keys, update on weapon/enchant/inventory events, and expose the existing bounded tooltip and out-of-combat cancellation behavior.
- Fishing Lure is a third OBB-owned presentation sourced from profession-tool temporary-enchantment state. It is not the OffHand weapon row and is distinct from a helpful fishing-bobber aura.
- Helpful semantic routing currently recognizes English name/description markers for well fed, flask/phial, augment rune, and bobber. Explicit spell-ID overrides take precedence over semantic routing.

Consequently, class identity is not an OBB routing input. The relevant question is whether a visible effect is AuraData, temporary equipment state, a permanent item property, or neither.

## 3. Evidence method

Evidence is kept in four classes:

- `VERIFIED SOURCE FACT`: current OBB code or the captured Blizzard API/source snapshot establishes the claim.
- `VERIFIED RUNTIME RESULT`: an exercised OBB scenario establishes only the stated composition.
- `SOURCE-SUPPORTED INFERENCE`: code and API contracts support an expectation that still needs the relevant runtime state.
- `ASSUMPTION / UNKNOWN`: evidence is insufficient; no behavior is inferred from historical class knowledge.

Primary Blizzard snapshot: branch `live`, commit `8ea15b61e45c0ed4eba01439c90757f86eb78d34`, Retail build `12.1.0.69587`. Its generated `PaperDollInfoDocumentation.lua` says the temporary-enchant query accepts an inventory-slot constant, may return nothing, and returns `enchantID`, `remainingTimeMs`, `chargesRemaining`, and `hasExpirationTime`. It does not provide a localized effect name.

External gameplay documentation is used only to establish that a mechanic exists or how players currently use it. It does not establish whether that mechanic appears in AuraData or the PaperDoll API.

## 4. Coverage categories

| Code | Meaning |
|---|---|
| A | Already handled correctly by the present architecture and relevant evidence |
| B | Architecturally handled; a particular runtime composition still needs validation |
| C | Possible functional gap with evidence sufficient to investigate |
| D | Not appropriate for OBB |
| E | Source or gameplay documentation can advance the case, but suitable runtime access is unavailable |
| F | Unknown because the current Retail representation is not established |

Runtime-access codes are: `1` testable now, `2` opportunistic, `3` source-only for now, `4` external gameplay documentation required, and `5` not worth runtime testing.

## 5. Representative gameplay paths

Coverage should be measured by state path, not by class count:

1. One ordinary readable helpful aura exercises the generic managed BUFFS path.
2. One ordinary readable harmful aura exercises the generic managed DEBUFFS path; it does not prove private-aura behavior.
3. One example from each semantic family exercises food, flask/phial, augment-rune, and fishing-bobber routing. It does not prove other locales or unrecognized wording.
4. One MainHand temporary enchant exercises the MainHand equipment-state row.
5. One actual OffHand weapon with a temporary enchant exercises the OffHand row. A shield, focus, or empty slot is not a substitute.
6. Simultaneous MainHand and OffHand temporary enchants exercise row independence, layout, per-key hiding, and event recovery.

## 6. Class/spec-relevant mechanics inventory

| Class/spec family or gameplay case | Mechanic | OBB area | Classification | Current finding |
|---|---|---|---|---|
| Shared across classes | Persistent and short self-buffs represented as readable AuraData | BUFFS | A | Generic managed HELPFUL handling applies; no per-class catalogue is needed. |
| Shared across classes | Player debuffs represented as readable AuraData | DEBUFFS | A | Generic managed HARMFUL handling applies. Private/restricted compositions remain separately bounded. |
| Paladin, Hunter, Priest, Mage, Warlock, Monk, Druid, Evoker; Arms/Protection Warrior; Blood/Unholy Death Knight; Elemental/Restoration Shaman | Readable class buffs, procs, and player debuffs | BUFFS/DEBUFFS | A | No separate class routing path is required for effects that arrive as readable AuraData. This does not classify effects whose current representation has not been observed. |
| Consumables | Food, flask/phial, augment rune | ENCHANTMENTS semantic ownership | A | Existing source and runtime evidence cover the named English marker families. |
| Fishing | Helpful bobber aura | ENCHANTMENTS semantic ownership | A | Managed helpful routing; distinct from the profession-tool Fishing Lure row. |
| Profession consumable | MainHand weapon oil or comparable temporary coating | MainHand row | A | MainHand application, timer, refresh, removal, tooltip, and exercised noncombat cancellation have runtime evidence. |
| Any eligible dual-wield setup | OffHand temporary enchant | OffHand row | B | The fixed slot architecture is correct by source; direct suitable OffHand runtime evidence is absent. |
| Any eligible dual-wield setup | Simultaneous temporary enchants | Both weapon rows | B | Known bounded validation gap, not a demonstrated defect. |
| Rogue | Weapon poisons | BUFFS or weapon rows | F | Current gameplay documentation confirms poisons and dual wield, but does not establish the current API representation OBB sees. Historical behavior is not substituted. |
| Enhancement Shaman | Windfury/Flametongue weapon imbues | BUFFS or weapon rows | E/F | Current gameplay guides describe weapon buffs; a targeted runtime/API observation is still required to establish AuraData versus slot state. |
| Frost Death Knight | Dual-wield Runeforging | Permanent item enchant boundary | D | External gameplay documentation describes Runeforging as permanent. It does not belong in temporary-enchant rows unless contrary current API evidence appears. |
| Demon Hunter / Fury Warrior / other dual-wield users | Two physical weapon slots | OffHand validation host | B | Useful representative hosts only if a currently eligible temporary coating can be applied; there is no class-specific OBB path. |
| Caster/tank off-hands | Shield, held-in-off-hand focus, or other non-weapon item | OffHand row | D | Slot occupancy is not evidence of temporary-enchant eligibility. A nil temporary-enchant result and hidden row are correct. |
| Shared across classes | Permanent crafted enchants, Runeforges, sockets, talents, spellbook capabilities, cooldowns, resources | Outside current OBB state models | D | These are item properties or gameplay capabilities, not transient player aura/temporary-enchant presentation. |

The inventory covers every Retail class/spec family through shared representations. No additional class-specific path was found that justifies one test per spec.

## 7. MainHand / OffHand findings

`VERIFIED SOURCE FACT` — OBB creates exactly two fixed weapon rows with separate slot constants and override keys. Each row independently queries its slot and hides on nil. This is architecturally suitable for a dual-wield composition when the game exposes temporary state for both slots.

`VERIFIED RUNTIME RESULT` — MainHand temporary oil behavior has been exercised. This does not establish OffHand or simultaneous-row behavior.

`SOURCE-SUPPORTED INFERENCE` — An actual OffHand weapon carrying temporary state should populate the OffHand row through the same implementation. A simultaneous case should populate both rows independently.

`ASSUMPTION / UNKNOWN` — Whether a particular current consumable or class imbue may be applied to an OffHand weapon must be established by current gameplay documentation or runtime. A shield/focus/non-weapon off-hand and a permanent enchant do not exercise this path.

## 8. Aura versus equipment-state findings

| Representation | OBB handling | Examples/boundary |
|---|---|---|
| Readable player AuraData | Managed BUFFS/DEBUFFS and paired helpful-enhancement ownership | Ordinary class buffs/procs, ordinary player debuffs, recognized consumable auras |
| Temporary inventory-slot enchant state | OBB MainHand/OffHand rows | Only what `GetTemporaryEnchantmentInfo(slot)` currently returns |
| Profession-tool temporary state | OBB Fishing Lure row | Separate slot resolution and presentation |
| Permanent item enchant | Outside temporary rows | Crafted permanent enchants and Runeforging-style item enhancements |
| Spellbook/action/talent capability | Outside OBB | An available ability does not prove an active aura or enchant |
| Unknown current representation | Keep unclassified until observed | Rogue poisons and Shaman imbues require targeted current-Retail confirmation |

## 9. Runtime testability matrix

| Gameplay case | Mechanic | OBB area | Expected handling | Evidence | Access | Test? | Priority | Notes / unknowns |
|---|---|---|---|---|---:|---|---|---|
| Ordinary self-buff | HELPFUL AuraData | BUFFS | Managed BUFFS | Source + runtime | 1 | Regression only | Low | One representative aura covers the generic path. |
| Ordinary player debuff | HARMFUL AuraData | DEBUFFS | Managed DEBUFFS | Source + runtime | 1 | Regression only | Low | Does not cover private aura composition. |
| Food/flask/rune/bobber | Helpful semantic route | ENCHANTMENTS | Paired ownership classifier | Source + runtime | 1 | Regression only | English-marker boundary remains. |
| MainHand oil | Temporary slot state | MainHand row | Visible independent row | Source + runtime | 1 | Regression only | Already exercised. |
| OffHand-only eligible coating | Temporary slot state | OffHand row | Visible independent row | Source inference | 2 | Yes | High | Requires an actual eligible OffHand weapon/state. |
| Simultaneous MH/OH coatings | Two temporary slot records | Both rows | Two independent rows | Source inference | 2 | Yes | Highest | Include independent removal and hidden overrides. |
| Rogue poison | Current representation unknown | BUFFS or weapon row | Generic path once representation is known | External existence only | 2/4 | Yes, if naturally available | Medium | Observe AuraData and both slot queries; do not infer from old expansions. |
| Enhancement imbues | Likely weapon-buff gameplay, API representation unproven | BUFFS or weapon rows | Generic path once representation is known | External current guide + inference | 2/4 | Yes, if naturally available | High | A natural dual-imbue setup could also close simultaneous-row coverage. |
| DH/Fury dual wield | Two weapon slots without a class-specific effect | OffHand validation host | Same generic slot path | Source inference | 2/4 | Only with eligible coating | Medium | Do not duplicate the same test by class. |
| Shield/focus/non-weapon off-hand | Noneligible or unknown item state | OffHand row | Hidden when query returns nil | API source | 3/5 | No | Low | Useful source boundary, not a positive enchant test. |
| Runeforging/permanent enchant | Permanent item property | Outside OBB | No temporary row | External gameplay docs + scope | 4/5 | No | None | Revisit only if current API evidence contradicts the permanent boundary. |
| Private/restricted harmful aura | Restricted aura composition | DEBUFFS | Managed Blizzard ownership | Prior source/runtime boundary | 2/3 | Opportunistic only | Medium | Do not manufacture a character solely for this case. |
| Non-English semantic text | Localized AuraData text | Helpful enhancement routing | Explicit override or default BUFFS when markers do not match | Source | 2/3 | Yes, if naturally available | Medium | Possible classifier limitation, not class coverage. |

## 10. Minimal representative test plan

1. On any current setup, retain a short regression check for one BUFF, one DEBUFF, one recognized helpful enhancement, and the existing MainHand oil path.
2. When an eligible dual-wield state occurs naturally, first apply an OffHand-only temporary enchant and verify appearance, timer/count state, removal/expiration, reload/world transition, and the OffHand hidden override.
3. In the same opportunity, apply simultaneous MainHand and OffHand temporary enchants. Verify two rows, stable order/layout, independent timers, independent hidden overrides, and independent removal.
4. If Rogue or Enhancement Shaman is naturally available, record only the representation: relevant AuraData spell IDs, results of both public temporary-enchant slot queries, and what changes on application/removal. Then map it to an existing path.
5. Treat a naturally encountered private harmful aura as a separate managed-DEBUFFS observation.

This plan requires no character creation or leveling.

## 11. Cases the user cannot currently test

No unavailable class/spec is a failed audit case. Rogue poisons, Enhancement imbues, dual-wield class hosts, and private harmful auras remain opportunistic where the required character/item/content state is absent. Source and targeted gameplay documentation may narrow them without inventing runtime results.

## 12. Source/documentation-only cases

- The PaperDoll API contract, nil behavior, returned record shape, and OBB's independent per-slot queries are source-verifiable.
- Runeforging's current gameplay permanence and current item/coating eligibility require targeted gameplay documentation; these are not Blizzard UI API conclusions.
- The official Rogue page confirms dual-wielded weapons and weapon poisons exist, but not their OBB-visible representation.
- A current 12.1 Enhancement guide lists Windfury Weapon and Flametongue Weapon as weapon buffs, but only runtime/API observation can establish their OBB-visible representation.
- Whether a current profession oil can coat both weapons is still a targeted external-gameplay question; it is not assumed.

## 13. Possible functional gaps

1. `C` — English semantic markers can miss equivalent localized or differently worded helpful enhancements. Explicit spell-ID routing remains the bounded fallback. Any broader classifier would be a separate product/design decision.
2. `B`, not a defect — simultaneous MainHand plus OffHand temporary-enchant presentation lacks direct OBB runtime validation.
3. `F` — if a current class weapon effect is neither readable AuraData nor exposed as temporary slot state, OBB will not present it. No such in-scope current effect has yet been demonstrated.

The absence of a localized temporary-enchant effect name is a public-data limitation already handled by bounded generic row labels; it is not by itself a functional gap.

## 14. Cases explicitly rejected as OBB scope

- Permanent item enchant tracking, including Runeforging-style permanent effects.
- Spellbook, talent, action-slot, cooldown, resource, proc-prediction, or equipment-eligibility displays.
- A spell-by-spell class catalogue or per-spec routing table where generic AuraData handling applies.
- Inferring a temporary enchant from item type, class, enchant ID, tooltip scraping, or historical behavior when the public slot query returns nil.
- Treating a shield, focus, or any occupied OffHand slot as though it were an enchanted weapon.

## 15. SavedVariables and compatibility risks for future work

No SavedVariables change is justified by this audit. If future evidence establishes a new in-scope row or semantic family:

- a new row would need a stable, non-spell override key without changing the existing MainHand/OffHand keys;
- a new helpful semantic family must preserve numeric spell-ID overrides and the hidden/explicit-route precedence;
- changing locale or classification behavior could reroute existing auras and therefore needs compatibility and user-expectation review;
- preserved historical D/E filter data must remain dormant unless a separate migration decision explicitly changes that contract.

## 16. Combat and security boundaries

- The PaperDoll cancellation function is documented as restricted. OBB exposes cancellation only through its current out-of-combat guarded composition; the exercised MainHand case is not a universal contract.
- Managed aura ownership, combat refresh behavior, independent-owner weapon tooltips, and restricted layout conclusions remain bounded to documented OBB compositions.
- This audit makes no general claim about combat safety, taint, secure execution, protected operations, or other addon layouts.

## 17. Remaining unknowns

- Current Retail API representation of each relevant Rogue poison effect.
- Current Retail API representation and slot behavior of Windfury/Flametongue imbues.
- A presently obtainable/useful coating that can exercise OffHand-only and simultaneous dual-slot state for this user.
- Direct OBB behavior with two simultaneous temporary-enchant records.
- Behavior of a naturally encountered private/restricted harmful aura in the current OBB composition.
- Non-English semantic-classifier coverage beyond explicit spell-ID overrides.

## 18. Recommended next runtime tests

The next high-value test is one naturally available simultaneous MainHand/OffHand temporary-enchant composition, preceded by OffHand-only state. Enhancement Shaman is useful only if its current imbues are exposed through the PaperDoll slot API; any eligible dual-wield character plus a two-weapon coating is equally valid. Rogue and private-aura checks are opportunistic representation observations, not prerequisites.

## 19. Recommended next engineering step

Do not implement a class-specific feature. Preserve this matrix as the Phase 1 boundary, collect the OffHand/simultaneous evidence when a suitable state naturally becomes available, and open a narrowly scoped Phase 2 design task only if runtime evidence demonstrates an in-scope effect that neither current generic path handles correctly.

## Sources

- OBB production authority: `OdysseusBuffBars_Managed.lua`, especially the fixed row definitions, helpful classifier, weapon-row refresh, creation, cancellation, and event registration.
- Blizzard generated API: `D:\WowDEV\Reference\Blizzard\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\PaperDollInfoDocumentation.lua` at Live source commit `8ea15b61e45c0ed4eba01439c90757f86eb78d34`.
- External gameplay documentation, accessed 2026-09-10:
  - Blizzard Rogue class page: <https://worldofwarcraft.blizzard.com/en-us/game/classes/rogue>
  - Blizzard Midnight pre-expansion notes (Flametongue's current talent presence): <https://worldofwarcraft.blizzard.com/en-us/news/24244455>
  - Wowhead Enhancement Shaman 12.1 overview: <https://www.wowhead.com/guide/classes/shaman/enhancement/overview-pve-dps>
  - Warcraft Wiki Runeforging overview: <https://warcraft.wiki.gg/wiki/Runeforging>
