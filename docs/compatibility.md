# Windows and architecture support

The desktop COM APIs used by this project are undocumented and have changed between Windows builds. The script checks the OS build and picks the matching helper backend. `winver` shows the Windows version and build number; the `UBR` value is the revision after the dot (for example, build `26100.2605`).

## Windows build matrix

| Windows build | Backend selected | DLL feature | Notes |
| --- | --- | --- | --- |
| Windows 10 client, build below 22000 | `win10` | `win10` / `winvd` 0.0.20 | Windows 10 backend. The current project was confirmed working on Windows 10 build 19045. |
| Windows 11, builds 22000–22620 | Unsupported | — | Update to Windows 11 build 22621 or later. |
| Windows 11, builds 22621–22630 | `win11_22h2` | `win11_22h2` / `winvd` 0.0.45 | Upstream marks this backend for Windows 11 build 22621 and newer. |
| Windows 11, builds 22631–26099 | `win11_23h2` | `win11_23h2` / `winvd` 0.0.46 | Upstream released this backend for Windows 11 23H2 build 22631.3085. |
| Windows 11 build 26100 revision 2605 or later through build 26200 | `win11_24h2` | `win11_24h2` / `winvd` 0.0.49 | Upstream requires at least 26100.2605 and reports testing through Windows 11 25H2 build 26200.8117. |

Windows 11 build 26100 with a revision below 2605 is rejected with an update message. Builds 22000–22620 are also rejected, because this project's supported Windows 11 backends start at build 22621. Builds above 26200, including Windows 11 26H1 and 26H2, are rejected until a backend is mapped and verified for them. Windows Server builds are outside this project's runtime support matrix.

The ranges follow the upstream backend release notes: [`winvd` 0.0.45](https://docs.rs/crate/winvd/0.0.45), [the 23H2 backend release](https://github.com/Ciantic/VirtualDesktopAccessor/releases/tag/2024-01-25-windows11), and [`winvd` 0.0.49](https://docs.rs/crate/winvd/0.0.49). The Windows 10 backend comes from [`winvd` 0.0.20](https://crates.io/crates/winvd/0.0.20). Microsoft's [Windows 11 release information](https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information) lists newer build families; this project does not assume that the undocumented interface remains unchanged on them.

## AMD64 and ARM64

Every DLL must have the same bitness as the running AutoHotkey process. AutoHotkey's pointer size determines whether the script selects the `x86` or `x64` DLL folder.

| Device / Windows | AutoHotkey process | Helper DLL | How it runs |
| --- | --- | --- | --- |
| AMD64, Windows 10 or 11 | x64 (recommended) | x64 | Native AMD64 |
| AMD64, Windows 10 or 11 | x86 | x86 | Windows x86-on-x64 emulation |
| ARM64, Windows 10 | x86 | x86 | Windows x86 emulation; Windows 10 on ARM does not emulate x64 apps |
| ARM64, Windows 11 | x64 | x64 | Windows x64 emulation |
| ARM64, Windows 11 | x86 | x86 | Windows x86 emulation |

This repository provides x86 and x64 builds, not an ARM64-native AutoHotkey/DLL pair. On ARM64, run the matching x86 or x64 process under Windows emulation. Microsoft's [Windows on Arm emulation guide](https://learn.microsoft.com/en-us/windows/arm/apps-on-arm-x86-emulation) documents the x86-only emulation support in Windows 10 on ARM and x86/x64 support in Windows 11 on ARM.

## Installation and troubleshooting

1. Install AutoHotkey v2.0 or newer. If both v1 and v2 are installed, open the script with AutoHotkey v2 or explicitly use the v2 interpreter.
2. Build or obtain the DLL for the OS family and process architecture, keeping this layout:

   ```text
   bin/
     win10-x86/vds.dll
     win10-x64/vds.dll
     win11_22h2-x86/vds.dll
     win11_22h2-x64/vds.dll
     win11_23h2-x86/vds.dll
     win11_23h2-x64/vds.dll
     win11_24h2-x86/vds.dll
     win11_24h2-x64/vds.dll
   ```

3. Keep `workspace-switcher.ahk` next to `bin` and launch it.

If the script reports a missing DLL, confirm the folder name matches your Windows build and AutoHotkey bitness. If Windows updates to a newer major build, the current backend may need to be revised because the COM interfaces are not a stable public API. The release-specific backend can be rebuilt with `scripts/build-dlls.ps1`.

### Runtime verification status

The user's Windows 10 x64 machine (build 19045) has run the Windows 10 backend successfully. Other Windows 10 builds, Windows 11 builds, x86 execution, and ARM emulation have not been runtime-verified here. The build script creates those variants; it does not certify behavior on every OS/processor combination.
