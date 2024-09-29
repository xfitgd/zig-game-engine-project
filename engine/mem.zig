const std = @import("std");
const builtin = @import("builtin");
const system = @import("system.zig");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const MemoryPool = std.heap.MemoryPool;

//TODO 검증되지 않음

pub inline fn memcpy_nonarray(dest: anytype, src: anytype) void {
    @memcpy(std.mem.asBytes(dest), std.mem.asBytes(src));
}
pub inline fn align_ptr_cast(dest_type: type, src: anytype) dest_type {
    return @as(dest_type, @ptrCast(@alignCast(src)));
}
///src 타입 배열(Slice)을 u8 배열(Slice)로 변환한다.
pub inline fn u8arr(src: anytype) []u8 {
    return @as([*]u8, @ptrCast(src.ptr))[0..@divFloor(@sizeOf(@TypeOf(src)), @sizeOf(u8))];
}
///src 타입 배열(Slice)을 dest_type 타입 배열(Slice)로 변환한다.
pub inline fn cvtarr(comptime dest_type: type, src: anytype) []dest_type {
    return @as([*]dest_type, src.ptr)[0..@divFloor(@sizeOf(@TypeOf(src)), @sizeOf(dest_type))];
}
