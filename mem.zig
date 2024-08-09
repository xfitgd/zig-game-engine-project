const std = @import("std");

//TODO 검증되지 않음

pub inline fn memcpy_nonarray(dest: anytype, src: anytype) void {
    @memcpy(std.mem.asBytes(dest), std.mem.asBytes(src));
}
pub inline fn align_ptr_cast(dest_type: type, src: anytype) dest_type {
    return @as(dest_type, @ptrCast(@alignCast(src)));
}
pub inline fn u8arr(src: anytype) *[@sizeOf(@TypeOf(src))]u8 {
    return @as(*[@sizeOf(@TypeOf(src))]u8, @constCast(@ptrCast(&src)));
}
pub inline fn cvtarr(comptime dest_type: type, src: anytype) *[@divFloor(@sizeOf(@TypeOf(src)), @sizeOf(dest_type))]dest_type {
    return @as(*[@divFloor(@sizeOf(@TypeOf(src)), @sizeOf(dest_type))]u8, @constCast(@ptrCast(&src)));
}
