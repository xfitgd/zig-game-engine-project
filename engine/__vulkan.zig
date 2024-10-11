const std = @import("std");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;
const MemoryPoolExtra = std.heap.MemoryPoolExtra;

const __windows = @import("__windows.zig");
const window = @import("window.zig");
const __android = @import("__android.zig");
const system = @import("system.zig");
const math = @import("math.zig");
const matrix = math.matrix;
const graphics = @import("graphics.zig");
const render_command = @import("render_command.zig");
const __render_command = @import("__render_command.zig");
const __system = @import("__system.zig");
const root = @import("root");

const __vulkan_allocator = @import("__vulkan_allocator.zig");
pub threadlocal var vk_allocator: ?*__vulkan_allocator = null;

pub const __vulkan_allocator_node = struct {
    alloc: __vulkan_allocator,
    is_free: bool,
};

pub var mem_prop: vk.VkPhysicalDeviceMemoryProperties = undefined;

pub var vk_allocators: ArrayList(*__vulkan_allocator_node) = undefined;
pub var pvk_allocators: MemoryPoolExtra(__vulkan_allocator_node, .{}) = undefined;
pub var vk_allocator_mutex: std.Thread.Mutex = .{};
pub var vk_allocator_free_count: usize = 0;
pub const vk_allocator_FREE_MAX = 16;
pub var vk_allocator_use_free: bool = false;
pub var vk_allocator_is_destroyed: bool = false;

pub const vk = @import("include/vulkan.zig");

// const shape_vert = @embedFile("shaders/out/shape_vert.spv");
// const shape_frag = @embedFile("shaders/out/shape_frag.spv");
// var shape_vert_shader: vk.VkShaderModule = undefined;
// var shape_frag_shader: vk.VkShaderModule = undefined;

const shape_curve_vert = @embedFile("shaders/out/shape_curve_vert.spv");
const shape_curve_frag = @embedFile("shaders/out/shape_curve_frag.spv");
var shape_curve_vert_shader: vk.VkShaderModule = undefined;
var shape_curve_frag_shader: vk.VkShaderModule = undefined;

const quad_shape_vert = @embedFile("shaders/out/quad_shape_vert.spv");
const quad_shape_frag = @embedFile("shaders/out/quad_shape_frag.spv");
var quad_shape_vert_shader: vk.VkShaderModule = undefined;
var quad_shape_frag_shader: vk.VkShaderModule = undefined;

const tex_vert = @embedFile("shaders/out/tex_vert.spv");
const tex_frag = @embedFile("shaders/out/tex_frag.spv");
var tex_vert_shader: vk.VkShaderModule = undefined;
var tex_frag_shader: vk.VkShaderModule = undefined;

const animate_tex_vert = @embedFile("shaders/out/animate_tex_vert.spv");
const animate_tex_frag = @embedFile("shaders/out/animate_tex_frag.spv");
var animate_tex_vert_shader: vk.VkShaderModule = undefined;
var animate_tex_frag_shader: vk.VkShaderModule = undefined;

pub var __pre_mat_uniform: __vulkan_allocator.vulkan_res_node(.buffer) = .{};

pub const pipeline_set = struct {
    pipeline: vk.VkPipeline = null,
    pipelineLayout: vk.VkPipelineLayout = null,
    descriptorSetLayout: vk.VkDescriptorSetLayout = null,
    descriptorSetLayout2: vk.VkDescriptorSetLayout = null,
};

//Predefined Pipelines
pub var shape_color_2d_pipeline_set: pipeline_set = .{};
//pub var color_2d_pipeline_set: pipeline_set = .{};
///tex_2d_pipeline_set의 descriptorSetLayout2는 animate_tex_2d_pipeline_set의 그것과 공유
pub var tex_2d_pipeline_set: pipeline_set = .{};
pub var quad_shape_2d_pipeline_set: pipeline_set = .{};
pub var animate_tex_2d_pipeline_set: pipeline_set = .{};
//

//const shape_shader_stages = create_shader_state(shape_vert_shader, shape_frag_shader);
var shape_curve_shader_stages: [2]vk.VkPipelineShaderStageCreateInfo = undefined;
var quad_shape_shader_stages: [2]vk.VkPipelineShaderStageCreateInfo = undefined;
var tex_shader_stages: [2]vk.VkPipelineShaderStageCreateInfo = undefined;
var animate_tex_shader_stages: [2]vk.VkPipelineShaderStageCreateInfo = undefined;

pub var properties: vk.VkPhysicalDeviceProperties = undefined;
const inputAssembly: vk.VkPipelineInputAssemblyStateCreateInfo = .{
    .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
    .topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    .primitiveRestartEnable = vk.VK_FALSE,
};

const dynamicStates = [_]vk.VkDynamicState{ vk.VK_DYNAMIC_STATE_VIEWPORT, vk.VK_DYNAMIC_STATE_SCISSOR };

const dynamicState: vk.VkPipelineDynamicStateCreateInfo = .{
    .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
    .dynamicStateCount = dynamicStates.len,
    .pDynamicStates = &dynamicStates,
};

const viewportState: vk.VkPipelineViewportStateCreateInfo = .{
    .flags = 0,
    .viewportCount = 1,
    .pViewports = null,
    .scissorCount = 1,
    .pScissors = null,
};

const rasterizer: vk.VkPipelineRasterizationStateCreateInfo = .{
    .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
    .depthClampEnable = vk.VK_FALSE,
    .rasterizerDiscardEnable = vk.VK_FALSE,
    .polygonMode = vk.VK_POLYGON_MODE_FILL,
    .lineWidth = 1,
    .cullMode = vk.VK_CULL_MODE_NONE,
    .frontFace = vk.VK_FRONT_FACE_CLOCKWISE,
    .depthBiasEnable = vk.VK_FALSE,
    .depthBiasConstantFactor = 0,
    .depthBiasClamp = 0,
    .depthBiasSlopeFactor = 0,
};

const multisampling: vk.VkPipelineMultisampleStateCreateInfo = .{
    .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
    .sampleShadingEnable = vk.VK_FALSE,
    .rasterizationSamples = vk.VK_SAMPLE_COUNT_1_BIT,
    .minSampleShading = 1,
    .pSampleMask = null,
    .alphaToCoverageEnable = vk.VK_FALSE,
    .alphaToOneEnable = vk.VK_FALSE,
};

const colorBlendAttachment: vk.VkPipelineColorBlendAttachmentState = .{
    .colorWriteMask = vk.VK_COLOR_COMPONENT_R_BIT | vk.VK_COLOR_COMPONENT_G_BIT | vk.VK_COLOR_COMPONENT_B_BIT | vk.VK_COLOR_COMPONENT_A_BIT,
    .blendEnable = vk.VK_FALSE,
    .srcColorBlendFactor = vk.VK_BLEND_FACTOR_ONE,
    .dstColorBlendFactor = vk.VK_BLEND_FACTOR_ZERO,
    .colorBlendOp = vk.VK_BLEND_OP_ADD,
    .srcAlphaBlendFactor = vk.VK_BLEND_FACTOR_ONE,
    .dstAlphaBlendFactor = vk.VK_BLEND_FACTOR_ZERO,
    .alphaBlendOp = vk.VK_BLEND_OP_ADD,
};

const colorAlphaBlendAttachment: vk.VkPipelineColorBlendAttachmentState = .{
    .colorWriteMask = vk.VK_COLOR_COMPONENT_R_BIT | vk.VK_COLOR_COMPONENT_G_BIT | vk.VK_COLOR_COMPONENT_B_BIT | vk.VK_COLOR_COMPONENT_A_BIT,
    .blendEnable = vk.VK_TRUE,
    .srcColorBlendFactor = vk.VK_BLEND_FACTOR_SRC_ALPHA,
    .dstColorBlendFactor = vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
    .colorBlendOp = vk.VK_BLEND_OP_ADD,
    .srcAlphaBlendFactor = vk.VK_BLEND_FACTOR_ONE,
    .dstAlphaBlendFactor = vk.VK_BLEND_FACTOR_ZERO,
    .alphaBlendOp = vk.VK_BLEND_OP_ADD,
};

const noBlendAttachment: vk.VkPipelineColorBlendAttachmentState = .{
    .colorWriteMask = 0,
    .blendEnable = vk.VK_FALSE,
    .srcColorBlendFactor = vk.VK_BLEND_FACTOR_SRC_ALPHA,
    .dstColorBlendFactor = vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
    .colorBlendOp = vk.VK_BLEND_OP_ADD,
    .srcAlphaBlendFactor = vk.VK_BLEND_FACTOR_ONE,
    .dstAlphaBlendFactor = vk.VK_BLEND_FACTOR_ZERO,
    .alphaBlendOp = vk.VK_BLEND_OP_ADD,
};

const colorBlending: vk.VkPipelineColorBlendStateCreateInfo = .{
    .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
    .logicOpEnable = vk.VK_FALSE,
    .logicOp = vk.VK_LOGIC_OP_COPY,
    .attachmentCount = 1,
    .pAttachments = @ptrCast(&colorBlendAttachment),
    .blendConstants = .{ 0, 0, 0, 0 },
};

const colorAlphaBlending: vk.VkPipelineColorBlendStateCreateInfo = .{
    .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
    .logicOpEnable = vk.VK_FALSE,
    .logicOp = vk.VK_LOGIC_OP_COPY,
    .attachmentCount = 1,
    .pAttachments = @ptrCast(&colorAlphaBlendAttachment),
    .blendConstants = .{ 0, 0, 0, 0 },
};

const noBlending: vk.VkPipelineColorBlendStateCreateInfo = .{
    .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
    .logicOpEnable = vk.VK_FALSE,
    .logicOp = vk.VK_LOGIC_OP_COPY,
    .attachmentCount = 1,
    .pAttachments = &noBlendAttachment,
    .blendConstants = .{ 0, 0, 0, 0 },
};

var colorAttachment: vk.VkAttachmentDescription = .{
    .format = 0,
    .samples = vk.VK_SAMPLE_COUNT_1_BIT,
    .loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
    .storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
    .stencilLoadOp = vk.VK_ATTACHMENT_STORE_OP_DONT_CARE,
    .stencilStoreOp = vk.VK_ATTACHMENT_STORE_OP_DONT_CARE,
    .initialLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
    .finalLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
};

const depthAttachment: vk.VkAttachmentDescription = .{
    .format = vk.VK_FORMAT_D24_UNORM_S8_UINT,
    .samples = vk.VK_SAMPLE_COUNT_1_BIT,
    .loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
    .storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
    .stencilLoadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
    .stencilStoreOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
    .initialLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
    .finalLayout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
};

const colorAttachmentRef: vk.VkAttachmentReference = .{ .attachment = 0, .layout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL };
const depthAttachmentRef: vk.VkAttachmentReference = .{ .attachment = 1, .layout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL };

const subpass: vk.VkSubpassDescription = .{
    .pipelineBindPoint = vk.VK_PIPELINE_BIND_POINT_GRAPHICS,
    .colorAttachmentCount = 1,
    .pColorAttachments = @ptrCast(&colorAttachmentRef),
    .pDepthStencilAttachment = @ptrCast(&depthAttachmentRef),
};

// const dependency: vk.VkSubpassDependency = .{
//     .srcSubpass = vk.VK_SUBPASS_EXTERNAL,
//     .dstSubpass = 0,
//     .srcStageMask = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
//     .srcAccessMask = 0,
//     .dstStageMask = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
//     .dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
// };

fn chooseSwapExtent(capabilities: vk.VkSurfaceCapabilitiesKHR) vk.VkExtent2D {
    if (capabilities.currentExtent.width != std.math.maxInt(u32)) {
        return capabilities.currentExtent;
    } else {
        var swapchainExtent = if (system.platform == .android)
            vk.VkExtent2D{ .width = @max(0, __android.android.ANativeWindow_getWidth(__android.app.window)), .height = @max(0, __android.android.ANativeWindow_getHeight(__android.app.window)) }
        else
            vk.VkExtent2D{ .width = @max(0, window.window_width()), .height = @max(0, window.window_height()) };
        swapchainExtent.width = std.math.clamp(swapchainExtent.width, capabilities.minImageExtent.width, capabilities.maxImageExtent.width);
        swapchainExtent.height = std.math.clamp(swapchainExtent.height, capabilities.minImageExtent.height, capabilities.maxImageExtent.height);
        return swapchainExtent;
    }
}

fn chooseSwapSurfaceFormat(availableFormats: []vk.VkSurfaceFormatKHR) vk.VkSurfaceFormatKHR {
    for (availableFormats) |value| {
        switch (value.format) {
            vk.VK_FORMAT_R8G8B8A8_UNORM, vk.VK_FORMAT_R8G8B8A8_SRGB, vk.VK_FORMAT_R8G8B8A8_UINT => return value,
            else => {},
        }
    }
    system.handle_error2("unsupported device format {any}", .{availableFormats});
}

fn chooseSwapPresentMode(availablePresentModes: []vk.VkPresentModeKHR, _vSync: bool) vk.VkPresentModeKHR {
    if (_vSync) return vk.VK_PRESENT_MODE_FIFO_KHR;
    for (availablePresentModes) |value| {
        if (value == vk.VK_PRESENT_MODE_MAILBOX_KHR) {
            return value;
        }
    }
    return vk.VK_PRESENT_MODE_FIFO_KHR;
}

inline fn create_shader_state(vert_module: vk.VkShaderModule, frag_module: vk.VkShaderModule) [2]vk.VkPipelineShaderStageCreateInfo {
    const stage_infov1: vk.VkPipelineShaderStageCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = vk.VK_SHADER_STAGE_VERTEX_BIT,
        .module = vert_module,
        .pName = "main",
    };
    const stage_infof1: vk.VkPipelineShaderStageCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
        .module = frag_module,
        .pName = "main",
    };

    return [2]vk.VkPipelineShaderStageCreateInfo{ stage_infov1, stage_infof1 };
}

var vkInstance: vk.VkInstance = undefined;
pub var vkDevice: vk.VkDevice = null;
var vkSurface: vk.VkSurfaceKHR = null;
var vkRenderPass: vk.VkRenderPass = undefined;
var vkSwapchain: vk.VkSwapchainKHR = null;

pub var vkCommandPool: vk.VkCommandPool = undefined;

var vkImageAvailableSemaphore: [render_command.MAX_FRAME]vk.VkSemaphore = .{null} ** render_command.MAX_FRAME;
var vkRenderFinishedSemaphore: [render_command.MAX_FRAME]vk.VkSemaphore = .{null} ** render_command.MAX_FRAME;

pub var vkInFlightFence: [render_command.MAX_FRAME]vk.VkFence = .{null} ** render_command.MAX_FRAME;

var vkDebugMessenger: vk.VkDebugUtilsMessengerEXT = null;

pub var vkGraphicsQueue: vk.VkQueue = undefined;
var vkPresentQueue: vk.VkQueue = undefined;

pub var vkExtent: vk.VkExtent2D = undefined;
var vkExtent_rotation: vk.VkExtent2D = undefined;
pub var vk_swapchain_frame_buffers: []vk.VkFramebuffer = undefined;
var vk_swapchain_image_views: []vk.VkImageView = undefined;

pub var vk_physical_device: vk.VkPhysicalDevice = undefined;

var graphicsFamilyIndex: u32 = std.math.maxInt(u32);
var presentFamilyIndex: u32 = std.math.maxInt(u32);
var queueFamiliesCount: u32 = 0;

pub var surfaceCap: vk.VkSurfaceCapabilitiesKHR = undefined;

var formats: []vk.VkSurfaceFormatKHR = undefined;
var format: vk.VkSurfaceFormatKHR = undefined;

pub var linear_sampler: vk.VkSampler = undefined;
pub var nearest_sampler: vk.VkSampler = undefined;
pub var quad_image_vertices: graphics.vertices(graphics.tex_vertex_2d) = undefined;
pub var quad_image_vertices_array: [6]graphics.tex_vertex_2d = .{
    graphics.tex_vertex_2d{
        .pos = .{ -0.5, 0.5 },
        .uv = .{ 0, 0 },
    },
    graphics.tex_vertex_2d{
        .pos = .{ 0.5, 0.5 },
        .uv = .{ 1, 0 },
    },
    graphics.tex_vertex_2d{
        .pos = .{ -0.5, -0.5 },
        .uv = .{ 0, 1 },
    },
    graphics.tex_vertex_2d{
        .pos = .{ 0.5, 0.5 },
        .uv = .{ 1, 0 },
    },
    graphics.tex_vertex_2d{
        .pos = .{ 0.5, -0.5 },
        .uv = .{ 1, 1 },
    },
    graphics.tex_vertex_2d{
        .pos = .{ -0.5, -0.5 },
        .uv = .{ 0, 1 },
    },
};
pub var no_color_tran: graphics.color_transform = undefined;

pub var depth_stencil_image = __vulkan_allocator.vulkan_res_node(.image){};

fn createShaderModule(code: []const u8) vk.VkShaderModule {
    const createInfo: vk.VkShaderModuleCreateInfo = .{ .codeSize = code.len, .pCode = code.ptr };

    var shaderModule: vk.VkShaderModule = undefined;
    const result = vk.vkCreateShaderModule(vkDevice, &createInfo, null, &shaderModule);

    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.createShaderModule.vkCreateShaderModule : {d}", .{result});

    return shaderModule;
}

fn create_sync_object() void {
    var i: usize = 0;
    while (i < render_command.MAX_FRAME) : (i += 1) {
        const semaphoreInfo: vk.VkSemaphoreCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO };
        const fenceInfo: vk.VkFenceCreateInfo = .{ .flags = vk.VK_FENCE_CREATE_SIGNALED_BIT, .sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO };

        var result = vk.vkCreateSemaphore(vkDevice, &semaphoreInfo, null, &vkImageAvailableSemaphore[i]);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateSemaphore vkImageAvailableSemaphore : {d}", .{result});
        result = vk.vkCreateSemaphore(vkDevice, &semaphoreInfo, null, &vkRenderFinishedSemaphore[i]);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateSemaphore vkRenderFinishedSemaphore : {d}", .{result});

        result = vk.vkCreateFence(vkDevice, &fenceInfo, null, &vkInFlightFence[i]);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateFence vkInFlightFence : {d}", .{result});
    }
}

fn cleanup_sync_object() void {
    var i: usize = 0;
    while (i < render_command.MAX_FRAME) : (i += 1) {
        vk.vkDestroySemaphore(vkDevice, vkImageAvailableSemaphore[i], null);
        vk.vkDestroySemaphore(vkDevice, vkRenderFinishedSemaphore[i], null);
        vk.vkDestroyFence(vkDevice, vkInFlightFence[i], null);
    }
}

fn recordCommandBuffer(commandBuffer: *render_command) void {
    if (commandBuffer.*.scene == null or commandBuffer.*.scene.?.len == 0) {
        return;
    }
    for (commandBuffer.*.__command_buffers) |cmds| {
        for (cmds, vk_swapchain_frame_buffers) |cmd, frame| {
            const clearColor: vk.VkClearValue = .{ .color = .{ .float32 = .{ 0, 0, 0, 0 } } };
            const clearDepthStencil: vk.VkClearValue = .{ .depthStencil = .{ .stencil = 0, .depth = 0 } };

            const renderPassInfo: vk.VkRenderPassBeginInfo = .{
                .sType = vk.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
                .renderPass = vkRenderPass,
                .framebuffer = frame,
                .renderArea = .{ .offset = .{ .x = 0, .y = 0 }, .extent = vkExtent_rotation },
                .clearValueCount = 2,
                .pClearValues = &[_]vk.VkClearValue{ clearColor, clearDepthStencil },
            };

            const beginInfo: vk.VkCommandBufferBeginInfo = .{
                .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
                .flags = 0,
                .pInheritanceInfo = null,
            };
            var result = vk.vkResetCommandBuffer(cmd, 0);
            system.handle_error(result == vk.VK_SUCCESS, "__vulkan.recordCommandBuffer.vkResetCommandBuffer : {d}", .{result});

            result = vk.vkBeginCommandBuffer(cmd, &beginInfo);
            system.handle_error(result == vk.VK_SUCCESS, "__vulkan.recordCommandBuffer.vkBeginCommandBuffer : {d}", .{result});

            vk.vkCmdBeginRenderPass(cmd, &renderPassInfo, vk.VK_SUBPASS_CONTENTS_INLINE);

            const viewport: vk.VkViewport = .{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(vkExtent_rotation.width),
                .height = @floatFromInt(vkExtent_rotation.height),
                .maxDepth = 1,
                .minDepth = 0,
            };
            const scissor: vk.VkRect2D = .{ .offset = vk.VkOffset2D{ .x = 0, .y = 0 }, .extent = vkExtent_rotation };

            vk.vkCmdSetViewport(cmd, 0, 1, @ptrCast(&viewport));
            vk.vkCmdSetScissor(cmd, 0, 1, @ptrCast(&scissor));

            for (commandBuffer.scene.?) |value| {
                value.*.__draw(cmd);
            }

            vk.vkCmdEndRenderPass(cmd);

            result = vk.vkEndCommandBuffer(cmd);
            system.handle_error(result == vk.VK_SUCCESS, "__vulkan.recordCommandBuffer.vkEndCommandBuffer : {d}", .{result});
        }
    }
}

pub fn vkCreateDebugUtilsMessengerEXT(instance: vk.VkInstance, pCreateInfo: ?*const vk.VkDebugUtilsMessengerCreateInfoEXT, pAllocator: ?*const vk.VkAllocationCallbacks, pDebugMessenger: ?*vk.VkDebugUtilsMessengerEXT) vk.VkResult {
    const func = @as(vk.PFN_vkCreateDebugUtilsMessengerEXT, @ptrCast(vk.vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT")));
    if (func != null) {
        return func.?(instance, pCreateInfo, pAllocator, pDebugMessenger);
    } else {
        return vk.VK_ERROR_EXTENSION_NOT_PRESENT;
    }
}
pub fn vkDestroyDebugUtilsMessengerEXT(instance: vk.VkInstance, debugMessenger: vk.VkDebugUtilsMessengerEXT, pAllocator: ?*const vk.VkAllocationCallbacks) void {
    const func = @as(vk.PFN_vkDestroyDebugUtilsMessengerEXT, @ptrCast(vk.vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT")));
    if (func != null) {
        func.?(instance, debugMessenger, pAllocator);
    }
}

fn debug_callback(messageSeverity: vk.VkDebugUtilsMessageSeverityFlagBitsEXT, messageType: vk.VkDebugUtilsMessageTypeFlagsEXT, pCallbackData: ?*const vk.VkDebugUtilsMessengerCallbackDataEXT, pUserData: ?*anyopaque) callconv(.C) vk.VkBool32 {
    if (pCallbackData.?.*.messageIdNumber == 1284057537) return vk.VK_FALSE; //https://vulkan.lunarg.com/doc/view/1.3.283.0/windows/1.3-extensions/vkspec.html#VUID-VkSwapchainCreateInfoKHR-pNext-07781
    _ = messageSeverity;
    _ = messageType;
    _ = pUserData;

    if (system.platform == .android) {
        _ = __android.LOGE(pCallbackData.?.*.pMessage, .{});
    } else {
        const len = std.mem.len(pCallbackData.?.*.pMessage);
        const msg = __system.allocator.alloc(u8, len) catch |e| system.handle_error3("debug_callback.alloc()", e);
        @memcpy(msg, pCallbackData.?.*.pMessage[0..len]);
        defer __system.allocator.free(msg);

        system.print("{s}\n\n", .{msg});
    }

    return vk.VK_FALSE;
}

fn cleanup_pipelines() void {
    vk.vkDestroyPipeline(vkDevice, quad_shape_2d_pipeline_set.pipeline, null);
    vk.vkDestroyPipeline(vkDevice, shape_color_2d_pipeline_set.pipeline, null);
    vk.vkDestroyPipeline(vkDevice, tex_2d_pipeline_set.pipeline, null);
    vk.vkDestroyPipeline(vkDevice, animate_tex_2d_pipeline_set.pipeline, null);
}

fn create_pipelines() void {
    {
        const vertexInputInfo: vk.VkPipelineVertexInputStateCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
            .vertexBindingDescriptionCount = 0,
            .vertexAttributeDescriptionCount = 0,
            .pVertexBindingDescriptions = null,
            .pVertexAttributeDescriptions = null,
        };

        const stencilOp = vk.VkStencilOpState{
            .compareMask = 0xff,
            .writeMask = 0xff,
            .compareOp = vk.VK_COMPARE_OP_EQUAL,
            .depthFailOp = vk.VK_STENCIL_OP_ZERO,
            .passOp = vk.VK_STENCIL_OP_ZERO,
            .failOp = vk.VK_STENCIL_OP_ZERO,
            .reference = 0xff,
        };

        const depthStencilState = vk.VkPipelineDepthStencilStateCreateInfo{
            .stencilTestEnable = vk.VK_TRUE,
            .depthTestEnable = vk.VK_FALSE,
            .depthWriteEnable = vk.VK_FALSE,
            .depthBoundsTestEnable = vk.VK_FALSE,
            .depthCompareOp = vk.VK_COMPARE_OP_NEVER,
            .flags = 0,
            .maxDepthBounds = 0,
            .minDepthBounds = 0,
            .back = stencilOp,
            .front = stencilOp,
        };

        const pipelineInfo: vk.VkGraphicsPipelineCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .stageCount = 2,
            .pStages = &quad_shape_shader_stages,
            .pVertexInputState = &vertexInputInfo,
            .pInputAssemblyState = &inputAssembly,
            .pViewportState = &viewportState,
            .pRasterizationState = &rasterizer,
            .pMultisampleState = &multisampling,
            .pDepthStencilState = &depthStencilState,
            .pColorBlendState = &colorAlphaBlending,
            .pDynamicState = &dynamicState,
            .layout = quad_shape_2d_pipeline_set.pipelineLayout,
            .renderPass = vkRenderPass,
            .subpass = 0,
            .basePipelineHandle = null,
            .basePipelineIndex = -1,
        };

        const result = vk.vkCreateGraphicsPipelines(vkDevice, std.mem.zeroes(vk.VkPipelineCache), 1, &pipelineInfo, null, &quad_shape_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateGraphicsPipelines quad_shape_2d_pipeline_set.pipeline : {d}", .{result});
    }
    {
        const bindingDescription: vk.VkVertexInputBindingDescription = .{
            .binding = 0,
            .stride = @sizeOf(f32) * (2 + 3),
            .inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX,
        };
        const attributeDescriptions: [2]vk.VkVertexInputAttributeDescription = .{
            .{ .binding = 0, .location = 0, .format = vk.VK_FORMAT_R32G32_SFLOAT, .offset = 0 },
            .{ .binding = 0, .location = 1, .format = vk.VK_FORMAT_R32G32B32_SFLOAT, .offset = @sizeOf(f32) * (2) },
        };

        const vertexInputInfo: vk.VkPipelineVertexInputStateCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
            .vertexBindingDescriptionCount = 1,
            .vertexAttributeDescriptionCount = attributeDescriptions.len,
            .pVertexBindingDescriptions = &bindingDescription,
            .pVertexAttributeDescriptions = &attributeDescriptions,
        };

        const stencilOp = vk.VkStencilOpState{
            .compareMask = 0xff,
            .writeMask = 0xff,
            .compareOp = vk.VK_COMPARE_OP_ALWAYS,
            .depthFailOp = vk.VK_STENCIL_OP_ZERO,
            .passOp = vk.VK_STENCIL_OP_INVERT,
            .failOp = vk.VK_STENCIL_OP_ZERO,
            .reference = 0xff,
        };
        const depthStencilState = vk.VkPipelineDepthStencilStateCreateInfo{
            .stencilTestEnable = vk.VK_TRUE,
            .depthTestEnable = vk.VK_FALSE,
            .depthWriteEnable = vk.VK_FALSE,
            .depthBoundsTestEnable = vk.VK_FALSE,
            .depthCompareOp = vk.VK_COMPARE_OP_NEVER,
            .flags = 0,
            .maxDepthBounds = 0,
            .minDepthBounds = 0,
            .back = stencilOp,
            .front = stencilOp,
        };

        const pipelineInfo: vk.VkGraphicsPipelineCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .stageCount = 2,
            .pStages = &shape_curve_shader_stages,
            .pVertexInputState = &vertexInputInfo,
            .pInputAssemblyState = &inputAssembly,
            .pViewportState = &viewportState,
            .pRasterizationState = &rasterizer,
            .pMultisampleState = &multisampling,
            .pDepthStencilState = &depthStencilState,
            .pColorBlendState = &noBlending,
            .pDynamicState = &dynamicState,
            .layout = shape_color_2d_pipeline_set.pipelineLayout,
            .renderPass = vkRenderPass,
            .subpass = 0,
            .basePipelineHandle = null,
            .basePipelineIndex = -1,
        };

        const result = vk.vkCreateGraphicsPipelines(vkDevice, std.mem.zeroes(vk.VkPipelineCache), 1, &pipelineInfo, null, &shape_color_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateGraphicsPipelines shape_color_2d_pipeline_set.pipeline : {d}", .{result});
    }
    {
        const bindingDescription: vk.VkVertexInputBindingDescription = .{
            .binding = 0,
            .stride = @sizeOf(f32) * (2 + 2),
            .inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX,
        };
        const attributeDescriptions: [2]vk.VkVertexInputAttributeDescription = .{
            .{ .binding = 0, .location = 0, .format = vk.VK_FORMAT_R32G32_SFLOAT, .offset = 0 },
            .{ .binding = 0, .location = 1, .format = vk.VK_FORMAT_R32G32_SFLOAT, .offset = @sizeOf(f32) * 2 },
        };

        const vertexInputInfo: vk.VkPipelineVertexInputStateCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
            .vertexBindingDescriptionCount = 1,
            .vertexAttributeDescriptionCount = 2,
            .pVertexBindingDescriptions = &bindingDescription,
            .pVertexAttributeDescriptions = &attributeDescriptions,
        };

        const stencilOp = vk.VkStencilOpState{
            .compareMask = 0xff,
            .writeMask = 0xff,
            .compareOp = vk.VK_COMPARE_OP_ALWAYS,
            .depthFailOp = vk.VK_STENCIL_OP_KEEP,
            .passOp = vk.VK_STENCIL_OP_KEEP,
            .failOp = vk.VK_STENCIL_OP_KEEP,
            .reference = 0xff,
        };
        const depthStencilState = vk.VkPipelineDepthStencilStateCreateInfo{
            .stencilTestEnable = vk.VK_FALSE,
            .depthTestEnable = vk.VK_FALSE,
            .depthWriteEnable = vk.VK_FALSE,
            .depthBoundsTestEnable = vk.VK_FALSE,
            .depthCompareOp = vk.VK_COMPARE_OP_NEVER,
            .flags = 0,
            .maxDepthBounds = 0,
            .minDepthBounds = 0,
            .back = stencilOp,
            .front = stencilOp,
        };

        const pipelineInfo: vk.VkGraphicsPipelineCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .stageCount = 2,
            .pStages = &tex_shader_stages,
            .pVertexInputState = &vertexInputInfo,
            .pInputAssemblyState = &inputAssembly,
            .pViewportState = &viewportState,
            .pRasterizationState = &rasterizer,
            .pMultisampleState = &multisampling,
            .pDepthStencilState = &depthStencilState,
            .pColorBlendState = &colorAlphaBlending,
            .pDynamicState = &dynamicState,
            .layout = tex_2d_pipeline_set.pipelineLayout,
            .renderPass = vkRenderPass,
            .subpass = 0,
            .basePipelineHandle = null,
            .basePipelineIndex = -1,
        };

        const result = vk.vkCreateGraphicsPipelines(vkDevice, null, 1, &pipelineInfo, null, &tex_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateGraphicsPipelines tex_2d_pipeline_set.pipeline : {d}", .{result});
    }
    {
        const bindingDescription: vk.VkVertexInputBindingDescription = .{
            .binding = 0,
            .stride = @sizeOf(f32) * (2 + 2),
            .inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX,
        };
        const attributeDescriptions: [2]vk.VkVertexInputAttributeDescription = .{
            .{ .binding = 0, .location = 0, .format = vk.VK_FORMAT_R32G32_SFLOAT, .offset = 0 },
            .{ .binding = 0, .location = 1, .format = vk.VK_FORMAT_R32G32_SFLOAT, .offset = @sizeOf(f32) * 2 },
        };

        const vertexInputInfo: vk.VkPipelineVertexInputStateCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
            .vertexBindingDescriptionCount = 1,
            .vertexAttributeDescriptionCount = 2,
            .pVertexBindingDescriptions = &bindingDescription,
            .pVertexAttributeDescriptions = &attributeDescriptions,
        };

        const stencilOp = vk.VkStencilOpState{
            .compareMask = 0xff,
            .writeMask = 0xff,
            .compareOp = vk.VK_COMPARE_OP_ALWAYS,
            .depthFailOp = vk.VK_STENCIL_OP_KEEP,
            .passOp = vk.VK_STENCIL_OP_KEEP,
            .failOp = vk.VK_STENCIL_OP_KEEP,
            .reference = 0xff,
        };
        const depthStencilState = vk.VkPipelineDepthStencilStateCreateInfo{
            .stencilTestEnable = vk.VK_FALSE,
            .depthTestEnable = vk.VK_FALSE,
            .depthWriteEnable = vk.VK_FALSE,
            .depthBoundsTestEnable = vk.VK_FALSE,
            .depthCompareOp = vk.VK_COMPARE_OP_NEVER,
            .flags = 0,
            .maxDepthBounds = 0,
            .minDepthBounds = 0,
            .back = stencilOp,
            .front = stencilOp,
        };

        const pipelineInfo: vk.VkGraphicsPipelineCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .stageCount = 2,
            .pStages = &animate_tex_shader_stages,
            .pVertexInputState = &vertexInputInfo,
            .pInputAssemblyState = &inputAssembly,
            .pViewportState = &viewportState,
            .pRasterizationState = &rasterizer,
            .pMultisampleState = &multisampling,
            .pDepthStencilState = &depthStencilState,
            .pColorBlendState = &colorAlphaBlending,
            .pDynamicState = &dynamicState,
            .layout = animate_tex_2d_pipeline_set.pipelineLayout,
            .renderPass = vkRenderPass,
            .subpass = 0,
            .basePipelineHandle = null,
            .basePipelineIndex = -1,
        };

        const result = vk.vkCreateGraphicsPipelines(vkDevice, null, 1, &pipelineInfo, null, &animate_tex_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateGraphicsPipelines animate_tex_2d_pipeline_set.pipeline : {d}", .{result});
    }
}

pub fn vulkan_start() void {
    const appInfo: vk.VkApplicationInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = "Hello Triangle",
        .applicationVersion = vk.VK_MAKE_API_VERSION(1, 0, 0, 0),
        .pEngineName = "No Engine",
        .engineVersion = vk.VK_MAKE_API_VERSION(1, 0, 0, 0),
        .apiVersion = vk.VK_API_VERSION_1_0,
    };
    // var property_count: u32 = undefined;
    // _ = try vkb.enumerateInstanceExtensionProperties(null, &property_count, null);

    // const extensions = try allocator.alloc(vk.ExtensionProperties, property_count);
    // defer allocator.free(extensions);
    // _ = try vkb.enumerateInstanceExtensionProperties(null, &property_count, @ptrCast(extensions));
    var extension_names = ArrayList([*:0]const u8).init(__system.allocator);
    defer extension_names.deinit();
    // var j: u32 = 0;
    // while (j < property_count) : (j += 1) {
    //     try extension_names.append(@ptrCast(&extensions[j].extension_name[0]));
    // }

    extension_names.append(vk.VK_KHR_SURFACE_EXTENSION_NAME) catch |e| system.handle_error3("vulkan_start.extension_names.append(vk.VK_KHR_SURFACE_EXTENSION_NAME)", e);
    var validation_layer_support = false;
    const validation_layer_name = "VK_LAYER_KHRONOS_validation";
    var result: c_int = undefined;

    if (system.platform == .windows and builtin.mode == std.builtin.OptimizeMode.Debug) {
        var layer_count: u32 = undefined;
        result = vk.vkEnumerateInstanceLayerProperties(&layer_count, null);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkEnumerateInstanceLayerProperties null : {d}", .{result});

        const available_layers = __system.allocator.alloc(vk.VkLayerProperties, layer_count) catch
            system.handle_error_msg2("vulkan_start.allocator.alloc(vk.VkLayerProperties) OutOfMemory");
        defer __system.allocator.free(available_layers);

        result = vk.vkEnumerateInstanceLayerProperties(&layer_count, available_layers.ptr);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkEnumerateInstanceLayerProperties available_layers.ptr : {d}", .{result});
        var layer_found = false;

        for (available_layers) |*value| {
            if (std.mem.eql(u8, value.*.layerName[0..std.mem.len(@as([*c]u8, @ptrCast(&value.*.layerName)))], validation_layer_name)) {
                layer_found = true;
                break;
            }
        }
        if (!layer_found) {
            system.print_error("WARN VK_LAYER_KHRONOS_validation not found disable vulkan Debug feature.\n", .{});
        } else {
            validation_layer_support = true;
            extension_names.append(vk.VK_EXT_DEBUG_UTILS_EXTENSION_NAME) catch |e| system.handle_error3("vulkan_start.extension_names.append(vk.VK_EXT_DEBUG_UTILS_EXTENSION_NAME)", e);
        }
    }
    if (system.platform == .windows) {
        extension_names.append(vk.VK_KHR_WIN32_SURFACE_EXTENSION_NAME) catch |e| system.handle_error3("vulkan_start.extension_names.append(vk.VK_KHR_WIN32_SURFACE_EXTENSION_NAME)", e);
    } else if (system.platform == .android) {
        extension_names.append(vk.VK_KHR_ANDROID_SURFACE_EXTENSION_NAME) catch |e| system.handle_error3("vulkan_start.extension_names.append(vk.VK_KHR_ANDROID_SURFACE_EXTENSION_NAME)", e);
    } else {
        @compileError("not support platform");
    }

    var createInfo: vk.VkInstanceCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &appInfo,
        .enabledLayerCount = if (validation_layer_support) 1 else 0,
        .ppEnabledLayerNames = if (validation_layer_support) @ptrCast(&validation_layer_name) else null,
        .enabledExtensionCount = @intCast(extension_names.items.len),
        .ppEnabledExtensionNames = extension_names.items.ptr,
    };

    result = vk.vkCreateInstance(&createInfo, null, &vkInstance);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateInstance : {d}", .{result});

    if (validation_layer_support) {
        const create_info = vk.VkDebugUtilsMessengerCreateInfoEXT{
            .sType = vk.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
            .messageSeverity = vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT | vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
            .messageType = vk.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | vk.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
            .pfnUserCallback = debug_callback,
            .pUserData = null,
        };
        result = vkCreateDebugUtilsMessengerEXT(vkInstance, &create_info, null, &vkDebugMessenger);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDebugUtilsMessengerEXT : {d}", .{result});
    }

    if (system.platform == .windows) {
        __windows.vulkan_windows_start(vkInstance, &vkSurface);
    } else if (system.platform == .android) {
        __android.vulkan_android_start(vkInstance, &vkSurface);
    } else {
        @compileError("not support platform");
    }

    var deviceCount: u32 = 0;
    result = vk.vkEnumeratePhysicalDevices(vkInstance, &deviceCount, null);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkEnumeratePhysicalDevices : {d}", .{result});

    //system.print_debug("deviceCount : {d}", .{deviceCount});
    system.handle_error(deviceCount != 0, "__vulkan.vulkan_start.deviceCount 0", .{});
    const vk_physical_devices = __system.allocator.alloc(vk.VkPhysicalDevice, deviceCount) catch
        system.handle_error_msg2("vulkan_start.allocator.alloc(vk.VkPhysicalDevice) OutOfMemory");
    defer __system.allocator.free(vk_physical_devices);

    result = vk.vkEnumeratePhysicalDevices(vkInstance, &deviceCount, vk_physical_devices.ptr);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkEnumeratePhysicalDevices vk_physical_devices.ptr : {d}", .{result});

    out: for (vk_physical_devices) |pd| {
        vk.vkGetPhysicalDeviceQueueFamilyProperties(pd, &queueFamiliesCount, null);
        system.handle_error(queueFamiliesCount != 0, "__vulkan.vulkan_start.queueFamiliesCount 0", .{});

        const queueFamilies = __system.allocator.alloc(vk.VkQueueFamilyProperties, queueFamiliesCount) catch
            system.handle_error_msg2("vulkan_start.allocator.alloc(vk.VkQueueFamilyProperties) OutOfMemory");
        defer __system.allocator.free(queueFamilies);

        vk.vkGetPhysicalDeviceQueueFamilyProperties(pd, &queueFamiliesCount, queueFamilies.ptr);

        var i: u32 = 0;
        while (i < queueFamiliesCount) : (i += 1) {
            if ((queueFamilies[i].queueFlags & vk.VK_QUEUE_GRAPHICS_BIT) != 0) {
                graphicsFamilyIndex = i;
            }
            var presentSupport: vk.VkBool32 = 0;
            result = vk.vkGetPhysicalDeviceSurfaceSupportKHR(pd, i, vkSurface, &presentSupport);
            system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkGetPhysicalDeviceSurfaceSupportKHR : {d}", .{result});

            if (presentSupport != 0) {
                presentFamilyIndex = i;
            }
            if (graphicsFamilyIndex != std.math.maxInt(u32) and presentFamilyIndex != std.math.maxInt(u32)) {
                vk_physical_device = pd;
                break :out;
            }
        }
    }
    const priority = [_]f32{1};
    const qci = [_]vk.VkDeviceQueueCreateInfo{
        .{
            .sType = vk.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .queueFamilyIndex = graphicsFamilyIndex,
            .queueCount = 1,
            .pQueuePriorities = &priority,
        },
        .{
            .sType = vk.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .queueFamilyIndex = presentFamilyIndex,
            .queueCount = 1,
            .pQueuePriorities = &priority,
        },
    };

    const queue_count: u32 = if (graphicsFamilyIndex == presentFamilyIndex) 1 else 2;

    var deviceFeatures: vk.VkPhysicalDeviceFeatures = .{
        .samplerAnisotropy = vk.VK_TRUE,
    };

    const device_extension_names = [_][:0]const u8{vk.VK_KHR_SWAPCHAIN_EXTENSION_NAME};
    var deviceCreateInfo: vk.VkDeviceCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pQueueCreateInfos = &qci,
        .queueCreateInfoCount = queue_count,
        .pEnabledFeatures = &deviceFeatures,
        .ppEnabledExtensionNames = @ptrCast(&device_extension_names),
        .enabledExtensionCount = 1,
    };
    result = vk.vkCreateDevice(vk_physical_device, &deviceCreateInfo, null, &vkDevice);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDevice : {d}", .{result});

    if (graphicsFamilyIndex == presentFamilyIndex) {
        vk.vkGetDeviceQueue(vkDevice, graphicsFamilyIndex, 0, &vkGraphicsQueue);
        vkPresentQueue = vkGraphicsQueue;
    } else {
        vk.vkGetDeviceQueue(vkDevice, graphicsFamilyIndex, 0, &vkGraphicsQueue);
        vk.vkGetDeviceQueue(vkDevice, presentFamilyIndex, 0, &vkPresentQueue);
    }

    vk.vkGetPhysicalDeviceMemoryProperties(vk_physical_device, &mem_prop);
    vk.vkGetPhysicalDeviceProperties(vk_physical_device, &properties);

    vk_allocators = ArrayList(*__vulkan_allocator_node).init(__system.allocator);
    pvk_allocators = MemoryPoolExtra(__vulkan_allocator_node, .{}).init(__system.allocator);
    const res = pvk_allocators.create() catch |e| system.handle_error3("vulkan_start.pvk_allocators.create()", e);
    res.*.is_free = false;
    res.*.alloc = __vulkan_allocator.init();
    vk_allocators.append(res) catch |e| system.handle_error3("vulkan_start.vk_allocators.append()", e);
    vk_allocator = &res.*.alloc;

    create_swapchain_and_imageviews();

    const renderPassInfo: vk.VkRenderPassCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = 2,
        .pAttachments = &[_]vk.VkAttachmentDescription{ colorAttachment, depthAttachment },
        .subpassCount = 1,
        .pSubpasses = &[_]vk.VkSubpassDescription{subpass},
        .pDependencies = null,
        .dependencyCount = 0,
    };

    result = vk.vkCreateRenderPass(vkDevice, &renderPassInfo, null, &vkRenderPass);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateRenderPass vkDepthRenderPass : {d}", .{result});

    //create_shader_stages
    //shape_vert_shader = createShaderModule(shape_vert);
    //shape_frag_shader = createShaderModule(shape_frag);
    shape_curve_vert_shader = createShaderModule(shape_curve_vert);
    shape_curve_frag_shader = createShaderModule(shape_curve_frag);
    quad_shape_vert_shader = createShaderModule(quad_shape_vert);
    quad_shape_frag_shader = createShaderModule(quad_shape_frag);
    tex_vert_shader = createShaderModule(tex_vert);
    tex_frag_shader = createShaderModule(tex_frag);
    animate_tex_vert_shader = createShaderModule(animate_tex_vert);
    animate_tex_frag_shader = createShaderModule(animate_tex_frag);

    shape_curve_shader_stages = create_shader_state(shape_curve_vert_shader, shape_curve_frag_shader);
    quad_shape_shader_stages = create_shader_state(quad_shape_vert_shader, quad_shape_frag_shader);
    tex_shader_stages = create_shader_state(tex_vert_shader, tex_frag_shader);
    animate_tex_shader_stages = create_shader_state(animate_tex_vert_shader, animate_tex_frag_shader);

    //quad_shape_2d_pipeline
    {
        const uboLayoutBinding = [1]vk.VkDescriptorSetLayoutBinding{
            vk.VkDescriptorSetLayoutBinding{
                .binding = 0,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
        };
        const set_layout_info: vk.VkDescriptorSetLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
            .bindingCount = uboLayoutBinding.len,
            .pBindings = &uboLayoutBinding,
        };
        result = vk.vkCreateDescriptorSetLayout(vkDevice, &set_layout_info, null, &quad_shape_2d_pipeline_set.descriptorSetLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDescriptorSetLayout quad_shape_shader_stages.descriptorSetLayout : {d}", .{result});

        const pipelineLayoutInfo: vk.VkPipelineLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 1,
            .pSetLayouts = &quad_shape_2d_pipeline_set.descriptorSetLayout,
            .pushConstantRangeCount = 0,
            .pPushConstantRanges = null,
        };

        result = vk.vkCreatePipelineLayout(vkDevice, &pipelineLayoutInfo, null, &quad_shape_2d_pipeline_set.pipelineLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreatePipelineLayout quad_shape_shader_stages.pipelineLayout : {d}", .{result});
    }
    //create_shape_color_2d_pipeline
    {
        const uboLayoutBinding = [_]vk.VkDescriptorSetLayoutBinding{
            vk.VkDescriptorSetLayoutBinding{
                .binding = 0,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 1,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 2,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 3,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
            },
        };
        const set_layout_info: vk.VkDescriptorSetLayoutCreateInfo = .{
            .bindingCount = uboLayoutBinding.len,
            .pBindings = &uboLayoutBinding,
        };
        result = vk.vkCreateDescriptorSetLayout(vkDevice, &set_layout_info, null, &shape_color_2d_pipeline_set.descriptorSetLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDescriptorSetLayout color_2d_pipeline_set.descriptorSetLayout : {d}", .{result});

        const pipelineLayoutInfo: vk.VkPipelineLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 1,
            .pSetLayouts = &shape_color_2d_pipeline_set.descriptorSetLayout,
            .pushConstantRangeCount = 0,
            .pPushConstantRanges = null,
        };

        result = vk.vkCreatePipelineLayout(vkDevice, &pipelineLayoutInfo, null, &shape_color_2d_pipeline_set.pipelineLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreatePipelineLayout color_2d_pipeline_set.pipelineLayout : {d}", .{result});
    }
    //create_tex_2d_pipeline
    {
        const uboLayoutBinding = [_]vk.VkDescriptorSetLayoutBinding{
            vk.VkDescriptorSetLayoutBinding{
                .binding = 0,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 1,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 2,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 3,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 4,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
        };
        const set_layout_info: vk.VkDescriptorSetLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
            .bindingCount = uboLayoutBinding.len,
            .pBindings = &uboLayoutBinding,
        };
        result = vk.vkCreateDescriptorSetLayout(vkDevice, &set_layout_info, null, &tex_2d_pipeline_set.descriptorSetLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDescriptorSetLayout tex_2d_pipeline_set.descriptorSetLayout : {d}", .{result});

        const uboLayoutBinding2 = [_]vk.VkDescriptorSetLayoutBinding{
            vk.VkDescriptorSetLayoutBinding{
                .binding = 0,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .stageFlags = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
        };
        const set_layout_info2: vk.VkDescriptorSetLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
            .bindingCount = uboLayoutBinding2.len,
            .pBindings = &uboLayoutBinding2,
        };
        result = vk.vkCreateDescriptorSetLayout(vkDevice, &set_layout_info2, null, &tex_2d_pipeline_set.descriptorSetLayout2);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDescriptorSetLayout tex_2d_pipeline_set.descriptorSetLayout2 : {d}", .{result});

        const pipelineLayoutInfo: vk.VkPipelineLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 2,
            .pSetLayouts = &[_]vk.VkDescriptorSetLayout{ tex_2d_pipeline_set.descriptorSetLayout, tex_2d_pipeline_set.descriptorSetLayout2 },
            .pushConstantRangeCount = 0,
            .pPushConstantRanges = null,
        };

        result = vk.vkCreatePipelineLayout(vkDevice, &pipelineLayoutInfo, null, &tex_2d_pipeline_set.pipelineLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreatePipelineLayout tex_2d_pipeline_set.pipelineLayout : {d}", .{result});
    }
    //create_tex_2d_pipeline
    {
        const uboLayoutBinding = [_]vk.VkDescriptorSetLayoutBinding{
            vk.VkDescriptorSetLayoutBinding{
                .binding = 0,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 1,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 2,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 3,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 4,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
            vk.VkDescriptorSetLayoutBinding{
                .binding = 5,
                .descriptorCount = 1,
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .stageFlags = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
        };
        const set_layout_info: vk.VkDescriptorSetLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
            .bindingCount = uboLayoutBinding.len,
            .pBindings = &uboLayoutBinding,
        };
        result = vk.vkCreateDescriptorSetLayout(vkDevice, &set_layout_info, null, &animate_tex_2d_pipeline_set.descriptorSetLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDescriptorSetLayout animate_tex_2d_pipeline_set.descriptorSetLayout : {d}", .{result});

        const pipelineLayoutInfo: vk.VkPipelineLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 2,
            .pSetLayouts = &[_]vk.VkDescriptorSetLayout{ animate_tex_2d_pipeline_set.descriptorSetLayout, tex_2d_pipeline_set.descriptorSetLayout2 },
            .pushConstantRangeCount = 0,
            .pPushConstantRanges = null,
        };

        result = vk.vkCreatePipelineLayout(vkDevice, &pipelineLayoutInfo, null, &animate_tex_2d_pipeline_set.pipelineLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreatePipelineLayout animate_tex_2d_pipeline_set.pipelineLayout : {d}", .{result});
    }
    create_pipelines();

    create_framebuffer();

    const poolInfo: vk.VkCommandPoolCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = graphicsFamilyIndex,
    };

    create_sync_object();

    result = vk.vkCreateCommandPool(vkDevice, &poolInfo, null, &vkCommandPool);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateCommandPool vkCommandPool : {d}", .{result});

    __render_command.start();

    //graphics create
    quad_image_vertices = graphics.vertices(graphics.tex_vertex_2d).init();
    quad_image_vertices.array = quad_image_vertices_array[0..quad_image_vertices_array.len];
    quad_image_vertices.build(.read_gpu);

    no_color_tran = graphics.color_transform.init();
    no_color_tran.build(.read_gpu);

    var sampler_info: vk.VkSamplerCreateInfo = .{
        .addressModeU = vk.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeV = vk.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeW = vk.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .mipmapMode = vk.VK_SAMPLER_MIPMAP_MODE_LINEAR,
        .magFilter = vk.VK_FILTER_LINEAR,
        .minFilter = vk.VK_FILTER_LINEAR,
        .mipLodBias = 0,
        .compareOp = vk.VK_COMPARE_OP_ALWAYS,
        .compareEnable = vk.VK_FALSE,
        .unnormalizedCoordinates = vk.VK_FALSE,
        .minLod = 0,
        .maxLod = 0,
        .anisotropyEnable = vk.VK_FALSE,
        .maxAnisotropy = properties.limits.maxSamplerAnisotropy,
        .borderColor = vk.VK_BORDER_COLOR_INT_OPAQUE_WHITE,
    };
    result = vk.vkCreateSampler(vkDevice, &sampler_info, null, &linear_sampler);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateSampler linear_sampler : {d}", .{result});

    sampler_info.mipmapMode = vk.VK_SAMPLER_MIPMAP_MODE_NEAREST;
    sampler_info.magFilter = vk.VK_FILTER_NEAREST;
    sampler_info.minFilter = vk.VK_FILTER_NEAREST;
    result = vk.vkCreateSampler(vkDevice, &sampler_info, null, &nearest_sampler);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateSampler nearest_sampler : {d}", .{result});

    //
}

pub fn vulkan_destroy() void {
    //graphics destroy
    quad_image_vertices.deinit();
    no_color_tran.deinit();
    __pre_mat_uniform.clean();

    vk.vkDestroySampler(vkDevice, linear_sampler, null);
    vk.vkDestroySampler(vkDevice, nearest_sampler, null);
    //

    cleanup_sync_object();

    vk.vkDestroyCommandPool(vkDevice, vkCommandPool, null);

    cleanup_swapchain();

    vk_allocator_mutex.lock();
    for (vk_allocators.items) |v| {
        v.*.alloc.deinit();
    }
    vk_allocators.deinit();
    pvk_allocators.deinit();

    vk_allocator_is_destroyed = true;
    vk_allocator_mutex.unlock();

    // vk.vkDestroyShaderModule(vkDevice, shape_vert_shader, null);
    // vk.vkDestroyShaderModule(vkDevice, shape_frag_shader, null);
    vk.vkDestroyShaderModule(vkDevice, quad_shape_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, quad_shape_frag_shader, null);
    vk.vkDestroyShaderModule(vkDevice, shape_curve_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, shape_curve_frag_shader, null);
    vk.vkDestroyShaderModule(vkDevice, tex_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, tex_frag_shader, null);
    vk.vkDestroyShaderModule(vkDevice, animate_tex_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, animate_tex_frag_shader, null);

    vk.vkDestroyPipelineLayout(vkDevice, quad_shape_2d_pipeline_set.pipelineLayout, null);
    vk.vkDestroyDescriptorSetLayout(vkDevice, quad_shape_2d_pipeline_set.descriptorSetLayout, null);

    vk.vkDestroyPipelineLayout(vkDevice, shape_color_2d_pipeline_set.pipelineLayout, null);
    vk.vkDestroyDescriptorSetLayout(vkDevice, shape_color_2d_pipeline_set.descriptorSetLayout, null);

    vk.vkDestroyPipelineLayout(vkDevice, tex_2d_pipeline_set.pipelineLayout, null);
    vk.vkDestroyDescriptorSetLayout(vkDevice, tex_2d_pipeline_set.descriptorSetLayout, null);
    vk.vkDestroyDescriptorSetLayout(vkDevice, tex_2d_pipeline_set.descriptorSetLayout2, null);

    vk.vkDestroyPipelineLayout(vkDevice, animate_tex_2d_pipeline_set.pipelineLayout, null);
    vk.vkDestroyDescriptorSetLayout(vkDevice, animate_tex_2d_pipeline_set.descriptorSetLayout, null);

    cleanup_pipelines();

    vk.vkDestroyRenderPass(vkDevice, vkRenderPass, null);

    vk.vkDestroySurfaceKHR(vkInstance, vkSurface, null);

    vk.vkDestroyDevice(vkDevice, null);

    if (vkDebugMessenger != null) vkDestroyDebugUtilsMessengerEXT(vkInstance, vkDebugMessenger, null);
    vk.vkDestroyInstance(vkInstance, null);

    __render_command.destroy();
}

fn cleanup_swapchain() void {
    if (vkSwapchain != null) {
        var i: usize = 0;
        while (i < vk_swapchain_frame_buffers.len) : (i += 1) {
            vk.vkDestroyFramebuffer(vkDevice, vk_swapchain_frame_buffers[i], null);
        }
        depth_stencil_image.clean();
        if (depth_stencil_image.pvulkan_buffer.*.is_empty()) depth_stencil_image.pvulkan_buffer.*.deinit();
        __system.allocator.free(vk_swapchain_frame_buffers);
        i = 0;
        while (i < vk_swapchain_image_views.len) : (i += 1) {
            vk.vkDestroyImageView(vkDevice, vk_swapchain_image_views[i], null);
        }
        __system.allocator.free(vk_swapchain_image_views);
        vk.vkDestroySwapchainKHR(vkDevice, vkSwapchain, null);
        vkSwapchain = null;

        __system.allocator.free(formats);
    }
}

fn create_framebuffer() void {
    vk_swapchain_frame_buffers = __system.allocator.alloc(vk.VkFramebuffer, vk_swapchain_image_views.len) catch
        system.handle_error_msg2("__vulkan.create_framebuffer.allocator.alloc(vk.VkFramebuffer) OutOfMemory");

    const img_info: vk.VkImageCreateInfo = .{
        .arrayLayers = 1,
        .extent = .{ .width = vkExtent_rotation.width, .height = vkExtent_rotation.height, .depth = 1 },
        .flags = 0,
        .format = vk.VK_FORMAT_D24_UNORM_S8_UINT,
        .imageType = vk.VK_IMAGE_TYPE_2D,
        .initialLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
        .mipLevels = 1,
        .pQueueFamilyIndices = null,
        .queueFamilyIndexCount = 0,
        .samples = vk.VK_SAMPLE_COUNT_1_BIT,
        .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
        .tiling = vk.VK_IMAGE_TILING_OPTIMAL,
        .usage = vk.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
    };
    graphics.check_vk_allocator();
    vk_allocator.?.*.create_image(&img_info, &depth_stencil_image, null, 0);

    var i: usize = 0;
    while (i < vk_swapchain_image_views.len) : (i += 1) {
        const attachments = [_]vk.VkImageView{ vk_swapchain_image_views[i], depth_stencil_image.__image_view };
        var frameBufferInfo: vk.VkFramebufferCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = vkRenderPass,
            .attachmentCount = 2,
            .pAttachments = &attachments,
            .width = vkExtent_rotation.width,
            .height = vkExtent_rotation.height,
            .layers = 1,
        };

        const result = vk.vkCreateFramebuffer(vkDevice, &frameBufferInfo, null, &vk_swapchain_frame_buffers[i]);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_framebuffer vkCreateFramebuffer vk_swapchain_frame_buffers : {d}", .{result});
    }

    refesh_pre_matrix();
}

pub fn refesh_pre_matrix() void {
    const orientation = window.get_screen_orientation();
    const mat: matrix = switch (orientation) {
        .unknown => matrix.identity(),
        .landscape90 => matrix.rotation2D(std.math.degreesToRadians(90.0)),
        .landscape270 => matrix.rotation2D(std.math.degreesToRadians(270.0)),
        .vertical180 => matrix.rotation2D(std.math.degreesToRadians(180.0)),
        .vertical360 => matrix.identity(),
    };
    if (__pre_mat_uniform.res == null) {
        graphics.create_buffer(
            vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
            .readwrite_cpu,
            @sizeOf(matrix),
            &__pre_mat_uniform,
            std.mem.sliceAsBytes(@as([*]const matrix, @ptrCast(&mat))[0..1]),
        );
    } else {
        var data: ?*matrix = undefined;
        __pre_mat_uniform.map(@ptrCast(&data));
        @memcpy(std.mem.sliceAsBytes(@as([*]matrix, @ptrCast(data.?))[0..1]), std.mem.sliceAsBytes(@as([*]const matrix, @ptrCast(&mat))[0..1]));
        __pre_mat_uniform.unmap();
    }
}

fn create_swapchain_and_imageviews() void {
    var result: c_int = undefined;
    var formatCount: u32 = 0;
    result = vk.vkGetPhysicalDeviceSurfaceFormatsKHR(vk_physical_device, vkSurface, &formatCount, null);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfaceFormatsKHR : {d}", .{result});
    system.handle_error_msg(formatCount != 0, "__vulkan.create_swapchain_and_imageviews.formatCount 0");

    formats = __system.allocator.alloc(vk.VkSurfaceFormatKHR, formatCount) catch
        system.handle_error_msg2("create_swapchain_and_imageviews.allocator.alloc(vk.VkSurfaceFormatKHR) OutOfMemory");

    result = vk.vkGetPhysicalDeviceSurfaceFormatsKHR(vk_physical_device, vkSurface, &formatCount, formats.ptr);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfaceFormatsKHR formats.ptr : {d}", .{result});
    system.handle_error_msg(formatCount != 0, "__vulkan.create_swapchain_and_imageviews.formatCount 0(2)");

    var presentModeCount: u32 = 0;
    result = vk.vkGetPhysicalDeviceSurfacePresentModesKHR(vk_physical_device, vkSurface, &presentModeCount, null);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfacePresentModesKHR : {d}", .{result});
    system.handle_error_msg(presentModeCount != 0, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfacePresentModesKHR presentModeCount 0");

    const presentModes = __system.allocator.alloc(vk.VkPresentModeKHR, presentModeCount) catch {
        system.handle_error_msg2("create_swapchain_and_imageviews.allocator.alloc(vk.VkPresentModeKHR) OutOfMemory");
    };
    defer __system.allocator.free(presentModes);

    result = vk.vkGetPhysicalDeviceSurfacePresentModesKHR(vk_physical_device, vkSurface, &presentModeCount, presentModes.ptr);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfacePresentModesKHR presentModes.ptr : {d}", .{result});

    result = vk.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(vk_physical_device, vkSurface, @ptrCast(&surfaceCap));
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfaceCapabilitiesKHR : {d}", .{result});

    vkExtent = chooseSwapExtent(surfaceCap);
    if (vkExtent.width <= 0 or vkExtent.height <= 0) {
        __system.allocator.free(formats);
        return;
    }

    if (system.platform == .android) {
        if (surfaceCap.currentTransform & vk.VK_SURFACE_TRANSFORM_ROTATE_90_BIT_KHR != 0) {
            vkExtent_rotation.width = vkExtent.height;
            vkExtent_rotation.height = vkExtent.width;
            @atomicStore(@TypeOf(__system.__screen_orientation), &__system.__screen_orientation, .landscape90, std.builtin.AtomicOrder.monotonic);
        } else if (surfaceCap.currentTransform & vk.VK_SURFACE_TRANSFORM_ROTATE_270_BIT_KHR != 0) {
            vkExtent_rotation.width = vkExtent.height;
            vkExtent_rotation.height = vkExtent.width;
            @atomicStore(@TypeOf(__system.__screen_orientation), &__system.__screen_orientation, .landscape270, std.builtin.AtomicOrder.monotonic);
        } else if (surfaceCap.currentTransform & vk.VK_SURFACE_TRANSFORM_ROTATE_180_BIT_KHR != 0) {
            @atomicStore(@TypeOf(__system.__screen_orientation), &__system.__screen_orientation, .vertical180, std.builtin.AtomicOrder.monotonic);
            vkExtent_rotation = vkExtent;
        } else {
            @atomicStore(@TypeOf(__system.__screen_orientation), &__system.__screen_orientation, .vertical360, std.builtin.AtomicOrder.monotonic);
            vkExtent_rotation = vkExtent;
        }
    } else {
        vkExtent_rotation = vkExtent;
    }
    @atomicStore(i32, &__system.init_set.window_width, @intCast(vkExtent.width), std.builtin.AtomicOrder.monotonic);
    @atomicStore(i32, &__system.init_set.window_height, @intCast(vkExtent.height), std.builtin.AtomicOrder.monotonic);

    format = chooseSwapSurfaceFormat(formats);
    colorAttachment.format = format.format;
    const presentMode = chooseSwapPresentMode(presentModes, __system.init_set.vSync);

    var imageCount = surfaceCap.minImageCount + 1;
    if (surfaceCap.maxImageCount > 0 and imageCount > surfaceCap.maxImageCount) {
        imageCount = surfaceCap.maxImageCount;
    }

    var swapChainCreateInfo: vk.VkSwapchainCreateInfoKHR = .{
        .sType = vk.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = vkSurface,
        .minImageCount = imageCount,
        .imageFormat = format.format,
        .imageColorSpace = format.colorSpace,
        .imageExtent = vkExtent_rotation,
        .imageArrayLayers = 1,
        .imageUsage = vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .presentMode = presentMode,
        .preTransform = surfaceCap.currentTransform,
        .compositeAlpha = surfaceCap.supportedCompositeAlpha,
        .clipped = 1,
        .oldSwapchain = null,
        .imageSharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
    };

    const queueFamiliesIndices = [_]u32{ graphicsFamilyIndex, presentFamilyIndex };

    if (graphicsFamilyIndex != presentFamilyIndex) {
        swapChainCreateInfo.imageSharingMode = vk.VK_SHARING_MODE_CONCURRENT;
        swapChainCreateInfo.queueFamilyIndexCount = 2;
        swapChainCreateInfo.pQueueFamilyIndices = &queueFamiliesIndices;
    }

    result = vk.vkCreateSwapchainKHR(vkDevice, &swapChainCreateInfo, null, &vkSwapchain);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkCreateSwapchainKHR : {d}", .{result});

    var swapchain_image_count: u32 = 0;

    result = vk.vkGetSwapchainImagesKHR(vkDevice, vkSwapchain, &swapchain_image_count, null);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetSwapchainImagesKHR : {d}", .{result});

    const swapchain_images = __system.allocator.alloc(vk.VkImage, swapchain_image_count) catch
        system.handle_error_msg2("__vulkan.create_swapchain_and_imageviews.allocator.alloc(vk.VkImage) OutOfMemory");
    defer __system.allocator.free(swapchain_images);

    result = vk.vkGetSwapchainImagesKHR(vkDevice, vkSwapchain, &swapchain_image_count, swapchain_images.ptr);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetSwapchainImagesKHR swapchain_images.ptr : {d}", .{result});

    vk_swapchain_image_views = __system.allocator.alloc(vk.VkImageView, swapchain_image_count) catch |e| system.handle_error3("vulkan_start.vk_swapchain_image_views alloc", e);

    var i: usize = 0;
    while (i < swapchain_image_count) : (i += 1) {
        const image_view_createInfo: vk.VkImageViewCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .image = swapchain_images[i],
            .viewType = vk.VK_IMAGE_VIEW_TYPE_2D,
            .format = format.format,
            .components = .{
                .r = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
                .g = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
                .b = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
                .a = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            },
            .subresourceRange = .{
                .aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
        };
        result = vk.vkCreateImageView(vkDevice, &image_view_createInfo, null, &vk_swapchain_image_views[i]);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkCreateImageView({d}) : {d}", .{ i, result });
    }
}

pub fn begin_single_time_commands() vk.VkCommandBuffer {
    const alloc_info: vk.VkCommandBufferAllocateInfo = .{
        .commandBufferCount = 1,
        .level = vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandPool = vkCommandPool,
    };
    var buf: vk.VkCommandBuffer = undefined;
    var result = vk.vkAllocateCommandBuffers(vkDevice, &alloc_info, &buf);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.begin_single_time_commands.vkAllocateCommandBuffers : {d}", .{result});

    const begin: vk.VkCommandBufferBeginInfo = .{ .flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT };
    result = vk.vkBeginCommandBuffer(buf, &begin);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.begin_single_time_commands.vkBeginCommandBuffer : {d}", .{result});

    return buf;
}
pub fn end_single_time_commands(buf: vk.VkCommandBuffer) void {
    const result = vk.vkEndCommandBuffer(buf);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.end_single_time_commands.vkEndCommandBuffer : {d}", .{result});
    queue_submit_and_wait(&[_]vk.VkCommandBuffer{buf});
}

pub fn queue_submit_and_wait(bufs: []const vk.VkCommandBuffer) void {
    const submitInfo: vk.VkSubmitInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = bufs.ptr,
    };

    var result = vk.vkQueueSubmit(vkGraphicsQueue, 1, &submitInfo, null);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.queue_submit_and_wait.vkQueueSubmit : {d}", .{result});
    result = vk.vkQueueWaitIdle(vkGraphicsQueue);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.queue_submit_and_wait.vkQueueWaitIdle : {d}", .{result});

    vk.vkFreeCommandBuffers(vkDevice, vkCommandPool, 1, bufs.ptr);
}

pub fn copy_buffer_to_image(src_buf: vk.VkBuffer, dst_img: vk.VkImage, width: c_uint, height: c_uint, depth: c_uint, array_size: c_uint) void {
    const buf = begin_single_time_commands();

    const region: vk.VkBufferImageCopy = .{
        .bufferOffset = 0,
        .bufferRowLength = 0,
        .bufferImageHeight = 0,
        .imageOffset = .{ .x = 0, .y = 0, .z = 0 },
        .imageExtent = .{ .width = width, .height = height, .depth = depth },
        .imageSubresource = .{
            .aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
            .baseArrayLayer = 0,
            .mipLevel = 0,
            .layerCount = array_size,
        },
    };
    vk.vkCmdCopyBufferToImage(buf, src_buf, dst_img, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

    end_single_time_commands(buf);
}

///rect는 Y가 작을수록 위
pub fn copy_buffer_to_image2(src_buf: vk.VkBuffer, dst_img: vk.VkImage, rect: math.recti, depth: c_uint) void {
    if (rect.left >= rect.right or rect.top >= rect.bottom) system.handle_error_msg2("copy_buffer_to_image2 invaild rect");
    const buf = begin_single_time_commands();

    const region: vk.VkBufferImageCopy = .{
        .bufferOffset = 0,
        .bufferRowLength = 0,
        .bufferImageHeight = 0,
        .imageOffset = .{ .x = rect.left, .y = rect.top, .z = 0 },
        .imageExtent = .{ .width = rect.width(), .height = rect.height(), .depth = depth },
        .imageSubresource = .{
            .aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
            .baseArrayLayer = 0,
            .mipLevel = 0,
            .layerCount = 1,
        },
    };
    vk.vkCmdCopyBufferToImage(buf, src_buf, dst_img, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

    end_single_time_commands(buf);
}

pub fn copy_buffer(srcBuffer: vk.VkBuffer, dstBuffer: vk.VkBuffer, size: vk.VkDeviceSize) void {
    const buf = begin_single_time_commands();

    const copyRegion: vk.VkBufferCopy = .{
        .size = size,
        .srcOffset = 0,
        .dstOffset = 0,
    };

    vk.vkCmdCopyBuffer(buf, srcBuffer, dstBuffer, 1, &copyRegion);
    end_single_time_commands(buf);
}

pub fn get_swapchain_image_length() usize {
    return vk_swapchain_image_views.len;
}

pub fn recreate_swapchain() void {
    if (vkDevice == null) return;
    wait_device_idle();

    if (system.platform == .android) {
        __android.vulkan_android_start(vkInstance, &vkSurface);
    } else if (system.platform == .windows) {
        //__windows.vulkan_windows_start(vkInstance, &vkSurface);
    }

    cleanup_swapchain();
    cleanup_sync_object();
    create_swapchain_and_imageviews();
    if (vkExtent.width <= 0 or vkExtent.height <= 0) {
        create_sync_object();
        return;
    }
    create_framebuffer();
    create_sync_object();

    __render_command.refresh_all();
    root.xfit_size();
}

pub var render_rwlock: std.Thread.Mutex = .{};

pub fn drawFrame() void {
    var imageIndex: u32 = 0;
    const state = struct {
        var frame: usize = 0;
    };
    if (system.platform == .android) {
        if (__android.orientationChanged) {
            recreate_swapchain();
            __android.orientationChanged = false;
        }
    }

    if (vkExtent.width <= 0 or vkExtent.height <= 0) {
        recreate_swapchain();
        return;
    }

    if (graphics.render_cmd != null) {
        var result = vk.vkAcquireNextImageKHR(vkDevice, vkSwapchain, std.math.maxInt(u64), vkImageAvailableSemaphore[state.frame], null, &imageIndex);
        if (result == vk.VK_ERROR_OUT_OF_DATE_KHR) {
            recreate_swapchain();
            return;
        }

        render_rwlock.lock();
        if (@atomicLoad(bool, &graphics.render_cmd.?.*.__refesh, .monotonic)) {
            @atomicStore(bool, &graphics.render_cmd.?.*.__refesh, false, .monotonic);
            recordCommandBuffer(graphics.render_cmd.?);
        }
        render_rwlock.unlock();

        const waitStages: u32 = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        const submitInfo: vk.VkSubmitInfo = .{
            .waitSemaphoreCount = 1,
            .commandBufferCount = 1,
            .signalSemaphoreCount = 1,
            .pWaitSemaphores = &vkImageAvailableSemaphore[state.frame],
            .pWaitDstStageMask = &waitStages,
            .pCommandBuffers = &graphics.render_cmd.?.*.__command_buffers[state.frame][imageIndex],
            .pSignalSemaphores = &vkRenderFinishedSemaphore[state.frame],
        };

        result = vk.vkResetFences(vkDevice, 1, &vkInFlightFence[state.frame]);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.drawFrame.vkResetFences : {d}", .{result});

        result = vk.vkQueueSubmit(vkGraphicsQueue, 1, &submitInfo, vkInFlightFence[state.frame]);

        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.drawFrame.vkQueueSubmit : {d}", .{result});

        result = vk.vkWaitForFences(vkDevice, 1, &vkInFlightFence[state.frame], vk.VK_TRUE, std.math.maxInt(u64));
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.wait_for_fences.vkWaitForFences : {d}", .{result});

        const swapChains = [_]vk.VkSwapchainKHR{vkSwapchain};

        const presentInfo: vk.VkPresentInfoKHR = .{
            .sType = vk.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = 1,
            .swapchainCount = 1,
            .pWaitSemaphores = &vkRenderFinishedSemaphore[state.frame],
            .pSwapchains = &swapChains,
            .pImageIndices = &imageIndex,
        };

        result = vk.vkQueuePresentKHR(vkPresentQueue, &presentInfo);

        if (result == vk.VK_ERROR_OUT_OF_DATE_KHR) {
            recreate_swapchain();
        } else if (result == vk.VK_SUBOPTIMAL_KHR) {
            const ww = window.window_width();
            const hh = window.window_height();
            if (ww != vkExtent.width or hh != vkExtent.height) recreate_swapchain();
        } else {
            system.handle_error(result == vk.VK_SUCCESS, "__vulkan.drawFrame.vkQueuePresentKHR : {d}", .{result});
        }
        state.frame = (state.frame + 1) % render_command.MAX_FRAME;
    }
}

pub fn wait_device_idle() void {
    const result = vk.vkDeviceWaitIdle(vkDevice);
    if (result != vk.VK_SUCCESS) system.print_error("__vulkan.vkDeviceWaitIdle : {d}", .{result});
}

pub fn transition_image_layout(image: vk.VkImage, mipLevels: u32, arrayLayers: u32, old_layout: vk.VkImageLayout, new_layout: vk.VkImageLayout) void {
    const buf = begin_single_time_commands();

    var barrier: vk.VkImageMemoryBarrier = .{
        .oldLayout = old_layout,
        .newLayout = new_layout,
        .srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
        .image = image,
        .subresourceRange = .{
            .aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
            .baseMipLevel = 0,
            .levelCount = mipLevels,
            .baseArrayLayer = 0,
            .layerCount = arrayLayers,
        },
    };

    var source_stage: vk.VkPipelineStageFlags = undefined;
    var destination_stage: vk.VkPipelineStageFlags = undefined;

    if (old_layout == vk.VK_IMAGE_LAYOUT_UNDEFINED and new_layout == vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL) {
        barrier.srcAccessMask = 0;
        barrier.dstAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT;

        source_stage = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
        destination_stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT;
    } else if (old_layout == vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL and new_layout == vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL) {
        barrier.srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT;
        barrier.dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT;

        source_stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT;
        destination_stage = vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
    } else {
        system.handle_error_msg2("__vulkan.transition_image_layout unsupported layout transition!");
    }

    vk.vkCmdPipelineBarrier(buf, source_stage, destination_stage, 0, 0, null, 0, null, 1, &barrier);

    end_single_time_commands(buf);
}
