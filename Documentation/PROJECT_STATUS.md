# Odysseus BuffBars Project Status

## 1. Checkpoint summary

Odysseus BuffBars is a World of Warcraft Retail aura-bar addon. The immutable
v1.0.0 release uses version `1.0.0`, build date `2026-08-28`, release commit
`6a7b7f7f967bc834251775b93b0aa149f7a9b5aa`, and annotated tag `v1.0.0`.

The current development checkpoint is post-v1.0 **Unreleased** work:

- Commit: `58331025cece26c46b70b0094253994c93d75474`
- Subject: `Polish Config companion dialogs and UI scaling`
- Addon metadata remains version `1.0.0`, build date `2026-08-28`.

Current production behavior and the cumulative Config modernization through
this checkpoint have been successfully runtime tested by the user on Retail
LIVE where recorded in the project documentation. Current HEAD is not the
v1.0.0 tagged release commit and has not been published as another release.

## 2. Production architecture

`OBB.Managed` is the production managed-aura implementation, and MANAGED is the
sole renderer authority for BUFFS, DEBUFFS, and ENCHANTMENTS. The former Bars,
secure-overlay, and direct Auras/Engine backends are retired and are not loaded
or available as fallbacks.

Core owns SavedVariables initialization, events, commands, and the
`OBB:RefreshAll()` coordinator. `RefreshAll()` requires a ready managed module;
outside combat it applies managed configuration and refreshes managed state,
while in combat it leaves the Blizzard-managed lifecycle authoritative.

BUFFS uses a managed HELPFUL `CustomAuraContainer`, DEBUFFS uses a separate
broad HARMFUL container, and ENCHANTMENTS uses its own managed host/container.
Blizzard-managed AuraButtons own supported aura presentation, updates,
tooltips, sorting, self-sizing, and cancellation behavior. Addon-owned hosts and
headers own supported placement and dragging. The Config root and its companion
UI form a separate ownership tree from the gameplay-facing managed hosts, bars,
and anchors.

## 3. ENCHANTMENTS architecture

ENCHANTMENTS combines three sources:

1. A managed `HelpfulEnhancements` HELPFUL aura group, capped at seven rows.
2. Native Main Hand and Off Hand temporary-enchantment registrations, ordered
   by slot through Blizzard's managed item-enchantment support.
3. One visually matched ordinary Fishing Lure footer below the managed
   container because the managed provider does not register the profession-tool
   slot.

This is the established `7 + 2 + 1` capacity policy. Fishing Bobber consumes a
HELPFUL enhancement slot; Fishing Lure is the separate footer. The footer is
outside the managed container's calculated bounds and has no cancellation
path.

Historical ENCHANTMENTS Sort and Max Bars SavedVariables remain preserved, but
production ENCHANTMENTS intentionally uses fixed `TIMELEFT` sorting and the
seven-row HELPFUL capacity. Config displays those controls as fixed/disabled;
the historical values do not govern the managed ENCHANTMENTS runtime.

## 4. Routing and overrides

Readable HELPFUL ownership resolves in this order: Hidden override, explicit
BUFFS or ENCHANTMENTS group override, semantic enhancement classification, then
default BUFFS. Only after ownership is resolved does the BUFFS-local
whitelist/blacklist stage admit or reject BUFF-owned Spell IDs. DEBUFFS and
ENCHANTMENTS intentionally do not consume destination whitelist/blacklist
filters.

Semantic routing recognizes readable food, flask/phial, augment-rune, and
fishing-bobber text. It is designed and tested around readable English aura and
spell text; numeric Spell ID overrides remain the fallback for other locales or
unclassified effects.

Override Settings provides manual Spell ID entry, a Current Spell selector,
Group, Hidden, and explicit Save. Its structured saved list shows Spell ID,
available name, group, Shown/Hidden state, and a row-specific X removal action.
Current Spell aggregates and deduplicates the same copied, current-readable OBB
HELPFUL candidate rows used by the Filter editor; it does not add an independent
aura scanner. Selecting a candidate fills only the editable Spell ID and does
not save or change Group/Hidden. Manual IDs remain supported for inactive and
future spells.

## 5. Config status

The completed Config currently includes:

- A resizable Midnight-style shell with General, BUFFS, DEBUFFS, and
  ENCHANTMENTS pages.
- Native Retail `MinimalSliderWithSteppersTemplate` numeric controls.
- Midnight-themed Filter and Override companions sharing the fixed right-side
  slot; opening one hides the other.
- Solid Midnight Texture and Font picker popups backed by LibSharedMedia-3.0.
- Minimap and independent Retail Addon Compartment launchers.
- A Config-only UI Scale preference at
  `OdysseusBuffBarsDB.config.uiScale`.

Config UI Scale ranges from `75%` through `125%` in `5%` increments and defaults
to `100%`. It scales the Config root and inherited pages, controls, companions,
and media pickers only. Runtime BUFFS, DEBUFFS, ENCHANTMENTS, and their anchors
are separate frames and are unaffected.

Logical Config bounds remain `680 x 610` minimum, `700 x 610` default, and
`900 x 720` maximum. Width and height remain logical values; scale-aware center
conversion preserves position persistence without progressively rewriting
saved geometry.

## 6. Compatibility and stability constraints

- `OdysseusBuffBarsDB` remains canonical. Historical data is preserved unless
  an explicit migration or purge is authorized.
- Unsupported historical BUFF duration and B/D/E topology are interpreted in a
  copied runtime-only effective state. Raw SavedVariables are not silently
  remapped or rewritten.
- Historical DEBUFFS/ENCHANTMENTS filter tables remain preserved as dormant
  compatibility data and are not consumed by managed D/E.
- Config mutation, frame movement/resizing, and managed anchor dragging remain
  combat guarded. Blizzard-owned managed lifecycle work continues in combat;
  future changes must preserve taint and restricted-layout boundaries.
- Config-owned frames must remain separate from runtime managed hosts so Config
  presentation changes cannot propagate into gameplay geometry.
- The following six named global runtime frames still conservatively retain
  `Prototype` in their names:
  - `OdysseusBuffBarsManagedPrototypeHost`
  - `OdysseusBuffBarsManagedPrototypeContainer`
  - `OdysseusBuffBarsManagedDebuffPrototypeHost`
  - `OdysseusBuffBarsManagedDebuffPrototypeContainer`
  - `OdysseusBuffBarsManagedEnchantmentPrototypeHost`
  - `OdysseusBuffBarsManagedEnchantmentPrototypeContainer`

Those names should not be casually changed. They are retained conservatively
because global frame identity, user-placed state, layout caching, and movement
state may be compatibility-sensitive; the exact engine persistence mechanism
has not been proven sufficiently to justify a cosmetic rename.

## 7. Known limitations and deferred items

There is no currently documented actionable production defect blocking normal
use. Genuine limitations or deferred coverage include:

- Semantic enhancement recognition is English-oriented; manual Spell ID
  routing is the supported fallback.
- Blizzard's public temporary-enchantment surface does not provide a clean
  enchant-effect name. The addon intentionally avoids tooltip scraping,
  AuraButton enumeration, private-provider inspection, and hardcoded maps.
- Fishing Lure cancellation is not provided.
- Direct private-HARMFUL, broader Main Hand lifecycle, and opportunistic Off
  Hand/dual-slot coverage remain targeted validation areas rather than known
  implementation gaps.
- `ABOVE` placement is intentionally unsupported. A future full-bounds
  ENCHANTMENTS parent would require separate research if downstream chaining is
  ever needed because Fishing Lure is outside the terminal managed container.
- Broader localization, class/effect/lure coverage, and any development-only
  diagnostic console remain separate future work.

The accepted cumulative Config-polish batch is complete. Further page-level
visual work is optional future polish, not an outstanding correction to this
checkpoint.

## 8. Blizzard UI research boundary

Investigation of newer Retail buttons, dialogs, borders, backgrounds, native
controls, or configuration widgets belongs in the separate Blizzard Research
project first. The intended flow is: verify current Retail source/API/template
behavior, build a small isolated sample addon when useful, LIVE-test the visual
and behavioral differences, and only then decide whether an OBB change is
worthwhile. This boundary does not imply that the current OBB Config requires a
redesign.

## 9. Validation baseline

The established static baseline at this checkpoint is:

- Core: `19 warnings / 0 errors`
- Config: `71 warnings / 0 errors`
- Managed: `31 warnings / 0 errors`
- Combined: `121 warnings / 0 errors`
- `git diff --check`: passed

The LuaCheck warnings are established WoW-global/style baseline warnings; there
are zero LuaCheck errors. The cumulative Config modernization through current
HEAD was successfully tested by the user on Retail LIVE.

## 10. Release history pointers

- v1.0.0 release commit:
  `6a7b7f7f967bc834251775b93b0aa149f7a9b5aa`
- Annotated release tag: `v1.0.0`
- Current post-release checkpoint:
  `58331025cece26c46b70b0094253994c93d75474`

The v1.0.0 release and tag are immutable. Current post-release work remains
Unreleased; any correction to v1.0.0 would require a later version rather than
moving the existing tag.
