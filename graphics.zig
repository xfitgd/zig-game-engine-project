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

pub const vertex_type = enum(u32) {
    pos,
    uv,
    color,
    normal,
    tangent,
    binormal,
};
pub const vertex = vertex_T(f32);

pub var objects: ArrayList(*vertex) = ArrayList(*vertex).init(_allocator);

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

pub fn vertex_T(comptime T: type) type {
    return struct {
        const Self = @This();
        const BUF_LEN = 6;

        pos: ArrayList(vector(T)) = undefined,
        uv: ArrayList(vector(T)) = undefined,
        color: ArrayList(vector(T)) = undefined,
        normal: ArrayList(vector(T)) = undefined,
        tangent: ArrayList(vector(T)) = undefined,
        binormal: ArrayList(vector(T)) = undefined,
        bufs: [BUF_LEN]vk.VkBuffer = .{null} ** BUF_LEN,
        buf_mems: [BUF_LEN]vk.VkDeviceMemory = .{null} ** BUF_LEN,

        pub fn clean(self: *Self) void {
            comptime var i = 0;
            inline while (i < BUF_LEN) : (i += 1) {
                if (self.*.bufs[i] != null) {
                    vk.vkDestroyBuffer(vkDevice.*, self.*.bufs[i], null);
                    vk.vkFreeMemory(vkDevice.*, self.*.buf_mems[i], null);
                    self.*.bufs[i] = null;
                    self.*.buf_mems[i] = null;
                }
            }
        }
        fn _build(self: *Self, _type: vertex_type, _array: []vector(T)) void {
            const buf_idx = @intFromEnum(_type);
            if (self.*.bufs[buf_idx] != null) {
                vk.vkDestroyBuffer(vkDevice.*, self.*.bufs[buf_idx], null);
                vk.vkFreeMemory(vkDevice.*, self.*.buf_mems[buf_idx], null);
            }
            const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = @sizeOf(vector(T)) * _array.len, .usage = vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

            var result = vk.vkCreateBuffer(vkDevice.*, &buf_info, null, &self.*.bufs[buf_idx]);
            system.handle_error(result == vk.VK_SUCCESS, result, "vertex_T._build.vkCreateBuffer");

            var mem_require: vk.VkMemoryRequirements = undefined;
            vk.vkGetBufferMemoryRequirements(vkDevice.*, self.*.bufs[buf_idx], &mem_require);

            const alloc_info: vk.VkMemoryAllocateInfo = .{
                .sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
                .allocationSize = mem_require.size,
                .memoryTypeIndex = find_memory_type(mem_require.memoryTypeBits, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_CACHED_BIT),
            };

            result = vk.vkAllocateMemory(vkDevice.*, &alloc_info, null, &self.*.buf_mems[buf_idx]);
            system.handle_error(result == vk.VK_SUCCESS, result, "vertex_T._build.vkAllocateMemory");
            result = vk.vkBindBufferMemory(vkDevice.*, self.*.bufs[buf_idx], self.*.buf_mems[buf_idx], 0);
            system.handle_error(result == vk.VK_SUCCESS, result, "vertex_T._build.vkBindBufferMemory");

            var data: ?*anyopaque = undefined;
            result = vk.vkMapMemory(vkDevice.*, self.*.buf_mems[buf_idx], 0, buf_info.size, 0, &data);
            system.handle_error(result == vk.VK_SUCCESS, result, "vertex_T._build.vkBindBufferMemory");
            @memcpy(@as([*]vector(T), @alignCast(@ptrCast(data))), _array);
            system.print("{d} {d}\n", .{ _array.len, @as([*]vector(T), @alignCast(@ptrCast(data)))[0.._array.len] });
            vk.vkUnmapMemory(vkDevice.*, self.*.buf_mems[buf_idx]);
        }
        pub fn build(self: *Self, comptime _type: vertex_type) void {
            _build(self, _type, @field(self.*, @tagName(_type)).items);
        }
    };
}
