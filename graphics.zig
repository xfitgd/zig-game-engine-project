const std = @import("std");
const ArrayList = std.ArrayList;

const file = @import("file.zig");
const system = @import("system.zig");
const __system = @import("__system.zig");
const __vulkan_allocator = @import("__vulkan_allocator.zig");

const _allocator = __system.allocator;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;

const math = @import("math.zig");
const point = math.point;
const point3d = math.point3d;
const vector = math.vector;
const matrix4x4 = math.matrix4x4;
const matrix_error = math.matrix_error;

const vulkan_buffer_node = __vulkan_allocator.vulkan_buffer_node;

pub const color_vertex_2d = color_vertex_2d_(f32);

pub fn color_vertex_2d_(comptime T: type) type {
    return extern struct {
        pos: point(T) align(1),
        color: vector(T) align(1),

        pub inline fn get_pipeline() vk.VkPipeline {
            return __vulkan.color_2d_pipeline;
        }
    };
}

pub var scene: ?*[]*ivertices = null;

fn find_memory_type(_type_filter: u32, _prop: vk.VkMemoryPropertyFlags) u32 {
    var mem_prop: vk.VkPhysicalDeviceMemoryProperties = undefined;
    vk.vkGetPhysicalDeviceMemoryProperties(__vulkan.vk_physical_devices[0], &mem_prop);

    var i: u32 = 0;
    while (i < mem_prop.memoryTypeCount) : (i += 1) {
        if ((_type_filter & (@as(u32, 1) << @intCast(i)) != 0) and (mem_prop.memoryTypes[i].propertyFlags & _prop == _prop)) {
            return i;
        }
    }
    system.print_error("ERR find_memory_type.memory_type_not_found\n", .{});
    unreachable;
}

pub const ivertices = struct {
    const Self = @This();

    get_vertices_len: *const fn (self: *ivertices) usize = undefined,

    node: vulkan_buffer_node = vulkan_buffer_node.init(),
    pipeline: vk.VkPipeline = undefined,

    pub inline fn clean(self: *Self) void {
        if (self.*.node.buffer != null) {
            __vulkan_allocator.destroy_buffer(&self.*.node);
        }
    }
};

pub fn vertices(comptime vertexT: type) type {
    return struct {
        const Self = @This();

        array: ArrayList(vertexT) = undefined,
        interface: ivertices = .{},

        pub fn init(allocator: std.mem.Allocator) Self {
            var self: Self = .{};
            self.array = ArrayList(vertexT).init(allocator);
            self.interface.pipeline = vertexT.get_pipeline();
            self.interface.get_vertices_len = get_vertices_len;
            return self;
        }
        pub fn get_vertices_len(_interface: *ivertices) usize {
            const self = @as(*Self, @fieldParentPtr("interface", _interface));
            return self.*.array.items.len;
        }
        ///완전히 정리
        pub inline fn destroy(self: *Self) void {
            clean(self);
            self.*.array.deinit();
        }
        ///다시 빌드할수 있게 버퍼 내용만 정리
        pub inline fn clean(self: *Self) void {
            self.*.interface.clean();
        }
        pub fn build(self: *Self) !void {
            clean(self);
            const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = @sizeOf(vertexT) * self.*.array.items.len, .usage = vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

            try __vulkan.vk_allocator.create_buffer(&buf_info, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_CACHED_BIT, &self.*.interface.node);

            var data: ?*anyopaque = undefined;
            try self.*.interface.node.map(&data);
            @memcpy(@as([*]vertexT, @alignCast(@ptrCast(data))), self.*.array.items);
            //system.print("{d} {d}\n", .{ self.*.array.len, @as([*]vertexT, @alignCast(@ptrCast(data)))[0..self.*.array.len] });
            self.*.interface.node.unmap();
        }
    };
}
