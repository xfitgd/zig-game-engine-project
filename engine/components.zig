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
const mem = @import("mem.zig");
const point = math.point;
const vector = math.vector;
const matrix = math.matrix;
const matrix_error = math.matrix_error;
const center_pt_pos = graphics.center_pt_pos;

pub const button = struct {
    pub const source = struct {
        src: shape.source,
        over_color: ?vector = null,
        down_color: ?vector = null,
    };
    const Self = @This();

    transform: transform = .{ .parent_type = ._button },
    src: []*source = undefined,
    __descriptor_set: vk.VkDescriptorSet = undefined,
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
