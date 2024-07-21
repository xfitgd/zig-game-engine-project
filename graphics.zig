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
const matrix4x4 = @import("math.zig").matrix4x4;
const matrix_error = @import("math.zig").matrix_error;

pub const write_flag = enum {
    write_GPU,
    read_only,
    write_CPU,
    read_write_CPU,
};
pub const vertex_type = enum {
    pos,
    uv,
    color,
    normal,
    tangent,
    binormal,
};
pub const vertex = vertex_T(f32);

pub fn vertex_T(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const node = struct {
            array: ArrayList(vector(T)) = undefined,
            buf: vk.VkBuffer = null,
            flag: write_flag = null,
        };
        pos: node,
        uv: node,
        color: node,
        normal: node,
        tangent: node,
        binormal: node,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{ .vertices = ArrayList(vector(T)).init(allocator) };
        }
        pub fn build(_type: vertex_type, _flag: write_flag) !void {
            _ = _flag;
            switch (_type) {
                .pos => {},
                .uv => {},
                .color => {},
                .normal => {},
                .tangent => {},
                .binormal => {},
            }
        }
    };
}
