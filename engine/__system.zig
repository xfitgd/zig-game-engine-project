const std = @import("std");

const builtin = @import("builtin");
const ArrayList = std.ArrayList;
const Timer = std.time.Timer;

pub var allocator: std.mem.Allocator = undefined;

const system = @import("system.zig");
const window = @import("window.zig");
const __vulkan = @import("__vulkan.zig");
const math = @import("math.zig");
const input = @import("input.zig");
const mem = @import("mem.zig");

const render_command = @import("render_command.zig");
const __raw_input = @import("__raw_input.zig");

const root = @import("root");

pub var exiting: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

comptime {
    @export(&lua_writestring, .{ .name = "lua_writestring", .linkage = .strong });
}

fn lua_writestring(ptr: ?*const anyopaque, size: usize) callconv(.C) usize {
    system.print("{s}", .{@as([*]const u8, @ptrCast(ptr.?))[0..size]});
    return size;
}

pub var prev_window: struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    state: window.window_state,
} = undefined;

pub var title: [:0]u8 = undefined;

pub var init_set: system.init_setting = .{};

pub var delta_time: u64 = 0;
pub var processor_core_len: u32 = 0;
pub var platform_ver: system.platform_version = undefined;
pub var __screen_orientation: window.screen_orientation = .unknown;

pub var mouse_out: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var mouse_scroll_dt: std.atomic.Value(i32) = std.atomic.Value(i32).init(0);

pub var Lmouse_click: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var Mmouse_click: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var Rmouse_click: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

pub var Lmouse_down_func: ?*const fn (pos: math.point) void = null;
pub var Mmouse_down_func: ?*const fn (pos: math.point) void = null;
pub var Rmouse_down_func: ?*const fn (pos: math.point) void = null;

pub var Lmouse_up_func: ?*const fn (pos: math.point) void = null;
pub var Mmouse_up_func: ?*const fn (pos: math.point) void = null;
pub var Rmouse_up_func: ?*const fn (pos: math.point) void = null;

pub var mouse_scroll_func: ?*const fn (dt: i32) void = null;

pub var mouse_leave_func: ?*const fn () void = null;
pub var mouse_hover_func: ?*const fn () void = null;
pub var mouse_move_func: ?*const fn (pos: math.point) void = null;

pub var touch_down_func: ?*const fn (touch_idx: u32, pos: math.point) void = null;
pub var touch_up_func: ?*const fn (touch_idx: u32, pos: math.point) void = null;

pub var window_move_func: ?*const fn () void = null;
pub var window_size_func: ?*const fn () void = null;

pub var error_handling_func: ?*const fn (text: []u8, stack_trace: []u8) void = null;

pub var cursor_pos: math.pointi = undefined;

pub var pause: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
pub var activated: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

///false = key_up, true = key_down
pub var keys: [KEY_SIZE]std.atomic.Value(bool) = [_]std.atomic.Value(bool){std.atomic.Value(bool).init(false)} ** KEY_SIZE;
pub const KEY_SIZE = 512;
pub var key_down_func: ?*const fn (key_code: input.key) void = null;
pub var key_up_func: ?*const fn (key_code: input.key) void = null;

pub var monitors: ArrayList(system.monitor_info) = undefined;
pub var primary_monitor: *system.monitor_info = undefined;

pub var sound_started: bool = false;
pub var font_started: bool = false;
pub var general_input_callback: ?input.general_input.CallbackFn = null;

pub fn init(_allocator: std.mem.Allocator, init_setting: *const system.init_setting) void {
    allocator = _allocator;
    monitors = ArrayList(system.monitor_info).init(allocator);
    if (system.platform == .android) {
        const width = init_set.window_width;
        const height = init_set.window_height;
        init_set = init_setting.*;
        init_set.window_width = width;
        init_set.window_height = height;
    } else {
        init_set = init_setting.*;
    }

    title = allocator.dupeZ(u8, init_set.window_title) catch |e| system.handle_error3("__system.init.title = allocator.dupeZ", e);
    if (system.platform == .windows) __raw_input.start();
}

pub fn loop() void {
    const S = struct {
        var start = false;
        var now: Timer = undefined;
    };
    const ispause = system.pause();
    if (!S.start) {
        S.now = Timer.start() catch |e| system.handle_error3("S.now = Timer.start()", e);
        S.start = true;
    } else {
        delta_time = S.now.lap();
        var maxframe: u64 = system.get_maxframe_u64();

        if (ispause and maxframe == 0) {
            maxframe = system.sec_to_nano_sec(60, 0);
        }

        if (maxframe > 0) {
            const maxf: u64 = @divTrunc((system.sec_to_nano_sec(1, 0) * system.sec_to_nano_sec(1, 0)), maxframe); //1000000000 / (maxframe / 1000000000); 나눗셈을 한번 줄임
            if (maxf > delta_time) {
                if (ispause) {
                    std.time.sleep(maxf - delta_time); //대기상태라 정확도가 적어도 괜찮다.
                } else {
                    system.sleep(maxf - delta_time);
                }
            }
            delta_time = maxf;
        }
    }
    root.xfit_update();

    if (!ispause) {
        __vulkan.drawFrame();
    }
    //system.print_debug("rendering {d}", .{system.delta_time()});
}

pub fn destroy() void {
    for (monitors.items) |*value| {
        value.*.resolutions.deinit();
    }
    monitors.deinit();
    allocator.free(title);
    if (system.platform == .windows) __raw_input.destroy();
}

pub fn real_destroy() void {
    if (sound_started) system.handle_error_msg2("sound not destroyed");
    if (font_started) system.handle_error_msg2("font not destroyed");
}
