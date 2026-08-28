# Odysseus Buff Bars

Odysseus Buff Bars is a configurable aura-bar addon for World of Warcraft
Retail. It presents player buffs, debuffs, and enhancements in three focused
groups while retaining Blizzard's managed aura behavior for supported rows.

## Aura groups

- **BUFFS** displays helpful player auras. It supports All or Timed Only
  duration modes, sorting, a maximum bar count, and Spell ID-based whitelist
  or blacklist filtering.
- **DEBUFFS** displays eligible harmful player auras. It is intentionally broad
  and does not apply the BUFFS destination filters.
- **ENCHANTMENTS** combines automatically routed enhancements, native temporary
  Main Hand and Off Hand weapon enchantments, and Fishing Lure tracking. Its
  managed enhancement sources are intentionally broad.

The addon automatically routes readable enhancement effects such as food,
flasks or phials, augment runes, and fishing bobbers into ENCHANTMENTS. Manual
Spell ID overrides can hide a helpful aura or route it between BUFFS and
ENCHANTMENTS.

Native temporary weapon-enchantment rows retain Blizzard's slot presentation,
inventory tooltip, duration handling, and supported right-click cancellation.
Fishing Lure is tracked separately from those native rows and has no
cancellation action.

## Configuration

Open the configuration window while out of combat with:

- `/obb`
- `/buffbars`
- `/obb config`
- `/obb options`

Other user commands:

- `/obb anchors` toggles the draggable group title bars.
- `/obb refresh` reapplies the current managed configuration out of combat. In
  combat it safely leaves Blizzard's managed aura lifecycle authoritative.

Configuration changes and anchor dragging are protected during combat.

The General page provides one global LibSharedMedia status-bar texture and one
global LibSharedMedia font face shared by BUFFS, DEBUFFS, and ENCHANTMENTS.
Each group retains its own independent font size and other bar settings.
General also contains Override Settings for manual Spell ID routing or hiding.

## Positioning and Blizzard frames

BUFFS is a screen-root group. DEBUFFS can be placed on screen or below, left,
or right of BUFFS; ENCHANTMENTS can be placed on screen or below, left, or
right of DEBUFFS. Screen-root groups can be dragged by their visible title bar
while anchors are unlocked and the player is out of combat.

Blizzard Edit Mode remains the supported owner of the default Aura Frame's
visibility. Use Edit Mode's Aura Frame **Hidden** setting when the default
Blizzard aura icons should stay hidden. Odysseus Buff Bars also provides a
best-effort convenience toggle for the default frames, but Blizzard may
reassert its own visibility policy.

## Installation

1. Download the curated OdysseusBuffBars addon ZIP attached to a GitHub
   Release. GitHub's automatically generated source archives are not the
   installable addon package.
2. Extract the `OdysseusBuffBars` folder into
   `World of Warcraft/_retail_/Interface/AddOns/`.
3. Confirm that `OdysseusBuffBars.toc` is directly inside that folder, then
   enable **Odysseus Buff Bars** on the character-selection AddOns screen.

## Current limitations

- World of Warcraft Retail is the only supported game flavor.
- Automatic semantic enhancement classification is currently designed and
  tested around readable English aura and spell text. Recognition of terms
  such as Well Fed, flask/phial, augment rune, and Fishing Lure or bobber
  semantics may not behave identically on non-English clients. Manual Spell ID
  routing and overrides provide a fallback for helpful auras.
- BUFFS alone provides destination whitelist/blacklist filtering; DEBUFFS and
  ENCHANTMENTS intentionally remain broad.
- Blizzard does not expose a supported public mapping from a temporary weapon
  enchant ID to a clean effect name, so native weapon rows retain their
  equipped-slot presentation and tooltip context.
- Fishing Lure cancellation is not provided.
- Profiles and a minimap launcher are not currently included.

Broader localization, additional class/effect/lure coverage, opportunistic
Off Hand and dual-slot validation, private-harmful-aura testing, and further
Fishing Lure research remain future work.

## License

OdysseusBuffBars-owned code is licensed under the MIT License; see
[LICENSE](LICENSE). Bundled libraries are separate third-party works and are
not covered by that license. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the third-party boundary.

Detailed architecture, validation, migration, and research history is retained
under [Documentation](Documentation/README.md).
