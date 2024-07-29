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
const MINIMUM_SIZE_DIV_CELL = 0.5;
const Self = @This();

//TODO 메모리 부족시 오류 처리가 제대로 안되있습니다.(unreachable로 때움)
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
    is_free: []bool,
    cell_size: u64,
    len: u64,
    cur: u64,
    mem: vk.VkDeviceMemory,
    info: vk.VkMemoryAllocateInfo,

    ///! 따로 vulkan_buffer.destroy를 호출하지 않는다.
    fn destroy(self: *vulkan_buffer) void {
        vk.vkFreeMemory(__vulkan.vkDevice, self.*.mem, null);
        _allocator.free(self.*.is_free);
    }
    fn allocate_memory(_info: *const vk.VkMemoryAllocateInfo, _mem: *vk.VkDeviceMemory) !void {
        const result = vk.vkAllocateMemory(__vulkan.vkDevice, _info, null, _mem);

        if (result == vk.VK_ERROR_OUT_OF_HOST_MEMORY) {
            return vulkan_alloc_error.out_of_host_memory;
        } else if (result == vk.VK_ERROR_OUT_OF_DEVICE_MEMORY) {
            return vulkan_alloc_error.out_of_device_memory;
        }
        system.handle_error(result == vk.VK_SUCCESS, result, "vulkan_buffer.init.vkAllocateMemory");
    }
    /// ! 따로 vulkan_buffer.init를 호출하지 않는다.
    fn init(_cell_size: u64, _len: u64, type_filter: u32, _prop: vk.VkMemoryPropertyFlags) !vulkan_buffer {
        var res = vulkan_buffer{
            .cell_size = _cell_size,
            .len = _len,
            .cur = 0,
            .mem = undefined,
            .is_free = try _allocator.alloc(bool, _len),
            .info = .{ .sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, .allocationSize = _len * _cell_size, .memoryTypeIndex = find_memory_type(type_filter, _prop) },
        };
        try allocate_memory(&res.info, &res.mem);
        errdefer _allocator.free(res.is_free);

        for (res.is_free) |*value| {
            value.* = true;
        }

        return res;
    }
    fn __bind_buffer(self: *vulkan_buffer, _mem: vk.VkDeviceMemory, _buf: vk.VkBuffer, _idx: u64) !void {
        const result = vk.vkBindBufferMemory(__vulkan.vkDevice, _buf, _mem, self.*.cell_size * _idx);
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
    fn bind_buffer(self: *vulkan_buffer, _buf: vk.VkBuffer) !u64 {
        var count: u64 = 0;
        while (!self.*.is_free[self.*.cur]) {
            self.*.cur += 1;
            count += 1;
            if (count >= self.*.len) return vulkan_alloc_error.buffer_full;
            if (self.*.cur >= self.*.len) self.*.cur = 0;
        }
        try __bind_buffer(self, self.*.mem, _buf, self.*.cur);
        self.*.is_free[self.*.cur] = false;

        const res = self.*.cur;
        self.*.cur += 1;
        if (self.*.cur >= self.*.len) self.*.cur = 0;
        return res;
    }
    ///bind_buffer에서 반환된 idx를 사용.
    fn unbind_buffer(self: *vulkan_buffer, _buf: vk.VkBuffer, _idx: u64) void {
        self.*.is_free[_idx] = true;
        vk.vkDestroyBuffer(__vulkan.vkDevice, _buf, null);
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
        if (mem_require.size > value.*.cell_size or mem_require.size < @as(u64, @intFromFloat(MINIMUM_SIZE_DIV_CELL * @as(f64, @floatFromInt(value.*.cell_size))))) continue;
        _out_vulkan_buffer_node.*.idx = value.*.bind_buffer(_out_vulkan_buffer_node.*.buffer) catch {
            continue;
        };
        buf = value;
        break;
    }
    if (buf == null) {
        buf = try self.*.buffers.create();
        errdefer self.*.buffers.destroy(buf.?);
        buf.?.* = try vulkan_buffer.init(math.round_up(u64, mem_require.size, mem_require.alignment), BLOCK_LEN, mem_require.memoryTypeBits, _prop);
        errdefer buf.?.*.destroy();

        _out_vulkan_buffer_node.*.idx = try buf.?.*.bind_buffer(_out_vulkan_buffer_node.*.buffer);
        try self.*.buffer_ids.append(buf.?);
    }
    _out_vulkan_buffer_node.*.pvulkan_buffer = buf.?;
}
pub fn destroy_buffer(_in_vulkan_buffer_node: *vulkan_buffer_node) void {
    _in_vulkan_buffer_node.*.pvulkan_buffer.*.unbind_buffer(_in_vulkan_buffer_node.*.buffer, _in_vulkan_buffer_node.*.idx);

    _in_vulkan_buffer_node.*.buffer = null;
}
///destroy_buffer 후 호출
pub fn destroy(self: *Self) void {
    for (self.*.buffer_ids.items) |value| {
        value.*.destroy(); // ! 따로 vulkan_buffer.destroy를 호출하지 않는다.
    }
    self.*.buffers.deinit();
}
