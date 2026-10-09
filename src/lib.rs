#[cfg(not(any(
    feature = "win10",
    feature = "win11_22h2",
    feature = "win11_23h2",
    feature = "win11_24h2"
)))]
compile_error!("select one Windows virtual-desktop backend feature");

#[cfg(any(
    all(feature = "win10", feature = "win11_22h2"),
    all(feature = "win10", feature = "win11_23h2"),
    all(feature = "win10", feature = "win11_24h2"),
    all(feature = "win11_22h2", feature = "win11_23h2"),
    all(feature = "win11_22h2", feature = "win11_24h2"),
    all(feature = "win11_23h2", feature = "win11_24h2")
))]
compile_error!("select exactly one Windows virtual-desktop backend feature");

#[cfg(feature = "win10")]
mod backend {
    use winvd_win10 as winvd;

    pub fn switch_to_desktop(desktop: u32) -> i32 {
        winvd::helpers::go_to_desktop_number(desktop as usize)
            .map(|_| 0)
            .unwrap_or(1)
    }

    pub fn get_desktop_count() -> i32 {
        winvd::helpers::get_desktop_count()
            .map(|count| i32::try_from(count).unwrap_or(-1))
            .unwrap_or(-1)
    }

    pub fn get_current_desktop() -> i32 {
        winvd::helpers::get_current_desktop_number()
            .map(|index| i32::try_from(index).unwrap_or(-1))
            .unwrap_or(-1)
    }

    pub fn move_window_to_desktop(hwnd: isize, desktop: u32) -> i32 {
        winvd::helpers::move_window_to_desktop_number(hwnd, desktop as usize)
            .map(|_| 0)
            .unwrap_or(1)
    }

    pub fn is_window_on_desktop(hwnd: isize, desktop: u32) -> i32 {
        match winvd::helpers::is_window_on_desktop_number(hwnd, desktop as usize) {
            Ok(true) => 1,
            Ok(false) => 0,
            Err(_) => -1,
        }
    }
}

#[cfg(feature = "win11_22h2")]
mod backend {
    use winvd_win11_22h2 as winvd;

    pub fn switch_to_desktop(desktop: u32) -> i32 {
        winvd::switch_desktop(desktop).map(|_| 0).unwrap_or(1)
    }

    pub fn get_desktop_count() -> i32 {
        winvd::get_desktop_count()
            .map(|count| i32::try_from(count).unwrap_or(-1))
            .unwrap_or(-1)
    }

    pub fn get_current_desktop() -> i32 {
        winvd::get_current_desktop()
            .map_or(-1, |desktop| desktop.get_index().map_or(-1, |n| n as i32))
    }

    pub fn move_window_to_desktop(hwnd: isize, desktop: u32) -> i32 {
        let hwnd = unsafe { std::mem::transmute::<isize, _>(hwnd) };
        winvd::move_window_to_desktop(desktop, &hwnd)
            .map(|_| 0)
            .unwrap_or(1)
    }

    pub fn is_window_on_desktop(hwnd: isize, desktop: u32) -> i32 {
        let hwnd = unsafe { std::mem::transmute::<isize, _>(hwnd) };
        match winvd::is_window_on_desktop(desktop, hwnd) {
            Ok(true) => 1,
            Ok(false) => 0,
            Err(_) => -1,
        }
    }
}

#[cfg(feature = "win11_23h2")]
mod backend {
    use winvd_win11_23h2 as winvd;

    pub fn switch_to_desktop(desktop: u32) -> i32 {
        winvd::switch_desktop(desktop).map(|_| 0).unwrap_or(1)
    }

    pub fn get_desktop_count() -> i32 {
        winvd::get_desktop_count()
            .map(|count| i32::try_from(count).unwrap_or(-1))
            .unwrap_or(-1)
    }

    pub fn get_current_desktop() -> i32 {
        winvd::get_current_desktop()
            .map_or(-1, |desktop| desktop.get_index().map_or(-1, |n| n as i32))
    }

    pub fn move_window_to_desktop(hwnd: isize, desktop: u32) -> i32 {
        let hwnd = unsafe { std::mem::transmute::<isize, _>(hwnd) };
        winvd::move_window_to_desktop(desktop, &hwnd)
            .map(|_| 0)
            .unwrap_or(1)
    }

    pub fn is_window_on_desktop(hwnd: isize, desktop: u32) -> i32 {
        let hwnd = unsafe { std::mem::transmute::<isize, _>(hwnd) };
        match winvd::is_window_on_desktop(desktop, hwnd) {
            Ok(true) => 1,
            Ok(false) => 0,
            Err(_) => -1,
        }
    }
}

#[cfg(feature = "win11_24h2")]
mod backend {
    use winvd_win11_24h2 as winvd;

    pub fn switch_to_desktop(desktop: u32) -> i32 {
        winvd::switch_desktop(desktop).map(|_| 0).unwrap_or(1)
    }

    pub fn get_desktop_count() -> i32 {
        winvd::get_desktop_count()
            .map(|count| i32::try_from(count).unwrap_or(-1))
            .unwrap_or(-1)
    }

    pub fn get_current_desktop() -> i32 {
        winvd::get_current_desktop()
            .map_or(-1, |desktop| desktop.get_index().map_or(-1, |n| n as i32))
    }

    pub fn move_window_to_desktop(hwnd: isize, desktop: u32) -> i32 {
        let hwnd = unsafe { std::mem::transmute::<isize, _>(hwnd) };
        winvd::move_window_to_desktop(desktop, &hwnd)
            .map(|_| 0)
            .unwrap_or(1)
    }

    pub fn is_window_on_desktop(hwnd: isize, desktop: u32) -> i32 {
        let hwnd = unsafe { std::mem::transmute::<isize, _>(hwnd) };
        match winvd::is_window_on_desktop(desktop, hwnd) {
            Ok(true) => 1,
            Ok(false) => 0,
            Err(_) => -1,
        }
    }
}

#[no_mangle]
pub extern "C" fn switch_to_desktop(n: u32) -> i32 {
    backend::switch_to_desktop(n)
}

#[no_mangle]
pub extern "C" fn get_desktop_count() -> i32 {
    backend::get_desktop_count()
}

#[no_mangle]
pub extern "C" fn get_current_desktop() -> i32 {
    backend::get_current_desktop()
}

/// Move a top-level window to a zero-based virtual-desktop index.
/// Returns 0 on success and 1 on failure.
#[no_mangle]
pub extern "C" fn move_window_to_desktop(hwnd: isize, desktop: u32) -> i32 {
    backend::move_window_to_desktop(hwnd, desktop)
}

/// Check whether a top-level window is on a zero-based desktop index.
/// Returns 1 for yes, 0 for no, and -1 if Windows rejected the query.
#[no_mangle]
pub extern "C" fn is_window_on_desktop(hwnd: isize, desktop: u32) -> i32 {
    backend::is_window_on_desktop(hwnd, desktop)
}
