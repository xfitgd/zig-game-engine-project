const std = @import("std");

pub inline fn test_number_type(T: type) void {
    switch (@typeInfo(T)) {
        .Int, .Float, .ComptimeInt, .ComptimeFloat => {},
        else => {
            @compileError("not a number type");
        },
    }
}
pub inline fn test_float_type(T: type) void {
    switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => {},
        else => {
            @compileError("not a number type");
        },
    }
}
