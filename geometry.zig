const std = @import("std");

const math = @import("math.zig");

pub fn rect(comptime T: type) type {
    math.test_number_type(T);
    return struct {
        const Self = @This();
        left: T,
        right: T,
        top: T,
        bottom: T,

        pub inline fn width(self: *Self) T {
            return @intCast(@abs(self.right - self.left));
        }
        pub inline fn height(self: *Self) T {
            return @intCast(@abs(self.top - self.bottom));
        }
        pub fn init(_left: T, _right: T, _top: T, _bottom: T) Self {
            return Self{
                .left = _left,
                .right = _right,
                .top = _top,
                .bottom = _bottom,
            };
        }
    };
}

pub fn point(comptime T: type) type {
    math.test_number_type(T);
    return @Vector(2, T);
}

pub fn point3dw(comptime T: type) type {
    math.test_number_type(T);
    return @Vector(4, T);
}

inline fn f32x4_mask3(comptime T: type) @Vector(4, T) {
    return @Vector(4, T){
        @as(T, @bitCast(@as(u32, 0xffff_ffff))),
        @as(T, @bitCast(@as(u32, 0xffff_ffff))),
        @as(T, @bitCast(@as(u32, 0xffff_ffff))),
        0,
    };
}

inline fn andInt(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    const T = @TypeOf(v0, v1);
    const Tu = @Vector(@typeInfo(T).Vector.Len, u32);
    const v0u = @as(Tu, @bitCast(v0));
    const v1u = @as(Tu, @bitCast(v1));
    return @as(T, @bitCast(v0u & v1u)); // andps
}
pub inline fn dot3(comptime T: type, v0: point3dw(T), v1: point3dw(T)) T {
    const dot = v0 * v1;
    return dot[0] + dot[1] + dot[2];
}
pub inline fn normalize3(comptime T: type, v: point3dw(T)) point3dw(T) {
    return v * @as(point3dw(T), @splat(1)) / std.math.sqrt(dot3(v, v));
}
pub inline fn cross3(comptime T: type, v0: point3dw(T), v1: point3dw(T)) point3dw(T) {
    var xmm0 = @shuffle(T, v0, undefined, [4]i32{ 1, 2, 1, 3 });
    var xmm1 = @shuffle(T, v1, undefined, [4]i32{ 2, 0, 1, 3 });
    var result = xmm0 * xmm1;
    xmm0 = @shuffle(T, xmm0, undefined, [4]i32{ 1, 2, 0, 3 });
    xmm1 = @shuffle(T, xmm1, undefined, [4]i32{ 2, 0, 1, 3 });
    result = result - xmm0 * xmm1;
    result[3] = 0;
    return result;
}
