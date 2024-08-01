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
const mem = @import("mem.zig");
const point = math.point;
const point3d = math.point3d;
const vector = math.vector;
const matrix4x4 = math.matrix4x4;
const matrix_error = math.matrix_error;

const vulkan_buffer_node = __vulkan_allocator.vulkan_buffer_node;

pub const color_vertex_2d = color_vertex_2d_(f32);
pub const indices16 = indices(.U16);
pub const indices32 = indices(.U32);

pub const dummy_vertices = [@sizeOf(vertices(u8))]u8;
pub const dummy_indices = [@sizeOf(indices(.U32))]u8;
pub const dummy_object = [@sizeOf(object(u8, .U16))]u8;

pub const take_vertices = mem.align_ptr_cast;
pub const take_indices = mem.align_ptr_cast;
pub const take_object = mem.align_ptr_cast;

pub const write_flag = enum { read_gpu, readwrite_cpu };

pub fn color_vertex_2d_(comptime T: type) type {
    return extern struct {
        pos: point(T) align(1),
        color: vector(T) align(1),

        pub inline fn get_pipeline() vk.VkPipeline {
            return __vulkan.color_2d_pipeline;
        }
    };
}

pub var scene: ?*[]*iobject = null;

pub const index_type = enum { U16, U32 };

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
pub const iindices = struct {
    const Self = @This();

    get_indices_len: *const fn (self: *iindices) usize = undefined,

    node: vulkan_buffer_node = vulkan_buffer_node.init(),
    idx_type: index_type = undefined,

    pub inline fn clean(self: *Self) void {
        if (self.*.node.buffer != null) {
            __vulkan_allocator.destroy_buffer(&self.*.node);
        }
    }
};

pub fn indices(comptime _type: index_type) type {
    return struct {
        const Self = @This();
        const idxT = switch (_type) {
            .U16 => u16,
            .U32 => u32,
        };

        array: ArrayList(idxT) = undefined,
        interface: iindices = .{},

        ///! 반드시 시스템 초기화 후 호출(xfit_init 함수 부터 호출 가능)
        pub fn init(allocator: std.mem.Allocator) Self {
            system.handle_error_msg(__vulkan.color_2d_pipeline != null, "Must be called this function after system initialisation (from xfit_init function)");
            var self: Self = .{};
            self.array = ArrayList(idxT).init(allocator);
            self.interface.get_indices_len = get_indices_len;
            self.interface.idx_type = _type;
            return self;
        }
        ///완전히 정리
        pub inline fn deinit(self: *Self) void {
            clean(self);
            self.*.array.deinit();
        }
        ///다시 빌드할수 있게 버퍼 내용만 정리
        pub inline fn clean(self: *Self) void {
            self.*.interface.clean();
        }
        fn get_indices_len(_interface: *iindices) usize {
            const self = @as(*Self, @fieldParentPtr("interface", _interface));
            return self.*.array.items.len;
        }
        pub fn build(self: *Self, _flag: write_flag) void {
            clean(self);
            const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = @sizeOf(idxT) * self.*.array.items.len, .usage = vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

            const prop: vk.VkMemoryPropertyFlags =
                switch (_flag) {
                .read_gpu => vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
                .readwrite_cpu => vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            };

            __vulkan.vk_allocator.create_buffer(&buf_info, prop, &self.*.interface.node, std.mem.sliceAsBytes(self.*.array.items)) catch unreachable;
        }
    };
}

pub fn vertices(comptime vertexT: type) type {
    return struct {
        const Self = @This();

        array: ArrayList(vertexT) = undefined,
        interface: ivertices = .{},

        ///! 반드시 시스템 초기화 후 호출(xfit_init 함수 부터 호출 가능)
        pub fn init(allocator: std.mem.Allocator) Self {
            var self: Self = .{};
            self.interface.pipeline = vertexT.get_pipeline();
            system.handle_error_msg(self.interface.pipeline != null, "Must be called this function after system initialisation (from xfit_init function)");
            self.array = ArrayList(vertexT).init(allocator);

            self.interface.get_vertices_len = get_vertices_len;
            return self;
        }
        fn get_vertices_len(_interface: *ivertices) usize {
            const self = @as(*Self, @fieldParentPtr("interface", _interface));
            return self.*.array.items.len;
        }
        ///완전히 정리
        pub inline fn deinit(self: *Self) void {
            clean(self);
            self.*.array.deinit();
        }
        ///다시 빌드할수 있게 버퍼 내용만 정리
        pub inline fn clean(self: *Self) void {
            self.*.interface.clean();
        }
        pub fn build(self: *Self, _flag: write_flag) void {
            clean(self);
            const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = @sizeOf(vertexT) * self.*.array.items.len, .usage = vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

            const prop: vk.VkMemoryPropertyFlags =
                switch (_flag) {
                .read_gpu => vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
                .readwrite_cpu => vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            };

            __vulkan.vk_allocator.create_buffer(&buf_info, prop, &self.*.interface.node, std.mem.sliceAsBytes(self.*.array.items)) catch unreachable;
        }
    };
}

pub const shape2d = object(color_vertex_2d, .U16);

pub const iobject = struct {
    const Self = @This();

    get_ivertices: *const fn (self: *iobject) ?*ivertices = undefined,
    get_iindices: *const fn (self: *iobject) ?*iindices = undefined,

    mat: math.matrix,
};

pub fn object(comptime vertexT: type, comptime _idx_type: index_type) type {
    return struct {
        const Self = @This();

        vertices: ?*vertices(vertexT),
        indices: ?*indices(_idx_type),
        interface: iobject,

        fn get_ivertices(_interface: *iobject) ?*ivertices {
            const self = @as(*Self, @fieldParentPtr("interface", _interface));
            return if (self.*.vertices != null) &self.*.vertices.?.*.interface else null;
        }
        fn get_iindices(_interface: *iobject) ?*iindices {
            const self = @as(*Self, @fieldParentPtr("interface", _interface));
            return if (self.*.indices != null) &self.*.indices.?.*.interface else null;
        }

        pub fn init() Self {
            var self = Self{
                .vertices = null,
                .indices = null,
                .interface = undefined,
            };
            self.interface.get_ivertices = get_ivertices;
            self.interface.get_iindices = get_iindices;
            self.interface.mat = math.matrix.identity();
            return self;
        }
        pub fn deinit(self: *Self) void {
            if (self.*.vertices != null) self.*.vertices.deinit();
            if (self.*.indices != null) self.*.indices.deinit();
        }
    };
}
