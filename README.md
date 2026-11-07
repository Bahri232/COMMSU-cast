# ComSSU Cast — Wireless Display System

[[https://img.shields.io/badge/version-1.0.0-blue.svg]](https://github.com/Bahri232/COMMSU-cast/releases)
[[https://img.shields.io/badge/academic%20year-2026%2F27-green.svg]](https://unimak.edu.sl)
[[https://img.shields.io/badge/society-ComSSU%20UniMak-orange.svg]](https://unimak.edu.sl)
[[https://img.shields.io/badge/License-GPLv3-blue.svg]](https://www.gnu.org/licenses/gpl-3.0)

> **"Engineered for cross-platform wireless screen projection (AirPlay, Miracast, Google Cast) for large-format interactive flat panel displays."**

**ComSSU Cast** turns computers and interactive flat panels into dedicated wireless presentation receivers. Designed for lecture halls, laboratories, and conference environments, it allows students, faculty, and presenters to mirror screens instantly from iPhones, iPads, Macs, Windows laptops, and Android devices without installing proprietary third-party software.

---

## Key Highlights

- **Multi-Protocol Receiver:** Accepts connections via Apple AirPlay, Microsoft Miracast (MS-MICE), Google Cast, and DLNA.
- **Optimized for 85" Interactive Displays:** Default fullscreen kiosk mode designed for large-format 4K interactive touch panels.
- **Zero Client Software:** Presenters use their operating system's built-in cast controls.
- **Dual-Layer Security:** Prominently displays a dynamic **4-digit PIN** on the idle HUD alongside an interactive **Allow / Deny** authorization dialog for incoming streams.
- **Hardware-Accelerated Decoding:** Low-latency H.264/H.265 video pipelines paired with synchronized audio playback via GStreamer.
- **Network Broadcast Name:** Broadcasts across local networks as **`CS Society Display`**.

---

## Supported Protocols

| Protocol | Source Devices | Native Menu / Method | Status |
| :--- | :--- | :--- | :--- |
| **AirPlay 2** | iPhone, iPad, Mac | Control Center → Screen Mirroring | Supported (Hardware H.264 & AAC Audio) |
| **Miracast (MS-MICE)** | Windows 10 / 11 | `Win + K` (Cast Menu) | Supported (Infrastructure mode) |
| **Google Cast** | Chrome Browser, Android | Cast Screen / Smart View | Supported (CastV2 streaming receiver) |
| **DLNA** | Android, media controllers | Cast media / DLNA share | Supported |



## Quick Start (Prebuilt Executable)

Precompiled binaries are published on the [Releases](https://github.com/Bahri232/COMMSU-cast/releases) page. No installation required:

| Platform | Package | How to Run |
| :--- | :--- | :--- |
| **Windows 10/11 (x64)** | `ComSSUCast-windows-x64.zip` | Extract and run `ComSSUCast.exe` |
| **Linux (x86_64, glibc 2.35+)** | `ComSSUCast-linux-x86_64.AppImage` | `chmod +x ComSSUCast-*.AppImage && ./ComSSUCast-*.AppImage` |
| **macOS 13+ (Apple Silicon)** | `ComSSUCast-macos-arm64.dmg` | Open the `.dmg` and launch `ComSSUCast` |

> **Network Note:** Presenters and the receiver must be on the same local network subnet. When running `ComSSUCast.exe` on Windows for the first time, allow network access on Private networks when prompted by Windows Defender Firewall.

---

## Building From Source

### Windows (MSYS2 / UCRT64)

1. Install [MSYS2](https://www.msys2.org/). Open the **MSYS2 UCRT64** terminal and install the toolchain:
   ```bash
   pacman -S --needed git mingw-w64-ucrt-x86_64-{toolchain,cmake,ninja,pkgconf,qt6-base,qt6-declarative,qt6-tools,gstreamer,gst-plugins-base,gst-plugins-good,gst-plugins-bad,gst-plugins-ugly,gst-libav,openssl,libupnp,libplist,protobuf,gtest}
