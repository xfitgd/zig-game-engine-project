const std = @import("std");

const builtin = @import("builtin");

const root = @import("root");

const system = @import("system.zig");
const __system = @import("__system.zig");
const __windows = @import("__windows.zig");
const math = @import("math.zig");

pub const window_show = enum(u32) {
    NORMAL = @bitCast(__windows.win32.SW_NORMAL),
    DEFAULT = @bitCast(__windows.win32.SW_SHOWDEFAULT),
    MAXIMIZE = @bitCast(__windows.win32.SW_MAXIMIZE),
    MINIMIZE = @bitCast(__windows.win32.SW_MINIMIZE),
};

pub fn window_width() i32 {
    if (root.platform == root.XfitPlatform.windows) {
        return @atomicLoad(i32, &__system.init_set.window_width, std.builtin.AtomicOrder.monotonic);
    }
    system.print_error("ERR window_width not support mobile platform.\n", .{});
    unreachable;
}
pub fn window_height() i32 {
    if (root.platform == root.XfitPlatform.windows) {
        return @atomicLoad(i32, &__system.init_set.window_height, std.builtin.AtomicOrder.monotonic);
    }
    system.print_error("ERR window_height not support mobile platform.\n", .{});
    unreachable;
}
pub fn window_x() i32 {
    if (root.platform == root.XfitPlatform.windows) {
        return @atomicLoad(i32, &__system.init_set.window_x, std.builtin.AtomicOrder.monotonic);
    }
    system.print_error("ERR window_x not support mobile platform.\n", .{});
    unreachable;
}
pub fn window_y() i32 {
    if (root.platform == root.XfitPlatform.windows) {
        return @atomicLoad(i32, &__system.init_set.window_y, std.builtin.AtomicOrder.monotonic);
    }
    system.print_error("ERR window_y not support mobile platform.\n", .{});
    unreachable;
}
pub fn can_maximize() bool {
    if (root.platform == root.XfitPlatform.windows) {
        return @atomicLoad(bool, &__system.init_set.can_maximize, std.builtin.AtomicOrder.monotonic);
    }
    system.print_error("ERR can_maximize not support mobile platform.\n", .{});
    unreachable;
}
pub fn can_minimize() bool {
    if (root.platform == root.XfitPlatform.windows) {
        return @atomicLoad(bool, &__system.init_set.can_minimize, std.builtin.AtomicOrder.monotonic);
    }
    system.print_error("ERR can_minimize not support mobile platform.\n", .{});
    unreachable;
}
pub fn can_resizewindow() bool {
    if (root.platform == root.XfitPlatform.windows) {
        return @atomicLoad(bool, &__system.init_set.can_resizewindow, std.builtin.AtomicOrder.monotonic);
    }
    system.print_error("ERR can_resizewindow not support mobile platform.\n", .{});
    unreachable;
}
//TODO pub fn set_window_size and pos ???
//TODO pub fn get_window_title() set_window_title()
pub fn set_window_mode(pos: math.point(i32), size: math.point(u32), state: system.window_state, _can_maximize: bool, _can_minimize: bool, _can_resizewindow: bool) void {
    if (root.platform == root.XfitPlatform.windows) {
        __windows.set_window_mode(pos, size, state, state, _can_maximize, _can_minimize, _can_resizewindow);
    } else {
        system.print_error("ERR monitor_info.set_window_mode not support mobile platform.\n", .{});
        unreachable;
    }
    @atomicStore(system.screen_mode, &__system.init_set.screen_mode, system.screen_mode.WINDOW, std.builtin.AtomicOrder.monotonic);
    @atomicStore(bool, &__system.init_set.can_maximize, _can_maximize, std.builtin.AtomicOrder.monotonic);
    @atomicStore(bool, &__system.init_set.can_minimize, _can_minimize, std.builtin.AtomicOrder.monotonic);
    @atomicStore(bool, &__system.init_set.can_resizewindow, _can_resizewindow, std.builtin.AtomicOrder.monotonic);
    @atomicStore(i32, &__system.init_set.window_x, pos.x, std.builtin.AtomicOrder.monotonic);
    @atomicStore(i32, &__system.init_set.window_y, pos.y, std.builtin.AtomicOrder.monotonic);
    @atomicStore(i32, &__system.init_set.window_width, size.x, std.builtin.AtomicOrder.monotonic);
    @atomicStore(i32, &__system.init_set.window_height, size.y, std.builtin.AtomicOrder.monotonic);

    switch (state) {
        .Restore => {
            @atomicStore(window_show, &__system.init_set.window_show, window_show.NORMAL, std.builtin.AtomicOrder.monotonic);
        },
        .Maximized => {
            @atomicStore(window_show, &__system.init_set.window_show, window_show.MAXIMIZE, std.builtin.AtomicOrder.monotonic);
        },
        .Minimized => {
            @atomicStore(window_show, &__system.init_set.window_show, window_show.MINIMIZE, std.builtin.AtomicOrder.monotonic);
        },
    }
}
pub inline fn set_window_move_func(_func: *const fn () void) void {
    __system.window_move_func = _func;
}
pub inline fn set_window_size_func(_func: *const fn () void) void {
    __system.window_size_func = _func;
}
