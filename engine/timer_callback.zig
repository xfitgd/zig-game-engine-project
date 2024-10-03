const std = @import("std");
const system = @import("system.zig");

inline fn loop(wait_nanosec: u64, comptime function: anytype, args: anytype) bool {
    system.sleep(wait_nanosec);
    return callback_(function, args);
}

fn callback_(comptime function: anytype, args: anytype) bool {
    const res = @typeInfo(@typeInfo(@TypeOf(function)).@"fn".return_type.?);
    if (res == .error_union) { // ? 표준 라이브러리 Thread.zig에서 가져온 코드
        if (res.error_union.payload == bool) {
            return @call(.auto, function, args) catch |err| {
                system.print_error("ERR : {s}\n", .{@errorName(err)});
                return false;
            };
        } else {
            _ = @call(.auto, function, args) catch |err| {
                system.print_error("ERR : {s}\n", .{@errorName(err)});
                return false;
            };
        }
    } else if (res == .bool) {
        return @call(.auto, function, args);
    } else {
        _ = @call(.auto, function, args);
    }
    return true;
}

fn callback(wait_nanosec: u64, repeat: u64, comptime function: anytype, args: anytype) void {
    var re = repeat;
    if (re == 0) {
        while (loop(wait_nanosec, function, args)) {}
    } else {
        while (re > 0 and loop(wait_nanosec, function, args)) : (re -= 1) {}
    }
}

///no spawn thread each callback function bool callback function return false or cause error -> exit timer
pub fn start(wait_nanosec: u64, repeat: u64, comptime function: anytype, args: anytype) std.Thread.SpawnError!std.Thread {
    return try std.Thread.spawn(.{}, callback, .{ wait_nanosec, repeat, function, args });
}
