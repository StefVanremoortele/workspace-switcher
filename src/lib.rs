use windows::Win32::Foundation::HWND;

#[no_mangle]
pub extern "C" fn switch_to_desktop(n: u32) -> i32 {
    match winvd::switch_desktop(n) {
        Ok(_) => 0,
        Err(_) => 1,
    }
}

#[no_mangle]
pub extern "C" fn get_desktop_count() -> i32 {
    winvd::get_desktop_count()
        .map(|c| c as i32)
        .unwrap_or(-1)
}

#[no_mangle]
pub extern "C" fn get_current_desktop() -> i32 {
    winvd::get_current_desktop()
        .and_then(|d| d.get_index())
        .map(|i| i as i32)
        .unwrap_or(-1)
}

/// Move a top-level window to a zero-based virtual-desktop index.
/// Returns 0 on success and 1 on failure.
#[no_mangle]
pub extern "C" fn move_window_to_desktop(hwnd: isize, desktop: u32) -> i32 {
    match winvd::move_window_to_desktop(desktop, &HWND(hwnd as _)) {
        Ok(_) => 0,
        Err(_) => 1,
    }
}

/// Check whether a top-level window is on a zero-based desktop index.
/// Returns 1 for yes, 0 for no, and -1 if Windows rejected the query.
#[no_mangle]
pub extern "C" fn is_window_on_desktop(hwnd: isize, desktop: u32) -> i32 {
    match winvd::is_window_on_desktop(desktop, HWND(hwnd as _)) {
        Ok(true) => 1,
        Ok(false) => 0,
        Err(_) => -1,
    }
}
