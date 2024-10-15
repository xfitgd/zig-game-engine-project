const std = @import("std");
const graphics = @import("graphics.zig");
const system = @import("system.zig");
const window = @import("window.zig");
const __system = @import("__system.zig");

const iobject = graphics.iobject;
const transform = graphics.transform;
const shape = graphics.shape;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;

const math = @import("math.zig");
const geometry = @import("geometry.zig");
const collision = @import("collision.zig");
const iarea = collision.iarea;
const iarea_type = collision.iarea_type;
const mem = @import("mem.zig");
const point = math.point;
const vector = math.vector;
const matrix = math.matrix;
const matrix_error = math.matrix_error;
const center_pt_pos = graphics.center_pt_pos;

pub const button_state = enum {
    UP,
    OVER,
    DOWN,
};

pub const button = struct {
    pub const source = struct {
        src: shape.source,
        over_color: ?vector = null,
        down_color: ?vector = null,

        pub fn init() source {
            return .{
                .src = shape.source.init(),
            };
        }
        pub fn init_for_alloc(__allocator: std.mem.Allocator) source {
            return .{
                .src = shape.source.init_for_alloc(__allocator),
            };
        }
    };
    const Self = @This();

    transform: transform = .{ .parent_type = ._button },
    src: []*source = undefined,
    area: iarea,
    state: button_state = .UP,
    __descriptor_set: vk.VkDescriptorSet = undefined,
    __descriptor_pool: vk.VkDescriptorPool = null,
    on_over: ?*const fn (self: *Self, _mouse_pos: point) void = null,
    on_down: ?*const fn (self: *Self, _mouse_pos: point) void = null,
    on_up: ?*const fn (self: *Self, _mouse_pos: ?point) void = null,

    fn update_color(self: *Self) void {
        for (self.*.src) |v| {
            if (self.*.state == .UP) {
                v.*.src.map_color_update();
            } else if (self.*.state == .OVER) {
                if (v.*.over_color == null) {
                    v.*.src.map_color_update();
                } else {
                    const colorT = v.*.src.color;
                    v.*.src.color = v.*.over_color.?;
                    v.*.src.map_color_update();
                    v.*.src.color = colorT;
                }
            } else if (self.*.state == .DOWN) {
                if (v.*.down_color != null) {
                    const colorT = v.*.src.color;
                    v.*.src.color = v.*.down_color.?;
                    v.*.src.map_color_update();
                    v.*.src.color = colorT;
                }
            }
        }
    }
    pub fn on_mouse_move(self: *Self, _mouse_pos: point) void {
        if (self.state == .UP) {
            if (self.area.rect.is_point_in(_mouse_pos)) {
                self.state = .OVER;
                self.update_color();
                if (self.on_over != null) self.on_over.?(self, _mouse_pos);
            }
        } else if (self.state == .OVER) {
            if (!self.area.rect.is_point_in(_mouse_pos)) {
                self.state = .UP;
                self.update_color();
            }
        }
    }
    pub fn on_mouse_down(self: *Self, _mouse_pos: point) void {
        if (self.state == .UP) {
            if (self.area.rect.is_point_in(_mouse_pos)) {
                self.state = .DOWN;
                self.update_color();
                if (self.on_down != null) self.on_down.?(self, _mouse_pos);
            }
        } else if (self.state == .OVER) {
            self.state = .DOWN;
            self.update_color();
            if (self.on_down != null) self.on_down.?(self, _mouse_pos);
        }
    }
    pub fn on_mouse_up(self: *Self, _mouse_pos: point) void {
        if (self.state == .DOWN) {
            if (self.area.rect.is_point_in(_mouse_pos)) {
                self.state = .OVER;
            } else {
                self.state = .UP;
            }
            self.update_color();
            if (self.on_up != null) self.on_up.?(self, _mouse_pos);
        }
    }
    pub fn on_mouse_out(self: *Self) void {
        if (self.state == .DOWN or self.state == .OVER) {
            self.state = .UP;
            self.update_color();
            if (self.state == .DOWN) {
                if (self.on_up != null) self.on_up.?(self, null);
            }
        }
    }

    pub fn make_square_button(_out: []*source, scale: point, _allocator: std.mem.Allocator) !void {
        _out[0].* = source.init_for_alloc(_allocator);
        _out[1].* = source.init_for_alloc(_allocator);
        _out[0].*.down_color = .{ 0.5, 0.5, 0.5, 0.8 };
        _out[0].*.over_color = .{ 0.5, 0.7, 0.7, 1 };
        _out[0].*.src.color = .{ 0.7, 0.7, 0.7, 1 };
        _out[1].*.down_color = .{ 0.5, 0.5, 1, 1 };
        _out[1].*.over_color = .{ 0.5, 0.5, 1, 1 };
        _out[1].*.src.color = .{ 0.5, 0.5, 0.5, 1 };

        var rect_line: [4]geometry.line = .{
            geometry.line.line_init(.{ -scale[0], scale[1] }, .{ scale[0], scale[1] }),
            geometry.line.line_init(.{ scale[0], scale[1] }, .{ scale[0], -scale[1] }),
            geometry.line.line_init(.{ scale[0], -scale[1] }, .{ -scale[0], -scale[1] }),
            geometry.line.line_init(.{ -scale[0], -scale[1] }, .{ -scale[0], scale[1] }),
        };

        var rl = [1][]geometry.line{rect_line[0..rect_line.len]};
        var rect_poly: geometry.polygon = .{
            .tickness = 2,
            .lines = rl[0..1],
        };
        var raw_polygon_outline = geometry.raw_polygon{
            .vertices = try _allocator.alloc(graphics.shape_color_vertex_2d, 0),
            .indices = try _allocator.alloc(u32, 0),
        };
        var raw_polygon = geometry.raw_polygon{
            .vertices = try _allocator.alloc(graphics.shape_color_vertex_2d, 0),
            .indices = try _allocator.alloc(u32, 0),
        };
        try rect_poly.compute_outline(_allocator, &raw_polygon_outline);
        try rect_poly.compute_polygon(_allocator, &raw_polygon);

        _out[0].*.src.vertices.array = raw_polygon.vertices;
        _out[0].*.src.indices.array = raw_polygon.indices;
        _out[0].*.src.build(.read_gpu, .readwrite_cpu);

        _out[1].*.src.vertices.array = raw_polygon_outline.vertices;
        _out[1].*.src.indices.array = raw_polygon_outline.indices;
        _out[1].*.src.build(.read_gpu, .readwrite_cpu);
    }

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
        for (self.*.src) |_src| {
            const src = &_src.*.src;
            vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.shape_color_2d_pipeline_set.pipeline);

            vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.shape_color_2d_pipeline_set.pipelineLayout, 0, 1, &self.*.__descriptor_set, 0, null);

            const offsets: vk.VkDeviceSize = 0;
            vk.vkCmdBindVertexBuffers(cmd, 0, 1, &src.*.vertices.node.res, &offsets);

            vk.vkCmdBindIndexBuffer(cmd, src.*.indices.node.res, 0, vk.VK_INDEX_TYPE_UINT32);
            vk.vkCmdDrawIndexed(cmd, src.*.indices.node.__resource_len, 1, 0, 0, 0);

            vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.quad_shape_2d_pipeline_set.pipeline);

            vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, __vulkan.quad_shape_2d_pipeline_set.pipelineLayout, 0, 1, &src.*.__descriptor_set, 0, null);
            vk.vkCmdDraw(cmd, 6, 1, 0, 0);
        }
    }
};
