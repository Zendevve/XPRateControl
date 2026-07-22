# XP Rate Control

A clean, modern GUI addon for managing experience rate adjustments and Joyous Journeys on WotLK 3.3.5a private servers (such as ChromieCraft).

![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-blue?style=flat-square)
![Interface](https://img.shields.io/badge/Interface-30300-blue?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.2-green?style=flat-square)
![License](https://img.shields.io/badge/License-All_Rights_Reserved-red?style=flat-square)

---

## Features

- **Tabbed Interface** — Three distinct, task-focused tabs (Rates, Automation, Buffs) contained in a compact 320x300 window.
- **Speedometer Dial & Pulse** — Visual gauge displaying your current rate, complete with a scaling text pulse on change and a category tag chip (`OFF`, `SLOW`, `BLIZZLIKE`, `FAST`, `MAX`).
- **Custom Slider** — Features a custom vertical pill thumb, a left-to-right fill track colored dynamically by the current rate, and a floating value bubble during dragging.
- **Apply-on-Change Semantics** — Standalone apply buttons are removed. Value modifications (via slider, checkboxes, presets, or inputs) are committed to the server instantly.
- **In-Panel Toasts** — Provides non-intrusive, bottom-of-panel toast notifications (e.g., `Sent 1.50x ✓`) to confirm action success.
- **6-Module Advanced Automation Engine (v1.2)**:
  - **Level Bracket Auto-Scaling** — Set custom rates per level bracket (1–59, 60–69, 70–79, 80). Rate updates automatically upon leveling up.
  - **Zone / Instance Type Auto-Scaling** — Location-aware rate switching for Open World, 5-Man Dungeons, Raids, and Battlegrounds/Arenas via `IsInInstance()`.
  - **Smart Party Level Disparity Protection** — Automatically dampens XP rate when group members lag behind by a configurable level threshold (e.g., >5 levels).
  - **Party Size Scaling** — Auto-scales rates based on group size (1P–5P).
  - **Mob Difficulty Scaling** — Auto-adjusts rate depending on targeted enemy difficulty color (Gray, Green, Yellow, Orange/Red).
  - **Quest Turn-in Automation** — Automatically switches to a designated rate (default `2.00x`) when interacting with Quest NPCs and restores previous rate on close.
- **Tiered Priority Hierarchy Evaluator** — Prevents automation conflicts using strict priority order: `Quest NPC > Zone/Instance > Level Bracket > Mob Difficulty > Party Disparity/Scaling > Rested XP`.
- **Notification Suppression & Quiet Automation Mode (v1.3)** — Fine-grained control over chat messages, toast alerts, and automatic rate-switching notifications. Quiet Automation suppresses all popups and chat messages during automatic rate transitions for seamless gameplay.
- **Escape Key Reversion** — Pressing ESC inside any rate input field cancels the edit, reverting the text and focus without applying unintended changes.
- **Window Position Persistence** — Panel drag position is saved in `XPRateControlDB` and restored on login.
- **Minimap Icon State** — Hourglass icon tint updates dynamically to match active rate color. Flashes orange when automation switches rates.

---

## Installation

1. Copy the `XPRateControl` folder into your World of Warcraft AddOns directory:
   ```
   World of Warcraft/Interface/AddOns/XPRateControl/
   ```
   *Note: The folder name must be exactly `XPRateControl` to match the `.toc` file.*
2. Restart the game or type `/reload` if you are already logged in.

### Folder Structure
```
Interface/AddOns/XPRateControl/
├── Core/
│   ├── Config.lua
│   ├── Network.lua
│   └── UIHelpers.lua
├── Engine/
│   └── Automation.lua
├── UI/
│   ├── MainFrame.lua
│   ├── MinimapButton.lua
│   ├── TabAutomation.lua
│   ├── TabBuffs.lua
│   └── TabRates.lua
├── Init.lua
├── XPRateControl.toc
└── README.md
```

---

## Usage

### Opening the Panel
- Click the hourglass minimap button, or
- Type `/xp` in the chat window.

### Rates Tab
- Drag the **custom slider** or type a value in the **numeric editbox** (0.00 – 2.00). Changes apply immediately on drag release, Enter key press, or focus lost.
- Click any **preset button** to instantly set and apply common rates (`0x`, `0.5x`, `1x`, `1.5x`, `2x`).
- Toggle notification settings in the **NOTIFICATIONS** card:
  - **Chat Messages** — Enable/disable chat box confirmation messages.
  - **Toast Alerts** — Enable/disable floating toast alerts.
  - **Quiet Automation** — Suppress all alerts during automated rate switches.

### Automation Tab
- Select from **7 automation sub-tabs** using the header dropdown menu:
  1. **AUTO RESTED XP** — Configure Rested vs Normal rates.
  2. **PARTY SIZE SCALING** — Set 1P–5P group size rates.
  3. **PARTY LEVEL DISPARITY** — Configure party level gap protection threshold and rate.
  4. **MOB DIFFICULTY SCALING** — Assign rates for Gray, Green, Yellow, and Red target mobs.
  5. **QUEST TURN-IN SCALING** — Auto-switch rate during quest giver interactions.
  6. **LEVEL BRACKET SCALING** — Define custom rates across character level ranges.
  7. **ZONE / INSTANCE SCALING** — Assign rates for Open World, 5-Man Dungeons, Raids, and BGs/Arenas.

### Buffs Tab
- Check **Enable Joyous Journeys Buff** to toggle the 50% experience gain buff. The large central card lights up when active and desaturates when inactive.

---

## Slash Commands

| Command | Description |
|---|---|
| `/xp` | Toggle the settings panel |
| `/xp <0-2>` | Set and apply XP rate directly (e.g., `/xp 1.25`) |
| `/xp auto [status\|on\|off]` | Master automation toggle or status check |
| `/xp zone [on\|off]` | Toggle zone / instance auto-scaling |
| `/xp bracket [on\|off]` | Toggle level bracket auto-scaling |
| `/xp disparity [on\|off]` | Toggle party level disparity protection |
| `/xp group [on\|off]` | Toggle party size auto-scaling |
| `/xp mob [on\|off]` | Toggle mob difficulty auto-scaling |
| `/xp quest [on\|off]` | Toggle quest interaction scaling |
| `/xp rested [on\|off]` | Toggle rested XP auto-scaling |
| `/xp chat [on\|off]` | Toggle chat message notifications |
| `/xp toast [on\|off]` | Toggle toast alert notifications |
| `/xp quiet [on\|off]` | Toggle quiet automation mode |
| `/xp status` | Display detailed automation status summary |
| `/xp minimap` | Toggle visibility of the minimap button |
| `/xp help` | Display available slash commands |

---

## Rate Color Indicators

| Rate | Color | Label |
|---|---|---|
| `0x` | Red | OFF |
| `0.01x – 0.99x` | Orange | SLOW |
| `1.00x` | Gold | BLIZZLIKE |
| `1.01x – 1.99x` | Green | FAST |
| `2.00x` | Cyan | MAX |

---

## Technical Information

### Server Commands
The addon issues standard AzerothCore chat commands:
- **Set XP rate** — `.w r <rate>` (Sends `1e-45` for `0x` to disable experience gain).
- **Toggle Joyous Journeys** — `.weekendxp j <on|off>`.

### Saved Variables
Settings persist across sessions in `XPRateControlDB`:
- `lastRate` — Last applied rate (default: `1.0`).
- `autoZone` & `zoneRates` — Location-based rates for world, dungeon, raid, and pvp.
- `autoBracket` & `bracketRates` — Level range brackets and assigned rates.
- `autoDisparity`, `disparityThreshold`, `disparityRate` — Level gap threshold and rate.
- `autoGroup` & `groupRates` — Rates mapped to group sizes (1P–5P).
- `autoMob` & `mobRates` — Enemy difficulty category rates.
- `autoQuest` & `questRate` — Quest NPC interaction rate.
- `autoRested`, `restedRate`, `normalRate` — Rested state rates.
- `showChat` — Enable/disable chat box notifications (default: `true`).
- `showToast` — Enable/disable floating toast alerts (default: `true`).
- `quietAuto` — Enable/disable quiet automation mode (default: `false`).
- `jjEnabled` — Joyous Journeys buff state.
- `minimapPos` & `showMinimap` — Minimap icon angle and visibility.
- `framePos` — Panel position coordinates.
