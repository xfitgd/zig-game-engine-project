const std = @import("std");
const ArrayList = std.ArrayList;

const file = @import("file.zig");
const system = @import("system.zig");
const __system = @import("__system.zig");

const _allocator = __system.allocator;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;
const math = @import("math.zig");
const vector = math.vector;
const matrix4x4 = @import("matrix_.zig").matrix4x4;
const matrix_error = @import("matrix_.zig").matrix_error;

pub const vertex = vertex_T(f32);

pub fn vertex_T(comptime T: type) type {
    return struct {
        const Self = @This();
        vertices: ArrayList(vector(T)) = undefined,
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{ .vertices = ArrayList(vector(T)).init(allocator) };
        }
        pub fn build() !void {}
    };
}
