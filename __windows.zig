const std = @import("std");

const builtin = @import("builtin");
const ArrayList = std.ArrayList;

const system = @import("system.zig");
const __system = @import("__system.zig");
const __vulkan = @import("__vulkan.zig");
const math = @import("math.zig");

const allocator = __system.allocator;

const root = @import("root");

pub const win32 = struct {
    pub usingnamespace @import("include/win32.zig").everything;
};

const WINAPI = @import("std").os.windows.WINAPI;
const HINSTANCE = win32.HINSTANCE;

pub const CW_USEDEFAULT = win32.CW_USEDEFAULT;
pub const MSG = win32.MSG;
pub const HWND = win32.HWND;
pub const RECT = win32.RECT;
pub const DWORD = c_ulong;
pub const WORD = c_ushort;
pub const SHORT = c_short;
pub const INT = c_int;
pub const TRUE: c_int = 1;
pub const FALSE: c_int = 0;
pub const BOOL = win32.BOOL;

var render_sem: std.Thread.Semaphore = .{};

pub var hWnd: HWND = undefined;
pub var hInstance: HINSTANCE = undefined;
pub var screen_mode: system.screen_mode = system.screen_mode.WINDOW;
pub var current_monitor: ?*system.monitor_info = null;
pub var current_resolution: ?*system.screen_info = null;

var exiting: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

pub inline fn HIWORD(l: anytype) WORD {
    return @as(WORD, @intCast((l >> 16) & 0xffff));
}
pub inline fn LOWORD(l: anytype) WORD {
    return @as(WORD, @intCast(l & 0xffff));
}
inline fn GET_WHEEL_DELTA_WPARAM(l: anytype) SHORT {
    return @intCast(HIWORD(l));
}
inline fn GET_X_LPARAM(l: anytype) INT {
    return @intCast(LOWORD(l));
}
inline fn GET_Y_LPARAM(l: anytype) INT {
    return @intCast(HIWORD(l));
}
pub fn vulkan_windows_start(vkInstance: __vulkan.vk.VkInstance, vkSurface: *__vulkan.vk.VkSurfaceKHR) void {
    //? hinstance, hwnd 필드 포인터 정렬 문제 때문에 직접 만들어서 넣음. extern struct -> C style struct
    const VkWin32SurfaceCreateInfoKHR = extern struct {
        sType: c_int = __vulkan.vk.VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR,
        pNext: ?*const anyopaque = null,
        flags: __vulkan.vk.VkWin32SurfaceCreateFlagsKHR = 0,
        hinstance: HINSTANCE,
        hwnd: HWND,
    };
    const win32SurfaceCreateInfo: VkWin32SurfaceCreateInfoKHR = .{
        .hwnd = hWnd,
        .hinstance = hInstance,
    };
    const result = __vulkan.vk.vkCreateWin32SurfaceKHR(vkInstance, @ptrCast(&win32SurfaceCreateInfo), null, vkSurface);
    if (result != __vulkan.vk.VK_SUCCESS) unreachable;
}

pub fn system_windows_start() void {
    if (builtin.mode == std.builtin.OptimizeMode.Debug)
        _ = win32.AllocConsole();

    var system_info: win32.SYSTEM_INFO = undefined;
    win32.GetSystemInfo(&system_info);
    __system.processor_core_len = system_info.dwNumberOfProcessors;

    var osversioninfo: win32.OSVERSIONINFOEXW = undefined;
    osversioninfo.dwOSVersionInfoSize = @sizeOf(win32.OSVERSIONINFOEXW);
    _ = std.os.windows.ntdll.RtlGetVersion(@ptrCast(&osversioninfo));

    __system.platform_ver.platform = root.XfitPlatform.windows;
    __system.platform_ver.version.windows.build_number = osversioninfo.dwBuildNumber;
    __system.platform_ver.version.windows.service_pack = osversioninfo.wServicePackMajor;

    const serverOS: bool = osversioninfo.wProductType != win32.VER_NT_WORKSTATION;
    if (!serverOS and __system.platform_ver.version.windows.build_number >= 22000) {
        __system.platform_ver.version.windows.version = system.platform_version.windows_version.Windows11;
    } else if (serverOS and __system.platform_ver.version.windows.build_number >= 20348) {
        __system.platform_ver.version.windows.version = system.platform_version.windows_version.WindowsServer2022;
    } else if (serverOS and __system.platform_ver.version.windows.build_number >= 17763) {
        __system.platform_ver.version.windows.version = system.platform_version.windows_version.WindowsServer2019;
    } else if (osversioninfo.dwMajorVersion == 6 and osversioninfo.dwMinorVersion == 1) {
        __system.platform_ver.version.windows.version = if (serverOS) system.platform_version.windows_version.WindowsServer2008R2 else system.platform_version.windows_version.Windows7;
    } else if (osversioninfo.dwMajorVersion == 6 and osversioninfo.dwMinorVersion == 2) {
        __system.platform_ver.version.windows.version = if (serverOS) system.platform_version.windows_version.WindowsServer2012 else system.platform_version.windows_version.Windows8;
    } else if (osversioninfo.dwMajorVersion == 6 and osversioninfo.dwMinorVersion == 3) {
        __system.platform_ver.version.windows.version = if (serverOS) system.platform_version.windows_version.WindowsServer2012R2 else system.platform_version.windows_version.Windows8Point1;
    } else if (osversioninfo.dwMajorVersion == 10 and osversioninfo.dwMinorVersion == 0) {
        __system.platform_ver.version.windows.version = if (serverOS) system.platform_version.windows_version.WindowsServer2016 else system.platform_version.windows_version.Windows10;
    } else {
        __system.platform_ver.version.windows.version = system.platform_version.windows_version.Unknown;
        system.print_debug("WARN system_windows_start UNKNOWN this root.platform.\n", .{});
    }

    _ = win32.EnumDisplayMonitors(null, null, MonitorEnumProc, 0);
    return;
}

pub fn windows_start() void {
    hInstance = win32.GetModuleHandleA(null) orelse unreachable;

    const CLASS_NAME = "Xfit Window Class";

    const wc = win32.WNDCLASSA{
        .style = .{},
        .lpfnWndProc = WindowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = if (__system.init_set.icon == null) win32.LoadIconA(null, @ptrCast(win32.IDI_APPLICATION)) else win32.LoadIconA(hInstance, @ptrCast(__system.init_set.icon)),
        .hCursor = if (__system.init_set.cursor == null) win32.LoadCursorA(null, @ptrCast(win32.IDC_ARROW)) else win32.LoadCursorA(hInstance, @ptrCast(__system.init_set.cursor)),
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = CLASS_NAME,
    };

    _ = win32.RegisterClassA(&wc);

    const window_style: DWORD = if (__system.init_set.screen_mode == system.screen_mode.WINDOW) (((((@as(DWORD, @bitCast(win32.WS_OVERLAPPED)) |
        @as(DWORD, @bitCast(win32.WS_CAPTION)) |
        @as(DWORD, @bitCast(win32.WS_SYSMENU)) |
        if (__system.init_set.can_resizewindow) @as(DWORD, @bitCast(win32.WS_THICKFRAME)) else 0) |
        if (__system.init_set.can_minimize) @as(DWORD, @bitCast(win32.WS_MINIMIZEBOX)) else 0) |
        if (__system.init_set.can_maximize) @as(DWORD, @bitCast(win32.WS_MAXIMIZEBOX)) else 0))) else @as(DWORD, @bitCast(win32.WS_POPUP));

    const ex_style: DWORD = if (__system.init_set.screen_mode != system.screen_mode.WINDOW) (@as(DWORD, @bitCast(win32.WS_EX_APPWINDOW)) | if (__system.init_set.screen_mode == system.screen_mode.FULLSCREEN) @as(DWORD, @bitCast(win32.WS_EX_TOPMOST)) else 0) else 0;

    var window_x: i32 = __system.init_set.window_x;
    var window_y: i32 = __system.init_set.window_y;
    var window_width: i32 = __system.init_set.window_width;
    var window_height: i32 = __system.init_set.window_height;

    if (__system.init_set.screen_mode != system.screen_mode.WINDOW) {
        if (__system.init_set.screen_index == system.init_setting.PRIMARY_SCREEN_INDEX) {
            window_x = __system.primary_monitor.?.*.rect.left;
            window_y = __system.primary_monitor.?.*.rect.top;
            window_width = __system.primary_monitor.?.*.rect.width();
            window_height = __system.primary_monitor.?.*.rect.height();
            if (__system.init_set.screen_mode == system.screen_mode.FULLSCREEN) {
                change_fullscreen(__system.primary_monitor.?, __system.primary_monitor.?.*.primary_resolution.?);
            }
        } else {
            if (__system.monitors.items.len <= __system.init_set.screen_index) __system.init_set.screen_index = @intCast(__system.monitors.items.len - 1);
            window_x = __system.monitors.items[__system.init_set.screen_index].rect.left;
            window_y = __system.monitors.items[__system.init_set.screen_index].rect.top;
            window_width = __system.monitors.items[__system.init_set.screen_index].rect.width();
            window_height = __system.monitors.items[__system.init_set.screen_index].rect.height();
            if (__system.init_set.screen_mode == system.screen_mode.FULLSCREEN) {
                change_fullscreen(&__system.monitors.items[__system.init_set.screen_index], __system.monitors.items[__system.init_set.screen_index].primary_resolution.?);
            }
        }
    }

    hWnd = win32.CreateWindowExA(@bitCast(ex_style), CLASS_NAME, @ptrCast(__system.init_set.window_title), @bitCast(window_style), window_x, window_y, window_width, window_height, null, null, hInstance, null) orelse {
        system.print_error("ERR windows_start.CreateWindowEx hWnd is null. code : {}\n", .{win32.GetLastError()});
        unreachable;
    };

    // const raw_input = [2]win32.RAWINPUTDEVICE{
    //     .{
    //         .usUsagePage = 1,
    //         .usUsage = 6, //KEYBOARD
    //         .dwFlags = win32.RIDEV_REMOVE,
    //         .hwndTarget = null,
    //     },
    //     .{
    //         .usUsagePage = 1,
    //         .usUsage = 2, //MOUSE
    //         .dwFlags = win32.RIDEV_REMOVE,
    //         .hwndTarget = null,
    //     },
    // };

    // if (win32.RegisterRawInputDevices(&raw_input, 2, @sizeOf(win32.RAWINPUTDEVICE)) == FALSE) {
    //     const err = win32.GetLastError();
    //     system.print("ERR {}\n", .{err});
    //     unreachable;
    // }
    // TODO JoyStick Needed

    _ = win32.ShowWindow(hWnd, if (__system.init_set.screen_mode == system.screen_mode.WINDOW) @bitCast(@intFromEnum(__system.init_set.window_show)) else win32.SW_MAXIMIZE);

    _ = win32.RegisterTouchWindow(hWnd, @enumFromInt(0));

    _ = std.Thread.spawn(.{}, render_thread, .{}) catch |err| {
        system.print_error("ERR windows_start.std.Thread.spawn(render_thread) Failed. msg : {}\n", .{err});
        unreachable;
    };
}

fn render_thread() void {
    __vulkan.vulkan_start();

    root.xfit_init();

    while (!exiting.load(std.builtin.AtomicOrder.acquire)) {
        __system.loop();
    }
    __vulkan.wait_for_fences();

    root.xfit_destroy();
    __vulkan.vulkan_destroy();

    render_sem.post();
}

pub fn windows_loop() void {
    var msg: MSG = undefined;
    while (win32.GetMessageA(&msg, null, 0, 0) != 0) {
        if (msg.message == win32.WM_QUIT) break;
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageA(&msg);
    }
}

pub fn set_window_mode(pos: math.point(i32), size: math.point(u32), state: system.window_state, can_maximize: bool, can_minimize: bool, can_resizewindow: bool) void {
    const style: c_long = ((((win32.WS_OVERLAPPED |
        win32.WS_CAPTION) |
        win32.WS_SYSMENU) |
        if (can_resizewindow) win32.WS_THICKFRAME else 0) |
        if (can_minimize) win32.WS_MINIMIZEBOX else 0) |
        if (can_maximize) win32.WS_MAXIMIZEBOX else 0;

    var rect: RECT = .{ .left = 0, .top = 0, .right = @intCast(size.x), .bottom = @intCast(size.y) };
    win32.AdjustWindowRect(&rect, style, FALSE);

    win32.SetWindowLongPtr(hWnd, win32.GWL_STYLE, style);
    win32.SetWindowLongPtr(hWnd, win32.GWL_EXSTYLE, 0);
    win32.SetWindowPos(hWnd, 0, pos.x, pos.y, rect.right - rect.left, rect.bottom - rect.top, win32.SWP_DRAWFRAME);

    _ = win32.ShowWindow(hWnd, switch (state) {
        .Restore => win32.SW_RESTORE,
        .Maximized => win32.SW_MAXIMIZE,
        .Minimized => win32.SW_MINIMIZE,
    });
}

pub fn set_borderlessscreen_mode(monitor: *system.monitor_info) void {
    win32.SetWindowLongPtr(hWnd, win32.GWL_STYLE, win32.WS_POPUP);
    win32.SetWindowLongPtr(hWnd, win32.GWL_EXSTYLE, win32.WS_EX_APPWINDOW);

    win32.SetWindowPos(hWnd, 0, monitor.*.rect.left, monitor.*.rect.top, monitor.*.rect.right - monitor.*.rect.left, monitor.*.rect.bottom - monitor.*.rect.top, win32.SWP_DRAWFRAME);

    win32.ShowWindow(hWnd, win32.SW_MAXIMIZE);
}

fn change_fullscreen(monitor: *system.monitor_info, resolution: *system.screen_info) void {
    var mode: win32.DEVMODEA = std.mem.zeroes(win32.DEVMODEA);
    mode.dmSize = @sizeOf(win32.DEVMODEA);
    mode.dmFields = win32.DM_PELSWIDTH | win32.DM_PELSHEIGHT | win32.DM_DISPLAYFREQUENCY;
    mode.dmPelsWidth = resolution.size[0];
    mode.dmPelsHeight = resolution.size[1];
    mode.dmDisplayFrequency = resolution.refleshrate;

    const res = win32.ChangeDisplaySettingsExA(@ptrCast(&monitor.name), &mode, null, .{ .FULLSCREEN = 1, .RESET = 1 }, null);
    _ = res;

    current_monitor = monitor;
    current_resolution = resolution;
}

pub fn set_fullscreen_mode(monitor: *system.monitor_info, resolution: *system.screen_info) void {
    screen_mode = system.screen_mode.FULLSCREEN;
    win32.SetWindowLongPtr(hWnd, win32.GWL_STYLE, win32.WS_POPUP);
    win32.SetWindowLongPtr(hWnd, win32.GWL_EXSTYLE, win32.WS_EX_APPWINDOW | win32.WS_EX_TOPMOST);

    win32.SetWindowPos(hWnd, win32.HWND_TOPMOST, monitor.*.rect.left, monitor.*.rect.top, resolution.*.size.x, resolution.*.size.y, 0);
    win32.ShowWindow(hWnd, win32.SW_MAXIMIZE);

    change_fullscreen(monitor, resolution);
}

//TODO IME 입력 이벤트는 에디트 박스 구현할때 같이 하기
//TODO 터치 이벤트
fn WindowProc(hwnd: HWND, uMsg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(WINAPI) win32.LRESULT {
    const S = struct {
        var activateInited = false;
        var sizeInited = false;
    };
    switch (uMsg) {
        win32.WM_LBUTTONDOWN => {
            __system.Lmouse_click.store(true, std.builtin.AtomicOrder.monotonic);
            if (__system.Lmouse_down_func != null) __system.Lmouse_down_func.?();
            return 0;
        },
        win32.WM_MBUTTONDOWN => {
            __system.Mmouse_click.store(true, std.builtin.AtomicOrder.monotonic);
            if (__system.Mmouse_down_func != null) __system.Mmouse_down_func.?();
            return 0;
        },
        win32.WM_RBUTTONDOWN => {
            __system.Rmouse_click.store(true, std.builtin.AtomicOrder.monotonic);
            if (__system.Rmouse_down_func != null) __system.Rmouse_down_func.?();
            return 0;
        },
        win32.WM_LBUTTONUP => {
            __system.Lmouse_click.store(false, std.builtin.AtomicOrder.monotonic);
            if (__system.Lmouse_up_func != null) __system.Lmouse_up_func.?();
            return 0;
        },
        win32.WM_MBUTTONUP => {
            __system.Mmouse_click.store(false, std.builtin.AtomicOrder.monotonic);
            if (__system.Mmouse_up_func != null) __system.Mmouse_up_func.?();
            return 0;
        },
        win32.WM_RBUTTONUP => {
            __system.Rmouse_click.store(false, std.builtin.AtomicOrder.monotonic);
            if (__system.Rmouse_up_func != null) __system.Rmouse_up_func.?();
            return 0;
        },
        win32.WM_KEYDOWN => {
            if (wParam < __system.KEY_SIZE) {
                if (!__system.keys[wParam].load(std.builtin.AtomicOrder.monotonic)) {
                    __system.keys[wParam].store(true, std.builtin.AtomicOrder.monotonic);
                    //system.print_debug("input key_down {d}\n", .{wParam});
                    if (__system.key_down_func != null) __system.key_down_func.?(@enumFromInt(wParam));
                }
            } else {
                system.print("WARN WindowProc WM_KEYDOWN out of range __system.keys[{d}] value : {d}\n", .{ __system.KEY_SIZE, wParam });
            }
            return 0;
        },
        win32.WM_KEYUP => {
            if (wParam < __system.KEY_SIZE) {
                __system.keys[wParam].store(false, std.builtin.AtomicOrder.monotonic);
                //system.print_debug("input key_up {d}\n", .{wParam});
                if (__system.key_up_func != null) __system.key_up_func.?(@enumFromInt(wParam));
            } else {
                system.print("WARN WindowProc WM_KEYUP out of range __system.keys[{d}] value : {d}\n", .{ __system.KEY_SIZE, wParam });
            }
            return 0;
        },
        win32.WM_KILLFOCUS => {
            for (&__system.keys) |*value| {
                value.*.store(false, std.builtin.AtomicOrder.monotonic);
            }
            return 0;
        },
        win32.WM_INPUT => {
            var rawinput: win32.RAWINPUT = std.mem.zeroes(win32.RAWINPUT);
            var unsize: u32 = @sizeOf(win32.RAWINPUT);
            _ = win32.GetRawInputData(@ptrFromInt(@as(usize, @intCast(lParam))), win32.RID_INPUT, &rawinput, &unsize, @sizeOf(win32.RAWINPUTHEADER));
            switch (rawinput.header.dwType) {
                else => {},
            }
            return 0;
        },
        win32.WM_ACTIVATE => {
            if (S.activateInited) {
                const pause = (HIWORD(wParam) != 0);
                const activated = (LOWORD(wParam) != win32.WA_INACTIVE);
                __system.pause.store(pause, std.builtin.AtomicOrder.monotonic);
                __system.activated.store(activated, std.builtin.AtomicOrder.monotonic);

                root.xfit_activate(activated, pause);
            }
            S.activateInited = true;
            return 0;
        },
        win32.WM_SIZE => {
            if (wParam != win32.SIZE_MINIMIZED) {
                if (S.sizeInited) {
                    @atomicStore(i32, &__system.init_set.window_width, @intCast(LOWORD(lParam)), std.builtin.AtomicOrder.monotonic);
                    @atomicStore(i32, &__system.init_set.window_height, @intCast(HIWORD(lParam)), std.builtin.AtomicOrder.monotonic);

                    if (__system.window_size_func != null) __system.window_size_func.?();
                }

                S.sizeInited = true;
            }
            return 0;
        },
        win32.WM_MOVE => {
            @atomicStore(i32, &__system.init_set.window_x, @intCast(LOWORD(lParam)), std.builtin.AtomicOrder.monotonic);
            @atomicStore(i32, &__system.init_set.window_y, @intCast(HIWORD(lParam)), std.builtin.AtomicOrder.monotonic);

            if (__system.window_move_func != null) __system.window_move_func.?();
            return 0;
        },
        win32.WM_MOUSEMOVE => {
            var mouse_event: win32.TRACKMOUSEEVENT = .{ .cbSize = @sizeOf(win32.TRACKMOUSEEVENT), .dwFlags = .{ .HOVER = 1, .LEAVE = 1 }, .hwndTrack = hWnd, .dwHoverTime = 10 };
            if (win32.TrackMouseEvent(&mouse_event) == FALSE) {
                system.print("WARN WindowProc.TrackMouseEvent Failed Code : {}\n", .{win32.GetLastError()});
            }
            @atomicStore(i32, &__system.cursor_pos[0], GET_X_LPARAM(lParam), std.builtin.AtomicOrder.monotonic);
            @atomicStore(i32, &__system.cursor_pos[1], GET_Y_LPARAM(lParam), std.builtin.AtomicOrder.monotonic);
            return 0;
        },
        // MOUSEMOVE 메시지에서 TrackMouseEvent를 호출하면 호출되는 메시지
        win32.WM_MOUSELEAVE => {
            __system.mouse_out.store(true, std.builtin.AtomicOrder.monotonic);
            return 0;
        },
        win32.WM_MOUSEHOVER => {
            __system.mouse_out.store(false, std.builtin.AtomicOrder.monotonic);
            return 0;
        },
        win32.WM_MOUSEWHEEL => {
            __system.mouse_scroll_dt.store(GET_WHEEL_DELTA_WPARAM(wParam), std.builtin.AtomicOrder.monotonic);
        },
        win32.WM_CLOSE => {
            if (!root.xfit_closing()) return 0;
        },
        win32.WM_DESTROY => {
            exiting.store(true, std.builtin.AtomicOrder.release);
            render_sem.wait();
            win32.PostQuitMessage(0);
            return 0;
        },
        else => {},
    }

    return win32.DefWindowProcA(hwnd, uMsg, wParam, lParam);
}

fn MonitorEnumProc(hMonitor: ?win32.HMONITOR, hdcMonitor: ?win32.HDC, lprcMonitor: [*c]win32.RECT, dwData: win32.LPARAM) callconv(WINAPI) BOOL {
    _ = hdcMonitor;
    _ = lprcMonitor;
    _ = dwData;

    var monitor_info: win32.MONITORINFOEXA = undefined;
    monitor_info.monitorInfo.cbSize = @sizeOf(win32.MONITORINFOEXA);

    _ = win32.GetMonitorInfoA(hMonitor, @ptrCast(&monitor_info));

    __system.monitors.append(system.monitor_info{ .is_primary = false, .rect = math.rect(i32).init(0, 0, 0, 0), .resolutions = ArrayList(system.screen_info).init(allocator) }) catch {
        system.print_error("ERR MonitorEnumProc.monitors.append\n", .{});
        unreachable;
    };
    var last = &__system.monitors.items[__system.monitors.items.len - 1];
    last.*.is_primary = (monitor_info.monitorInfo.dwFlags & win32.MONITORINFOF_PRIMARY) != 0;
    if (last.*.is_primary) __system.primary_monitor = last;
    last.*.rect = math.rect(i32).init(monitor_info.monitorInfo.rcMonitor.left, monitor_info.monitorInfo.rcMonitor.right, monitor_info.monitorInfo.rcMonitor.top, monitor_info.monitorInfo.rcMonitor.bottom);

    var i: u32 = 0;
    var dm: win32.DEVMODEA = std.mem.zeroes(win32.DEVMODEA);
    dm.dmSize = @sizeOf(win32.DEVMODEA);
    while (win32.EnumDisplaySettingsA(@ptrCast(&monitor_info.szDevice), @enumFromInt(i), &dm) != FALSE) : (i += 1) {
        last.*.resolutions.append(.{ .monitor = last, .refleshrate = dm.dmDisplayFrequency, .size = .{ dm.dmPelsWidth, dm.dmPelsHeight } }) catch {
            system.print_error("ERR MonitorEnumProc.last.*.resolutions.append\n", .{});
            unreachable;
        };
    }
    _ = win32.EnumDisplaySettingsA(@ptrCast(&monitor_info.szDevice), win32.ENUM_CURRENT_SETTINGS, &dm);
    last.primary_resolution = null;

    var j: usize = 0;
    while (j < last.resolutions.items.len) : (j += 1) {
        if (dm.dmPelsWidth == last.*.resolutions.items[j].size[0] and dm.dmPelsHeight == last.resolutions.items[j].size[1] and dm.dmDisplayFrequency == last.resolutions.items[j].refleshrate) {
            last.*.primary_resolution = &last.*.resolutions.items[j];
            break;
        }
    }
    if (last.*.primary_resolution == null) {
        system.print("WARN can't find primary_resolution.\n", .{});
        last.*.primary_resolution = &last.*.resolutions.items[last.resolutions.items.len - 1];
    }
    std.mem.copyForwards(u8, &last.*.name, &monitor_info.szDevice);

    return TRUE;
}
