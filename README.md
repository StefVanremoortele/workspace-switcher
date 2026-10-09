# workspace-switcher

An AutoHotkey v2 script for switching Windows virtual desktops, with a small Rust DLL for the Windows virtual-desktop COM APIs.

The script chooses a helper DLL based on the Windows build and the bitness of the running AutoHotkey process. This lets the same source package serve AMD64 PCs and Windows on ARM PCs through Windows' x86/x64 emulation.

## Requirements

- Windows 10 or Windows 11 on a supported build; see [Windows and architecture support](docs/compatibility.md).
- [AutoHotkey v2.0 or newer](https://www.autohotkey.com/). Use a 32-bit interpreter with the x86 DLL, or a 64-bit interpreter with the x64 DLL.
- The matching helper DLL under `bin\<backend>-<architecture>\vds.dll`. The current Windows 10 x64 checkout can also use the root `vds.dll` as a fallback.

## Run it

1. Install AutoHotkey v2. The official installer can install v2 alongside v1.
2. Keep `workspace-switcher.ahk` and the `bin` folder together (or, for the existing Windows 10 x64 setup, keep the root `vds.dll` beside the script).
3. Double-click `workspace-switcher.ahk`.

The script runs in the tray and is portable. It does not need administrator rights.

### Hotkeys

| Shortcut | Action |
| --- | --- |
| `Alt+Shift+1`..`9` | Switch to desktop 1..9, if it exists |
| `Alt+Shift+0` | Switch to the last desktop |
| `Alt+Shift+Left` / `Right` | Switch to the previous / next desktop, wrapping around |
| `Alt+Shift+P` | Pause or resume the terminal-only desktop guard |

### Terminal-only desktop guard

Desktop 2 (zero-based index 1) is reserved for terminal windows. Every 1.5 seconds, the script moves visible non-terminal application windows found there to desktop 1. The guard starts enabled; press `Alt+Shift+P` to pause or resume it. Set `DRY_RUN := true` near the top of the script to show tray notifications for would-be moves without moving windows.

After switching desktops, the script scans visible top-level windows in Z order and activates the first eligible window. It skips windows cloaked on another desktop, shell/tool windows, and windows without a title.

## Build the DLLs

Building requires Rust with the MSVC target toolchain and Visual Studio Build Tools with the C++ workload. From PowerShell at the repository root:

```powershell
.\scripts\build-dlls.ps1
```

The script installs the x86 and x64 Rust targets if needed, then writes eight DLLs under `bin\` (four Windows backends for each architecture). To build only one architecture:

```powershell
.\scripts\build-dlls.ps1 -Architecture x64
```

To build one backend manually, use one feature and one target at a time. For example:

```powershell
cargo build --release --locked --target x86_64-pc-windows-msvc --no-default-features --features win11_24h2
```

The matching output is `target\x86_64-pc-windows-msvc\release\vds.dll`. The default feature is `win10`; a plain `cargo build --release --locked` builds that backend for the Rust host architecture. Use the matrix script to produce the x86/x64 DLLs that the AutoHotkey script loads.

## How the version selection works

`workspace-switcher.ahk` reads `CurrentBuildNumber` and `UBR` from the Windows version registry key, then selects one backend. That matters because Windows' virtual-desktop COM interfaces are undocumented and have changed between Windows releases. The exact mapping and ARM emulation limits are in [docs/compatibility.md](docs/compatibility.md).

To report a compatibility issue, include the Windows build shown by `winver`, whether the device is AMD64 or ARM64, and whether AutoHotkey is running as x86 or x64.

## Source and dependencies

- `workspace-switcher.ahk` — AutoHotkey v2 hotkeys, window focus handling, and terminal guard.
- `src/lib.rs` — stable C exports consumed by the script.
- `vendor/winvd` — vendored Windows 10 `winvd` 0.0.20 source, with `HWND` corrected to pointer-sized; MIT license is included.
- `winvd` 0.0.45, 0.0.46, and 0.0.49 — pinned Windows 11 virtual-desktop backends selected through Cargo features.
- `scripts/build-dlls.ps1` — x86/x64 build matrix.

The Windows desktop COM interfaces are undocumented. The OS-specific backends reduce known version mismatches, but a future Windows update can still change these interfaces.
