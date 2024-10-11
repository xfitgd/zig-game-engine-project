//TODO VkDeviceMemory 하나당 vkBuffer 여러개를 효율적으로 할당할수 있게 만드는것이 목표인 vulkan 할당자
const std = @import("std");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;
const MemoryPoolExtra = std.heap.MemoryPoolExtra;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;
const __system = @import("__system.zig");
const system = @import("system.zig");
const math = @import("math.zig");
const mem = @import("mem.zig");
const graphics = @import("graphics.zig");

const BLOCK_LEN = 8192;
const NODE_SIZE = 2048;

///버퍼 크기가 MINIMUM_SIZE보다 크면서 셀 크기의 MINIMUM_SIZE_DIV_CELL비율 보다 작을 경우 공간 활용을 위해 다른 버퍼에 넣는다.
const MINIMUM_SIZE_DIV_CELL = 0.5;
const MINIMUM_SIZE = 32768;
const MAX_IDX_COUNT = 8;
const Self = @This();

pub const ERROR = error{device_memory_limit};

buffers: MemoryPoolExtra(vulkan_res, .{}),
buffer_ids: ArrayList(*vulkan_res),
memory_idx_counts: []u32,

fn find_memory_type(_type_filter: u32, _prop: vk.VkMemoryPropertyFlags) u32 {
    var i: u32 = 0;
    while (i < __vulkan.mem_prop.memoryTypeCount) : (i += 1) {
        if ((_type_filter & (@as(u32, 1) << @intCast(i)) != 0) and (__vulkan.mem_prop.memoryTypes[i].propertyFlags & _prop == _prop)) {
            return i;
        }
    }
    system.print_error("ERR find_memory_type.memory_type_not_found\n", .{});
    unreachable;
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
        __resource_len: u32 = undefined,
        pvulkan_buffer: *vulkan_res = undefined,
        __image_view: if (_res_type == .image) vk.VkImageView else void = if (_res_type == .image) undefined,
        __image_frames: if (_res_type == .image) f32 else void = if (_res_type == .image) 1,

        pub inline fn is_build(self: *vulkan_res_node_Self) bool {
            return self.*.res != null;
        }
        pub inline fn map(self: *vulkan_res_node_Self, _out_data: *?*anyopaque) void {
            self.*.pvulkan_buffer.*.map(self.*.idx, _out_data);
        }
        pub inline fn unmap(self: *vulkan_res_node_Self) void {
            self.*.pvulkan_buffer.*.unmap();
        }
        pub inline fn map_update(self: *vulkan_res_node_Self, _data: anytype) void {
            var data: ?*anyopaque = undefined;
            self.*.pvulkan_buffer.*.map(self.*.idx, &data);
            const u8data = mem.obj_to_u8arrC(_data);
            @memcpy(@as([*]u8, @ptrCast(data.?))[0..u8data.len], u8data);
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
    //alignment: usize,
    len: usize,
    cur: usize,
    mem: vk.VkDeviceMemory,
    info: vk.VkMemoryAllocateInfo,
    this: *Self,
    is_full: bool = false,

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
        self.*.this.*.memory_idx_counts[self.*.info.memoryTypeIndex] -= 1;
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
    fn bind_any(self: *vulkan_res, _buf: anytype) ERROR!usize {
        if (self.*.is_full) return ERROR.device_memory_limit;

        var count: u64 = 0;
        while (!self.*.is_free[self.*.cur]) {
            self.*.cur += 1;
            count += 1;
            if (self.*.cur >= self.*.len) self.*.cur = 0;
            if (count >= self.*.len) {
                self.*.is_full = true;
                return ERROR.device_memory_limit;
            }
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
        if (self.*.this.*.memory_idx_counts[self.*.info.memoryTypeIndex] > MAX_IDX_COUNT) {
            for (self.*.is_free) |v| {
                if (!v) return;
            }
            self.*.deinit();
        }
    }
};

pub fn init() Self {
    const res = Self{
        .buffers = MemoryPoolExtra(vulkan_res, .{}).init(__system.allocator),
        .buffer_ids = ArrayList(*vulkan_res).init(__system.allocator),
        .memory_idx_counts = __system.allocator.alloc(u32, __vulkan.mem_prop.memoryTypeCount) catch |e| system.handle_error3("__vulkan_allocator init alloc memory_idx_counts", e),
    };
    @memset(res.memory_idx_counts, 0);

    return res;
}

fn create_allocator_and_bind(self: *Self, _res: anytype, _mem_require: *const vk.VkMemoryRequirements, _prop: vk.VkMemoryPropertyFlags, _out_idx: *usize, _max_size: usize) *vulkan_res {
    var res: ?*vulkan_res = null;
    var max_size = _max_size;
    if (max_size < _mem_require.*.size) {
        max_size = _mem_require.*.size;
    }
    const cell = math.ceil_up(max_size, _mem_require.*.alignment);
    for (self.buffer_ids.items) |value| {
        //버퍼 크기가 MINIMUM_SIZE보다 크면서 셀 크기의 MINIMUM_SIZE_DIV_CELL비율 보다 작을 경우 공간 활용을 위해 다른 버퍼에 넣는다.
        if (max_size > value.*.cell_size or ((value.*.cell_size % _mem_require.*.alignment) != 0) or ((value.*.cell_size >= MINIMUM_SIZE) and (max_size < @as(usize, @intFromFloat(MINIMUM_SIZE_DIV_CELL * @as(f64, @floatFromInt(value.*.cell_size))))))) continue;
        if (value.*.info.memoryTypeIndex != find_memory_type(_mem_require.*.memoryTypeBits, _prop)) continue;
        _out_idx.* = value.*.bind_any(_res) catch continue;
        //system.print_debug("(1) {d} {d} {d} {d}", .{ max_size, value.*.cell_size, value.*.len, _mem_require.*.alignment });
        res = value;
        break;
    }
    if (res == null) {
        res = self.*.buffers.create() catch |err| {
            system.print_error("ERR {s} __vulkan_allocator.create_allocator_and_bind.self.*.buffers.create\n", .{@errorName(err)});
            unreachable;
        };

        // system.print_debug("(2) {d} {d} {d}", .{
        //     max_size,
        //     std.math.divCeil(usize, BLOCK_LEN, std.math.divCeil(usize, cell, NODE_SIZE) catch 1) catch 1,
        //     _mem_require.*.alignment,
        // });

        res.?.* = vulkan_res.init(cell, std.math.divCeil(usize, BLOCK_LEN, std.math.divCeil(usize, cell, NODE_SIZE) catch 1) catch 1, _mem_require.*.memoryTypeBits, _prop, self);

        _out_idx.* = res.?.*.bind_any(_res) catch unreachable; //발생할수 없는 오류
        self.*.buffer_ids.append(res.?) catch |err| {
            system.print_error("ERR {s} __vulkan_allocator.create_allocator_and_bind.self.*.buffer_ids.append\n", .{@errorName(err)});
            unreachable;
        };
    }
    self.*.memory_idx_counts[res.?.*.info.memoryTypeIndex] += 1;
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

    if (_data != null) {
        img_info.usage |= vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT;

        if (img_info.extent.width * img_info.extent.width * img_info.extent.depth * img_info.arrayLayers * 4 > _data.?.len) {
            system.handle_error_msg2("create_image _data not enough for size(rect).");
        }
    }

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
            .layerCount = img_info.arrayLayers,
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
        @memcpy(@as([*]u8, @alignCast(@ptrCast(_out_data.?))), _data.?);
        staging_alloc.*.unmap();

        __vulkan.transition_image_layout(_out_vulkan_image_node.*.res, img_info.mipLevels, img_info.arrayLayers, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);
        __vulkan.copy_buffer_to_image(staging_buf, _out_vulkan_image_node.*.res, img_info.extent.width, img_info.extent.height, img_info.extent.depth, img_info.arrayLayers);
        __vulkan.transition_image_layout(_out_vulkan_image_node.*.res, img_info.mipLevels, img_info.arrayLayers, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
        staging_alloc.unbind_res(staging_buf, staging_buf_idx);
    }
}

pub fn copy_texture(self: *Self, image: *graphics.texture, _data: []const u8, rect: ?math.recti) void {
    var result: c_int = undefined;
    var mem_require: vk.VkMemoryRequirements = undefined;
    var staging_alloc: *vulkan_res = undefined;
    var staging_buf: vk.VkBuffer = undefined;
    var staging_buf_idx: usize = undefined;

    if (_data != null) {
        const size = if (rect == null) image.width * image.height * 4 else rect.?.width() * rect.?.height() * 4;
        if (size > image.width * image.height * 4) {
            system.handle_error_msg2("copy_image rect region can't bigger than image size.");
        }
        if (size > _data.len) {
            system.handle_error_msg2("copy_image _data not enough for size(rect).");
        }
        const staging_buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = size, .usage = vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };
        result = vk.vkCreateBuffer(__vulkan.vkDevice, &staging_buf_info, null, &staging_buf);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan_allocator.create_image.vkCreateBuffer staging_buf : {d}", .{result});

        vk.vkGetBufferMemoryRequirements(__vulkan.vkDevice, staging_buf, &mem_require);

        staging_alloc = create_allocator_and_bind(self, staging_buf, &mem_require, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &staging_buf_idx, 0);

        var _out_data: ?*anyopaque = null;
        staging_alloc.*.map(staging_buf_idx, &_out_data);
        @memcpy(@as([*]u8, @alignCast(@ptrCast(_out_data.?))), _data[0..size]);
        staging_alloc.*.unmap();

        __vulkan.transition_image_layout(image.*.__image.res, 1, 1, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);
        if (rect != null) {
            __vulkan.copy_buffer_to_image2(staging_buf, image.*.__image.res, rect, 1);
        } else {
            __vulkan.copy_buffer_to_image(staging_buf, image.*.__image.res, image.*.width, image.*.height, 1, 1);
        }
        __vulkan.transition_image_layout(image.*.__image.res, 1, 1, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
        staging_alloc.unbind_res(staging_buf, staging_buf_idx);
    }
}

pub fn deinit(self: *Self) void {
    for (self.*.buffer_ids.items) |value| {
        value.*.deinit2(); // ! 따로 vulkan_res.deinit를 호출하지 않는다.
    }
    self.*.buffers.deinit();
    self.*.buffer_ids.deinit();
    __system.allocator.free(self.*.memory_idx_counts);
}
