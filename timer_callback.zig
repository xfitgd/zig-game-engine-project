const std = @import("std");
const system = @import("system.zig");

const Self = @This();

thread: std.Thread,

fn loop(wait_nanosec: u64, comptime function: anytype, args: anytype) bool {
    std.time.sleep(wait_nanosec);
    if (@typeInfo(@typeInfo(@TypeOf(function)).Fn.return_type.?) == .ErrorUnion) { // ? 표준 라이브러리 Thread.zig에서 가져온 코드
        const res = @call(.auto, function, args) catch |err| {
            system.print_error("ERR : {s}\n", .{@errorName(err)});
            // if (@errorReturnTrace()) |trace| {
            //     std.debug.dumpStackTrace(trace.*);
            // } 모바일 작동을 보장할수 없어서 일단은 비활성화
            return false;
        };
        if (@typeInfo(@TypeOf(res)) == .Bool and !res) return false;
    } else {
        const res = function(args);
        if (@typeInfo(@TypeOf(res)) == .Bool and !res) return false;
    }
    return true;
}

fn callback(wait_nanosec: u64, repeat: u32, comptime function: anytype, args: anytype) void {
    var re = repeat;
    if (re == 0) {
        while (true) {
            if (!loop(wait_nanosec, function, args)) break;
        }
    } else {
        while (re > 0) : (re -= 1) {
            if (!loop(wait_nanosec, function, args)) break;
        }
    }
}

///반환 타입을 bool로 하고 false를 리턴시키면 또는 오류발생시 도중에 타이머 루프 종료
pub fn start(wait_nanosec: u64, repeat: u32, comptime function: anytype, args: anytype) std.Thread.SpawnError!std.Thread {
    return try std.Thread.spawn(.{}, callback, .{ wait_nanosec, repeat, function, args });
}
