const std = @import("std");

const builtin = @import("builtin");
const ArrayList = std.ArrayList;

pub var allocator: std.mem.Allocator = undefined;

const system = @import("system.zig");
const window = @import("window.zig");
const __vulkan = @import("__vulkan.zig");
const math = @import("math.zig");
const input = @import("input.zig");
const mem = @import("mem.zig");

const root = @import("root");

pub var prev_window: struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    state: window.window_state,
} = undefined;

pub var init_set: system.init_setting = .{};

pub var delta_time: i64 = 0;
pub var processor_core_len: u32 = 0;
pub var platform_ver: system.platform_version = undefined;

pub var mouse_out: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var mouse_scroll_dt: std.atomic.Value(i32) = std.atomic.Value(i32).init(0);

pub var Lmouse_click: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var Mmouse_click: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var Rmouse_click: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

pub var Lmouse_down_func: ?*const fn () void = null;
pub var Mmouse_down_func: ?*const fn () void = null;
pub var Rmouse_down_func: ?*const fn () void = null;

pub var Lmouse_up_func: ?*const fn () void = null;
pub var Mmouse_up_func: ?*const fn () void = null;
pub var Rmouse_up_func: ?*const fn () void = null;

pub var window_move_func: ?*const fn () void = null;
pub var window_size_func: ?*const fn () void = null;

pub var cursor_pos: math.pointi = undefined;

pub var pause: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var activated: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

///false = key_up, true = key_down
pub var keys: [KEY_SIZE]std.atomic.Value(bool) = [_]std.atomic.Value(bool){std.atomic.Value(bool).init(false)} ** KEY_SIZE;
pub const KEY_SIZE = 512;
pub var key_down_func: ?*const fn (key_code: input.key()) void = null;
pub var key_up_func: ?*const fn (key_code: input.key()) void = null;

pub var monitors: ArrayList(system.monitor_info) = undefined;
pub var primary_monitor: ?*system.monitor_info = null;
pub var size_update_sem: std.Thread.Semaphore = .{};

pub fn init(_allocator: std.mem.Allocator, init_setting: *const system.init_setting) void {
    allocator = _allocator;
    monitors = ArrayList(system.monitor_info).init(allocator);
    init_set = init_setting.*;
}

pub fn loop() void {
    const S = struct {
        var start = false;
        var now: i128 = 0;
    };
    if (!S.start) {
        S.now = std.time.nanoTimestamp();
        S.start = true;
    } else {
        const temp = S.now;
        S.now = std.time.nanoTimestamp();
        delta_time = @intCast(S.now - temp);
        const maxframe: i64 = system.get_maxframe_i64();

        if (maxframe > 0) {
            const maxf: i64 = @divTrunc((1000000000 * 1000000000), maxframe); //1000000000 / (maxframe / 1000000000); 나눗셈을 한번 줄임
            const sleep: i64 = maxf - delta_time;
            if (sleep > 0) system.sleep(@intCast(sleep));
            delta_time = maxf;
        }
    }
    var need_size_update = true;
    size_update_sem.timedWait(0) catch {
        need_size_update = false; //?need_size_update 변수를 안쓰는 방법이 있나..?
    };
    if (need_size_update) {
        root.xfit_size_update();
    }
    root.xfit_update();
    __vulkan.drawFrame();

    //system.print_debug("rendering {d}", .{system.delta_time()});
}

pub fn destroy() void {
    for (monitors.items) |*value| {
        value.*.resolutions.deinit();
    }
    monitors.deinit();
}
