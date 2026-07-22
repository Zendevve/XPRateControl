# XP Rate Control

A clean, modern GUI addon for managing experience rate adjustments and Joyous Journeys on WotLK 3.3.5a private servers (such as ChromieCraft).

![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-blue?style=flat-square)
![Interface](https://img.shields.io/badge/Interface-30300-blue?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.1-green?style=flat-square)

---

## Features

- **Tabbed Interface** — Three distinct, task-focused tabs (Rates, Automation, Buffs) contained in a compact 320x300 window.
- **Speedometer Dial & Pulse** — Visual gauge displaying your current rate, complete with a scaling text pulse on change and a category tag chip (`OFF`, `SLOW`, `BLIZZLIKE`, `FAST`, `MAX`).
- **Custom Slider** — Features a custom vertical pill thumb, a left-to-right fill track colored dynamically by the current rate, and a floating value bubble during dragging.
- **Apply-on-Change Semantics** — Standalone apply buttons are removed. Value modifications (via slider, checkboxes, presets, or inputs) are committed to the server instantly.
- **In-Panel Toasts** — Provides non-intrusive, bottom-of-panel toast notifications (e.g., `Sent 1.50x ✓`) to confirm action success.
- **Rested XP Automation** — Allows auto-switching rates when you enter or leave Rested state. Features preset rows and manual editboxes for both Rested and Normal states.
- **Quest Turn-in Automation** — Automatically switches to a designated rate (default `2.00x`) when interacting with Quest NPCs and restores your previous rate when the quest window closes.
- **Escape Key Reversion** — Pressing ESC inside any rate input field cancels the edit, reverting the text and focus without applying unintended changes.
- **Window Position Persistence** — The panel's drag position is saved in `XPRateControlDB` and restored on login.
- **Minimap Icon State** — Tint of the minimap button hourglass icon updates dynamically to match the active rate's color. Flashes orange when automation switches rates.

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
├── XPRateControl.toc
├── XPRateControl.lua
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

### Automation Tab
- Use the sub-tab dropdown menu to configure **Auto Rested XP**, **Party Auto Scaling**, **Mob Difficulty Scaling**, or **Quest Turn-In Scaling**.
- Toggle **Auto-switch on Quest Interaction** to automatically enforce your Quest Interaction Rate while talking to Quest NPCs.

### Buffs Tab
- Check **Enable Joyous Journeys Buff** to toggle the 50% experience gain buff. The large central card lights up when active and desaturates when inactive.

### Minimap Button Actions
- **Left-Click** — Toggles the settings panel.
- **Right-Click** — Opens a quick rate menu.
- **Drag** — Repositions the button around the minimap border.

---

## Slash Commands

| Command | Description |
|---|---|
| `/xp` | Toggle the settings panel |
| `/xp <0-2>` | Set and apply XP rate directly (e.g., `/xp 1.25`) |
| `/xp minimap` | Toggle visibility of the minimap button |
| `/xp help` | Display available commands |

---

## Rate Color Indicators

The addon uses color indicators for different rate ranges:

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
Settings persist across sessions in the `XPRateControlDB` saved variable:
- `lastRate` — Last applied rate (default: `1.0`).
- `minimapPos` — Angle position of the minimap button (default: `45`).
- `showMinimap` — Visibility state of the minimap button (default: `true`).
- `autoRested` — Enabled state of rested XP auto-switching (default: `false`).
- `restedRate` — Rate to switch to when Rested (default: `2.0`).
- `normalRate` — Rate to switch to when Normal (default: `1.0`).
- `autoQuest` — Enabled state of quest interaction auto-switching (default: `false`).
- `questRate` — Rate to switch to during Quest interactions (default: `2.0`).
- `jjEnabled` — Joyous Journeys buff state (default: `true`).
- `framePos` — Coordinates and anchors of the main panel.
