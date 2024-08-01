const std = @import("std");

pub fn memcpy_nonarray(dest: anytype, src: anytype) void {
    @memcpy(std.mem.asBytes(dest), std.mem.asBytes(src));
}
pub fn align_ptr_cast(dest: anytype, src: anytype) @TypeOf(dest) {
    return @as(@TypeOf(dest), @ptrCast(@alignCast(src)));
}
