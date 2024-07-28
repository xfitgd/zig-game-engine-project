//TODO VkDeviceMemory 하나당 vkBuffer 여러개를 효율적으로 할당할수 있게 만드는것이 목표인 vulkan 할당자
const std = @import("std");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;
const MemoryPool = std.heap.MemoryPool;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;
const __system = @import("__system.zig");
const system = @import("system.zig");
const math = @import("math.zig");

const _allocator = __system.allocator;

const BLOCK_LEN = 100;
const Self = @This();

pub const vulkan_alloc_error = error{ out_of_host_memory, out_of_device_memory, buffer_full };

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

pub const vulkan_buffer_node = struct {
    buffer: vk.VkBuffer,
    idx: u64,
    pvulkan_buffer: *vulkan_buffer,

    pub fn init() vulkan_buffer_node {
        return .{
            .buffer = null,
            .idx = 0,
            .pvulkan_buffer = undefined,
        };
    }
    pub fn map(self: *vulkan_buffer_node, _out_data: *?*anyopaque) !void {
        try self.*.pvulkan_buffer.*.map(self.*.idx, _out_data);
    }
    pub fn unmap(self: *vulkan_buffer_node) void {
        self.*.pvulkan_buffer.*.unmap();
    }
};

/// Vulkan 메모리 체계가 u64이기 때문에 u64를 사용하겠습니다.
const vulkan_buffer = struct {
    indices: []u64,
    cell_size: u64,
    __free_len: u64,
    len: u64,
    __init_len: u64,
    __next: ?*u64,
    mem: vk.VkDeviceMemory,
    info: vk.VkMemoryAllocateInfo,

    ///! 따로 vulkan_buffer.destroy를 호출하지 않는다.
    fn destroy(self: *vulkan_buffer) void {
        vk.vkFreeMemory(__vulkan.vkDevice, self.*.mem, null);
        _allocator.free(self.*.indices);
    }
    pub fn init(_cell_size: u64, _len: u64, type_filter: u32, _prop: vk.VkMemoryPropertyFlags) !vulkan_buffer {
        var res = vulkan_buffer{
            .indices = try _allocator.alloc(u64, _len),
            .cell_size = _cell_size,
            .len = _len,
            .__init_len = 0,
            .__free_len = _len,
            .mem = undefined,
            .__next = null,
            .info = .{ .sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, .allocationSize = _len * _cell_size, .memoryTypeIndex = find_memory_type(type_filter, _prop) },
        };
        const result = vk.vkAllocateMemory(__vulkan.vkDevice, &res.info, null, &res.mem);
        errdefer _allocator.free(res.indices);
        if (result == vk.VK_ERROR_OUT_OF_HOST_MEMORY) {
            return vulkan_alloc_error.out_of_host_memory;
        } else if (result == vk.VK_ERROR_OUT_OF_DEVICE_MEMORY) {
            return vulkan_alloc_error.out_of_device_memory;
        }
        system.handle_error(result == vk.VK_SUCCESS, result, "vulkan_buffer.init.vkAllocateMemory");

        res.__next = &res.indices[0];
        return res;
    }
    fn __bind_buffer(self: *vulkan_buffer, _buf: vk.VkBuffer, _idx: u64) !void {
        const result = vk.vkBindBufferMemory(__vulkan.vkDevice, _buf, self.*.mem, self.*.cell_size * _idx);
        if (result == vk.VK_ERROR_OUT_OF_HOST_MEMORY) {
            return vulkan_alloc_error.out_of_host_memory;
        } else if (result == vk.VK_ERROR_OUT_OF_DEVICE_MEMORY) {
            return vulkan_alloc_error.out_of_device_memory;
        }
        system.handle_error(result == vk.VK_SUCCESS, result, "vulkan_buffer.bind_buffer.vkBindBufferMemory");
    }
    pub fn map(self: *vulkan_buffer, _buf_idx: u64, _out_data: *?*anyopaque) !void {
        const result = vk.vkMapMemory(__vulkan.vkDevice, self.*.mem, _buf_idx * self.*.cell_size, self.*.cell_size, 0, _out_data);
        if (result == vk.VK_ERROR_OUT_OF_HOST_MEMORY) {
            return vulkan_alloc_error.out_of_host_memory;
        } else if (result == vk.VK_ERROR_OUT_OF_DEVICE_MEMORY) {
            return vulkan_alloc_error.out_of_device_memory;
        }
        system.handle_error(result == vk.VK_SUCCESS, result, "vulkan_buffer.map.vkMapMemory");
    }
    pub fn unmap(self: *vulkan_buffer) void {
        vk.vkUnmapMemory(__vulkan.vkDevice, self.*.mem);
    }
    ///_buf 크기는 따로 확인하지 않는다. 호출 쪽에서 확인해서 오류가 없게한다.
    pub fn bind_buffer(self: *vulkan_buffer, _buf: vk.VkBuffer) !u64 {
        if (self.*.__init_len < self.*.len) {
            self.*.indices[self.*.__init_len] = self.*.__init_len + 1;
            self.*.__init_len += 1;
        }
        if (self.*.__free_len > 0) {
            try __bind_buffer(self, _buf, self.*.__next.?.*);
            const res: u64 = self.*.__next.?.*;
            self.*.__free_len -= 1;
            if (self.*.__free_len > 0) {
                self.*.__next = &self.*.indices[self.*.__next.?.*];
            } else {
                self.*.__next = null;
            }
            return res;
        } else {
            return vulkan_alloc_error.buffer_full;
        }
    }
    ///bind_buffer에서 반환된 idx를 사용, 버퍼 삭제는 별도로
    pub fn unbind_buffer(self: *vulkan_buffer, _idx: u64) void {
        self.*.indices[_idx] = if (self.*.__next == null) self.*.len else (@as(u64, @intFromPtr(self.*.__next.?)) - @as(u64, @intFromPtr(&self.indices[0]))) / @sizeOf(u64);
        self.*.__next = &self.*.indices[_idx];
        self.*.__free_len += 1;
    }
};

pub fn init() Self {
    return Self{
        .buffers = MemoryPool(vulkan_buffer).init(_allocator),
        .buffer_ids = ArrayList(*vulkan_buffer).init(_allocator),
    };
}

buffers: MemoryPool(vulkan_buffer),
buffer_ids: ArrayList(*vulkan_buffer),

pub fn create_buffer(self: *Self, _buf_info: *const vk.VkBufferCreateInfo, _prop: vk.VkMemoryPropertyFlags, _out_vulkan_buffer_node: *vulkan_buffer_node) !void {
    const result = vk.vkCreateBuffer(__vulkan.vkDevice, _buf_info, null, &_out_vulkan_buffer_node.*.buffer);
    system.handle_error(result == vk.VK_SUCCESS, result, "__vulkan_allocator.create_buffer.vkCreateBuffer");
    errdefer vk.vkDestroyBuffer(__vulkan.vkDevice, _out_vulkan_buffer_node.*.buffer, null);

    var mem_require: vk.VkMemoryRequirements = undefined;
    vk.vkGetBufferMemoryRequirements(__vulkan.vkDevice, _out_vulkan_buffer_node.*.buffer, &mem_require);

    var buf: ?*vulkan_buffer = null;
    for (self.*.buffer_ids.items) |value| {
        if (mem_require.size < value.*.cell_size) continue;
        _out_vulkan_buffer_node.*.idx = value.*.bind_buffer(_out_vulkan_buffer_node.*.buffer) catch {
            continue;
        };
        buf = value;
        break;
    }
    if (buf == null) {
        buf = try self.*.buffers.create();
        errdefer self.*.buffers.destroy(buf.?);
    }
    try self.*.buffer_ids.append(buf.?);
    errdefer _ = self.*.buffer_ids.pop();

    buf.?.* = try vulkan_buffer.init(math.round_up(u64, mem_require.size, mem_require.alignment), BLOCK_LEN, mem_require.memoryTypeBits, _prop);
    errdefer buf.?.*.destroy();

    _out_vulkan_buffer_node.*.idx = try buf.?.*.bind_buffer(_out_vulkan_buffer_node.*.buffer);
    _out_vulkan_buffer_node.*.pvulkan_buffer = buf.?;
}
pub fn destroy_buffer(_in_vulkan_buffer_node: *vulkan_buffer_node) void {
    vk.vkDestroyBuffer(__vulkan.vkDevice, _in_vulkan_buffer_node.*.buffer, null);

    _in_vulkan_buffer_node.*.pvulkan_buffer.*.unbind_buffer(_in_vulkan_buffer_node.*.idx);
}
///destroy_buffer 후 호출
pub fn destroy(self: *Self) void {
    for (self.*.buffer_ids.items) |value| {
        value.*.destroy(); // ! 따로 vulkan_buffer.destroy를 호출하지 않는다.
    }
    self.*.buffers.deinit();
}
