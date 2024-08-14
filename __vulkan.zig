const std = @import("std");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;

const __windows = @import("__windows.zig");
const __android = @import("__android.zig");
const system = @import("system.zig");
const math = @import("math.zig");
const matrix = math.matrix;
const graphics = @import("graphics.zig");
const __system = @import("__system.zig");

const allocator = __system.allocator;

const root = @import("root");

const __vulkan_allocator = @import("__vulkan_allocator.zig");
pub var vk_allocator: __vulkan_allocator = __vulkan_allocator.init();

pub const vk = @import("include/vulkan.zig");

const shape_vert = @embedFile("shaders/out/shape_vert.spv");
const shape_frag = @embedFile("shaders/out/shape_frag.spv");
var shape_vert_shader: vk.VkShaderModule = undefined;
var shape_frag_shader: vk.VkShaderModule = undefined;

const tex_vert = @embedFile("shaders/out/tex_vert.spv");
const tex_frag = @embedFile("shaders/out/tex_frag.spv");
var tex_vert_shader: vk.VkShaderModule = undefined;
var tex_frag_shader: vk.VkShaderModule = undefined;

pub const pipeline_set = struct {
    pipeline: vk.VkPipeline = null,
    pipelineLayout: vk.VkPipelineLayout = null,
    descriptorSetLayout: vk.VkDescriptorSetLayout = null,

    pub fn deinit(self: *pipeline_set) void {
        if (self.*.pipeline != null) {
            vk.vkDestroyPipeline(vkDevice, self.*.pipeline, null);
            vk.vkDestroyPipelineLayout(vkDevice, self.*.pipelineLayout, null);
            vk.vkDestroyDescriptorSetLayout(vkDevice, self.*.descriptorSetLayout, null);
        }
    }
};

//Predefined Pipelines
pub var color_2d_pipeline_set: pipeline_set = .{};
pub var tex_2d_pipeline_set: pipeline_set = .{};
//

fn chooseSwapExtent(capabilities: vk.VkSurfaceCapabilitiesKHR) vk.VkExtent2D {
    if (capabilities.currentExtent.width != std.math.maxInt(u32)) {
        return capabilities.currentExtent;
    } else {
        if (root.platform == root.XfitPlatform.windows) {
            var rect: __windows.RECT = undefined;

            _ = __windows.win32.GetClientRect(__windows.hWnd, &rect);
            var width = @abs(rect.right - rect.left);
            var height = @abs(rect.bottom - rect.top);
            width = std.math.clamp(width, capabilities.minImageExtent.width, capabilities.maxImageExtent.width);
            height = std.math.clamp(height, capabilities.minImageExtent.height, capabilities.maxImageExtent.height);
            return vk.VkExtent2D{ .width = width, .height = height };
        } else if (root.platform == root.XfitPlatform.android) {
            return vk.VkExtent2D{ .width = __android.get_device_width(), .height = __android.get_device_height() };
        } else {
            @compileError("not support platform");
        }
    }
}

fn chooseSwapSurfaceFormat(availableFormats: []vk.VkSurfaceFormatKHR) vk.VkSurfaceFormatKHR {
    for (availableFormats) |value| {
        if (value.format == vk.VK_FORMAT_B8G8R8A8_SRGB and value.colorSpace == vk.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return value;
        }
    }
    return availableFormats[0];
}

fn chooseSwapPresentMode(availablePresentModes: []vk.VkPresentModeKHR) vk.VkPresentModeKHR {
    for (availablePresentModes) |value| {
        if (value == vk.VK_PRESENT_MODE_MAILBOX_KHR) {
            return value;
        }
    }
    return vk.VK_PRESENT_MODE_FIFO_KHR;
}

var vkInstance: vk.VkInstance = undefined;
pub var vkDevice: vk.VkDevice = undefined;
var vkSurface: vk.VkSurfaceKHR = undefined;
var vkRenderPass: vk.VkRenderPass = undefined;
var vkSwapchain: vk.VkSwapchainKHR = undefined;

var vkCommandPool: vk.VkCommandPool = undefined;
var vkCommandBuffer: vk.VkCommandBuffer = undefined;

var vkImageAvailableSemaphore: vk.VkSemaphore = null;
var vkRenderFinishedSemaphore: vk.VkSemaphore = null;

var vkInFlightFence: vk.VkFence = null;

var vkDebugMessenger: vk.VkDebugUtilsMessengerEXT = null;

var vkGraphicsQueue: vk.VkQueue = undefined;
var vkPresentQueue: vk.VkQueue = undefined;

var vkExtent: vk.VkExtent2D = undefined;
var vk_swapchain_frame_buffers: []vk.VkFramebuffer = undefined;
var vk_swapchain_image_views: []vk.VkImageView = undefined;

pub var vk_physical_devices: []vk.VkPhysicalDevice = undefined;

var graphicsFamilyIndex: u32 = std.math.maxInt(u32);
var presentFamilyIndex: u32 = std.math.maxInt(u32);
var queueFamiliesCount: u32 = 0;

var formats: []vk.VkSurfaceFormatKHR = undefined;
var format: vk.VkSurfaceFormatKHR = undefined;

pub var linear_sampler: vk.VkSampler = undefined;
pub var nearest_sampler: vk.VkSampler = undefined;

fn createShaderModule(code: []const u8) vk.VkShaderModule {
    const createInfo: vk.VkShaderModuleCreateInfo = .{ .codeSize = code.len, .pCode = code.ptr };

    var shaderModule: vk.VkShaderModule = undefined;
    const result = vk.vkCreateShaderModule(vkDevice, &createInfo, null, &shaderModule);

    system.handle_error(result == vk.VK_SUCCESS, result);

    return shaderModule;
}

fn recordCommandBuffer(commandBuffer: vk.VkCommandBuffer, imageIndex: u32) void {
    const beginInfo: vk.VkCommandBufferBeginInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, .flags = 0, .pInheritanceInfo = null };

    var result = vk.vkBeginCommandBuffer(commandBuffer, &beginInfo);
    system.handle_error(result == vk.VK_SUCCESS, result);

    const clearColor: vk.VkClearValue = .{ .color = .{ .float32 = .{ 0, 0, 0, 0 } } };

    const renderPassInfo: vk.VkRenderPassBeginInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO, .renderPass = vkRenderPass, .framebuffer = vk_swapchain_frame_buffers[imageIndex], .renderArea = .{ .offset = .{ .x = 0, .y = 0 }, .extent = vkExtent }, .clearValueCount = 1, .pClearValues = @ptrCast(&clearColor) };

    vk.vkCmdBeginRenderPass(commandBuffer, &renderPassInfo, vk.VK_SUBPASS_CONTENTS_INLINE);

    const viewport: vk.VkViewport = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(vkExtent.width),
        .height = @floatFromInt(vkExtent.height),
        .maxDepth = 1,
        .minDepth = 0,
    };
    const scissor: vk.VkRect2D = .{ .offset = vk.VkOffset2D{ .x = 0, .y = 0 }, .extent = vkExtent };

    if (graphics.scene != null) {
        for (graphics.scene.?.*) |value| {
            const ivertices = value.*.get_ivertices(value) orelse continue;
            vk.vkCmdBindPipeline(commandBuffer, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, ivertices.*.pipeline.*.pipeline);

            vk.vkCmdSetViewport(commandBuffer, 0, 1, @ptrCast(&viewport));
            vk.vkCmdSetScissor(commandBuffer, 0, 1, @ptrCast(&scissor));

            vk.vkCmdBindDescriptorSets(commandBuffer, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, ivertices.pipeline.*.pipelineLayout, 0, 1, &value.__descriptor_set, 0, null);

            const offsets: vk.VkDeviceSize = 0;
            vk.vkCmdBindVertexBuffers(commandBuffer, 0, 1, &ivertices.*.node.res, &offsets);

            const iindices = value.*.get_iindices(value);
            if (iindices != null) {
                vk.vkCmdBindIndexBuffer(commandBuffer, iindices.?.*.node.res, 0, switch (iindices.?.*.idx_type) {
                    .U16 => vk.VK_INDEX_TYPE_UINT16,
                    .U32 => vk.VK_INDEX_TYPE_UINT32,
                });
                vk.vkCmdDrawIndexed(commandBuffer, @intCast(iindices.?.*.get_indices_len(iindices.?)), 1, 0, 0, 0);
            } else {
                vk.vkCmdDraw(commandBuffer, @intCast(ivertices.*.get_vertices_len(ivertices)), 1, 0, 0);
            }
        }
    }

    vk.vkCmdEndRenderPass(commandBuffer);
    result = vk.vkEndCommandBuffer(commandBuffer);
    system.handle_error(result == vk.VK_SUCCESS, result);
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

    system.print("{s}\n\n", .{pCallbackData.?.*.pMessage});

    return vk.VK_FALSE;
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
    var extension_names = ArrayList([*:0]const u8).init(allocator);
    defer extension_names.deinit();
    // var j: u32 = 0;
    // while (j < property_count) : (j += 1) {
    //     try extension_names.append(@ptrCast(&extensions[j].extension_name[0]));
    // }

    extension_names.append("VK_KHR_surface") catch unreachable;
    var validation_layer_support = false;
    const validation_layer_name = "VK_LAYER_KHRONOS_validation";
    var result: c_int = undefined;

    if (root.platform == root.XfitPlatform.windows) {
        if (builtin.mode == std.builtin.OptimizeMode.Debug) {
            var layer_count: u32 = undefined;
            result = vk.vkEnumerateInstanceLayerProperties(&layer_count, null);
            system.handle_error(result == vk.VK_SUCCESS, result);

            const available_layers = allocator.alloc(vk.VkLayerProperties, layer_count) catch {
                system.print_error("ERR vulkan_start.allocator.alloc(vk.VkLayerProperties) OutOfMemory\n", .{});
                unreachable;
            };
            defer allocator.free(available_layers);

            result = vk.vkEnumerateInstanceLayerProperties(&layer_count, available_layers.ptr);
            system.handle_error(result == vk.VK_SUCCESS, result);
            var layer_found = false;

            for (available_layers) |*value| {
                if (std.mem.eql(u8, value.*.layerName[0..std.mem.len(@as([*c]u8, @ptrCast(&value.*.layerName)))], validation_layer_name)) {
                    layer_found = true;
                    break;
                }
            }
            if (!layer_found) {
                system.print("WARN VK_LAYER_KHRONOS_validation not found disable vulkan Debug feature.\n", .{});
            } else {
                validation_layer_support = true;
                extension_names.append(vk.VK_EXT_DEBUG_UTILS_EXTENSION_NAME) catch unreachable;
            }
        }
        extension_names.append("VK_KHR_win32_surface") catch unreachable;
    } else if (root.platform == root.XfitPlatform.android) {
        extension_names.append("VK_KHR_android_surface") catch unreachable;
    } else {
        @compileError("not support platform");
    }

    const createInfo: vk.VkInstanceCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &appInfo,
        .enabledLayerCount = if (validation_layer_support) 1 else 0,
        .ppEnabledLayerNames = if (validation_layer_support) @ptrCast(&validation_layer_name) else null,
        .enabledExtensionCount = @intCast(extension_names.items.len),
        .ppEnabledExtensionNames = extension_names.items.ptr,
    };

    result = vk.vkCreateInstance(&createInfo, null, &vkInstance);
    system.handle_error(result == vk.VK_SUCCESS, result);

    if (validation_layer_support) {
        const create_info = vk.VkDebugUtilsMessengerCreateInfoEXT{
            .sType = vk.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
            .messageSeverity = vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT | vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
            .messageType = vk.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | vk.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
            .pfnUserCallback = debug_callback,
            .pUserData = null,
        };
        result = vkCreateDebugUtilsMessengerEXT(vkInstance, &create_info, null, &vkDebugMessenger);
        system.handle_error(result == vk.VK_SUCCESS, result);
    }

    if (root.platform == root.XfitPlatform.windows) {
        __windows.vulkan_windows_start(vkInstance, &vkSurface);
    } else if (root.platform == root.XfitPlatform.android) {
        __android.vulkan_android_start(vkInstance, &vkSurface);
    } else {
        @compileError("not support platform");
    }

    var deviceCount: u32 = 0;
    result = vk.vkEnumeratePhysicalDevices(vkInstance, &deviceCount, null);
    system.handle_error(result == vk.VK_SUCCESS, result);

    //system.print("{d}\n", .{deviceCount});
    system.handle_error(deviceCount != 0, 0);
    vk_physical_devices = allocator.alloc(vk.VkPhysicalDevice, deviceCount) catch {
        system.print_error("ERR vulkan_start.allocator.alloc(vk.VkPhysicalDevice) OutOfMemory\n", .{});
        unreachable;
    };

    result = vk.vkEnumeratePhysicalDevices(vkInstance, &deviceCount, vk_physical_devices.ptr);
    system.handle_error(result == vk.VK_SUCCESS, result);

    vk.vkGetPhysicalDeviceQueueFamilyProperties(vk_physical_devices[0], &queueFamiliesCount, null);
    system.handle_error(queueFamiliesCount != 0, 0);

    const queueFamilies = allocator.alloc(vk.VkQueueFamilyProperties, queueFamiliesCount) catch {
        system.print_error("ERR vulkan_start.allocator.alloc(vk.VkQueueFamilyProperties) OutOfMemory\n", .{});
        unreachable;
    };
    defer allocator.free(queueFamilies);

    vk.vkGetPhysicalDeviceQueueFamilyProperties(vk_physical_devices[0], &queueFamiliesCount, queueFamilies.ptr);

    var i: u32 = 0;
    while (i < queueFamiliesCount) : (i += 1) {
        if ((queueFamilies[i].queueFlags & vk.VK_QUEUE_GRAPHICS_BIT) != 0) {
            graphicsFamilyIndex = i;
        }
        var presentSupport: vk.VkBool32 = 0;
        result = vk.vkGetPhysicalDeviceSurfaceSupportKHR(vk_physical_devices[0], i, vkSurface, &presentSupport);
        system.handle_error(result == vk.VK_SUCCESS, result);

        if (presentSupport != 0) {
            presentFamilyIndex = i;
        }
        if (graphicsFamilyIndex != std.math.maxInt(u32) and presentFamilyIndex != std.math.maxInt(u32)) break;
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
    result = vk.vkCreateDevice(vk_physical_devices[0], &deviceCreateInfo, null, &vkDevice);
    system.handle_error(result == vk.VK_SUCCESS, result);

    if (graphicsFamilyIndex == presentFamilyIndex) {
        vk.vkGetDeviceQueue(vkDevice, graphicsFamilyIndex, 0, &vkGraphicsQueue);
        vkPresentQueue = vkGraphicsQueue;
    } else {
        vk.vkGetDeviceQueue(vkDevice, graphicsFamilyIndex, 0, &vkGraphicsQueue);
        vk.vkGetDeviceQueue(vkDevice, presentFamilyIndex, 0, &vkPresentQueue);
    }

    create_swapchain_and_imageviews();

    var properties: vk.VkPhysicalDeviceProperties = undefined;
    vk.vkGetPhysicalDeviceProperties(vk_physical_devices[0], &properties);

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
        .anisotropyEnable = vk.VK_TRUE,
        .maxAnisotropy = properties.limits.maxSamplerAnisotropy,
        .borderColor = vk.VK_BORDER_COLOR_INT_OPAQUE_WHITE,
    };
    result = vk.vkCreateSampler(vkDevice, &sampler_info, null, &linear_sampler);
    system.handle_error(result == vk.VK_SUCCESS, result);

    sampler_info.mipmapMode = vk.VK_SAMPLER_MIPMAP_MODE_NEAREST;
    result = vk.vkCreateSampler(vkDevice, &sampler_info, null, &nearest_sampler);
    system.handle_error(result == vk.VK_SUCCESS, result);

    const dynamicStates = [_]vk.VkDynamicState{ vk.VK_DYNAMIC_STATE_VIEWPORT, vk.VK_DYNAMIC_STATE_SCISSOR };

    const inputAssembly: vk.VkPipelineInputAssemblyStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        .primitiveRestartEnable = vk.VK_FALSE,
    };

    const viewport: vk.VkViewport = .{ .x = 0, .y = 0, .width = @floatFromInt(vkExtent.width), .height = @floatFromInt(vkExtent.height), .maxDepth = 1, .minDepth = 0 };

    const scissor: vk.VkRect2D = .{ .offset = vk.VkOffset2D{ .x = 0, .y = 0 }, .extent = vkExtent };

    const dynamicState: vk.VkPipelineDynamicStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .dynamicStateCount = dynamicStates.len,
        .pDynamicStates = &dynamicStates,
    };

    const viewportState: vk.VkPipelineViewportStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .viewportCount = 1,
        .scissorCount = 1,
        .pViewports = @ptrCast(&viewport),
        .pScissors = @ptrCast(&scissor),
    };

    const rasterizer: vk.VkPipelineRasterizationStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .depthClampEnable = vk.VK_FALSE,
        .rasterizerDiscardEnable = vk.VK_FALSE,
        .polygonMode = vk.VK_POLYGON_MODE_FILL,
        .lineWidth = 1,
        .cullMode = vk.VK_CULL_MODE_BACK_BIT,
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

    const colorBlending: vk.VkPipelineColorBlendStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .logicOpEnable = vk.VK_FALSE,
        .logicOp = vk.VK_LOGIC_OP_COPY,
        .attachmentCount = 1,
        .pAttachments = @ptrCast(&colorBlendAttachment),
        .blendConstants = .{ 0, 0, 0, 0 },
    };

    const colorAttachment: vk.VkAttachmentDescription = .{
        .format = format.format,
        .samples = vk.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = vk.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
    };

    const colorAttachmentRef: vk.VkAttachmentReference = .{ .attachment = 0, .layout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL };

    const subpass: vk.VkSubpassDescription = .{
        .pipelineBindPoint = vk.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = @ptrCast(&colorAttachmentRef),
    };

    const renderPassInfo: vk.VkRenderPassCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = 1,
        .pAttachments = @ptrCast(&colorAttachment),
        .subpassCount = 1,
        .pSubpasses = @ptrCast(&subpass),
    };

    result = vk.vkCreateRenderPass(vkDevice, &renderPassInfo, null, &vkRenderPass);
    system.handle_error(result == vk.VK_SUCCESS, result);

    //create_shape_shader_stages
    shape_vert_shader = createShaderModule(shape_vert);
    shape_frag_shader = createShaderModule(shape_frag);

    const stage_infov1: vk.VkPipelineShaderStageCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = vk.VK_SHADER_STAGE_VERTEX_BIT,
        .module = shape_vert_shader,
        .pName = "main",
    };
    const stage_infof1: vk.VkPipelineShaderStageCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
        .module = shape_frag_shader,
        .pName = "main",
    };

    const shape_shader_stages = [2]vk.VkPipelineShaderStageCreateInfo{ stage_infov1, stage_infof1 };

    //create_tex_shader_stages
    tex_vert_shader = createShaderModule(tex_vert);
    tex_frag_shader = createShaderModule(tex_frag);

    const stage_infov2: vk.VkPipelineShaderStageCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = vk.VK_SHADER_STAGE_VERTEX_BIT,
        .module = tex_vert_shader,
        .pName = "main",
    };
    const stage_infof2: vk.VkPipelineShaderStageCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
        .module = tex_frag_shader,
        .pName = "main",
    };

    const tex_shader_stages = [2]vk.VkPipelineShaderStageCreateInfo{ stage_infov2, stage_infof2 };

    //create_color_2d_pipeline
    {
        const uboLayoutBinding = [3]vk.VkDescriptorSetLayoutBinding{
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
        };
        const set_layout_info: vk.VkDescriptorSetLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
            .bindingCount = uboLayoutBinding.len,
            .pBindings = &uboLayoutBinding,
        };
        result = vk.vkCreateDescriptorSetLayout(vkDevice, &set_layout_info, null, &color_2d_pipeline_set.descriptorSetLayout);
        system.handle_error(result == vk.VK_SUCCESS, result);

        const pipelineLayoutInfo: vk.VkPipelineLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 1,
            .pSetLayouts = &color_2d_pipeline_set.descriptorSetLayout,
            .pushConstantRangeCount = 0,
            .pPushConstantRanges = null,
        };

        result = vk.vkCreatePipelineLayout(vkDevice, &pipelineLayoutInfo, null, &color_2d_pipeline_set.pipelineLayout);
        system.handle_error(result == vk.VK_SUCCESS, result);

        const bindingDescription: vk.VkVertexInputBindingDescription = .{
            .binding = 0,
            .stride = @sizeOf(f32) * (2 + 4),
            .inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX,
        };
        const attributeDescriptions: [2]vk.VkVertexInputAttributeDescription = .{
            .{ .binding = 0, .location = 0, .format = vk.VK_FORMAT_R32G32_SFLOAT, .offset = 0 },
            .{ .binding = 0, .location = 1, .format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, .offset = @sizeOf(f32) * 2 },
        };

        const vertexInputInfo: vk.VkPipelineVertexInputStateCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
            .vertexBindingDescriptionCount = 1,
            .vertexAttributeDescriptionCount = 2,
            .pVertexBindingDescriptions = &bindingDescription,
            .pVertexAttributeDescriptions = &attributeDescriptions,
        };

        const pipelineInfo: vk.VkGraphicsPipelineCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .stageCount = 2,
            .pStages = &shape_shader_stages,
            .pVertexInputState = &vertexInputInfo,
            .pInputAssemblyState = &inputAssembly,
            .pViewportState = &viewportState,
            .pRasterizationState = &rasterizer,
            .pMultisampleState = &multisampling,
            .pDepthStencilState = null,
            .pColorBlendState = &colorBlending,
            .pDynamicState = &dynamicState,
            .layout = color_2d_pipeline_set.pipelineLayout,
            .renderPass = vkRenderPass,
            .subpass = 0,
            .basePipelineHandle = null,
            .basePipelineIndex = -1,
        };

        result = vk.vkCreateGraphicsPipelines(vkDevice, std.mem.zeroes(vk.VkPipelineCache), 1, &pipelineInfo, null, &color_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, result);
    }
    //create_tex_2d_pipeline
    {
        const uboLayoutBinding = [4]vk.VkDescriptorSetLayoutBinding{
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
                .descriptorType = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT | vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = null,
            },
        };
        const set_layout_info: vk.VkDescriptorSetLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
            .bindingCount = uboLayoutBinding.len,
            .pBindings = &uboLayoutBinding,
        };
        result = vk.vkCreateDescriptorSetLayout(vkDevice, &set_layout_info, null, &tex_2d_pipeline_set.descriptorSetLayout);
        system.handle_error(result == vk.VK_SUCCESS, result);

        const pipelineLayoutInfo: vk.VkPipelineLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 1,
            .pSetLayouts = &tex_2d_pipeline_set.descriptorSetLayout,
            .pushConstantRangeCount = 0,
            .pPushConstantRanges = null,
        };

        result = vk.vkCreatePipelineLayout(vkDevice, &pipelineLayoutInfo, null, &tex_2d_pipeline_set.pipelineLayout);
        system.handle_error(result == vk.VK_SUCCESS, result);

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

        const pipelineInfo: vk.VkGraphicsPipelineCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .stageCount = 2,
            .pStages = &tex_shader_stages,
            .pVertexInputState = &vertexInputInfo,
            .pInputAssemblyState = &inputAssembly,
            .pViewportState = &viewportState,
            .pRasterizationState = &rasterizer,
            .pMultisampleState = &multisampling,
            .pDepthStencilState = null,
            .pColorBlendState = &colorBlending,
            .pDynamicState = &dynamicState,
            .layout = tex_2d_pipeline_set.pipelineLayout,
            .renderPass = vkRenderPass,
            .subpass = 0,
            .basePipelineHandle = null,
            .basePipelineIndex = -1,
        };

        result = vk.vkCreateGraphicsPipelines(vkDevice, std.mem.zeroes(vk.VkPipelineCache), 1, &pipelineInfo, null, &tex_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, result);
    }

    create_framebuffer();

    const poolInfo: vk.VkCommandPoolCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = graphicsFamilyIndex,
    };

    result = vk.vkCreateCommandPool(vkDevice, &poolInfo, null, &vkCommandPool);
    system.handle_error(result == vk.VK_SUCCESS, result);

    const allocInfo: vk.VkCommandBufferAllocateInfo = .{
        .commandPool = vkCommandPool,
        .level = vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = 1,
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
    };

    result = vk.vkAllocateCommandBuffers(vkDevice, &allocInfo, @ptrCast(&vkCommandBuffer));
    system.handle_error(result == vk.VK_SUCCESS, result);

    const semaphoreInfo: vk.VkSemaphoreCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO };
    const fenceInfo: vk.VkFenceCreateInfo = .{ .flags = vk.VK_FENCE_CREATE_SIGNALED_BIT, .sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO };

    result = vk.vkCreateSemaphore(vkDevice, &semaphoreInfo, null, &vkImageAvailableSemaphore);
    system.handle_error(result == vk.VK_SUCCESS, result);
    result = vk.vkCreateSemaphore(vkDevice, &semaphoreInfo, null, &vkRenderFinishedSemaphore);
    system.handle_error(result == vk.VK_SUCCESS, result);

    result = vk.vkCreateFence(vkDevice, &fenceInfo, null, &vkInFlightFence);
    system.handle_error(result == vk.VK_SUCCESS, result);
}

pub fn vulkan_destroy() void {
    vk.vkDestroySemaphore(vkDevice, vkImageAvailableSemaphore, null);
    vk.vkDestroySemaphore(vkDevice, vkRenderFinishedSemaphore, null);
    vk.vkDestroyFence(vkDevice, vkInFlightFence, null);

    vk.vkDestroyCommandPool(vkDevice, vkCommandPool, null);

    cleanup_swapchain();
    vk_allocator.deinit();

    vk.vkDestroySampler(vkDevice, linear_sampler, null);
    vk.vkDestroySampler(vkDevice, nearest_sampler, null);

    vk.vkDestroyShaderModule(vkDevice, shape_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, shape_frag_shader, null);
    vk.vkDestroyShaderModule(vkDevice, tex_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, tex_frag_shader, null);

    color_2d_pipeline_set.deinit();
    tex_2d_pipeline_set.deinit();

    vk.vkDestroyRenderPass(vkDevice, vkRenderPass, null);

    vk.vkDestroySurfaceKHR(vkInstance, vkSurface, null);

    vk.vkDestroyDevice(vkDevice, null);

    if (vkDebugMessenger != null) vkDestroyDebugUtilsMessengerEXT(vkInstance, vkDebugMessenger, null);
    vk.vkDestroyInstance(vkInstance, null);

    allocator.free(vk_physical_devices);
}

fn cleanup_swapchain() void {
    var i: usize = 0;
    while (i < vk_swapchain_frame_buffers.len) : (i += 1) {
        vk.vkDestroyFramebuffer(vkDevice, vk_swapchain_frame_buffers[i], null);
    }
    allocator.free(vk_swapchain_frame_buffers);
    i = 0;
    while (i < vk_swapchain_image_views.len) : (i += 1) {
        vk.vkDestroyImageView(vkDevice, vk_swapchain_image_views[i], null);
    }
    allocator.free(vk_swapchain_image_views);
    vk.vkDestroySwapchainKHR(vkDevice, vkSwapchain, null);

    allocator.free(formats);
}

fn create_framebuffer() void {
    vk_swapchain_frame_buffers = allocator.alloc(vk.VkFramebuffer, vk_swapchain_image_views.len) catch {
        system.print_error("ERR create_framebuffer.allocator.alloc(vk.VkFramebuffer) OutOfMemory\n", .{});
        unreachable;
    };

    var i: usize = 0;
    while (i < vk_swapchain_image_views.len) : (i += 1) {
        const attachments = [_]vk.VkImageView{vk_swapchain_image_views[i]};
        const frameBufferInfo: vk.VkFramebufferCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = vkRenderPass,
            .attachmentCount = 1,
            .pAttachments = &attachments,
            .width = vkExtent.width,
            .height = vkExtent.height,
            .layers = 1,
        };

        const result = vk.vkCreateFramebuffer(vkDevice, &frameBufferInfo, null, &vk_swapchain_frame_buffers[i]);
        system.handle_error(result == vk.VK_SUCCESS, result);
    }
}

fn create_swapchain_and_imageviews() void {
    var surfaceCap: vk.VkSurfaceCapabilitiesKHR = undefined;
    var result: c_int = undefined;
    var formatCount: u32 = 0;
    result = vk.vkGetPhysicalDeviceSurfaceFormatsKHR(vk_physical_devices[0], vkSurface, &formatCount, null);
    system.handle_error(result == vk.VK_SUCCESS, result);
    system.handle_error(formatCount != 0, 0);

    formats = allocator.alloc(vk.VkSurfaceFormatKHR, formatCount) catch {
        system.print_error("ERR create_swapchain_and_imageviews.allocator.alloc(vk.VkSurfaceFormatKHR) OutOfMemory\n", .{});
        unreachable;
    };
    result = vk.vkGetPhysicalDeviceSurfaceFormatsKHR(vk_physical_devices[0], vkSurface, &formatCount, formats.ptr);
    system.handle_error(result == vk.VK_SUCCESS, result);
    system.handle_error(formatCount != 0, 0);

    var presentModeCount: u32 = 0;
    result = vk.vkGetPhysicalDeviceSurfacePresentModesKHR(vk_physical_devices[0], vkSurface, &presentModeCount, null);
    system.handle_error(result == vk.VK_SUCCESS, result);
    system.handle_error(presentModeCount != 0, 0);

    const presentModes = allocator.alloc(vk.VkPresentModeKHR, presentModeCount) catch {
        system.print_error("ERR create_swapchain_and_imageviews.allocator.alloc(vk.VkPresentModeKHR) OutOfMemory\n", .{});
        unreachable;
    };
    defer allocator.free(presentModes);

    result = vk.vkGetPhysicalDeviceSurfacePresentModesKHR(vk_physical_devices[0], vkSurface, &presentModeCount, presentModes.ptr);
    system.handle_error(result == vk.VK_SUCCESS, result);

    result = vk.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(vk_physical_devices[0], vkSurface, @ptrCast(&surfaceCap));
    system.handle_error(result == vk.VK_SUCCESS, result);

    vkExtent = chooseSwapExtent(surfaceCap);
    format = chooseSwapSurfaceFormat(formats);
    const presentMode = chooseSwapPresentMode(presentModes);

    var imageCount = surfaceCap.minImageCount + 1;
    if (surfaceCap.maxImageCount > 0 and imageCount > surfaceCap.maxImageCount) {
        imageCount = surfaceCap.maxImageCount;
    }

    var swapChainCreateInfo: vk.VkSwapchainCreateInfoKHR = .{ .sType = vk.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR, .surface = vkSurface, .minImageCount = imageCount, .imageFormat = format.format, .imageColorSpace = format.colorSpace, .imageExtent = vkExtent, .imageArrayLayers = 1, .imageUsage = vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT, .presentMode = presentMode, .preTransform = surfaceCap.currentTransform, .compositeAlpha = vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR, .clipped = 1, .oldSwapchain = std.mem.zeroes(vk.VkSwapchainKHR), .imageSharingMode = vk.VK_SHARING_MODE_EXCLUSIVE };

    const queueFamiliesIndices = [_]u32{ graphicsFamilyIndex, presentFamilyIndex };

    if (graphicsFamilyIndex != presentFamilyIndex) {
        swapChainCreateInfo.imageSharingMode = vk.VK_SHARING_MODE_CONCURRENT;
        swapChainCreateInfo.queueFamilyIndexCount = 2;
        swapChainCreateInfo.pQueueFamilyIndices = &queueFamiliesIndices;
    }

    result = vk.vkCreateSwapchainKHR(vkDevice, &swapChainCreateInfo, null, &vkSwapchain);
    system.handle_error(result == vk.VK_SUCCESS, result);

    var swapchain_image_count: u32 = 0;

    result = vk.vkGetSwapchainImagesKHR(vkDevice, vkSwapchain, &swapchain_image_count, null);
    system.handle_error(result == vk.VK_SUCCESS, result);

    const swapchain_images = allocator.alloc(vk.VkImage, swapchain_image_count) catch {
        system.print_error("ERR create_swapchain_and_imageviews.allocator.alloc(vk.VkImage) OutOfMemory\n", .{});
        unreachable;
    };
    defer allocator.free(swapchain_images);

    result = vk.vkGetSwapchainImagesKHR(vkDevice, vkSwapchain, &swapchain_image_count, swapchain_images.ptr);
    system.handle_error(result == vk.VK_SUCCESS, result);

    vk_swapchain_image_views = allocator.alloc(vk.VkImageView, swapchain_image_count) catch {
        system.print_error("ERR create_swapchain_and_imageviews.allocator.alloc(vk.VkImageView) OutOfMemory\n", .{});
        unreachable;
    };

    var i: usize = 0;
    while (i < swapchain_image_count) : (i += 1) {
        const image_view_createInfo: vk.VkImageViewCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO, .image = swapchain_images[i], .viewType = vk.VK_IMAGE_VIEW_TYPE_2D, .format = format.format, .components = .{ .r = vk.VK_COMPONENT_SWIZZLE_IDENTITY, .g = vk.VK_COMPONENT_SWIZZLE_IDENTITY, .b = vk.VK_COMPONENT_SWIZZLE_IDENTITY, .a = vk.VK_COMPONENT_SWIZZLE_IDENTITY }, .subresourceRange = .{ .aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 } };
        result = vk.vkCreateImageView(vkDevice, &image_view_createInfo, null, &vk_swapchain_image_views[i]);
        system.handle_error(result == vk.VK_SUCCESS, result);
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
    system.handle_error(result == vk.VK_SUCCESS, result);

    const begin: vk.VkCommandBufferBeginInfo = .{ .flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT };
    result = vk.vkBeginCommandBuffer(buf, &begin);
    system.handle_error(result == vk.VK_SUCCESS, result);

    return buf;
}
pub fn end_single_time_commands(buf: vk.VkCommandBuffer) void {
    const result = vk.vkEndCommandBuffer(buf);
    system.handle_error(result == vk.VK_SUCCESS, result);
    queue_submit_and_wait(&[_]vk.VkCommandBuffer{buf});
}

pub fn queue_submit_and_wait(bufs: []const vk.VkCommandBuffer) void {
    const submitInfo: vk.VkSubmitInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = bufs.ptr,
    };

    var result = vk.vkQueueSubmit(vkGraphicsQueue, 1, &submitInfo, null);
    system.handle_error(result == vk.VK_SUCCESS, result);
    result = vk.vkQueueWaitIdle(vkGraphicsQueue);
    system.handle_error(result == vk.VK_SUCCESS, result);
}

pub fn copy_buffer_to_image(src_buf: vk.VkBuffer, dst_img: vk.VkImage, width: c_uint, height: c_uint, depth: c_uint) void {
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

pub fn recreate_swapchain(_recreate_window: bool) void {
    if (root.platform == root.XfitPlatform.android and _recreate_window) {
        __android.vulkan_android_recreate_surface(vkInstance, &vkSurface);
    }
    const result = vk.vkDeviceWaitIdle(vkDevice);
    system.handle_error(result == vk.VK_SUCCESS, result);

    cleanup_swapchain();
    create_swapchain_and_imageviews();
    create_framebuffer();
}

pub fn wait_for_fences() void {
    const result = vk.vkWaitForFences(vkDevice, 1, @ptrCast(&vkInFlightFence), vk.VK_TRUE, std.math.maxInt(u64));
    system.handle_error(result == vk.VK_SUCCESS, result);
}

pub fn drawFrame() void {
    wait_for_fences();

    var imageIndex: u32 = undefined;

    var result = vk.vkAcquireNextImageKHR(vkDevice, vkSwapchain, std.math.maxInt(u64), vkImageAvailableSemaphore, std.mem.zeroes(vk.VkFence), &imageIndex);
    if (result == vk.VK_ERROR_OUT_OF_DATE_KHR) {
        recreate_swapchain(false);
        return;
    }
    system.handle_error(!(result != vk.VK_SUCCESS and result != vk.VK_SUBOPTIMAL_KHR), result);

    result = vk.vkResetFences(vkDevice, 1, @ptrCast(&vkInFlightFence));
    system.handle_error(result == vk.VK_SUCCESS, result);

    result = vk.vkResetCommandBuffer(vkCommandBuffer, 0);
    system.handle_error(result == vk.VK_SUCCESS, result);
    recordCommandBuffer(vkCommandBuffer, imageIndex);

    const waitSemaphores = [_]vk.VkSemaphore{vkImageAvailableSemaphore};
    const signalSemaphores = [_]vk.VkSemaphore{vkRenderFinishedSemaphore};
    const waitStages = [_]vk.VkPipelineStageFlags{vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};

    const submitInfo: vk.VkSubmitInfo = .{ .waitSemaphoreCount = 1, .commandBufferCount = 1, .signalSemaphoreCount = 1, .pWaitSemaphores = &waitSemaphores, .pWaitDstStageMask = &waitStages, .pCommandBuffers = &vkCommandBuffer, .pSignalSemaphores = &signalSemaphores };
    result = vk.vkQueueSubmit(vkGraphicsQueue, 1, &submitInfo, vkInFlightFence);
    system.handle_error(result == vk.VK_SUCCESS, result);

    const swapChains = [_]vk.VkSwapchainKHR{vkSwapchain};

    const presentInfo: vk.VkPresentInfoKHR = .{ .sType = vk.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR, .waitSemaphoreCount = 1, .swapchainCount = 1, .pWaitSemaphores = &signalSemaphores, .pSwapchains = &swapChains, .pImageIndices = &imageIndex };

    result = vk.vkQueuePresentKHR(vkPresentQueue, &presentInfo);

    if (result == vk.VK_ERROR_OUT_OF_DATE_KHR or result == vk.VK_SUBOPTIMAL_KHR) {
        recreate_swapchain(false);
    } else {
        system.handle_error(result == vk.VK_SUCCESS, result);
    }
}

pub fn transition_image_layout(image: vk.VkImage, image_info: *vk.VkImageCreateInfo, old_layout: vk.VkImageLayout, new_layout: vk.VkImageLayout) void {
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
            .levelCount = image_info.*.mipLevels,
            .baseArrayLayer = 0,
            .layerCount = image_info.*.arrayLayers,
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
        system.print_error("ERR : unsupported layout transition!\n", .{});
    }

    vk.vkCmdPipelineBarrier(buf, source_stage, destination_stage, 0, 0, null, 0, null, 1, &barrier);

    end_single_time_commands(buf);
}
