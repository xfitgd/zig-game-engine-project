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
    system.unreachable2();
}

pub const res_type = enum { buffer, image };

pub inline fn ivulkan_res(_res_type: res_type) type {
    return switch (_res_type) {
        .buffer => vk.VkBuffer,
        .image => vk.VkImage,
    };
}

pub fn vulkan_res_node(_res_type: res_type) type {
    return struct {
        const vulkan_res_node_Self = @This();
        res: ivulkan_res(_res_type) = null,
        idx: usize = undefined,
        pvulkan_buffer: *vulkan_res = undefined,
        __image_view: if (_res_type == .image) vk.VkImageView else void = if (_res_type == .image) undefined,

        pub inline fn is_build(self: *vulkan_res_node_Self) bool {
            return self.*.res != null;
        }
        pub inline fn map(self: *vulkan_res_node_Self, _out_data: *?*anyopaque) void {
            self.*.pvulkan_buffer.*.map(self.*.idx, _out_data);
        }
        pub inline fn unmap(self: *vulkan_res_node_Self) void {
            self.*.pvulkan_buffer.*.unmap();
        }
        pub inline fn clean(self: *vulkan_res_node_Self) void {
            if (is_build(self)) {
                switch (_res_type) {
                    .image => {
                        vk.vkDestroyImageView(__vulkan.vkDevice, self.*.__image_view, null);
                    },
                    else => {},
                }
                self.*.pvulkan_buffer.*.unbind_res(self.*.res, self.*.idx);
                self.*.res = null;
            }
        }
    };
}

const vulkan_res = struct {
    is_free: []bool,
    cell_size: usize,
    len: usize,
    cur: usize,
    mem: vk.VkDeviceMemory,
    info: vk.VkMemoryAllocateInfo,
    this: *Self,

    ///! 따로 vulkan_res.deinit2를 호출하지 않는다.
    fn deinit2(self: *vulkan_res) void {
        vk.vkFreeMemory(__vulkan.vkDevice, self.*.mem, null);
        __system.allocator.free(self.*.is_free);
    }
    pub fn is_empty(self: *vulkan_res) bool {
        for (self.*.is_free) |v| {
            if (!v) return false;
        }
        return true;
    }
    pub fn deinit(self: *vulkan_res) void {
        self.*.deinit2();
        var i: usize = 0;
        while (i < self.*.this.*.buffer_ids.items.len) : (i += 1) {
            if (self.*.this.*.buffer_ids.items[i] == self) {
                _ = self.*.this.*.buffer_ids.orderedRemove(i);
                break;
            }
        }
        self.*.this.*.buffers.destroy(self);
    }
    fn allocate_memory(_info: *const vk.VkMemoryAllocateInfo, _mem: *vk.VkDeviceMemory) void {
        const result = vk.vkAllocateMemory(__vulkan.vkDevice, _info, null, _mem);

        system.handle_error(result == vk.VK_SUCCESS, "vulkan_res.allocate_memory.vkAllocateMemory code : {d}", .{result});
    }
    /// ! 따로 vulkan_res.init를 호출하지 않는다.
    fn init(_cell_size: usize, _len: usize, type_filter: u32, _prop: vk.VkMemoryPropertyFlags, _this: *Self) vulkan_res {
        var res = vulkan_res{
            .cell_size = _cell_size,
            .len = _len,
            .cur = 0,
            .mem = undefined,
            .is_free = __system.allocator.alloc(bool, _len) catch |err|
                system.handle_error3("vulkan_res.init.alloc is_free", err),
            .info = .{
                .sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
                .allocationSize = _len * _cell_size,
                .memoryTypeIndex = find_memory_type(type_filter, _prop),
            },
            .this = _this,
        };
        allocate_memory(&res.info, &res.mem);

        for (res.is_free) |*value| {
            value.* = true;
        }

        return res;
    }
    fn __bind_any(self: *vulkan_res, _mem: vk.VkDeviceMemory, _buf: anytype, _idx: u64) void {
        switch (@TypeOf(_buf)) {
            vk.VkBuffer => {
                const result = vk.vkBindBufferMemory(__vulkan.vkDevice, _buf, _mem, self.*.cell_size * _idx);
                system.handle_error(result == vk.VK_SUCCESS, "vulkan_res.__bind_any.vkBindBufferMemory code : {d}", .{result});
            },
            vk.VkImage => {
                const result = vk.vkBindImageMemory(__vulkan.vkDevice, _buf, _mem, self.*.cell_size * _idx);
                system.handle_error(result == vk.VK_SUCCESS, "vulkan_res.__bind_any.vkBindImageMemory code : {d}", .{result});
            },
            else => @compileError("__bind_any invaild res type."),
        }
    }
    pub fn map(self: *vulkan_res, _buf_idx: u64, _out_data: *?*anyopaque) void {
        const result = vk.vkMapMemory(__vulkan.vkDevice, self.*.mem, _buf_idx * self.*.cell_size, self.*.cell_size, 0, _out_data);
        system.handle_error(result == vk.VK_SUCCESS, "vulkan_res.map.vkMapMemory code : {d}", .{result});
    }
    pub fn unmap(self: *vulkan_res) void {
        vk.vkUnmapMemory(__vulkan.vkDevice, self.*.mem);
    }
    ///_buf 크기는 따로 확인하지 않는다. 호출 쪽에서 확인해서 오류가 없게한다.
    fn bind_any(self: *vulkan_res, _buf: anytype) usize {
        var count: u64 = 0;
        while (!self.*.is_free[self.*.cur]) {
            self.*.cur += 1;
            count += 1;
            if (count >= self.*.len) system.unreachable2(); //TODO 버퍼 꽉찰시 버퍼 확장 또는 새버퍼에 넣기
            if (self.*.cur >= self.*.len) self.*.cur = 0;
        }
        __bind_any(self, self.*.mem, _buf, self.*.cur);
        self.*.is_free[self.*.cur] = false;

        const res = self.*.cur;
        self.*.cur += 1;
        if (self.*.cur >= self.*.len) self.*.cur = 0;
        return res;
    }
    ///bind_buffer에서 반환된 idx를 사용.
    fn unbind_res(self: *vulkan_res, _buf: anytype, _idx: usize) void {
        self.*.is_free[_idx] = true;
        switch (@TypeOf(_buf)) {
            vk.VkBuffer => vk.vkDestroyBuffer(__vulkan.vkDevice, _buf, null),
            vk.VkImage => vk.vkDestroyImage(__vulkan.vkDevice, _buf, null),
            else => @compileError("invaild buf type"),
        }
    }
};

pub fn init() Self {
    return Self{
        .buffers = MemoryPool(vulkan_res).init(__system.allocator),
        .buffer_ids = ArrayList(*vulkan_res).init(__system.allocator),
    };
}

buffers: MemoryPool(vulkan_res),
buffer_ids: ArrayList(*vulkan_res),

fn create_allocator_and_bind(self: *Self, _res: anytype, _mem_require: *const vk.VkMemoryRequirements, _prop: vk.VkMemoryPropertyFlags, _out_idx: *usize, _max_size: usize) *vulkan_res {
    var res: ?*vulkan_res = null;
    var max_size = _max_size;
    if (max_size < _mem_require.*.size) {
        max_size = _mem_require.*.size;
    }
    for (self.buffer_ids.items) |value| {
        //버퍼 크기가 MINIMUM_SIZE보다 크면서 셀 크기의 MINIMUM_SIZE_DIV_CELL비율 보다 작을 경우 공간 활용을 위해 다른 버퍼에 넣는다.
        if (max_size > value.*.cell_size or value.*.cell_size % _mem_require.*.alignment != 0 or (max_size > MINIMUM_SIZE and max_size < @as(usize, @intFromFloat(MINIMUM_SIZE_DIV_CELL * @as(f64, @floatFromInt(value.*.cell_size)))))) continue;
        if (value.*.info.memoryTypeIndex != find_memory_type(_mem_require.*.memoryTypeBits, _prop)) continue;
        _out_idx.* = value.*.bind_any(_res);
        res = value;
        break;
    }
    if (res == null) {
        res = self.*.buffers.create() catch |err| {
            system.print_error("ERR {s} __vulkan_allocator.create_allocator_and_bind.self.*.buffers.create\n", .{@errorName(err)});
            system.unreachable2();
        };
        res.?.* = vulkan_res.init(math.ceil_up(max_size, _mem_require.*.alignment), BLOCK_LEN, _mem_require.*.memoryTypeBits, _prop, self);

        _out_idx.* = res.?.*.bind_any(_res);
        self.*.buffer_ids.append(res.?) catch |err| {
            system.print_error("ERR {s} __vulkan_allocator.create_allocator_and_bind.self.*.buffer_ids.append\n", .{@errorName(err)});
            system.unreachable2();
        };
    }
    return res.?;
}

pub fn create_buffer(self: *Self, _buf_info: *const vk.VkBufferCreateInfo, _prop: vk.VkMemoryPropertyFlags, _out_vulkan_buffer_node: *vulkan_res_node(.buffer), _data: ?[]const u8) void {
    var result: c_int = undefined;
    var mem_require: vk.VkMemoryRequirements = undefined;
    var staging_alloc: *vulkan_res = undefined;
    var staging_buf: vk.VkBuffer = undefined;
    var staging_buf_idx: usize = undefined;
    var buf_info = _buf_info.*;

    if (_prop & vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT != 0) {
        const staging_buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = buf_info.size, .usage = vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };
        result = vk.vkCreateBuffer(__vulkan.vkDevice, &staging_buf_info, null, &staging_buf);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan_allocator.create_buffer.vkCreateBuffer staging_buf code : {d}", .{result});

        vk.vkGetBufferMemoryRequirements(__vulkan.vkDevice, staging_buf, &mem_require);

        buf_info.usage |= vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT;

        staging_alloc = create_allocator_and_bind(self, staging_buf, &mem_require, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &staging_buf_idx, mem_require.size);
        var _out_data: ?*anyopaque = null;
        staging_alloc.*.map(staging_buf_idx, &_out_data);
        @memcpy(@as([*]u8, @alignCast(@ptrCast(_out_data))), _data.?);
        staging_alloc.*.unmap();
    }
    result = vk.vkCreateBuffer(__vulkan.vkDevice, &buf_info, null, &_out_vulkan_buffer_node.*.res);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan_allocator.create_buffer.vkCreateBuffer _out_vulkan_buffer_node.*.res code : {d}", .{result});

    vk.vkGetBufferMemoryRequirements(__vulkan.vkDevice, _out_vulkan_buffer_node.*.res, &mem_require);

    _out_vulkan_buffer_node.*.pvulkan_buffer = create_allocator_and_bind(self, _out_vulkan_buffer_node.*.res, &mem_require, _prop, &_out_vulkan_buffer_node.*.idx, mem_require.size);

    if (_prop & vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT != 0) {
        __vulkan.copy_buffer(staging_buf, _out_vulkan_buffer_node.*.res, buf_info.size); // ! mem_require.size X
        staging_alloc.unbind_res(staging_buf, staging_buf_idx);
    } else if (_data != null) {
        var _out_data: ?*anyopaque = null;
        _out_vulkan_buffer_node.*.map(&_out_data);
        @memcpy(@as([*]u8, @alignCast(@ptrCast(_out_data))), _data.?);
        _out_vulkan_buffer_node.*.unmap();
    }
}

pub fn create_image(self: *Self, _img_info: *const vk.VkImageCreateInfo, _out_vulkan_image_node: *vulkan_res_node(.image), _data: ?[]const u8, max_image_size: usize) void {
    var result: c_int = undefined;
    var mem_require: vk.VkMemoryRequirements = undefined;
    var staging_alloc: *vulkan_res = undefined;
    var staging_buf: vk.VkBuffer = undefined;
    var staging_buf_idx: usize = undefined;
    var img_info = _img_info.*;

    img_info.usage |= vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT;

    result = vk.vkCreateImage(__vulkan.vkDevice, &img_info, null, &_out_vulkan_image_node.*.res);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan_allocator.create_buffer.vkCreateBuffer _out_vulkan_buffer_node.*.res code : {d}", .{result});

    vk.vkGetImageMemoryRequirements(__vulkan.vkDevice, _out_vulkan_image_node.*.res, &mem_require);
    const img_size = mem_require.size;

    _out_vulkan_image_node.*.pvulkan_buffer = create_allocator_and_bind(self, _out_vulkan_image_node.*.res, &mem_require, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &_out_vulkan_image_node.*.idx, max_image_size);

    const image_view_create_info: vk.VkImageViewCreateInfo = .{
        .viewType = img_info.imageType,
        .format = img_info.format,
        .components = .{
            .r = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .g = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .b = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .a = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
        },
        .image = _out_vulkan_image_node.*.res,
        .subresourceRange = .{
            .aspectMask = if (img_info.format == vk.VK_FORMAT_D24_UNORM_S8_UINT) vk.VK_IMAGE_ASPECT_DEPTH_BIT | vk.VK_IMAGE_ASPECT_STENCIL_BIT else vk.VK_IMAGE_ASPECT_COLOR_BIT,
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
    };
    result = vk.vkCreateImageView(__vulkan.vkDevice, &image_view_create_info, null, &_out_vulkan_image_node.*.__image_view);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan_allocator.create_image.vkCreateImageView _out_vulkan_image_node.*.__image_view : {d}", .{result});

    if (_data != null) {
        const staging_buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = img_size, .usage = vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };
        result = vk.vkCreateBuffer(__vulkan.vkDevice, &staging_buf_info, null, &staging_buf);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan_allocator.create_image.vkCreateBuffer staging_buf : {d}", .{result});

        vk.vkGetBufferMemoryRequirements(__vulkan.vkDevice, staging_buf, &mem_require);

        staging_alloc = create_allocator_and_bind(self, staging_buf, &mem_require, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &staging_buf_idx, max_image_size);

        var _out_data: ?*anyopaque = null;
        staging_alloc.*.map(staging_buf_idx, &_out_data);
        @memcpy(@as([*]u8, @alignCast(@ptrCast(_out_data))), _data.?);
        staging_alloc.*.unmap();

        __vulkan.transition_image_layout(_out_vulkan_image_node.*.res, &img_info, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);
        __vulkan.copy_buffer_to_image(staging_buf, _out_vulkan_image_node.*.res, img_info.extent.width, img_info.extent.height, img_info.extent.depth);
        __vulkan.transition_image_layout(_out_vulkan_image_node.*.res, &img_info, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
        staging_alloc.unbind_res(staging_buf, staging_buf_idx);
    }
}

pub fn deinit(self: *Self) void {
    for (self.*.buffer_ids.items) |value| {
        value.*.deinit2(); // ! 따로 vulkan_res.deinit를 호출하지 않는다.
    }
    self.*.buffers.deinit();
    self.*.buffer_ids.deinit();
}
