# ⏳ XP Rate Control

A clean, modern GUI addon for managing experience rate adjustments and Joyous Journeys on WotLK 3.3.5a private servers (e.g. [ChromieCraft](https://www.chromiecraft.com)).

![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-blue?style=flat-square)
![Interface](https://img.shields.io/badge/Interface-30300-blue?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.0-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## ✨ Features

- **XP Rate Slider** — Smoothly adjust your XP rate from `0x` to `2x` with a draggable slider or direct numeric input
- **Quick Presets** — One-click buttons for common rates: `0x`, `0.5x`, `1x`, `1.5x`, `2x`
- **Joyous Journeys Toggle** — Enable or disable the 50% XP buff with a single checkbox
- **Minimap Button** — Draggable minimap icon with left-click (toggle panel) and right-click (quick menu)
- **Saved Settings** — Your last rate, minimap position, and preferences persist across sessions
- **Slash Commands** — Full command-line control via `/xp`
- **Dark Themed UI** — Sleek dark panel with color-coded rate indicators

---

## 📦 Installation

1. **Download** this repository (Code → Download ZIP) or clone it:
   ```
   git clone https://github.com/Zendevve/XPRateControl.git
   ```
2. **Copy** the `XPRateControl` folder into your WoW addons directory:
   ```
   World of Warcraft/Interface/AddOns/XPRateControl/
   ```
   > ⚠️ The folder name **must** be `XPRateControl` — it must match the `.toc` filename exactly.
3. **Restart** WoW or type `/reload` if you're already in-game.
4. Verify the addon is loaded in the character select screen under **AddOns**.

### Folder Structure

```
Interface/AddOns/XPRateControl/
├── XPRateControl.toc
├── XPRateControl.lua
└── README.md
```

---

## 🎮 Usage

### Opening the Panel

- **Click** the hourglass minimap button, or
- Type **`/xp`** in chat

### Adjusting XP Rate

1. Drag the **slider** or type a value in the **input box** (0.00 – 2.00)
2. Click **Apply Rate** to send the command to the server
3. Or use a **preset button** to instantly set and apply a rate

### Joyous Journeys

1. Check or uncheck the **Enabled** checkbox
2. Click **Apply** to toggle the 50% XP buff on the server

### Minimap Button

| Action | Result |
|---|---|
| **Left-Click** | Toggle the settings panel |
| **Right-Click** | Open quick rate menu |
| **Drag** | Reposition around the minimap |

---

## 💬 Slash Commands

| Command | Description |
|---|---|
| `/xp` | Toggle the settings panel |
| `/xp <0-2>` | Set XP rate directly (e.g. `/xp 1.25`) |
| `/xp minimap` | Show/hide the minimap button |
| `/xp help` | Display all available commands |

---

## 🎨 Rate Color Indicators

The displayed rate value changes color based on the current setting:

| Rate | Color | Label |
|---|---|---|
| `0x` | 🔴 Red | OFF |
| `0.01x – 0.99x` | 🟠 Orange | — |
| `1x` | 🟡 Gold | Blizzlike |
| `1.01x – 1.5x` | 🟢 Green | — |
| `1.51x – 2x` | 🔵 Cyan | Maximum (at 2x) |

---

## ⚙️ Server Commands

This addon sends the following chat commands to the server:

| Action | Server Command |
|---|---|
| Set XP rate | `.w r <rate>` |
| Toggle Joyous Journeys | `.weekendxp j <on\|off>` |

> **Note:** These commands are specific to [ChromieCraft](https://www.chromiecraft.com) and compatible AzerothCore servers. Your server may use different commands — modify the `SendXPCommand` and `SendJJCommand` functions in `XPRateControl.lua` if needed.

---

## 🔧 Configuration

All settings are saved automatically in `XPRateControlDB` (WTF saved variables):

| Setting | Default | Description |
|---|---|---|
| `lastRate` | `1.0` | Last applied XP rate |
| `minimapPos` | `45` | Minimap button angle (degrees) |
| `showMinimap` | `true` | Minimap button visibility |
| `jjEnabled` | `true` | Joyous Journeys checkbox state |

---

## 🖥️ Compatibility

- **WoW Version:** 3.3.5a (WotLK)
- **Interface:** 30300
- **Tested on:** [ChromieCraft](https://www.chromiecraft.com) (AzerothCore)
- **Dependencies:** None

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

## 👤 Author

**Zendevve**

---

*Made for the ChromieCraft community* 🎄
