#Requires AutoHotkey v2.0
#SingleInstance Force

; Virtual Desktop Switcher - Alt+Shift+1-9
; Calls vds.dll (Rust + winvd crate) directly via DllCall.

VDS_DLL := A_ScriptDir "\vds.dll"

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

if !FileExist(VDS_DLL) {
    MsgBox "vds.dll not found in " A_ScriptDir, "VD Switcher", 48
    ExitApp
}

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
        hwnd := DllCall("GetWindow", "ptr", hwnd, "uint", 2, "ptr")  ; GW_HWNDNEXT
    }
}

IsAltTabWindow(hwnd) {
    if !DllCall("IsWindowVisible", "ptr", hwnd)
        return false
    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "int*", &cloaked, "uint", 4)
    if cloaked
        return false
    if WinGetExStyle("ahk_id " hwnd) & 0x80  ; WS_EX_TOOLWINDOW
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
    if WinGetExStyle("ahk_id " hwnd) & 0x80  ; WS_EX_TOOLWINDOW
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




