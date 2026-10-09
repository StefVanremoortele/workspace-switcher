#Requires AutoHotkey v2.0
#SingleInstance Force

; Virtual Desktop Switcher - Alt+Shift+1-9
; Selects the matching OS-build and process-architecture DLL automatically.
VDS_DLL := ResolveBackendDll()
if !VDS_DLL
    ExitApp

; Terminal-only desktop guard. Indices are zero-based, matching the DLL:
; desktop 0 receives evicted windows and desktop 1 is terminal-only.
TERMINAL_DESKTOP := 1
EVICTION_DESKTOP := 0
DRY_RUN := false
CHECK_INTERVAL_MS := 1500
TERMINAL_PROCESSES := Map(
    "WindowsTerminal.exe", true,
    "WindowsTerminalPreview.exe", true,
    "wt.exe", true,
    "pwsh.exe", true,
    "powershell.exe", true,
    "cmd.exe", true,
    "conhost.exe", true,
    "OpenConsole.exe", true,
    "wezterm-gui.exe", true,
    "wezterm.exe", true,
    "alacritty.exe", true,
    "kitty.exe", true,
    "mintty.exe", true,
    "ConEmu64.exe", true
)
TERMINAL_GUARD_PAUSED := false
DRY_RUN_REPORTED := Map()

Loop 9 {
    n := A_Index
    HotKey "!+" n, SwitchVD.Bind(n)
}

HotKey "!+0", SwitchVDLast
HotKey "!+Left", SwitchVDRelative.Bind(-1)
HotKey "!+Right", SwitchVDRelative.Bind(1)
HotKey "!+p", ToggleTerminalGuard
SetTimer EnforceTerminalDesktop, CHECK_INTERVAL_MS

SwitchVD(n, *) {
    global VDS_DLL
    if (n > DllCall(VDS_DLL "\get_desktop_count", "int"))
        return
    DllCall(VDS_DLL "\switch_to_desktop", "uint", n - 1, "int")
    ActivateTopOnCurrentDesktop()
}

SwitchVDLast(*) {
    global VDS_DLL
    count := DllCall(VDS_DLL "\get_desktop_count", "int")
    if (count <= 0)
        return
    DllCall(VDS_DLL "\switch_to_desktop", "uint", count - 1, "int")
    ActivateTopOnCurrentDesktop()
}

SwitchVDRelative(delta, *) {
    global VDS_DLL
    count := DllCall(VDS_DLL "\get_desktop_count", "int")
    current := DllCall(VDS_DLL "\get_current_desktop", "int")
    if (count <= 0 || current < 0)
        return
    target := Mod(Mod(current + delta, count) + count, count)
    DllCall(VDS_DLL "\switch_to_desktop", "uint", target, "int")
    ActivateTopOnCurrentDesktop()
}

; Focus the topmost normal window after changing virtual desktops.
ActivateTopOnCurrentDesktop() {
    hwnd := DllCall("GetTopWindow", "ptr", 0, "ptr")
    while hwnd {
        if IsAltTabWindow(hwnd) {
            try WinActivate("ahk_id " hwnd)
            return
        }
        hwnd := DllCall("GetWindow", "ptr", hwnd, "uint", 2, "ptr") ; GW_HWNDNEXT
    }
}

IsAltTabWindow(hwnd) {
    if !DllCall("IsWindowVisible", "ptr", hwnd)
        return false
    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "int*", &cloaked, "uint", 4)
    if cloaked
        return false
    if WinGetExStyle("ahk_id " hwnd) & 0x80 ; WS_EX_TOOLWINDOW
        return false
    if WinGetTitle("ahk_id " hwnd) = ""
        return false
    cls := WinGetClass("ahk_id " hwnd)
    return (cls != "Progman" && cls != "WorkerW")
}

; Move non-terminal application windows off the terminal-only desktop.
EnforceTerminalDesktop() {
    global VDS_DLL, TERMINAL_DESKTOP, EVICTION_DESKTOP, DRY_RUN, TERMINAL_GUARD_PAUSED, DRY_RUN_REPORTED

    if TERMINAL_GUARD_PAUSED
        return
    if (DllCall(VDS_DLL "\get_desktop_count", "int") <= TERMINAL_DESKTOP)
        return

    for hwnd in WinGetList() {
        if !IsGuardableAppWindow(hwnd)
            continue
        if (DllCall(VDS_DLL "\is_window_on_desktop", "ptr", hwnd, "uint", TERMINAL_DESKTOP, "int") != 1)
            continue
        if IsTerminalWindow(hwnd)
            continue

        title := WinGetTitle("ahk_id " hwnd)
        if DRY_RUN {
            reportKey := hwnd ":" title
            if !DRY_RUN_REPORTED.Has(reportKey) {
                DRY_RUN_REPORTED[reportKey] := true
                TrayTip "Terminal guard (dry run)", "Would move: " title, 1
            }
            continue
        }
        DllCall(VDS_DLL "\move_window_to_desktop", "ptr", hwnd, "uint", EVICTION_DESKTOP, "int")
    }
}

IsGuardableAppWindow(hwnd) {
    if !DllCall("IsWindowVisible", "ptr", hwnd)
        return false
    if !WinGetTitle("ahk_id " hwnd)
        return false
    if WinGetExStyle("ahk_id " hwnd) & 0x80 ; WS_EX_TOOLWINDOW
        return false
    cls := WinGetClass("ahk_id " hwnd)
    return (cls != "Progman" && cls != "WorkerW" && cls != "Shell_TrayWnd")
}

IsTerminalWindow(hwnd) {
    global TERMINAL_PROCESSES
    try return TERMINAL_PROCESSES.Has(WinGetProcessName("ahk_id " hwnd))
    catch
        return false
}

ToggleTerminalGuard(*) {
    global TERMINAL_GUARD_PAUSED
    TERMINAL_GUARD_PAUSED := !TERMINAL_GUARD_PAUSED
    state := TERMINAL_GUARD_PAUSED ? "paused" : "running"
    TrayTip "Terminal guard", "Terminal-only enforcement is " state ".", 1
}

ResolveBackendDll() {
    currentVersionKey := "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    try {
        build := RegRead(currentVersionKey, "CurrentBuildNumber") + 0
        ubr := RegRead(currentVersionKey, "UBR", 0) + 0
    } catch Error as err {
        MsgBox "Could not read the Windows build number." "`n`n" err.Message,
            "VD Switcher", 16
        return ""
    }

    if (build < 22000) {
        backend := "win10"
    } else if (build < 22621) {
        message := "Windows 11 build " build " is not supported by the bundled backends."
        message .= "`nUpdate Windows to build 22621 or newer, then restart this script."
        MsgBox message, "VD Switcher", 48
        return ""
    } else if (build < 22631) {
        backend := "win11_22h2"
    } else if (build < 26100) {
        backend := "win11_23h2"
    } else {
        if (build > 26200) {
            message := "Windows build " build " is newer than the latest mapped virtual-desktop backend."
            message .= "`nSee README.md for supported builds and updates."
            MsgBox message, "VD Switcher", 48
            return ""
        }
        if (build = 26100 && ubr < 2605) {
            message := "Windows build 26100." ubr " needs a newer cumulative update."
            message .= "`nInstall updates through build 26100.2605 or newer, then restart this script."
            MsgBox message, "VD Switcher", 48
            return ""
        }
        backend := "win11_24h2"
    }

    architecture := (A_PtrSize = 8) ? "x64" : "x86"
    dllPath := A_ScriptDir "\bin\" backend "-" architecture "\vds.dll"

    ; Keep the existing Windows 10 x64 checkout runnable before the full
    ; multi-architecture package has been built or downloaded.
    if (!FileExist(dllPath) && backend = "win10" && architecture = "x64") {
        legacyPath := A_ScriptDir "\vds.dll"
        if FileExist(legacyPath)
            dllPath := legacyPath
    }

    if !FileExist(dllPath) {
        message := "No helper DLL was found for Windows build " build " (" architecture ")."
        message .= "`nExpected: " dllPath
        message .= "`n`nSee README.md for the build and compatibility matrix."
        MsgBox message, "VD Switcher", 16
        return ""
    }

    return dllPath
}
