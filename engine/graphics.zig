const std = @import("std");

const system = @import("system.zig");
const window = @import("window.zig");
const __system = @import("__system.zig");

const dbg = system.dbg;

const __vulkan_allocator = @import("__vulkan_allocator.zig");

const _allocator = __system.allocator;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;

const math = @import("math.zig");
const geometry = @import("geometry.zig");
const render_command = @import("render_command.zig");
const line = geometry.line;
const mem = @import("mem.zig");
const point = math.point;
const vector = math.vector;
const matrix = math.matrix;
const matrix_error = math.matrix_error;

const vulkan_res_node = __vulkan_allocator.vulkan_res_node;

///use make_shape2d_data fn
pub const indices16 = indices_(.U16);
pub const indices32 = indices_(.U32);
pub const indices = indices_(DEF_IDX_TYPE_);

pub const dummy_vertices = [@sizeOf(vertices(u8))]u8;
pub const dummy_indices = [@sizeOf(indices)]u8;

pub fn take_vertices(dest_type: type, src_ptrmempool: anytype) !dest_type {
    return @as(dest_type, @alignCast(@ptrCast(try src_ptrmempool.*.create())));
}
pub const take_indices = take_vertices;

pub const write_flag = enum { read_gpu, readwrite_cpu };

pub const shape_color_vertex_2d = extern struct {
    pos: point align(1),
    uvw: [3]f32 align(1),
};

pub const tex_vertex_2d = extern struct {
    pos: point align(1),
    uv: point align(1),
};

pub var render_cmd: ?[]*render_command = null;

pub const index_type = enum { U16, U32 };
pub const DEF_IDX_TYPE_: index_type = .U32;
pub const DEF_IDX_TYPE = indices_(DEF_IDX_TYPE_).idxT;

pub const iobject = union(enum) {
    const Self = @This();
    _shape: shape,
    _image: image,
    _anim_image: animate_image,

    pub inline fn deinit(self: *Self) void {
        switch (self.*) {
            inline else => |*case| case.*.deinit(),
        }
    }
    pub inline fn build(self: *Self) void {
        switch (self.*) {
            inline else => |*case| case.*.build(),
        }
    }
    pub inline fn update(self: *Self) void {
        switch (self.*) {
            inline else => |*case| case.*.update(),
        }
    }
    pub inline fn __draw(self: *Self, cmd: vk.VkCommandBuffer) void {
        switch (self.*) {
            inline else => |*case| case.*.__draw(cmd),
        }
    }
};

pub fn vertices(comptime vertexT: type) type {
    return struct {
        const Self = @This();

        array: ?[]vertexT = null,
        node: vulkan_res_node(.buffer) = .{},

        allocator: std.mem.Allocator = undefined,
        __check_init: mem.check_init = .{},

        pub fn init() Self {
            const self: Self = .{};
            return self;
        }
        pub fn init_for_alloc(__allocator: std.mem.Allocator) Self {
            const self: Self = .{ .allocator = __allocator };
            return self;
        }
        pub inline fn deinit(self: *Self) void {
            self.*.__check_init.deinit();
            self.*.node.clean();
        }
        pub inline fn deinit_for_alloc(self: *Self) void {
            deinit(self);
            self.allocator.free(self.array.?);
        }
        pub fn build(self: *Self, _flag: write_flag) void {
            self.*.__check_init.init();
            create_buffer(vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, _flag, @sizeOf(vertexT) * self.*.array.?.len, &self.*.node, std.mem.sliceAsBytes(self.*.array.?));
            self.*.node.__resource_len = @intCast(self.*.array.?.len);
        }
        ///write_flag가 readwrite_cpu만 호출
        pub fn map_update(self: *Self) void {
            self.*.node.map_update(self.*.array.?.ptr);
        }
    };
}

pub fn check_vk_allocator() void {
    if (__vulkan.vk_allocator == null) {
        __vulkan.vk_allocator_mutex.lock();
        if (__vulkan.vk_allocator_use_free) {
            for (__vulkan.vk_allocators.items) |v| {
                if (v.*.is_free) {
                    __vulkan.vk_allocator = &v.*.alloc;
                    v.*.is_free = false;
                    break;
                }
            }
            __vulkan.vk_allocator_free_count -= 1;
            if (__vulkan.vk_allocator_free_count == 0) {
                __vulkan.vk_allocator_use_free = false;
            }
        } else {
            const res = __vulkan.pvk_allocators.create() catch |e| system.handle_error3("graphics.check_vk_allocator.pvk_allocators.create()", e);
            res.*.alloc = __vulkan_allocator.init();
            res.*.is_free = false;
            __vulkan.vk_allocators.append(res) catch |e| system.handle_error3("graphics.check_vk_allocator.vk_allocators.append()", e);
            __vulkan.vk_allocator = &res.*.alloc;
        }
        __vulkan.vk_allocator_mutex.unlock();
    }
}

///다른 스레드에서 graphics 개체.build 함수를 호출해서 메모리를 할당한적이 있을때 호출합니다. -> 안했으면 null 검사로 넘어감.
pub fn deinit_vk_allocator_thread() void {
    if (__vulkan.vk_allocator != null) {
        __vulkan.vk_allocator_mutex.lock();
        defer __vulkan.vk_allocator_mutex.unlock();
        if (__vulkan.vk_allocator_is_destroyed) return;
        if (__vulkan.vk_allocator == &__vulkan.vk_allocators.items[0].alloc) { //0번은 메인스레드라 지우면 안됩니다.
            system.print_error("WARN cant deinit main thread vk_allocators.items[0]\n", .{});
            return;
        }

        var i: usize = 0;
        for (__vulkan.vk_allocators.items) |v| {
            if (&v.*.alloc == __vulkan.vk_allocator) {
                if (__vulkan.vk_allocators.items.len > __vulkan.vk_allocator_FREE_MAX) {
                    v.*.alloc.deinit();
                    _ = __vulkan.vk_allocators.orderedRemove(i);
                    __vulkan.pvk_allocators.destroy(v);
                } else {
                    v.*.is_free = true;
                    __vulkan.vk_allocator_free_count += 1;

                    if (__vulkan.vk_allocator_free_count >= __vulkan.vk_allocator_FREE_MAX) __vulkan.vk_allocator_use_free = true;
                }
                break;
            }
            i += 1;
        }
        __vulkan.vk_allocator = null;
    }
}

pub fn create_buffer(usage: vk.VkBufferUsageFlags, _flag: write_flag, size: u64, _out_vulkan_buffer_node: *vulkan_res_node(.buffer), _data: ?[]const u8) void {
    const buf_info: vk.VkBufferCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, .size = size, .usage = usage, .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

    const prop: vk.VkMemoryPropertyFlags =
        switch (_flag) {
        .read_gpu => vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        .readwrite_cpu => vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
    };
    check_vk_allocator();
    __vulkan.vk_allocator.?.*.create_buffer(&buf_info, prop, _out_vulkan_buffer_node, _data);
}

pub fn indices_(comptime _type: index_type) type {
    return struct {
        const Self = @This();
        const idxT = switch (_type) {
            .U16 => u16,
            .U32 => u32,
        };

        node: vulkan_res_node(.buffer) = .{},
        idx_type: index_type = undefined,
        array: ?[]idxT = null,
        allocator: std.mem.Allocator = undefined,
        __check_init: mem.check_init = .{},

        pub fn init() Self {
            var self: Self = .{};
            self.idx_type = _type;
            return self;
        }
        pub fn init_for_alloc(__allocator: std.mem.Allocator) Self {
            var self: Self = .{};
            self.idx_type = _type;
            self.allocator = __allocator;
            return self;
        }
        pub inline fn deinit(self: *Self) void {
            self.*.__check_init.deinit();
            self.*.node.clean();
        }
        pub inline fn deinit_for_alloc(self: *Self) void {
            deinit(self);
            self.allocator.free(self.array.?);
        }
        pub fn build(self: *Self, _flag: write_flag) void {
            self.*.__check_init.init();
            create_buffer(vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, _flag, @sizeOf(idxT) * self.*.array.?.len, &self.*.node, std.mem.sliceAsBytes(self.*.array.?));
            self.*.node.__resource_len = @intCast(self.*.array.?.len);
        }
        ///write_flag가 readwrite_cpu만 호출
        pub fn map_update(self: *Self) void {
            self.*.node.map_update(self.*.array.?.ptr);
        }
    };
}

pub const projection = struct {
    const Self = @This();
    proj: matrix = undefined,
    __uniform: vulkan_res_node(.buffer) = .{},
    __check_alloc: mem.check_alloc = .{},

    pub fn init_matrix_orthographic(self: *Self, _width: f32, _height: f32) matrix_error!void {
        const width = @as(f32, @floatFromInt(window.window_width()));
        const height = @as(f32, @floatFromInt(window.window_height()));
        const ratio = if (width / height > _width / _height) _height / height else _width / width;
        self.*.proj = try matrix.orthographicLhVulkan(
            width * ratio,
            height * ratio,
            0.1,
            100,
        );
    }
    pub fn init_matrix_orthographic2(self: *Self, _width: f32, _height: f32, near: f32, far: f32) matrix_error!void {
        const width = @as(f32, @floatFromInt(window.window_width()));
        const height = @as(f32, @floatFromInt(window.window_height()));
        const ratio = if (width / height > _width / _height) _height / height else _width / width;
        self.*.proj = try matrix.orthographicLhVulkan(
            width * ratio,
            height * ratio,
            near,
            far,
        );
    }
    pub fn init_matrix_perspective(self: *Self, fov: f32) matrix_error!void {
        self.*.proj = try matrix.perspectiveFovLhVulkan(
            fov,
            @as(f32, @floatFromInt(window.window_width())) / @as(f32, @floatFromInt(window.window_height())),
            0.1,
            100,
        );
    }
    pub fn init_matrix_perspective2(self: *Self, fov: f32, near: f32, far: f32) matrix_error!void {
        self.*.proj = try matrix.perspectiveFovLhVulkan(
            fov,
            @as(f32, @floatFromInt(window.window_width())) / @as(f32, @floatFromInt(window.window_height())),
            near,
            far,
        );
    }
    pub inline fn deinit(self: *Self) void {
        self.*.__check_alloc.deinit();
        self.*.__uniform.clean();
    }
    pub fn build(self: *Self, _flag: write_flag) void {
        self.*.__check_alloc.init(__system.allocator);
        create_buffer(vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, _flag, @sizeOf(matrix), &self.*.__uniform, mem.obj_to_u8arrC(&self.*.proj));
    }
    pub fn map_update(self: *Self) void {
        self.*.__uniform.map_update(&self.*.proj);
    }
};
pub const camera = struct {
    const Self = @This();
    view: matrix,
    __uniform: vulkan_res_node(.buffer) = .{},
    __check_alloc: mem.check_alloc = .{},

    /// w좌표는 신경 x, 시스템 초기화 후 호출
    pub fn init(eyepos: vector, focuspos: vector, updir: vector) Self {
        var res = Self{ .view = matrix.lookAtLh(eyepos, focuspos, updir) };
        res.__check_alloc.init(__system.allocator);
        build(&res, .readwrite_cpu);
        return res;
    }
    pub inline fn deinit(self: *Self) void {
        self.*.__check_alloc.deinit();
        self.*.__uniform.clean();
    }
    fn build(self: *Self, _flag: write_flag) void {
        create_buffer(vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, _flag, @sizeOf(matrix), &self.*.__uniform, mem.obj_to_u8arrC(&self.*.view));
    }
    pub fn map_update(self: *Self) void {
        self.*.__uniform.map_update(&self.*.view);
    }
};
pub const color_transform = struct {
    const Self = @This();
    color_mat: matrix,
    __uniform: vulkan_res_node(.buffer) = .{},
    __check_alloc: mem.check_alloc = .{},

    pub fn get_no_default() *Self {
        return &__vulkan.no_color_tran;
    }

    /// w좌표는 신경 x, 시스템 초기화 후 호출
    pub fn init() Self {
        const res = Self{ .color_mat = matrix.identity() };
        return res;
    }
    pub inline fn deinit(self: *Self) void {
        self.*.__check_alloc.deinit();
        self.*.__uniform.clean();
    }
    pub fn build(self: *Self, _flag: write_flag) void {
        self.*.__check_alloc.init(__system.allocator);
        create_buffer(vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, _flag, @sizeOf(matrix), &self.*.__uniform, mem.obj_to_u8arrC(&self.*.color_mat));
    }
    pub fn map_update(self: *Self) void {
        self.*.__check_alloc.check_inited();
        self.*.__uniform.map_update(&self.*.color_mat);
    }
};
//transform는 object와 한몸이라 따로 check_alloc 필요없음
pub const transform = struct {
    const Self = @This();

    model: matrix = matrix.identity(),
    ///이 값이 변경되면 update 필요
    camera: ?*camera = null,
    ///이 값이 변경되면 update 필요
    projection: ?*projection = null,
    __model_uniform: vulkan_res_node(.buffer) = .{},

    __check_init: mem.check_init = .{},

    pub inline fn __deinit(self: *Self) void {
        self.*.__check_init.deinit();
        self.*.__model_uniform.clean();
    }
    pub inline fn __build(self: *Self) void {
        self.*.__check_init.init();
        create_buffer(vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, .readwrite_cpu, @sizeOf(matrix), &self.*.__model_uniform, mem.obj_to_u8arrC(&self.*.model));
    }
    ///write_flag가 readwrite_cpu일때만 호출
    pub fn map_update(self: *Self) void {
        self.*.__check_init.check_inited();
        self.*.__model_uniform.map_update(&self.*.model);
    }
};

pub const texture = struct {
    const Self = @This();
    __image: vulkan_res_node(.image) = .{},
    width: u32 = 0,
    height: u32 = 0,
    pixels: ?[]u8 = null,
    vertices: *vertices(tex_vertex_2d),
    indices: ?*indices32,
    sampler: vk.VkSampler,
    __descriptor_set: vk.VkDescriptorSet = undefined,
    __descriptor_pool: vk.VkDescriptorPool = undefined,
    __check_init: mem.check_init = .{},

    pub fn get_default_quad_image_vertices() *vertices(tex_vertex_2d) {
        return &__vulkan.quad_image_vertices;
    }
    pub fn get_default_linear_sampler() vk.VkSampler {
        return __vulkan.linear_sampler;
    }
    pub fn get_default_nearest_sampler() vk.VkSampler {
        return __vulkan.nearest_sampler;
    }

    pub fn init() Self {
        return .{
            .vertices = get_default_quad_image_vertices(),
            .indices = null,
            .sampler = get_default_linear_sampler(),
        };
    }

    pub inline fn deinit(self: *Self) void {
        self.*.__check_init.deinit();
        self.*.__image.clean();
        vk.vkDestroyDescriptorPool(__vulkan.vkDevice, self.*.__descriptor_pool, null);
    }
    pub fn build(self: *Self) void {
        self.*.__check_init.init();
        if (self.*.width == 0 or self.*.height == 0) {
            system.print_error("WARN can't build texture\n", .{});
            return;
        }
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
        check_vk_allocator();
        __vulkan.vk_allocator.?.*.create_image(&img_info, &self.*.__image, std.mem.sliceAsBytes(self.*.pixels.?), 0);

        var result: vk.VkResult = undefined;

        const pool_size = [1]vk.VkDescriptorPoolSize{.{
            .descriptorCount = 1,
            .type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        }};
        const pool_info: vk.VkDescriptorPoolCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = pool_size.len,
            .pPoolSizes = &pool_size,
            .maxSets = 1,
        };
        result = vk.vkCreateDescriptorPool(__vulkan.vkDevice, &pool_info, null, &self.*.__descriptor_pool);
        system.handle_error(result == vk.VK_SUCCESS, "image.build.vkCreateDescriptorPool(tex_2d_pipeline_set) : {d}", .{result});

        const alloc_info: vk.VkDescriptorSetAllocateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = self.*.__descriptor_pool,
            .descriptorSetCount = 1,
            .pSetLayouts = &__vulkan.tex_2d_pipeline_set.descriptorSetLayout2,
        };
        result = vk.vkAllocateDescriptorSets(__vulkan.vkDevice, &alloc_info, &self.*.__descriptor_set);
        system.handle_error(result == vk.VK_SUCCESS, "image.build.vkAllocateDescriptorSets : {d}", .{result});

        const imageInfo: vk.VkDescriptorImageInfo = .{
            .imageLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .imageView = self.*.__image.__image_view,
            .sampler = self.*.sampler,
        };
        const descriptorWrite = [_]vk.VkWriteDescriptorSet{
            .{
                .dstSet = self.*.__descriptor_set,
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .pBufferInfo = null,
                .pImageInfo = &imageInfo,
                .pTexelBufferView = null,
            },
        };
        vk.vkUpdateDescriptorSets(__vulkan.vkDevice, descriptorWrite.len, &descriptorWrite, 0, null);
    }
    pub fn copy(self: *Self, _data: []const u8, rect: ?math.recti) void {
        check_vk_allocator();
        __vulkan.vk_allocator.?.*.copy_texture(self, _data, rect);
    }
};

pub const texture_array = struct {
    const Self = @This();
    __image: vulkan_res_node(.image) = .{},
    width: u32 = 0,
    height: u32 = 0,
    frames: u32 = 0,
    ///1차원 배열에 순차적으로 이미지 프레임 데이터들을 배치
    pixels: ?[]u8 = null,
    vertices: *vertices(tex_vertex_2d),
    indices: ?*indices32,
    sampler: vk.VkSampler,
    __descriptor_set: vk.VkDescriptorSet = undefined,
    __descriptor_pool: vk.VkDescriptorPool = undefined,
    __check_init: mem.check_init = .{},

    pub fn get_default_quad_image_vertices() *vertices(tex_vertex_2d) {
        return &__vulkan.quad_image_vertices;
    }
    pub fn get_default_linear_sampler() vk.VkSampler {
        return __vulkan.linear_sampler;
    }
    pub fn get_default_nearest_sampler() vk.VkSampler {
        return __vulkan.nearest_sampler;
    }
    pub fn get_frame_count_build(self: *Self) u32 {
        return self.*.__image.__resource_len;
    }

    pub fn init() Self {
        return .{
            .vertices = get_default_quad_image_vertices(),
            .indices = null,
            .sampler = get_default_linear_sampler(),
        };
    }

    pub inline fn deinit(self: *Self) void {
        self.*.__check_init.deinit();
        self.*.__image.clean();
        vk.vkDestroyDescriptorPool(__vulkan.vkDevice, self.*.__descriptor_pool, null);
    }
    pub fn build(self: *Self) void {
        self.*.__check_init.init();
        if (self.*.width == 0 or self.*.height == 0 or self.*.frames == 0) {
            system.print_error("WARN can't build texture array\n", .{});
            return;
        }
        const img_info: vk.VkImageCreateInfo = .{
            .arrayLayers = self.*.frames,
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
        check_vk_allocator();
        __vulkan.vk_allocator.?.*.create_image(&img_info, &self.*.__image, std.mem.sliceAsBytes(self.*.pixels.?), 0);

        var result: vk.VkResult = undefined;

        const pool_size = [1]vk.VkDescriptorPoolSize{.{
            .descriptorCount = 1,
            .type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        }};
        const pool_info: vk.VkDescriptorPoolCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = pool_size.len,
            .pPoolSizes = &pool_size,
            .maxSets = 1,
        };
        result = vk.vkCreateDescriptorPool(__vulkan.vkDevice, &pool_info, null, &self.*.__descriptor_pool);
        system.handle_error(result == vk.VK_SUCCESS, "image.build.vkCreateDescriptorPool(tex_2d_pipeline_set) : {d}", .{result});

        const alloc_info: vk.VkDescriptorSetAllocateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = self.*.__descriptor_pool,
            .descriptorSetCount = 1,
            .pSetLayouts = &__vulkan.tex_2d_pipeline_set.descriptorSetLayout2,
        };
        result = vk.vkAllocateDescriptorSets(__vulkan.vkDevice, &alloc_info, &self.*.__descriptor_set);
        system.handle_error(result == vk.VK_SUCCESS, "image.build.vkAllocateDescriptorSets : {d}", .{result});

        const imageInfo: vk.VkDescriptorImageInfo = .{
            .imageLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .imageView = self.*.__image.__image_view,
            .sampler = self.*.sampler,
        };
        const descriptorWrite = [_]vk.VkWriteDescriptorSet{
            .{
                .dstSet = self.*.__descriptor_set,
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .pBufferInfo = null,
                .pImageInfo = &imageInfo,
                .pTexelBufferView = null,
            },
        };
        vk.vkUpdateDescriptorSets(__vulkan.vkDevice, descriptorWrite.len, &descriptorWrite, 0, null);
    }
};

pub const shape = struct {
    const Self = @This();

    pub const source = struct {
        vertices: vertices(shape_color_vertex_2d),
        indices: indices32,
        color: vector = .{ 1, 1, 1, 1 },
        __uniform: vulkan_res_node(.buffer) = .{},
        __descriptor_set: vk.VkDescriptorSet = undefined,
        __descriptor_pool: vk.VkDescriptorPool = undefined,

        pub fn init() source {
            return .{
                .vertices = vertices(shape_color_vertex_2d).init(),
                .indices = indices32.init(),
            };
        }
        pub fn init_for_alloc(__allocator: std.mem.Allocator) source {
            return .{
                .vertices = vertices(shape_color_vertex_2d).init_for_alloc(__allocator),
                .indices = indices32.init_for_alloc(__allocator),
            };
        }
        pub fn build(self: *source, _flag: write_flag, _colorflag: write_flag) void {
            self.*.vertices.build(_flag);
            self.*.indices.build(_flag);

            create_buffer(vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, _colorflag, @sizeOf(vector), &self.*.__uniform, std.mem.sliceAsBytes(@as([*]vector, @ptrCast(&self.*.color))[0..1]));

            const pool_size: [1]vk.VkDescriptorPoolSize = .{.{
                .descriptorCount = 1,
                .type = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            }};
            const pool_info: vk.VkDescriptorPoolCreateInfo = .{
                .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
                .poolSizeCount = pool_size.len,
                .pPoolSizes = &pool_size,
                .maxSets = 1,
            };
            var result = vk.vkCreateDescriptorPool(__vulkan.vkDevice, &pool_info, null, &self.*.__descriptor_pool);
            system.handle_error(result == vk.VK_SUCCESS, "shape.source.build.vkCreateDescriptorPool : {d}", .{result});

            const alloc_info: vk.VkDescriptorSetAllocateInfo = .{
                .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
                .descriptorPool = self.*.__descriptor_pool,
                .descriptorSetCount = 1,
                .pSetLayouts = &[_]vk.VkDescriptorSetLayout{
                    __vulkan.quad_shape_2d_pipeline_set.descriptorSetLayout,
                },
            };
            result = vk.vkAllocateDescriptorSets(__vulkan.vkDevice, &alloc_info, &self.*.__descriptor_set);
            system.handle_error(result == vk.VK_SUCCESS, "shape.source.build.vkAllocateDescriptorSets : {d}", .{result});

            const buffer_info = [1]vk.VkDescriptorBufferInfo{vk.VkDescriptorBufferInfo{
                .buffer = self.*.__uniform.res,
                .offset = 0,
                .range = @sizeOf(vector),
            }};
            const descriptorWrite = [_]vk.VkWriteDescriptorSet{
                .{
                    .dstSet = self.*.__descriptor_set,
                    .dstBinding = 0,
                    .dstArrayElement = 0,
                    .descriptorCount = buffer_info.len,
                    .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                    .pBufferInfo = &buffer_info,
                    .pImageInfo = null,
                    .pTexelBufferView = null,
                },
            };
            vk.vkUpdateDescriptorSets(__vulkan.vkDevice, descriptorWrite.len, &descriptorWrite, 0, null);
        }
        pub fn deinit(self: *source) void {
            self.*.vertices.deinit();
            self.*.indices.deinit();
            vk.vkDestroyDescriptorPool(__vulkan.vkDevice, self.*.__descriptor_pool, null);
            self.*.__uniform.clean();
        }
        pub fn deinit_for_alloc(self: *source) void {
            self.*.vertices.deinit_for_alloc();
            self.*.indices.deinit_for_alloc();
            vk.vkDestroyDescriptorPool(__vulkan.vkDevice, self.*.__descriptor_pool, null);
            self.*.__uniform.clean();
        }
        pub fn map_color_update(self: *source) void {
            var data: ?*vector = undefined;
            self.*.__uniform.map(@ptrCast(&data));
            mem.memcpy_nonarray(data.?, &self.*.color);
            self.*.__uniform.unmap();
        }
    };

    src: *source = undefined,
    extra_src: ?[]*source = null,
    __descriptor_set: vk.VkDescriptorSet = undefined,
    transform: transform = .{},
    __descriptor_pool: vk.VkDescriptorPool = null,

    pub fn can_build(self: Self) bool {
        return self.transform.projection.?.*.__uniform.res != null and self.transform.camera.?.*.__uniform.res != null;
    }
    pub fn update(self: *Self) void {
        if (!(self.*.can_build() and self.transform.__model_uniform.res != null)) {
            system.handle_error_msg2("shape update need transform build and need transform.camera, projection build(invaild)");
        }

        const buffer_info = [_]vk.VkDescriptorBufferInfo{
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
            vk.VkDescriptorBufferInfo{
                .buffer = __vulkan.__pre_mat_uniform.res,
                .offset = 0,
                .range = @sizeOf(matrix),
            },
        };
        const descriptorWrite = [_]vk.VkWriteDescriptorSet{
            .{
                .dstSet = self.*.__descriptor_set,
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorCount = buffer_info.len,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .pBufferInfo = &buffer_info,
                .pImageInfo = null,
                .pTexelBufferView = null,
            },
        };
        vk.vkUpdateDescriptorSets(__vulkan.vkDevice, descriptorWrite.len, &descriptorWrite, 0, null);
    }
    pub fn build(self: *Self) void {
        if (!self.*.can_build()) {
            system.handle_error_msg2("shape build need transform.camera, projection build(invaild)");
        }
        if (!self.*.src.__uniform.is_build()) {
            system.handle_error_msg2("shape build need vertices");
        }
        var result: vk.VkResult = undefined;

        const pool_size: [1]vk.VkDescriptorPoolSize = .{.{
            .descriptorCount = 4,
            .type = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        }};
        const pool_info: vk.VkDescriptorPoolCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = pool_size.len,
            .pPoolSizes = &pool_size,
            .maxSets = 1,
        };
        result = vk.vkCreateDescriptorPool(__vulkan.vkDevice, &pool_info, null, &self.*.__descriptor_pool);
        system.handle_error(result == vk.VK_SUCCESS, "shape.build.vkCreateDescriptorPool : {d}", .{result});
        const alloc_info: vk.VkDescriptorSetAllocateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = self.*.__descriptor_pool,
            .descriptorSetCount = 1,
            .pSetLayouts = &[_]vk.VkDescriptorSetLayout{
                __vulkan.shape_color_2d_pipeline_set.descriptorSetLayout,
            },
        };
        result = vk.vkAllocateDescriptorSets(__vulkan.vkDevice, &alloc_info, &self.*.__descriptor_set);
        system.handle_error(result == vk.VK_SUCCESS, "shape.build.vkAllocateDescriptorSets : {d}", .{result});

        self.*.transform.__build();

        self.*.update();
    }
    pub fn deinit(self: *Self) void {
        vk.vkDestroyDescriptorPool(__vulkan.vkDevice, self.*.__descriptor_pool, null);
        self.*.transform.__deinit();
    }
    pub fn __draw(self: *Self, cmd: vk.VkCommandBuffer) void {
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.shape_color_2d_pipeline_set.pipeline);

        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.shape_color_2d_pipeline_set.pipelineLayout, 0, 1, &self.*.__descriptor_set, 0, null);

        const offsets: vk.VkDeviceSize = 0;
        vk.vkCmdBindVertexBuffers(cmd, 0, 1, &self.*.src.*.vertices.node.res, &offsets);

        vk.vkCmdBindIndexBuffer(cmd, self.*.src.*.indices.node.res, 0, vk.VK_INDEX_TYPE_UINT32);
        vk.vkCmdDrawIndexed(cmd, self.*.src.*.indices.node.__resource_len, 1, 0, 0, 0);

        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.quad_shape_2d_pipeline_set.pipeline);

        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.quad_shape_2d_pipeline_set.pipelineLayout, 0, 1, &self.*.src.*.__descriptor_set, 0, null);
        vk.vkCmdDraw(cmd, 6, 1, 0, 0);

        if (self.*.extra_src != null and self.*.extra_src.?.len > 0) {
            for (self.*.extra_src.?) |src| {
                vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.shape_color_2d_pipeline_set.pipeline);
                vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.shape_color_2d_pipeline_set.pipelineLayout, 0, 1, &self.*.__descriptor_set, 0, null);
                vk.vkCmdBindVertexBuffers(cmd, 0, 1, &src.*.vertices.node.res, &offsets);

                vk.vkCmdBindIndexBuffer(cmd, src.*.indices.node.res, 0, vk.VK_INDEX_TYPE_UINT32);
                vk.vkCmdDrawIndexed(cmd, src.*.indices.node.__resource_len, 1, 0, 0, 0);

                vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.quad_shape_2d_pipeline_set.pipeline);
                vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.quad_shape_2d_pipeline_set.pipelineLayout, 0, 1, &src.*.__descriptor_set, 0, null);

                vk.vkCmdDraw(cmd, 6, 1, 0, 0);
            }
        }
    }
};

pub const center_pt_pos = enum {
    center,
    left,
    right,
    top_left,
    top,
    top_right,
    bottom_left,
    bottom,
    bottom_right,
};

pub const image = struct {
    const Self = @This();

    src: *texture = undefined,
    color_tran: *color_transform,
    __descriptor_set: vk.VkDescriptorSet = undefined,
    __descriptor_pool: vk.VkDescriptorPool = null,
    transform: transform = .{},

    ///회전 했을때 고려안함, img scale은 기본(이미지 크기) 비율일때 기준
    pub fn pixel_perfect_point(img: Self, _p: point, _canvas_w: f32, _canvas_h: f32, center: center_pt_pos) point {
        const width = @as(f32, @floatFromInt(window.window_width()));
        const height = @as(f32, @floatFromInt(window.window_height()));
        if (width / height > _canvas_w / _canvas_h) { //1배 비율이 아니면 적용할수 없다.
            if (_canvas_h != height) return _p;
        } else {
            if (_canvas_w != width) return _p;
        }
        _p = @floor(_p);
        if (window.window_width() % 2 != 0) _p.x -= 0.5;
        if (window.window_height() % 2 != 0) _p.y += 0.5;

        switch (center) {
            .center => {
                if (img.src.*.texture.width % 2 != 0) _p.x += 0.5;
                if (img.src.*.texture.height % 2 != 0) _p.y -= 0.5;
            },
            .right, .left => {
                if (img.src.*.texture.height % 2 != 0) _p.y -= 0.5;
            },
            .top, .bottom => {
                if (img.src.*.texture.width % 2 != 0) _p.x += 0.5;
            },
            else => {},
        }
        return _p;
    }
    pub fn deinit(self: *Self) void {
        vk.vkDestroyDescriptorPool(__vulkan.vkDevice, self.*.__descriptor_pool, null);
        self.*.transform.__deinit();
    }
    pub fn update(self: *Self) void {
        if (!self.*.can_build()) {
            system.handle_error_msg2("image update need transform build and need transform.camera, projection build(invaild)");
        }
        if (self.*.src.*.__image.res == null) {
            system.handle_error_msg2("image update need texture build");
        }
        const buffer_info = [5]vk.VkDescriptorBufferInfo{
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
            vk.VkDescriptorBufferInfo{
                .buffer = __vulkan.__pre_mat_uniform.res,
                .offset = 0,
                .range = @sizeOf(matrix),
            },
            vk.VkDescriptorBufferInfo{
                .buffer = self.*.color_tran.*.__uniform.res,
                .offset = 0,
                .range = @sizeOf(matrix),
            },
        };
        const descriptorWrite2 = [2]vk.VkWriteDescriptorSet{
            .{
                .sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = self.*.__descriptor_set,
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorCount = 4,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .pBufferInfo = &buffer_info,
                .pImageInfo = null,
                .pTexelBufferView = null,
            },
            .{
                .sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = self.*.__descriptor_set,
                .dstBinding = 4,
                .dstArrayElement = 0,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .pBufferInfo = &buffer_info[4],
                .pImageInfo = null,
                .pTexelBufferView = null,
            },
        };
        vk.vkUpdateDescriptorSets(__vulkan.vkDevice, descriptorWrite2.len, &descriptorWrite2, 0, null);
    }
    pub fn can_build(self: Self) bool {
        return self.transform.projection.?.*.__uniform.res != null and self.transform.camera.?.*.__uniform.res != null;
    }
    pub fn build(self: *Self) void {
        if (!self.*.can_build()) {
            system.handle_error_msg2("image build need transform.camera, projection build(invaild)");
        }
        var result: vk.VkResult = undefined;

        const pool_size = [2]vk.VkDescriptorPoolSize{ .{
            .descriptorCount = 4,
            .type = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        }, .{
            .descriptorCount = 1,
            .type = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        } };
        const pool_info: vk.VkDescriptorPoolCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = pool_size.len,
            .pPoolSizes = &pool_size,
            .maxSets = 1,
        };
        result = vk.vkCreateDescriptorPool(__vulkan.vkDevice, &pool_info, null, &self.*.__descriptor_pool);
        system.handle_error(result == vk.VK_SUCCESS, "image.build.vkCreateDescriptorPool(tex_2d_pipeline_set) : {d}", .{result});

        const alloc_info: vk.VkDescriptorSetAllocateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = self.*.__descriptor_pool,
            .descriptorSetCount = 1,
            .pSetLayouts = &__vulkan.tex_2d_pipeline_set.descriptorSetLayout,
        };
        result = vk.vkAllocateDescriptorSets(__vulkan.vkDevice, &alloc_info, &self.*.__descriptor_set);
        system.handle_error(result == vk.VK_SUCCESS, "image.build.vkAllocateDescriptorSets : {d}", .{result});

        self.*.transform.__build();

        self.*.update();
    }
    pub fn __draw(self: *Self, cmd: vk.VkCommandBuffer) void {
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.tex_2d_pipeline_set.pipeline);

        vk.vkCmdBindDescriptorSets(
            cmd,
            vk.VK_PIPELINE_BIND_POINT_GRAPHICS,
            __vulkan.tex_2d_pipeline_set.pipelineLayout,
            0,
            2,
            &[_]vk.VkDescriptorSet{ self.*.__descriptor_set, self.*.src.*.__descriptor_set },
            0,
            null,
        );

        const offsets: vk.VkDeviceSize = 0;
        vk.vkCmdBindVertexBuffers(cmd, 0, 1, &self.*.src.vertices.*.node.res, &offsets);

        if (self.*.src.indices != null) {
            vk.vkCmdBindIndexBuffer(cmd, self.*.src.indices.?.*.node.res, 0, switch (self.*.src.indices.?.*.idx_type) {
                .U16 => vk.VK_INDEX_TYPE_UINT16,
                .U32 => vk.VK_INDEX_TYPE_UINT32,
            });
            vk.vkCmdDrawIndexed(cmd, self.*.src.indices.?.*.node.__resource_len, 1, 0, 0, 0);
        } else {
            vk.vkCmdDraw(cmd, self.*.src.vertices.*.node.__resource_len, 1, 0, 0);
        }
    }
    pub fn init() Self {
        const self = Self{
            .color_tran = color_transform.get_no_default(),
        };
        return self;
    }
};
pub const animate_image = struct {
    const Self = @This();

    src: *texture_array = undefined,
    color_tran: *color_transform,
    __descriptor_set: vk.VkDescriptorSet = undefined,
    __descriptor_pool: vk.VkDescriptorPool = null,
    transform: transform = .{},
    __frame_uniform: vulkan_res_node(.buffer) = .{},
    frame: u32 = 0,

    ///회전 했을때 고려안함, img scale은 기본(이미지 크기) 비율일때 기준
    pub fn pixel_perfect_point(img: Self, _p: point, _canvas_w: f32, _canvas_h: f32, center: center_pt_pos) point {
        const width = @as(f32, @floatFromInt(window.window_width()));
        const height = @as(f32, @floatFromInt(window.window_height()));
        if (width / height > _canvas_w / _canvas_h) { //1배 비율이 아니면 적용할수 없다.
            if (_canvas_h != height) return _p;
        } else {
            if (_canvas_w != width) return _p;
        }
        _p = @floor(_p);
        if (window.window_width() % 2 != 0) _p.x -= 0.5;
        if (window.window_height() % 2 != 0) _p.y += 0.5;

        switch (center) {
            .center => {
                if (img.src.*.texture.width % 2 != 0) _p.x += 0.5;
                if (img.src.*.texture.height % 2 != 0) _p.y -= 0.5;
            },
            .right, .left => {
                if (img.src.*.texture.height % 2 != 0) _p.y -= 0.5;
            },
            .top, .bottom => {
                if (img.src.*.texture.width % 2 != 0) _p.x += 0.5;
            },
            else => {},
        }
        return _p;
    }
    pub fn deinit(self: *Self) void {
        vk.vkDestroyDescriptorPool(__vulkan.vkDevice, self.*.__descriptor_pool, null);
        self.*.transform.__deinit();
        self.*.__frame_uniform.clean();
    }
    pub fn next_frame(self: *Self) void {
        if (!self.*.__frame_uniform.is_build() or self.*.src.*.get_frame_count_build() == 0) return;
        if (self.*.src.*.__image.__resource_len - 1 < self.*.frame) {
            self.*.frame = 0;
            return;
        }
        self.*.frame = (self.*.frame + 1) % self.*.src.*.get_frame_count_build();
    }
    pub fn prev_frame(self: *Self) void {
        if (!self.*.__frame_uniform.is_build() or self.*.src.*.get_frame_count_build() == 0) return;
        if (self.*.src.*.__image.__resource_len - 1 < self.*.frame) {
            self.*.frame = 0;
            return;
        }
        self.*.frame = if (self.*.frame > 0) (self.*.frame - 1) else (self.*.src.*.get_frame_count_build() - 1);
    }

    pub fn map_update_frame(self: *Self) void {
        if (!self.*.__frame_uniform.is_build() or self.*.src.*.__image.__resource_len == 0 or self.*.src.*.__image.__resource_len - 1 < self.*.frame) return;
        const F: f32 = @floatFromInt(self.*.frame);
        self.*.__frame_uniform.map_update(&F);
    }
    pub fn update(self: *Self) void {
        if (!self.*.can_build()) {
            system.handle_error_msg2("image update need transform build and need transform.camera, projection build(invaild)");
        }
        if (self.*.src.*.__image.res == null) {
            system.handle_error_msg2("image update need texture build");
        }
        const buffer_info = [6]vk.VkDescriptorBufferInfo{
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
            vk.VkDescriptorBufferInfo{
                .buffer = __vulkan.__pre_mat_uniform.res,
                .offset = 0,
                .range = @sizeOf(matrix),
            },
            vk.VkDescriptorBufferInfo{
                .buffer = self.*.color_tran.*.__uniform.res,
                .offset = 0,
                .range = @sizeOf(matrix),
            },
            vk.VkDescriptorBufferInfo{
                .buffer = self.*.__frame_uniform.res,
                .offset = 0,
                .range = @sizeOf(f32),
            },
        };
        const descriptorWrite2 = [2]vk.VkWriteDescriptorSet{
            .{
                .sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = self.*.__descriptor_set,
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorCount = 4,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .pBufferInfo = &buffer_info,
                .pImageInfo = null,
                .pTexelBufferView = null,
            },
            .{
                .sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = self.*.__descriptor_set,
                .dstBinding = 4,
                .dstArrayElement = 0,
                .descriptorCount = 2,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .pBufferInfo = &buffer_info[4],
                .pImageInfo = null,
                .pTexelBufferView = null,
            },
        };
        vk.vkUpdateDescriptorSets(__vulkan.vkDevice, descriptorWrite2.len, &descriptorWrite2, 0, null);
    }
    pub fn can_build(self: Self) bool {
        return self.transform.projection.?.*.__uniform.res != null and self.transform.camera.?.*.__uniform.res != null;
    }
    pub fn build(self: *Self) void {
        if (!self.*.can_build()) {
            system.handle_error_msg2("image build need transform.camera, projection build(invaild)");
        }
        var result: vk.VkResult = undefined;

        const pool_size = [2]vk.VkDescriptorPoolSize{ .{
            .descriptorCount = 4,
            .type = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        }, .{
            .descriptorCount = 2,
            .type = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        } };
        const pool_info: vk.VkDescriptorPoolCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = pool_size.len,
            .pPoolSizes = &pool_size,
            .maxSets = 1,
        };
        result = vk.vkCreateDescriptorPool(__vulkan.vkDevice, &pool_info, null, &self.*.__descriptor_pool);
        system.handle_error(result == vk.VK_SUCCESS, "image.build.vkCreateDescriptorPool(tex_2d_pipeline_set) : {d}", .{result});

        const alloc_info: vk.VkDescriptorSetAllocateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = self.*.__descriptor_pool,
            .descriptorSetCount = 1,
            .pSetLayouts = &__vulkan.animate_tex_2d_pipeline_set.descriptorSetLayout,
        };
        result = vk.vkAllocateDescriptorSets(__vulkan.vkDevice, &alloc_info, &self.*.__descriptor_set);
        system.handle_error(result == vk.VK_SUCCESS, "image.build.vkAllocateDescriptorSets : {d}", .{result});

        self.*.transform.__build();

        const F: f32 = @floatFromInt(self.*.frame);
        create_buffer(vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, .readwrite_cpu, @sizeOf(f32), &self.*.__frame_uniform, mem.obj_to_u8arrC(&F));

        self.*.update();
    }
    pub fn __draw(self: *Self, cmd: vk.VkCommandBuffer) void {
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.animate_tex_2d_pipeline_set.pipeline);

        vk.vkCmdBindDescriptorSets(
            cmd,
            vk.VK_PIPELINE_BIND_POINT_GRAPHICS,
            __vulkan.animate_tex_2d_pipeline_set.pipelineLayout,
            0,
            2,
            &[_]vk.VkDescriptorSet{ self.*.__descriptor_set, self.*.src.*.__descriptor_set },
            0,
            null,
        );

        const offsets: vk.VkDeviceSize = 0;
        vk.vkCmdBindVertexBuffers(cmd, 0, 1, &self.*.src.vertices.*.node.res, &offsets);

        if (self.*.src.indices != null) {
            vk.vkCmdBindIndexBuffer(cmd, self.*.src.indices.?.*.node.res, 0, switch (self.*.src.indices.?.*.idx_type) {
                .U16 => vk.VK_INDEX_TYPE_UINT16,
                .U32 => vk.VK_INDEX_TYPE_UINT32,
            });
            vk.vkCmdDrawIndexed(cmd, self.*.src.indices.?.*.node.__resource_len, 1, 0, 0, 0);
        } else {
            vk.vkCmdDraw(cmd, self.*.src.vertices.*.node.__resource_len, 1, 0, 0);
        }
    }
    pub fn init() Self {
        const self = Self{
            .color_tran = color_transform.get_no_default(),
        };
        return self;
    }
};
