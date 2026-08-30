# Changelog

This is the canonical public release changelog for OdysseusBuffBars. Detailed
development chronology is preserved separately in
`Documentation/CHANGELOG.md`.

## Unreleased

### ⭐ Added

- Added a minimap launcher for opening OdysseusBuffBars configuration.
- Added a Retail Addon Compartment entry for opening configuration.
- Added new OdysseusBuffBars production artwork and icon assets.
- Added the first Midnight-style configuration shell and placed the production
  logo at the top of the scrollable General page.

### Changed

- Synchronized the BUFFS filter editor and Override Settings with the Midnight
  Config theme in the same fixed right-side companion slot. Override Settings
  now has a compact editor with a current-spell candidate selector and a
  structured, scrollable saved-override list with direct row removal. Texture
  and Font picker popups now use solid Midnight backgrounds. Added an immediate
  Config-only UI Scale control from 75% through 125% in 5% increments; the
  Config and its companion/popup descendants inherit that scale without
  changing aura bars or anchors. Filtering and override semantics remain
  unchanged. Retail LIVE testing accepted the complete cumulative Config polish.
- Replaced the interim Config slider arrows with Blizzard's native minimal
  sliders and steppers, retained 46-pixel same-row numeric inputs, and corrected
  the minimum Config size so the full BUFFS page remains visible. Tightened the
  General-page top spacing and placed its three primary checkboxes on one row.
  LIVE visual testing finalized the minimum window at `680 x 610`, and the
  General scroll extent now ends 20 pixels below its bottom-most visible content.
  Retail LIVE testing accepted the native slider rendering, dragging, steppers,
  same-row value boxes, compact General layout, and scrollbar auto-hide behavior.

## OdysseusBuffBars v1.0.0

**Release date:** 2026-08-28

### Overview

OdysseusBuffBars is a configurable aura-bar addon for World of Warcraft
Retail. It presents the player's helpful auras, harmful auras, and enhancements
as three focused BUFFS, DEBUFFS, and ENCHANTMENTS groups while retaining
Blizzard's managed aura behavior for supported rows, including native updates,
timers, tooltips, sorting, and supported cancellation.

### Aura groups and controls

- **BUFFS** displays helpful player auras with All or Timed Only duration
  modes, configurable sorting and maximum bar count, and Spell ID-based
  whitelist or blacklist filtering.
- **DEBUFFS** displays eligible harmful player auras. It is intentionally broad
  so important harmful effects are not removed by BUFFS-style destination
  filters.
- **ENCHANTMENTS** combines automatically routed helpful enhancements, native
  temporary Main Hand and Off Hand weapon enchantments, and a separate Fishing
  Lure row. Its managed enhancement sources are intentionally broad.

Each group provides configurable bar dimensions, spacing, font size, colors,
background opacity, icon side, scale, alpha, and growth direction, with sorting
and maximum-count controls where supported. Shared-group synchronization can
apply common bar settings while preserving each group's position. One global
LibSharedMedia status-bar texture and one global LibSharedMedia font face apply
across all three groups, with previews available in the General configuration
page.

### Routing, filtering, and enhancements

OdysseusBuffBars automatically routes readable food, flask or phial, augment
rune, and fishing-bobber effects into ENCHANTMENTS. Manual numeric Spell ID
overrides can hide a helpful aura or route it between BUFFS and ENCHANTMENTS.
BUFFS also provides manual Spell ID whitelist and blacklist entries, including
entries for auras that are not currently active.

Automatic semantic recognition is designed and tested around readable English
aura and spell text. It may not classify equivalent effects correctly on
non-English clients; manual Spell ID routing and overrides remain the fallback
when automatic recognition does not classify a helpful aura correctly.

Native temporary weapon-enchantment rows retain Blizzard's equipped-slot
presentation, inventory tooltip, duration handling, and supported non-combat
right-click cancellation. Fishing Lure tracking is presented separately for an
equipped fishing profession tool and does not provide a cancellation action.

### Positioning and persistence

BUFFS is positioned as a screen-root group. DEBUFFS can be placed on screen or
below, left, or right of BUFFS; ENCHANTMENTS can be placed on screen or below,
left, or right of DEBUFFS. Screen-root groups can be dragged by their title bars
while anchors are unlocked and the player is out of combat. Positions, group
settings, media selections, filters, and overrides persist through
`OdysseusBuffBarsDB` SavedVariables.

Blizzard Edit Mode remains the supported owner of the default Aura Frame's
visibility. Use Edit Mode's Aura Frame **Hidden** setting for persistent control
of Blizzard's icons. The addon's own default-frame visibility option is a
best-effort out-of-combat convenience and does not replace Blizzard's policy.

### Commands

- `/obb`, `/buffbars`, `/obb config`, or `/obb options` opens configuration
  while out of combat.
- `/obb anchors` toggles the draggable group title bars while out of combat.
- `/obb refresh` reapplies the current managed configuration out of combat and
  safely leaves Blizzard's managed aura lifecycle authoritative in combat.

Configuration changes and dragging are protected during combat. This release
supports World of Warcraft Retail only. BUFFS is the only group with destination
whitelist/blacklist filtering; DEBUFFS and ENCHANTMENTS intentionally remain
broad. Temporary weapon-enchantment effect names are limited to Blizzard's
supported equipped-slot presentation and tooltip context. Profiles and a
minimap launcher are not included in v1.0.0.
