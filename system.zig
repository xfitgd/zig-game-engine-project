const std = @import("std");
const builtin = @import("builtin");

const ArrayList = std.ArrayList;

const root = @import("root");

const __android = @import("__android.zig");
const __windows = @import("__windows.zig");
const window = @import("window.zig");
const __vulkan = @import("__vulkan.zig");
const __system = @import("__system.zig");
const math = @import("math.zig");

pub const windows = __windows.win32;
pub const android = __android.android;
pub const vulkan = __vulkan.vk;

pub const vulkan_ext = struct {
    pub const vkCreateDebugUtilsMessengerEXT = __vulkan.vkCreateDebugUtilsMessengerEXT;
    pub const vkDestroyDebugUtilsMessengerEXT = __vulkan.vkDestroyDebugUtilsMessengerEXT;
};

pub const screen_mode = enum { WINDOW, BORDERLESSSCREEN, FULLSCREEN };

pub inline fn get_processor_core_len() u32 {
    return __system.processor_core_len;
}

pub inline fn pause() bool {
    return __system.pause.load(std.builtin.AtomicOrder.monotonic);
}
pub inline fn activated() bool {
    return __system.activated.load(std.builtin.AtomicOrder.monotonic);
}

pub const platform_version = struct {
    pub const android_api_level = enum(u32) { Nougat = 24, Nougat_MR1 = 25, Oreo = 26, Oreo_MR1 = 27, Pie = 28, Q = 29, R = 30, S = 31, S_V2 = 32, Tiramisu = 33, UpsideDownCake = 34, VanillaIceCream = 35, Unknown = 0 };
    pub const windows_version = enum { Windows7, WindowsServer2008R2, Windows8, WindowsServer2012, Windows8Point1, WindowsServer2012R2, Windows10, WindowsServer2016, Windows11, WindowsServer2019, WindowsServer2022, Unknown };

    platform: root.XfitPlatform,
    version: union {
        windows: struct { version: windows_version, build_number: u32, service_pack: u32 },
        android: struct {
            api_level: android_api_level,
        },
    },
};

pub const screen_info = struct {
    monitor: *monitor_info,
    size: math.point(u32),
    refleshrate: u32,
};

pub const monitor_info = struct {
    const Self = @This();
    rect: math.rect(i32),

    is_primary: bool,
    primary_resolution: ?*screen_info = null,
    resolutions: ArrayList(screen_info),

    name: [32]u8 = std.mem.zeroes([32]u8),

    fn save_prev_window_state() void {
        if (__system.init_set.screen_mode == .WINDOW) {
            __system.prev_window = .{
                .x = window.window_x(),
                .y = window.window_y(),
                .width = window.window_width(),
                .height = window.window_height(),
                .state = if (root.platform == root.XfitPlatform.windows) __windows.get_window_state() else window.window_state.Restore,
            };
        }
    }

    pub fn set_fullscreen_mode(self: Self, resolution: *screen_info) void {
        save_prev_window_state();
        if (root.platform == root.XfitPlatform.windows) {
            __windows.set_fullscreen_mode(&self, resolution);
            @atomicStore(screen_mode, &__system.init_set.screen_mode, screen_mode.FULLSCREEN, std.builtin.AtomicOrder.monotonic);
        } else {
            print("WARN monitor_info.set_fullscreen_mode not support mobile platform.\n", .{});
            return;
        }
    }
    pub fn set_borderlessscreen_mode(self: Self) void {
        save_prev_window_state();
        if (root.platform == root.XfitPlatform.windows) {
            __windows.set_borderlessscreen_mode(&self);
            @atomicStore(screen_mode, &__system.init_set.screen_mode, screen_mode.BORDERLESSSCREEN, std.builtin.AtomicOrder.monotonic);
        } else {
            print("WARN monitor_info.set_borderlessscreen_mode not support mobile platform.\n", .{});
            return;
        }
    }
};

///_int * 1000000000 + _dec
pub inline fn sec_to_nano_sec(_int: anytype, _dec: anytype) @TypeOf(_int, _dec) {
    return _int * 1000000000 + _dec;
}

pub const init_setting = struct {
    pub const DEF_POS_SIZE = __windows.CW_USEDEFAULT;
    pub const PRIMARY_SCREEN_INDEX = std.math.maxInt(u32);
    //*ignore field mobile
    window_width: i32 = DEF_POS_SIZE,
    window_height: i32 = DEF_POS_SIZE,
    window_x: i32 = DEF_POS_SIZE,
    window_y: i32 = DEF_POS_SIZE,

    window_show: window.window_show = window.window_show.DEFAULT,
    screen_mode: screen_mode = screen_mode.WINDOW,
    screen_index: u32 = PRIMARY_SCREEN_INDEX,

    can_maximize: bool = true,
    can_minimize: bool = true,
    can_resizewindow: bool = true,

    window_title: ?[]const u8 = "Xfit",
    icon: ?[]const u8 = null,
    cursor: ?[]const u8 = null,
    //*

    ///nanosec 단위 1프레임당 1sec = 1000000000 nanosec
    maxframe: i64 = 0,
    refleshrate: u32 = 0,
    vSync: bool = false,
};

pub inline fn monitors() []const monitor_info {
    return __windows.monitors.items;
}
pub inline fn primary_monitor() *const monitor_info {
    return __windows.primary_monitor.?;
}

///nanosec
pub inline fn dt_i64() i64 {
    return __system.delta_time;
}
pub inline fn dt() f64 {
    return @as(f64, @floatFromInt(__system.delta_time)) / 1000000000;
}

///nanosec
pub inline fn get_maxframe_i64() i64 {
    return __system.init_set.maxframe;
}
pub inline fn get_maxframe() f64 {
    return @as(f64, @floatFromInt(__system.init_set.maxframe)) / 1000000000;
}
///nanosec
pub inline fn set_maxframe_i64(_maxframe: i64) void {
    __system.init_set.maxframe = _maxframe;
}

pub inline fn get_platform_version() *const platform_version {
    return &__system.platform_ver;
}
pub inline fn print(comptime fmt: []const u8, args: anytype) void {
    if (root.platform != root.XfitPlatform.android) {
        std.debug.print(fmt, args);
    } else {
        //TODO _ = __android.LOGV(fmt.ptr, args); 직접 구현 필요
    }
}
pub fn notify() void {
    if (root.platform == root.XfitPlatform.windows) {
        _ = __windows.win32.FlashWindow(__windows.hWnd, __windows.TRUE);
    } else {
        print("WARN notify not support mobile platform.\n", .{});
        return;
    }
}
pub fn text_notify(text: []const u8) void {
    _ = text;
    if (root.platform == root.XfitPlatform.windows) {
        //TODO 윈도우즈 텍스트 알림 구현
    } else if (root.platform == root.XfitPlatform.android) {
        //TODO 안드로이드 텍스트 알림 구현
    } else {
        @compileError("not support platform");
    }
}

pub inline fn print_debug(comptime fmt: []const u8, args: anytype) void {
    if (builtin.mode == std.builtin.OptimizeMode.Debug) {
        if (root.platform != root.XfitPlatform.android) {
            std.debug.print(fmt, args);
        } else {
            //TODO _ = __android.LOGV(fmt.ptr, args); 직접 구현 필요
        }
    }
}

pub inline fn print_error(comptime fmt: []const u8, args: anytype) void {
    if (root.platform != root.XfitPlatform.android) {
        std.debug.print(fmt, args);
    } else {
        //TODO _ = __android.LOGE(fmt.ptr, args); 직접 구현 필요
    }
}

pub inline fn handle_error_msg(errtest: bool, msg: []const u8) void {
    if (!errtest) {
        print_error("ERR {s}\n", .{msg});
        unreachable;
    }
}

pub inline fn handle_error(errtest: bool, code: i32) void {
    if (!errtest) {
        print_error("ERR Fail {d}\n", .{code});
        unreachable;
    }
}

pub inline fn handle_error2(errtest: bool, code: i32, err: anyerror) void {
    if (!errtest) {
        print_error("ERR Fail {d} {}\n", .{ code, err });
        unreachable;
    }
}

pub inline fn handle_try_error(errtest: bool, code: i32, err: anyerror) !void {
    if (!errtest) {
        print_error("ERR Fail {d} {}\n", .{ code, err });
        try err;
    }
}

pub inline fn sleep(ns: u64) void {
    if (root.platform == root.XfitPlatform.windows) {
        __windows.nanosleep(ns);
    } else {
        std.time.sleep(ns);
    }
}
