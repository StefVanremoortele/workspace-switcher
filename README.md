# workspace-switcher

`Alt+Shift+1`..`Alt+Shift+9` — instant switching to virtual desktop 1..9 on Windows 11.

AutoHotkey v2 binds the hotkeys; a tiny Rust DLL does the actual COM work via the
[`winvd`](https://crates.io/crates/winvd) crate. No subprocess overhead — each hotkey
is a direct `DllCall`.

After switching, focus is moved to the topmost real window on the new desktop, so
typing goes to that window instead of the (now-hidden) window you came from.

## Run it

1. Make sure [AutoHotkey v2](https://www.autohotkey.com/) is installed.
2. Double-click `workspace-switcher.ahk`. A tray icon appears.
3. Press `Alt+Shift+N` to jump to desktop N.

That's it. The folder is self-contained and **fully portable** — move it anywhere,
the AHK script resolves `vds.dll` relative to itself.

## Files

| File                      | Purpose                                                         |
| ------------------------- | --------------------------------------------------------------- |
| `workspace-switcher.ahk`  | Hotkey bindings; calls into `vds.dll`                           |
| `vds.dll`                 | Built x64 helper (winvd → IVirtualDesktopManagerInternal)       |
| `Cargo.toml`, `src/lib.rs`| Source for `vds.dll`                                            |
| `Cargo.lock`              | Pinned dependency versions                                      |
| `rust-toolchain.toml`     | Pins the x64 MSVC toolchain (works regardless of folder path)   |

## Focus follows the switch

`winvd::switch_desktop` changes which desktop is visible but does not transfer
keyboard focus — the previously-active window stays foreground even though it is
now cloaked, so keystrokes leak to the desktop you just left.

The script fixes this in pure AHK (no DLL involvement): after the switch it walks
top-level windows in Z order and activates the first one that is on the new desktop.
"On this desktop" is detected via `DwmGetWindowAttribute(..., DWMWA_CLOAKED, ...)` —
windows the shell has hidden on other virtual desktops report as cloaked, so
skipping cloaked + toolwindows + `Progman`/`WorkerW` lands on the topmost real app.

## Rebuilding `vds.dll`

Required once: Visual Studio Build Tools 2022 with the C++ workload, and the x64
Rust toolchain (`rustup toolchain install stable-x86_64-pc-windows-msvc --force-non-host`
on ARM64 Windows; just `stable-x86_64-pc-windows-msvc` on x64).

From a Developer PowerShell (so `link.exe` is on `PATH`):

```powershell
cargo build --release
copy target\release\vds.dll .
```

`rust-toolchain.toml` makes cargo pick the x64 toolchain automatically.

## Why an x64 DLL on ARM64 Windows?

AutoHotkey ships only x86 / x64 binaries — `AutoHotkey64.exe` runs under WoW64
emulation. A `DllCall` target must match the host process architecture, hence x64.

## Updating `winvd`

If a future Windows build breaks switching, bump the `winvd` version in `Cargo.toml`
and rebuild. The crate's maintainer tracks new builds — see
[github.com/Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor).
"# workspace-switcher" 
