const std = @import("std");
const ArrayList = std.ArrayList;

const file = @import("file.zig");
const system = @import("system.zig");
const window = @import("window.zig");
const __system = @import("__system.zig");

const builtin = @import("builtin");
const dbg = builtin.mode == .Debug;

const __vulkan_allocator = @import("__vulkan_allocator.zig");

const _allocator = __system.allocator;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;

const math = @import("math.zig");
const mem = @import("mem.zig");
const point = math.point;
const point3d = math.point3d;
const vector = math.vector;
const matrix = math.matrix;
const matrix_error = math.matrix_error;

const vulkan_res_node = __vulkan_allocator.vulkan_res_node;

pub const color_vertex_2d = color_vertex_2d_(f32);
pub const indices16 = indices_(.U16);
pub const indices32 = indices_(.U32);
pub const indices = indices_(DEF_IDX_TYPE);

pub const dummy_vertices = [@sizeOf(vertices(u8))]u8;
pub const dummy_indices = [@sizeOf(indices)]u8;
pub const dummy_object = [@sizeOf(object(u8))]u8;

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
pub const DEF_IDX_TYPE: index_type = .U16;

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

    get_vertices_len: *const fn (self: *Self) usize = undefined,
    deinit: *const fn (self: *Self) void = undefined,

    node: vulkan_res_node(.buffer) = .{},
    pipeline: vk.VkPipeline = undefined,

    pub inline fn clean(self: *Self) void {
        self.*.node.clean();
    }
};
pub const iindices = struct {
    const Self = @This();

    get_indices_len: *const fn (self: *Self) usize = undefined,
    deinit: *const fn (self: *Self) void = undefined,

    node: vulkan_res_node(.buffer) = .{},
    idx_type: index_type = undefined,

    pub inline fn clean(self: *Self) void {
        self.*.node.clean();
    }
};

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
            self.interface.deinit = _deinit;
            return self;
        }
        fn get_vertices_len(_interface: *ivertices) usize {
            const self = @as(*Self, @fieldParentPtr("interface", _interface));
            return self.*.array.items.len;
        }
        fn _deinit(_interface: *ivertices) void {
            const self = @as(*Self, @fieldParentPtr("interface", _interface));
            deinit(self);
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

            __vulkan.vk_allocator.create_buffer(&buf_info, prop, &self.*.interface.node, std.mem.sliceAsBytes(self.*.array.items));
        }
        ///write_flag가 readwrite_cpu만 호출
        pub fn map_update(self: *Self) void {
            var data: ?*vertexT = undefined;
            self.*.interface.node.map(@ptrCast(&data));
            mem.memcpy_nonarray(data.?, self.*.array.items.ptr);
            self.*.interface.node.unmap();
        }
    };
}

pub fn indices_(comptime _type: index_type) type {
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
            self.interface.deinit = _deinit;
            return self;
        }
        fn _deinit(_interface: *iindices) void {
            const self = @as(*Self, @fieldParentPtr("interface", _interface));
            deinit(self);
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

            __vulkan.vk_allocator.create_buffer(&buf_info, prop, &self.*.interface.node, std.mem.sliceAsBytes(self.*.array.items));
        }
        ///write_flag가 readwrite_cpu만 호출
        pub fn map_update(self: *Self) void {
            var data: ?*idxT = undefined;
            self.*.interface.node.map(@ptrCast(&data));
            mem.memcpy_nonarray(data.?, self.*.array.items.ptr);
            self.*.interface.node.unmap();
        }
    };
}

pub const shape2d = object(color_vertex_2d);

pub const projection = struct {
    const Self = @This();
    pub const view_type = enum { orthographic, perspective };
    proj: matrix = undefined,
    __uniform: vulkan_res_node(.buffer) = .{},
    __check_alloc: if (dbg) ?*anyopaque else void = if (dbg) null,

    ///_view_type이 orthographic경우 fov는 무시됨, 시스템 초기화 후 호출 perspective일 경우 near, far 기본값 각각 0.1, 100
    pub fn init(_view_type: view_type, fov: f32) matrix_error!Self {
        var res: Self = .{};
        try res.init_matrix(_view_type, fov);
        build(&res, .readwrite_cpu);

        if (dbg) res.__check_alloc = __system.dummy_allocator.alloc();
        return res;
    }
    ///_view_type이 orthographic경우 fov는 무시됨, 시스템 초기화 후 호출
    pub fn init2(_view_type: view_type, fov: f32, near: f32, far: f32) matrix_error!Self {
        var res: Self = .{};
        try res.init_matrix2(_view_type, fov, near, far);
        build(&res, .readwrite_cpu);

        if (dbg) res.__check_alloc = __system.dummy_allocator.alloc();
        return res;
    }
    pub fn init_matrix(self: *Self, _view_type: view_type, fov: f32) matrix_error!void {
        self.*.proj = switch (_view_type) {
            .orthographic => try matrix.orthographicLh(@floatFromInt(window.window_width()), @floatFromInt(window.window_height()), 0.1, 100),
            .perspective => try matrix.perspectiveFovLh(fov, @as(f32, @floatFromInt(window.window_width())) / @as(f32, @floatFromInt(window.window_height())), 0.1, 100),
        };
    }
    pub fn init_matrix2(self: *Self, _view_type: view_type, fov: f32, near: f32, far: f32) matrix_error!void {
        self.*.proj = switch (_view_type) {
            .orthographic => try matrix.orthographicLh(@floatFromInt(window.window_width()), @floatFromInt(window.window_height()), near, far),
            .perspective => try matrix.perspectiveFovLh(fov, @as(f32, @floatFromInt(window.window_width())) / @as(f32, @floatFromInt(window.window_height())), near, far),
        };
    }
    pub inline fn is_inited(self: *Self) bool {
        return self.*.__uniform.is_build();
    }
    pub inline fn deinit(self: *Self) void {
        self.*.__uniform.clean();

        if (dbg) __system.dummy_allocator.free(self.*.__check_alloc orelse unreachable);
    }
    fn build(self: *Self, _flag: write_flag) void {
        const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = @sizeOf(matrix), .usage = vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

        const prop: vk.VkMemoryPropertyFlags =
            switch (_flag) {
            .read_gpu => vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            .readwrite_cpu => vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        };
        __vulkan.vk_allocator.create_buffer(&buf_info, prop, &self.*.__uniform, mem.u8arr(self.*.proj));
    }
    pub fn map_update(self: *Self) void {
        var data: ?*matrix = undefined;
        self.*.__uniform.map(@ptrCast(&data));
        mem.memcpy_nonarray(data.?, &self.*.proj);
        self.*.__uniform.unmap();
    }
};
pub const camera = struct {
    const Self = @This();
    view: matrix = undefined,
    __uniform: vulkan_res_node(.buffer) = .{},
    __check_alloc: if (dbg) ?*anyopaque else void = if (dbg) null,

    /// w좌표는 신경 x, 시스템 초기화 후 호출
    pub fn init(eyepos: vector(f32), focuspos: vector(f32), updir: vector(f32)) Self {
        var res = Self{ .view = matrix.lookAtLh(eyepos, focuspos, updir) };
        build(&res, .readwrite_cpu);

        if (dbg) res.__check_alloc = __system.dummy_allocator.alloc();
        return res;
    }
    pub inline fn is_inited(self: *Self) bool {
        return self.*.__uniform.is_build();
    }
    pub inline fn deinit(self: *Self) void {
        self.*.__uniform.clean();

        if (dbg) __system.dummy_allocator.free(self.*.__check_alloc orelse unreachable);
    }
    fn build(self: *Self, _flag: write_flag) void {
        const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = @sizeOf(matrix), .usage = vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

        const prop: vk.VkMemoryPropertyFlags =
            switch (_flag) {
            .read_gpu => vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            .readwrite_cpu => vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        };
        __vulkan.vk_allocator.create_buffer(&buf_info, prop, &self.*.__uniform, mem.u8arr(self.*.view));
    }
    pub fn map_update(self: *Self) void {
        var data: ?*matrix = undefined;
        self.*.__uniform.map(@ptrCast(&data));
        mem.memcpy_nonarray(data, &self.*.view);
        self.*.__uniform.unmap();
    }
};
//transform는 object와 한몸이라 따로 check_alloc 필요없음
pub const transform = struct {
    const Self = @This();

    model: matrix = matrix.identity(),
    ///이 값이 변경되면 update 필요 또는 build로 초기화하기
    camera: ?*camera = null,
    ///이 값이 변경되면 update 필요 또는 build로 초기화하기
    projection: ?*projection = null,
    __model_uniform: vulkan_res_node(.buffer) = .{},
    pub inline fn is_build(self: *Self) bool {
        return self.*.__model_uniform.is_build() and self.*.camera != null and self.*.projection != null and self.*.camera.?.*.is_inited() and self.*.projection.?.*.is_inited();
    }
    pub inline fn clean(self: *Self) void {
        self.*.__model_uniform.clean();
    }
    pub fn build(self: *Self) void {
        clean(self);
        const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = @sizeOf(matrix), .usage = vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

        __vulkan.vk_allocator.create_buffer(&buf_info, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &self.*.__model_uniform, mem.u8arr(self.*.model));
    }
    ///write_flag가 readwrite_cpu만 호출
    pub fn map_update(self: *Self) void {
        var data: ?*matrix = undefined;
        self.*.__model_uniform.map(@ptrCast(&data));
        mem.memcpy_nonarray(data.?, &self.*.model);
        self.*.__model_uniform.unmap();
    }
};

pub const texture = struct {
    const Self = @This();
    __sampler: vk.VkSampler = null,
    __image: vulkan_res_node(.image) = .{},
    width: u32 = undefined,
    height: u32 = undefined,
    pixels: ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .pixels = ArrayList(u8).init(allocator),
        };
    }
    ///완전히 정리
    pub inline fn deinit(self: *Self) void {
        clean(self);
        self.*.pixels.deinit();
    }
    ///write_flag가 readwrite_cpu만 호출
    pub fn map_update(self: *Self) void {
        var data: ?*u8 = undefined;
        self.*.__model_uniform.map(@ptrCast(&data));
        mem.memcpy_nonarray(data.?, self.*.pixels.items.ptr);
        self.*.__model_uniform.unmap();
    }
    ///다시 빌드할수 있게 버퍼 내용만 정리
    pub inline fn clean(self: *Self) void {
        self.*.__image.clean();
    }
    pub fn build(self: *Self, _flag: write_flag) void {
        clean(self);
        const img_info: vk.VkImageCreateInfo = .{
            .arrayLayers = 1,
            .extent = .{ .width = self.*.width, .height = self.*.height, .depth = 1 },
            .flags = 0,
            .format = vk.VK_FORMAT_R8G8B8A8_UNORM,
            .imageType = vk.VK_IMAGE_TYPE_2D,
            .initialLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
            .mipLevels = 1,
            .pQueueFamilyIndices = null,
            .queueFamilyIndexCount = 0,
            .samples = vk.VK_SAMPLE_COUNT_1_BIT,
            .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
            .tiling = vk.VK_IMAGE_TILING_OPTIMAL,
            .usage = vk.VK_IMAGE_USAGE_SAMPLED_BIT,
        };

        const prop: vk.VkMemoryPropertyFlags =
            switch (_flag) {
            .read_gpu => vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            .readwrite_cpu => vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        };

        __vulkan.vk_allocator.create_image(&img_info, prop, &self.*.__image, std.mem.sliceAsBytes(self.*.array.items));
    }
};

/// ! object는 deinit 필요없음 vertices, indices는 따로 해제
pub const iobject = struct {
    const Self = @This();

    get_ivertices: *const fn (self: *iobject) ?*ivertices = undefined,
    get_iindices: *const fn (self: *iobject) ?*iindices = undefined,
    transform: transform = .{},
    __descriptor_set: vk.VkDescriptorSet = null,
    __descriptor_pool: vk.VkDescriptorPool = null,
    __check_alloc: if (dbg) ?*anyopaque else void = if (dbg) null,

    pub inline fn is_build(self: *Self) bool {
        return self.*.__descriptor_pool != null and self.*.transform.is_build();
    }
    ///transform에 포함된 버퍼 값이 변경될때마다 호출한다. 리소스만 변경시에는 대신 map_update 호출
    pub fn update(self: *Self) void {
        if (!self.*.is_build()) {
            system.print_error("ERR : need transform build and need transform.camera, projection build(invaild)\n", .{});
            unreachable;
        }
        const buffer_info = [3]vk.VkDescriptorBufferInfo{
            vk.VkDescriptorBufferInfo{
                .buffer = self.*.transform.__model_uniform.res,
                .offset = 0,
                .range = @sizeOf(matrix),
            },
            vk.VkDescriptorBufferInfo{
                .buffer = self.*.transform.camera.?.*.__uniform.res,
                .offset = 0,
                .range = @sizeOf(matrix),
            },
            vk.VkDescriptorBufferInfo{
                .buffer = self.*.transform.projection.?.*.__uniform.res,
                .offset = 0,
                .range = @sizeOf(matrix),
            },
        };
        const descriptorWrite: vk.VkWriteDescriptorSet = .{
            .sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = self.*.__descriptor_set,
            .dstBinding = 0,
            .dstArrayElement = 0,
            .descriptorCount = buffer_info.len,
            .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .pBufferInfo = &buffer_info,
            .pImageInfo = null,
            .pTexelBufferView = null,
        };
        vk.vkUpdateDescriptorSets(__vulkan.vkDevice, 1, &descriptorWrite, 0, null);
    }

    pub fn init() Self {
        var res: Self = .{};
        if (dbg) res.__check_alloc = __system.dummy_allocator.alloc();
        return res;
    }

    pub fn build(self: *Self, _flag: write_flag) void {
        _ = _flag;
        if (self.*.transform.camera == null or self.*.transform.projection == null or !self.*.transform.camera.?.*.is_inited() or !self.*.transform.projection.?.*.is_inited()) {
            system.print_error("ERR : need transform.camera, projection build(invaild)\n", .{});
            unreachable;
        }
        clean(self);

        const pool_size: vk.VkDescriptorPoolSize = .{
            .descriptorCount = 3,
            .type = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        };
        const pool_info: vk.VkDescriptorPoolCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = 1,
            .pPoolSizes = &pool_size,
            .maxSets = 1,
        };
        var result = vk.vkCreateDescriptorPool(__vulkan.vkDevice, &pool_info, null, &self.*.__descriptor_pool);
        system.handle_error(result == vk.VK_SUCCESS, result, "iobject.build.vkCreateDescriptorPool");

        const alloc_info: vk.VkDescriptorSetAllocateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = self.*.__descriptor_pool,
            .descriptorSetCount = 1,
            .pSetLayouts = &__vulkan.vkDescriptorSetLayout,
        };
        result = vk.vkAllocateDescriptorSets(__vulkan.vkDevice, &alloc_info, &self.*.__descriptor_set);
        system.handle_error(result == vk.VK_SUCCESS, result, "iobject.build.vkAllocateDescriptorSets");

        self.*.transform.build();

        update(self);
        //update(self); 중복 업데이트 하면 값이 갱신된다.
    }
    pub fn deinit(self: *Self) void {
        clean(self);

        if (dbg) __system.dummy_allocator.free(self.*.__check_alloc orelse unreachable);
    }
    pub fn clean(self: *Self) void {
        if (self.*.__descriptor_pool != null) {
            vk.vkDestroyDescriptorPool(__vulkan.vkDevice, self.*.__descriptor_pool, null);
            self.*.__descriptor_pool = null;
            self.*.__descriptor_set = null;
        }
        self.*.transform.clean();
    }
};
/// ! object는 deinit 필요없음 vertices, indices는 따로 해제
pub fn object(comptime vertexT: type) type {
    return object_(vertexT, DEF_IDX_TYPE);
}
/// ! object는 deinit 필요없음 vertices, indices는 따로 해제
pub fn object_(comptime vertexT: type, comptime _idx_type: index_type) type {
    return struct {
        const Self = @This();

        vertices: ?*vertices(vertexT),
        indices: ?*indices_(_idx_type),
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
                .interface = .{},
            };
            self.interface = iobject.init();
            self.interface.get_ivertices = get_ivertices;
            self.interface.get_iindices = get_iindices;

            return self;
        }
        pub fn build(self: *Self, _flag: write_flag) void {
            self.*.interface.build(_flag);
        }
        ///transform에 포함된 버퍼 값이 변경될때마다 호출한다. 리소스만 변경시에는 대신 map_update 호출
        pub fn update(self: *Self) void {
            self.*.interface.update();
        }
        pub fn deinit(self: *Self) void {
            self.*.interface.deinit();
        }
    };
}
