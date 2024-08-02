const std = @import("std");

pub fn memcpy_nonarray(dest: anytype, src: anytype) void {
    @memcpy(std.mem.asBytes(dest), std.mem.asBytes(src));
}
pub fn align_ptr_cast(dest_type: type, src: anytype) dest_type {
    return @as(dest_type, @ptrCast(@alignCast(src)));
}
