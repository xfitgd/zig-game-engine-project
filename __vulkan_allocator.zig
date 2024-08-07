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

const BLOCK_LEN = 128;

///버퍼 크기가 MINIMUM_SIZE보다 크면서 셀 크기의 MINIMUM_SIZE_DIV_CELL비율 보다 작을 경우 공간 활용을 위해 다른 버퍼에 넣는다.
const MINIMUM_SIZE_DIV_CELL = 0.5;
const MINIMUM_SIZE = 128;
const Self = @This();

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
    buffer: vk.VkBuffer = null,
    idx: u64 = undefined,
    pvulkan_buffer: *vulkan_buffer = undefined,

    pub inline fn is_build(self: *vulkan_buffer_node) bool {
        return self.*.buffer != null;
    }
    pub inline fn map(self: *vulkan_buffer_node, _out_data: *?*anyopaque) void {
        self.*.pvulkan_buffer.*.map(self.*.idx, _out_data);
    }
    pub inline fn unmap(self: *vulkan_buffer_node) void {
        self.*.pvulkan_buffer.*.unmap();
    }
    pub inline fn clean(self: *vulkan_buffer_node) void {
        if (is_build(self)) {
            destroy_buffer(self);
            self.*.buffer = null;
        }
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

    ///! 따로 vulkan_buffer.deinit를 호출하지 않는다.
    fn deinit(self: *vulkan_buffer) void {
        vk.vkFreeMemory(__vulkan.vkDevice, self.*.mem, null);
        __system.allocator.free(self.*.is_free);
    }
    fn allocate_memory(_info: *const vk.VkMemoryAllocateInfo, _mem: *vk.VkDeviceMemory) void {
        const result = vk.vkAllocateMemory(__vulkan.vkDevice, _info, null, _mem);

        system.handle_error(result == vk.VK_SUCCESS, result, "vulkan_buffer.init.vkAllocateMemory");
    }
    /// ! 따로 vulkan_buffer.init를 호출하지 않는다.
    fn init(_cell_size: u64, _len: u64, type_filter: u32, _prop: vk.VkMemoryPropertyFlags) vulkan_buffer {
        var res = vulkan_buffer{
            .cell_size = _cell_size,
            .len = _len,
            .cur = 0,
            .mem = undefined,
            .is_free = __system.allocator.alloc(bool, _len) catch |err| {
                system.print_error("ERR : {s}\n", .{@errorName(err)});
                unreachable;
            },
            .info = .{ .sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, .allocationSize = _len * _cell_size, .memoryTypeIndex = find_memory_type(type_filter, _prop) },
        };
        allocate_memory(&res.info, &res.mem);

        for (res.is_free) |*value| {
            value.* = true;
        }

        return res;
    }
    fn __bind_buffer(self: *vulkan_buffer, _mem: vk.VkDeviceMemory, _buf: vk.VkBuffer, _idx: u64) void {
        const result = vk.vkBindBufferMemory(__vulkan.vkDevice, _buf, _mem, self.*.cell_size * _idx);
        system.handle_error(result == vk.VK_SUCCESS, result, "vulkan_buffer.bind_buffer.vkBindBufferMemory");
    }
    pub fn map(self: *vulkan_buffer, _buf_idx: u64, _out_data: *?*anyopaque) void {
        const result = vk.vkMapMemory(__vulkan.vkDevice, self.*.mem, _buf_idx * self.*.cell_size, self.*.cell_size, 0, _out_data);
        system.handle_error(result == vk.VK_SUCCESS, result, "vulkan_buffer.map.vkMapMemory");
    }
    pub fn unmap(self: *vulkan_buffer) void {
        vk.vkUnmapMemory(__vulkan.vkDevice, self.*.mem);
    }
    ///_buf 크기는 따로 확인하지 않는다. 호출 쪽에서 확인해서 오류가 없게한다.
    fn bind_buffer(self: *vulkan_buffer, _buf: vk.VkBuffer) u64 {
        var count: u64 = 0;
        while (!self.*.is_free[self.*.cur]) {
            self.*.cur += 1;
            count += 1;
            if (count >= self.*.len) unreachable; //TODO 버퍼 꽉찰시 버퍼 확장 또는 새버퍼에 넣기
            if (self.*.cur >= self.*.len) self.*.cur = 0;
        }
        __bind_buffer(self, self.*.mem, _buf, self.*.cur);
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
        .buffers = MemoryPool(vulkan_buffer).init(__system.allocator),
        .buffer_ids = ArrayList(*vulkan_buffer).init(__system.allocator),
    };
}

buffers: MemoryPool(vulkan_buffer),
buffer_ids: ArrayList(*vulkan_buffer),

fn create_allocator_and_bind(self: *Self, _buf: vk.VkBuffer, _mem_require: *const vk.VkMemoryRequirements, _prop: vk.VkMemoryPropertyFlags, _out_idx: *u64) *vulkan_buffer {
    var buf: ?*vulkan_buffer = null;
    for (self.*.buffer_ids.items) |value| {
        //버퍼 크기가 MINIMUM_SIZE보다 크면서 셀 크기의 MINIMUM_SIZE_DIV_CELL비율 보다 작을 경우 공간 활용을 위해 다른 버퍼에 넣는다.
        if (_mem_require.*.size > value.*.cell_size or (_mem_require.*.size > MINIMUM_SIZE and _mem_require.*.size < @as(u64, @intFromFloat(MINIMUM_SIZE_DIV_CELL * @as(f64, @floatFromInt(value.*.cell_size)))))) continue;
        _out_idx.* = value.*.bind_buffer(_buf);
        buf = value;
        break;
    }
    if (buf == null) {
        buf = self.*.buffers.create() catch |err| {
            system.print_error("ERR : {s}\n", .{@errorName(err)});
            unreachable;
        };
        buf.?.* = vulkan_buffer.init(math.round_up(u64, _mem_require.*.size, _mem_require.*.alignment), BLOCK_LEN, _mem_require.*.memoryTypeBits, _prop);

        _out_idx.* = buf.?.*.bind_buffer(_buf);
        self.*.buffer_ids.append(buf.?) catch |err| {
            system.print_error("ERR : {s}\n", .{@errorName(err)});
            unreachable;
        };
    }
    return buf.?;
}

pub fn create_buffer(self: *Self, _buf_info: *const vk.VkBufferCreateInfo, _prop: vk.VkMemoryPropertyFlags, _out_vulkan_buffer_node: *vulkan_buffer_node, _data: ?[]const u8) void {
    var result: c_int = undefined;
    var mem_require: vk.VkMemoryRequirements = undefined;
    var staging_alloc: *vulkan_buffer = undefined;
    var staging_buf: vk.VkBuffer = undefined;
    var staging_buf_idx: u64 = undefined;
    var buf_info = _buf_info.*;

    if (_prop & vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT != 0) {
        const staging_buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = buf_info.size, .usage = vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };
        result = vk.vkCreateBuffer(__vulkan.vkDevice, &staging_buf_info, null, &staging_buf);
        system.handle_error(result == vk.VK_SUCCESS, result, "__vulkan_allocator.create_buffer.vkCreateBuffer");

        vk.vkGetBufferMemoryRequirements(__vulkan.vkDevice, staging_buf, &mem_require);

        buf_info.usage |= vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT;

        staging_alloc = create_allocator_and_bind(self, staging_buf, &mem_require, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &staging_buf_idx);
        var _out_data: ?*anyopaque = null;
        staging_alloc.*.map(staging_buf_idx, &_out_data);
        @memcpy(@as([*]u8, @alignCast(@ptrCast(_out_data))), _data.?);
        staging_alloc.*.unmap();
    }
    result = vk.vkCreateBuffer(__vulkan.vkDevice, &buf_info, null, &_out_vulkan_buffer_node.*.buffer);
    system.handle_error(result == vk.VK_SUCCESS, result, "__vulkan_allocator.create_buffer.vkCreateBuffer");

    vk.vkGetBufferMemoryRequirements(__vulkan.vkDevice, _out_vulkan_buffer_node.*.buffer, &mem_require);

    _out_vulkan_buffer_node.*.pvulkan_buffer = create_allocator_and_bind(self, _out_vulkan_buffer_node.*.buffer, &mem_require, _prop, &_out_vulkan_buffer_node.*.idx);

    if (_prop & vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT != 0) {
        __vulkan.copyBuffer(staging_buf, _out_vulkan_buffer_node.*.buffer, buf_info.size); // ! mem_require.size X
        staging_alloc.unbind_buffer(staging_buf, staging_buf_idx);
    } else if (_data != null) {
        var _out_data: ?*anyopaque = null;
        _out_vulkan_buffer_node.*.map(&_out_data);
        @memcpy(@as([*]u8, @alignCast(@ptrCast(_out_data))), _data.?);
        _out_vulkan_buffer_node.*.unmap();
    }
}
pub fn destroy_buffer(_in_vulkan_buffer_node: *vulkan_buffer_node) void {
    _in_vulkan_buffer_node.*.pvulkan_buffer.*.unbind_buffer(_in_vulkan_buffer_node.*.buffer, _in_vulkan_buffer_node.*.idx);

    _in_vulkan_buffer_node.*.buffer = null;
}
///destroy_buffer 후 호출
pub fn deinit(self: *Self) void {
    for (self.*.buffer_ids.items) |value| {
        value.*.deinit(); // ! 따로 vulkan_buffer.destroy를 호출하지 않는다.
    }
    self.*.buffers.deinit();
    self.*.buffer_ids.deinit();
}
