const std = @import("std");
const ArrayList = std.ArrayList;

const file = @import("file.zig");
const system = @import("system.zig");
const __system = @import("__system.zig");

const _allocator = __system.allocator;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;
const math = @import("math.zig");
const point = math.point;
const point3d = math.point3d;
const vector = math.vector;
const matrix4x4 = @import("math.zig").matrix4x4;
const matrix_error = @import("math.zig").matrix_error;

const vkDevice = &__vulkan.vkDevice;

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
    buf: vk.VkBuffer = null,
    buf_mem: vk.VkDeviceMemory = undefined,
    pipeline: vk.VkPipeline = undefined,

    pub inline fn clean(self: *Self) void {
        if (self.*.buf != null) {
            vk.vkDestroyBuffer(vkDevice.*, self.*.buf, null);
            vk.vkFreeMemory(vkDevice.*, self.*.buf_mem, null);
            self.*.buf = null;
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
        pub inline fn free(self: *Self) void {
            clean(self);
            self.*.array.deinit();
        }
        pub inline fn clean(self: *Self) void {
            self.*.interface.clean();
        }
        pub fn build(self: *Self) void {
            clean(self);
            const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = @sizeOf(vertexT) * self.*.array.items.len, .usage = vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

            var result = vk.vkCreateBuffer(vkDevice.*, &buf_info, null, &self.*.interface.buf);
            system.handle_error(result == vk.VK_SUCCESS, result, "vertex_T._build.vkCreateBuffer");

            var mem_require: vk.VkMemoryRequirements = undefined;
            vk.vkGetBufferMemoryRequirements(vkDevice.*, self.*.interface.buf, &mem_require);

            const alloc_info: vk.VkMemoryAllocateInfo = .{
                .sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
                .allocationSize = mem_require.size,
                .memoryTypeIndex = find_memory_type(mem_require.memoryTypeBits, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_CACHED_BIT),
            };

            result = vk.vkAllocateMemory(vkDevice.*, &alloc_info, null, &self.*.interface.buf_mem);
            system.handle_error(result == vk.VK_SUCCESS, result, "vertex_T._build.vkAllocateMemory");
            result = vk.vkBindBufferMemory(vkDevice.*, self.*.interface.buf, self.*.interface.buf_mem, 0);
            system.handle_error(result == vk.VK_SUCCESS, result, "vertex_T._build.vkBindBufferMemory");

            var data: ?*anyopaque = undefined;
            result = vk.vkMapMemory(vkDevice.*, self.*.interface.buf_mem, 0, buf_info.size, 0, &data);
            system.handle_error(result == vk.VK_SUCCESS, result, "vertex_T._build.vkBindBufferMemory");
            @memcpy(@as([*]vertexT, @alignCast(@ptrCast(data))), self.*.array.items);
            //system.print("{d} {d}\n", .{ self.*.array.len, @as([*]vertexT, @alignCast(@ptrCast(data)))[0..self.*.array.len] });
            vk.vkUnmapMemory(vkDevice.*, self.*.interface.buf_mem);
        }
    };
}
