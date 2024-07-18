const std = @import("std");

const builtin = @import("builtin");
const ArrayList = std.ArrayList;
pub const allocator = std.heap.c_allocator;

const system = @import("system.zig");
const __vulkan = @import("__vulkan.zig");
const geometry = @import("geometry.zig");
const input = @import("input.zig");

const root = @import("root");

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

pub var cursor_pos: geometry.point(i32) = undefined;

pub var pause: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var activated: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

///false = key_up, true = key_down
pub var keys: [KEY_SIZE]std.atomic.Value(bool) = [_]std.atomic.Value(bool){std.atomic.Value(bool).init(false)} ** KEY_SIZE;
pub const KEY_SIZE = 512;
pub var key_down_func: ?*const fn (key_code: input.Key()) void = null;
pub var key_up_func: ?*const fn (key_code: input.Key()) void = null;

pub var monitors: ArrayList(system.monitor_info) = ArrayList(system.monitor_info).init(allocator);
pub var primary_monitor: ?*system.monitor_info = null;

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
        const maxframe = @atomicLoad(i64, &init_set.maxframe, std.builtin.AtomicOrder.monotonic);
        if (maxframe > 0) {
            const maxf: i64 = @divFloor((1000000000 * 1000000000), maxframe); //1000000000 / (maxframe / 1000000000); 나눗셈을 한번 줄임
            const sleep: i64 = maxf - delta_time;
            if (sleep > 0) std.time.sleep(@intCast(sleep));
            delta_time = maxf;
        }
    }
    root.xfit_update();
    __vulkan.drawFrame();

    //system.print_debug("rendering {d}\n", .{system.delta_time()});
}
