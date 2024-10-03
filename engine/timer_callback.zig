const std = @import("std");
const system = @import("system.zig");

const Self = @This();

thread: std.Thread,

inline fn loop(wait_nanosec: u64, comptime function: anytype, args: anytype) void {
    system.sleep(wait_nanosec);
    _ = std.Thread.spawn(.{}, callback_, .{ function, args }) catch |err|
        system.print_error("timer_callback loop : {s}\n", .{@errorName(err)});
}

inline fn loop2(wait_nanosec: u64, comptime function: anytype, args: anytype) void {
    system.sleep(wait_nanosec);
    if (@typeInfo(@typeInfo(@TypeOf(function)).@"fn".return_type.?) == .error_union) { // ? 표준 라이브러리 Thread.zig에서 가져온 코드
        _ = @call(.auto, function, args) catch |err| {
            system.print_error("ERR : {s}\n", .{@errorName(err)});
        };
    } else {
        _ = @call(.auto, function, args);
    }
}

fn callback_(comptime function: anytype, args: anytype) void {
    if (@typeInfo(@typeInfo(@TypeOf(function)).@"fn".return_type.?) == .error_union) { // ? 표준 라이브러리 Thread.zig에서 가져온 코드
        _ = @call(.auto, function, args) catch |err| {
            system.print_error("ERR : {s}\n", .{@errorName(err)});
        };
    } else {
        _ = @call(.auto, function, args);
    }
}

fn callback(wait_nanosec: u64, repeat: u32, comptime function: anytype, args: anytype) void {
    var re = repeat;
    if (re == 0) {
        while (true) {
            loop(wait_nanosec, function, args);
        }
    } else {
        while (re > 0) : (re -= 1) {
            loop(wait_nanosec, function, args);
        }
    }
}

fn callback2(wait_nanosec: u64, repeat: u32, comptime function: anytype, args: anytype) void {
    var re = repeat;
    if (re == 0) {
        while (true) {
            loop2(wait_nanosec, function, args);
        }
    } else {
        while (re > 0) : (re -= 1) {
            loop2(wait_nanosec, function, args);
        }
    }
}

pub fn start(wait_nanosec: u64, repeat: u32, comptime function: anytype, args: anytype) std.Thread.SpawnError!std.Thread {
    return try std.Thread.spawn(.{}, callback, .{ wait_nanosec, repeat, function, args });
}

///no spawn thread each callback function
pub fn start2(wait_nanosec: u64, repeat: u32, comptime function: anytype, args: anytype) std.Thread.SpawnError!std.Thread {
    return try std.Thread.spawn(.{}, callback2, .{ wait_nanosec, repeat, function, args });
}
