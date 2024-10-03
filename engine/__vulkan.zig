const std = @import("std");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;

const __windows = @import("__windows.zig");
const __android = @import("__android.zig");
const system = @import("system.zig");
const math = @import("math.zig");
const matrix = math.matrix;
const graphics = @import("graphics.zig");
const render_command = @import("render_command.zig");
const __system = @import("__system.zig");

const __vulkan_allocator = @import("__vulkan_allocator.zig");
pub var vk_allocator: __vulkan_allocator = undefined;

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

pub const pipeline_set = struct {
    pipeline: vk.VkPipeline = null,
    pipelineLayout: vk.VkPipelineLayout = null,
    descriptorSetLayout: vk.VkDescriptorSetLayout = null,

    pub fn deinit(self: *pipeline_set) void {
        if (self.*.pipeline != null) {
            vk.vkDestroyPipeline(vkDevice, self.*.pipeline, null);
            // if (self.*.pipelineLayout != null) { //서로 공유 하는 경우
            //     vk.vkDestroyPipelineLayout(vkDevice, self.*.pipelineLayout, null);
            //     self.*.pipelineLayout = null;
            // }
            // if (self.*.descriptorSetLayout != null) { //서로 공유 하는 경우
            //     vk.vkDestroyDescriptorSetLayout(vkDevice, self.*.descriptorSetLayout, null);
            //     self.*.descriptorSetLayout = null;
            // }
        }
    }
};

//Predefined Pipelines
pub var shape_color_2d_pipeline_set: pipeline_set = .{};
//pub var color_2d_pipeline_set: pipeline_set = .{};
pub var tex_2d_pipeline_set: pipeline_set = .{};
pub var quad_shape_2d_pipeline_set: pipeline_set = .{};
//

fn chooseSwapExtent(capabilities: vk.VkSurfaceCapabilitiesKHR) vk.VkExtent2D {
    if (capabilities.currentExtent.width != std.math.maxInt(u32)) {
        return capabilities.currentExtent;
    } else {
        if (system.platform == .windows) {
            var rect: __windows.RECT = undefined;

            _ = __windows.win32.GetClientRect(__windows.hWnd, &rect);
            var width = @abs(rect.right - rect.left);
            var height = @abs(rect.bottom - rect.top);
            width = std.math.clamp(width, capabilities.minImageExtent.width, capabilities.maxImageExtent.width);
            height = std.math.clamp(height, capabilities.minImageExtent.height, capabilities.maxImageExtent.height);
            return vk.VkExtent2D{ .width = width, .height = height };
        } else if (system.platform == .android) {
            return vk.VkExtent2D{ .width = __android.get_device_width(), .height = __android.get_device_height() };
        } else {
            @compileError("not support platform");
        }
    }
}

fn chooseSwapSurfaceFormat(availableFormats: []vk.VkSurfaceFormatKHR) vk.VkSurfaceFormatKHR {
    for (availableFormats) |value| {
        if (value.format == vk.VK_FORMAT_R8G8B8A8_UNORM) {
            return value;
        }
    }
    return availableFormats[0];
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
pub var vkDevice: vk.VkDevice = undefined;
var vkSurface: vk.VkSurfaceKHR = undefined;
var vkRenderPass: vk.VkRenderPass = undefined;
var vkSwapchain: vk.VkSwapchainKHR = null;

pub var vkCommandPool: vk.VkCommandPool = undefined;
pub var vkCommandBuffer: vk.VkCommandBuffer = undefined;

var vkImageAvailableSemaphore: vk.VkSemaphore = null;
var vkRenderFinishedSemaphore: vk.VkSemaphore = null;

pub var vkInFlightFence: vk.VkFence = null;

var vkDebugMessenger: vk.VkDebugUtilsMessengerEXT = null;

pub var vkGraphicsQueue: vk.VkQueue = undefined;
var vkPresentQueue: vk.VkQueue = undefined;

var vkExtent: vk.VkExtent2D = undefined;
pub var vk_swapchain_frame_buffers: []vk.VkFramebuffer = undefined;
var vk_swapchain_image_views: []vk.VkImageView = undefined;

pub var vk_physical_devices: []vk.VkPhysicalDevice = undefined;

var graphicsFamilyIndex: u32 = std.math.maxInt(u32);
var presentFamilyIndex: u32 = std.math.maxInt(u32);
var queueFamiliesCount: u32 = 0;

var formats: []vk.VkSurfaceFormatKHR = undefined;
var format: vk.VkSurfaceFormatKHR = undefined;

pub var linear_sampler: vk.VkSampler = undefined;
pub var nearest_sampler: vk.VkSampler = undefined;

pub var depth_stencil_image = __vulkan_allocator.vulkan_res_node(.image){};

fn createShaderModule(code: []const u8) vk.VkShaderModule {
    const createInfo: vk.VkShaderModuleCreateInfo = .{ .codeSize = code.len, .pCode = code.ptr };

    var shaderModule: vk.VkShaderModule = undefined;
    const result = vk.vkCreateShaderModule(vkDevice, &createInfo, null, &shaderModule);

    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.createShaderModule.vkCreateShaderModule : {d}", .{result});

    return shaderModule;
}

fn recordCommandBuffer(commandBuffer: *render_command) void {
    if (commandBuffer.*.scene == null or commandBuffer.*.scene.?.len == 0) {
        return;
    }
    var i: usize = 0;
    while (i < get_swapchain_image_lenghth()) : (i += 1) {
        const cmd = if (system.dbg) commandBuffer.*.__command_buffers.? else commandBuffer.*.__command_buffers;
        var result = vk.vkResetCommandBuffer(cmd[i], 0);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.recordCommandBuffer.vkResetCommandBuffer : {d}", .{result});

        const info = vk.VkCommandBufferInheritanceInfo{
            .renderPass = vkRenderPass,
            .framebuffer = null,
            .occlusionQueryEnable = 0,
            .queryFlags = 0,
            .pipelineStatistics = 0,
            .subpass = 0,
        };

        const beginInfo: vk.VkCommandBufferBeginInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .flags = vk.VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT,
            .pInheritanceInfo = &info,
        };

        result = vk.vkBeginCommandBuffer(cmd[i], &beginInfo);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.recordCommandBuffer.vkBeginCommandBuffer : {d}", .{result});

        const viewport: vk.VkViewport = .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(vkExtent.width),
            .height = @floatFromInt(vkExtent.height),
            .maxDepth = 1,
            .minDepth = 0,
        };
        const scissor: vk.VkRect2D = .{ .offset = vk.VkOffset2D{ .x = 0, .y = 0 }, .extent = vkExtent };

        vk.vkCmdSetViewport(cmd[i], 0, 1, @ptrCast(&viewport));
        vk.vkCmdSetScissor(cmd[i], 0, 1, @ptrCast(&scissor));

        for (commandBuffer.scene.?) |value| {
            const ivertices = value.*.get_ivertices(value, 0) orelse continue;
            if (ivertices.*.pipeline == &shape_color_2d_pipeline_set) {
                vk.vkCmdBindDescriptorSets(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, ivertices.*.pipeline.*.pipelineLayout, 0, 1, &value.*.get_descriptor_sets(value, 0), 0, null);
                for (
                    [_]*graphics.ivertices{ivertices},
                    [_]*graphics.iindices{value.*.get_iindices(value, 0).?},
                ) |v, in| {
                    vk.vkCmdBindPipeline(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, v.*.pipeline.*.pipeline);

                    const offsets: vk.VkDeviceSize = 0;
                    vk.vkCmdBindVertexBuffers(cmd[i], 0, 1, &v.*.node.res, &offsets);

                    vk.vkCmdBindIndexBuffer(cmd[i], in.*.node.res, 0, vk.VK_INDEX_TYPE_UINT32);
                    vk.vkCmdDrawIndexed(cmd[i], @intCast(in.*.get_indices_len(in)), 1, 0, 0, 0);
                }
                vk.vkCmdBindPipeline(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, quad_shape_2d_pipeline_set.pipeline);

                vk.vkCmdPushConstants(
                    cmd[i],
                    quad_shape_2d_pipeline_set.pipelineLayout,
                    vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                    0,
                    @sizeOf(math.vector),
                    &@as(*graphics.shape.source, @alignCast(@ptrCast(value.*.get_source(value).?))).*.color,
                );

                vk.vkCmdDraw(cmd[i], 6, 1, 0, 0);

                const extra = @as(?[]*graphics.shape.source, @ptrCast(value.*.get_extra_sources(value)));
                if (extra != null) {
                    if (extra.?.len > 0) vk.vkCmdBindDescriptorSets(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, ivertices.*.pipeline.*.pipelineLayout, 0, 1, &value.*.get_descriptor_sets(value, 0), 0, null);
                    for (extra.?) |src| {
                        for (
                            [_]*graphics.ivertices{&src.*.vertices.interface},
                            [_]*graphics.iindices{&src.*.indices.interface},
                        ) |v, in| {
                            vk.vkCmdBindPipeline(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, v.*.pipeline.*.pipeline);

                            vk.vkCmdBindDescriptorSets(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, v.*.pipeline.*.pipelineLayout, 0, 1, &value.*.get_descriptor_sets(value, 0), 0, null);

                            const offsets: vk.VkDeviceSize = 0;
                            vk.vkCmdBindVertexBuffers(cmd[i], 0, 1, &v.*.node.res, &offsets);

                            vk.vkCmdBindIndexBuffer(cmd[i], in.*.node.res, 0, vk.VK_INDEX_TYPE_UINT32);
                            vk.vkCmdDrawIndexed(cmd[i], @intCast(in.*.get_indices_len(in)), 1, 0, 0, 0);
                        }
                        vk.vkCmdBindPipeline(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, quad_shape_2d_pipeline_set.pipeline);

                        vk.vkCmdPushConstants(
                            cmd[i],
                            quad_shape_2d_pipeline_set.pipelineLayout,
                            vk.VK_SHADER_STAGE_FRAGMENT_BIT,
                            0,
                            @sizeOf(math.vector),
                            &src.*.color,
                        );

                        vk.vkCmdDraw(cmd[i], 6, 1, 0, 0);
                    }
                }
            } else {
                vk.vkCmdBindPipeline(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, ivertices.*.pipeline.*.pipeline);

                vk.vkCmdBindDescriptorSets(cmd[i], vk.VK_PIPELINE_BIND_POINT_GRAPHICS, ivertices.*.pipeline.*.pipelineLayout, 0, 1, &value.*.get_descriptor_sets(value, 0), 0, null);

                const offsets: vk.VkDeviceSize = 0;
                vk.vkCmdBindVertexBuffers(cmd[i], 0, 1, &ivertices.*.node.res, &offsets);

                const iindices = value.*.get_iindices(value, 0);
                if (iindices != null) {
                    vk.vkCmdBindIndexBuffer(cmd[i], iindices.?.*.node.res, 0, switch (iindices.?.*.idx_type) {
                        .U16 => vk.VK_INDEX_TYPE_UINT16,
                        .U32 => vk.VK_INDEX_TYPE_UINT32,
                    });
                    vk.vkCmdDrawIndexed(cmd[i], @intCast(iindices.?.*.get_indices_len(iindices.?)), 1, 0, 0, 0);
                } else {
                    vk.vkCmdDraw(cmd[i], @intCast(ivertices.*.get_vertices_len(ivertices)), 1, 0, 0);
                }
            }
        }

        result = vk.vkEndCommandBuffer(cmd[i]);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.recordCommandBuffer.vkEndCommandBuffer : {d}", .{result});
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

    system.print("{s}\n\n", .{pCallbackData.?.*.pMessage});

    return vk.VK_FALSE;
}

pub fn vulkan_start() void {
    vk_allocator = __vulkan_allocator.init();
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

    if (system.platform == .windows) {
        if (builtin.mode == std.builtin.OptimizeMode.Debug) {
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
        extension_names.append(vk.VK_KHR_WIN32_SURFACE_EXTENSION_NAME) catch |e| system.handle_error3("vulkan_start.extension_names.append(vk.VK_KHR_WIN32_SURFACE_EXTENSION_NAME)", e);
    } else if (system.platform == .android) {
        extension_names.append(vk.VK_KHR_ANDROID_SURFACE_EXTENSION_NAME) catch |e| system.handle_error3("vulkan_start.extension_names.append(vk.VK_KHR_ANDROID_SURFACE_EXTENSION_NAME)", e);
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
    vk_physical_devices = __system.allocator.alloc(vk.VkPhysicalDevice, deviceCount) catch
        system.handle_error_msg2("vulkan_start.allocator.alloc(vk.VkPhysicalDevice) OutOfMemory");

    result = vk.vkEnumeratePhysicalDevices(vkInstance, &deviceCount, vk_physical_devices.ptr);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkEnumeratePhysicalDevices vk_physical_devices.ptr : {d}", .{result});

    vk.vkGetPhysicalDeviceQueueFamilyProperties(vk_physical_devices[0], &queueFamiliesCount, null);
    system.handle_error(queueFamiliesCount != 0, "__vulkan.vulkan_start.queueFamiliesCount 0", .{});

    const queueFamilies = __system.allocator.alloc(vk.VkQueueFamilyProperties, queueFamiliesCount) catch
        system.handle_error_msg2("vulkan_start.allocator.alloc(vk.VkQueueFamilyProperties) OutOfMemory");
    defer __system.allocator.free(queueFamilies);

    vk.vkGetPhysicalDeviceQueueFamilyProperties(vk_physical_devices[0], &queueFamiliesCount, queueFamilies.ptr);

    var i: u32 = 0;
    while (i < queueFamiliesCount) : (i += 1) {
        if ((queueFamilies[i].queueFlags & vk.VK_QUEUE_GRAPHICS_BIT) != 0) {
            graphicsFamilyIndex = i;
        }
        var presentSupport: vk.VkBool32 = 0;
        result = vk.vkGetPhysicalDeviceSurfaceSupportKHR(vk_physical_devices[0], i, vkSurface, &presentSupport);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkGetPhysicalDeviceSurfaceSupportKHR : {d}", .{result});

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
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDevice : {d}", .{result});

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
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateSampler linear_sampler : {d}", .{result});

    sampler_info.mipmapMode = vk.VK_SAMPLER_MIPMAP_MODE_NEAREST;
    result = vk.vkCreateSampler(vkDevice, &sampler_info, null, &nearest_sampler);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateSampler nearest_sampler : {d}", .{result});

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
    //_ = colorAlphaBlending;

    const colorAttachment: vk.VkAttachmentDescription = .{
        .format = format.format,
        .samples = vk.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .stencilStoreOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
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

    const dependency: vk.VkSubpassDependency = .{
        .srcSubpass = vk.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .srcAccessMask = 0,
        .dstStageMask = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
    };

    const renderPassInfo: vk.VkRenderPassCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = 2,
        .pAttachments = &[_]vk.VkAttachmentDescription{ colorAttachment, depthAttachment },
        .subpassCount = 1,
        .pSubpasses = &[_]vk.VkSubpassDescription{subpass},
        .pDependencies = &dependency,
        .dependencyCount = 1,
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

    //const shape_shader_stages = create_shader_state(shape_vert_shader, shape_frag_shader);
    const shape_curve_shader_stages = create_shader_state(shape_curve_vert_shader, shape_curve_frag_shader);
    const quad_shape_shader_stages = create_shader_state(quad_shape_vert_shader, quad_shape_frag_shader);
    const tex_shader_stages = create_shader_state(tex_vert_shader, tex_frag_shader);

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

        const pushRange = vk.VkPushConstantRange{
            .offset = 0,
            .size = @sizeOf(math.vector),
            .stageFlags = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
        };

        const pipelineLayoutInfo: vk.VkPipelineLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 1,
            .pSetLayouts = &quad_shape_2d_pipeline_set.descriptorSetLayout,
            .pushConstantRangeCount = 1,
            .pPushConstantRanges = &pushRange,
        };

        result = vk.vkCreatePipelineLayout(vkDevice, &pipelineLayoutInfo, null, &quad_shape_2d_pipeline_set.pipelineLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreatePipelineLayout quad_shape_shader_stages.pipelineLayout : {d}", .{result});

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

        result = vk.vkCreateGraphicsPipelines(vkDevice, std.mem.zeroes(vk.VkPipelineCache), 1, &pipelineInfo, null, &quad_shape_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateGraphicsPipelines quad_shape_2d_pipeline_set.pipeline : {d}", .{result});
    }
    //create_shape_color_2d_pipeline
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

        result = vk.vkCreateGraphicsPipelines(vkDevice, std.mem.zeroes(vk.VkPipelineCache), 1, &pipelineInfo, null, &shape_color_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateGraphicsPipelines shape_color_2d_pipeline_set.pipeline : {d}", .{result});
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
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateDescriptorSetLayout tex_2d_pipeline_set.descriptorSetLayout : {d}", .{result});

        const pipelineLayoutInfo: vk.VkPipelineLayoutCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 1,
            .pSetLayouts = &tex_2d_pipeline_set.descriptorSetLayout,
            .pushConstantRangeCount = 0,
            .pPushConstantRanges = null,
        };

        result = vk.vkCreatePipelineLayout(vkDevice, &pipelineLayoutInfo, null, &tex_2d_pipeline_set.pipelineLayout);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreatePipelineLayout tex_2d_pipeline_set.pipelineLayout : {d}", .{result});

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
            .pStages = &tex_shader_stages,
            .pVertexInputState = &vertexInputInfo,
            .pInputAssemblyState = &inputAssembly,
            .pViewportState = &viewportState,
            .pRasterizationState = &rasterizer,
            .pMultisampleState = &multisampling,
            .pDepthStencilState = &depthStencilState,
            .pColorBlendState = &colorBlending,
            .pDynamicState = &dynamicState,
            .layout = tex_2d_pipeline_set.pipelineLayout,
            .renderPass = vkRenderPass,
            .subpass = 0,
            .basePipelineHandle = null,
            .basePipelineIndex = -1,
        };

        result = vk.vkCreateGraphicsPipelines(vkDevice, std.mem.zeroes(vk.VkPipelineCache), 1, &pipelineInfo, null, &tex_2d_pipeline_set.pipeline);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateGraphicsPipelines tex_2d_pipeline_set.pipeline : {d}", .{result});
    }

    create_framebuffer();

    const poolInfo: vk.VkCommandPoolCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = graphicsFamilyIndex,
    };

    result = vk.vkCreateCommandPool(vkDevice, &poolInfo, null, &vkCommandPool);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateCommandPool vkCommandPool : {d}", .{result});

    const allocInfo: vk.VkCommandBufferAllocateInfo = .{
        .commandPool = vkCommandPool,
        .level = vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = 1,
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
    };

    result = vk.vkAllocateCommandBuffers(vkDevice, &allocInfo, @ptrCast(&vkCommandBuffer));
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkAllocateCommandBuffers vkCommandPool : {d}", .{result});

    const semaphoreInfo: vk.VkSemaphoreCreateInfo = .{ .sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO };
    const fenceInfo: vk.VkFenceCreateInfo = .{ .flags = vk.VK_FENCE_CREATE_SIGNALED_BIT, .sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO };

    result = vk.vkCreateSemaphore(vkDevice, &semaphoreInfo, null, &vkImageAvailableSemaphore);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateSemaphore vkImageAvailableSemaphore : {d}", .{result});
    result = vk.vkCreateSemaphore(vkDevice, &semaphoreInfo, null, &vkRenderFinishedSemaphore);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateSemaphore vkRenderFinishedSemaphore : {d}", .{result});

    result = vk.vkCreateFence(vkDevice, &fenceInfo, null, &vkInFlightFence);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.vulkan_start.vkCreateFence vkInFlightFence : {d}", .{result});
}

pub fn vulkan_destroy() void {
    vk.vkDestroySemaphore(vkDevice, vkImageAvailableSemaphore, null);
    vk.vkDestroySemaphore(vkDevice, vkRenderFinishedSemaphore, null);
    vk.vkDestroyFence(vkDevice, vkInFlightFence, null);
    vkInFlightFence = null;

    vk.vkDestroyCommandPool(vkDevice, vkCommandPool, null);

    cleanup_swapchain();
    vk_allocator.deinit();

    vk.vkDestroySampler(vkDevice, linear_sampler, null);
    vk.vkDestroySampler(vkDevice, nearest_sampler, null);

    // vk.vkDestroyShaderModule(vkDevice, shape_vert_shader, null);
    // vk.vkDestroyShaderModule(vkDevice, shape_frag_shader, null);
    vk.vkDestroyShaderModule(vkDevice, quad_shape_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, quad_shape_frag_shader, null);
    vk.vkDestroyShaderModule(vkDevice, shape_curve_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, shape_curve_frag_shader, null);
    vk.vkDestroyShaderModule(vkDevice, tex_vert_shader, null);
    vk.vkDestroyShaderModule(vkDevice, tex_frag_shader, null);

    shape_color_2d_pipeline_set.deinit();
    quad_shape_2d_pipeline_set.deinit();
    //color_2d_pipeline_set.deinit();
    tex_2d_pipeline_set.deinit();

    vk.vkDestroyPipelineLayout(vkDevice, quad_shape_2d_pipeline_set.pipelineLayout, null);
    vk.vkDestroyDescriptorSetLayout(vkDevice, quad_shape_2d_pipeline_set.descriptorSetLayout, null);

    vk.vkDestroyPipelineLayout(vkDevice, shape_color_2d_pipeline_set.pipelineLayout, null);
    vk.vkDestroyDescriptorSetLayout(vkDevice, shape_color_2d_pipeline_set.descriptorSetLayout, null);

    vk.vkDestroyPipelineLayout(vkDevice, tex_2d_pipeline_set.pipelineLayout, null);
    vk.vkDestroyDescriptorSetLayout(vkDevice, tex_2d_pipeline_set.descriptorSetLayout, null);

    vk.vkDestroyRenderPass(vkDevice, vkRenderPass, null);

    vk.vkDestroySurfaceKHR(vkInstance, vkSurface, null);

    vk.vkDestroyDevice(vkDevice, null);

    if (vkDebugMessenger != null) vkDestroyDebugUtilsMessengerEXT(vkInstance, vkDebugMessenger, null);
    vk.vkDestroyInstance(vkInstance, null);

    __system.allocator.free(vk_physical_devices);
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
        .extent = .{ .width = vkExtent.width, .height = vkExtent.height, .depth = 1 },
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
    vk_allocator.create_image(&img_info, &depth_stencil_image, null, 0);

    var i: usize = 0;
    while (i < vk_swapchain_image_views.len) : (i += 1) {
        const attachments = [_]vk.VkImageView{ vk_swapchain_image_views[i], depth_stencil_image.__image_view };
        var frameBufferInfo: vk.VkFramebufferCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = vkRenderPass,
            .attachmentCount = 2,
            .pAttachments = &attachments,
            .width = vkExtent.width,
            .height = vkExtent.height,
            .layers = 1,
        };

        const result = vk.vkCreateFramebuffer(vkDevice, &frameBufferInfo, null, &vk_swapchain_frame_buffers[i]);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_framebuffer vkCreateFramebuffer vk_swapchain_frame_buffers : {d}", .{result});
    }
}

fn create_swapchain_and_imageviews() void {
    var surfaceCap: vk.VkSurfaceCapabilitiesKHR = undefined;
    var result: c_int = undefined;
    var formatCount: u32 = 0;
    result = vk.vkGetPhysicalDeviceSurfaceFormatsKHR(vk_physical_devices[0], vkSurface, &formatCount, null);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfaceFormatsKHR : {d}", .{result});
    system.handle_error_msg(formatCount != 0, "__vulkan.create_swapchain_and_imageviews.formatCount 0");

    formats = __system.allocator.alloc(vk.VkSurfaceFormatKHR, formatCount) catch
        system.handle_error_msg2("create_swapchain_and_imageviews.allocator.alloc(vk.VkSurfaceFormatKHR) OutOfMemory");

    result = vk.vkGetPhysicalDeviceSurfaceFormatsKHR(vk_physical_devices[0], vkSurface, &formatCount, formats.ptr);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfaceFormatsKHR formats.ptr : {d}", .{result});
    system.handle_error_msg(formatCount != 0, "__vulkan.create_swapchain_and_imageviews.formatCount 0(2)");

    var presentModeCount: u32 = 0;
    result = vk.vkGetPhysicalDeviceSurfacePresentModesKHR(vk_physical_devices[0], vkSurface, &presentModeCount, null);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfacePresentModesKHR : {d}", .{result});
    system.handle_error_msg(presentModeCount != 0, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfacePresentModesKHR presentModeCount 0");

    const presentModes = __system.allocator.alloc(vk.VkPresentModeKHR, presentModeCount) catch {
        system.handle_error_msg2("create_swapchain_and_imageviews.allocator.alloc(vk.VkPresentModeKHR) OutOfMemory");
    };
    defer __system.allocator.free(presentModes);

    result = vk.vkGetPhysicalDeviceSurfacePresentModesKHR(vk_physical_devices[0], vkSurface, &presentModeCount, presentModes.ptr);
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfacePresentModesKHR presentModes.ptr : {d}", .{result});

    result = vk.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(vk_physical_devices[0], vkSurface, @ptrCast(&surfaceCap));
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.create_swapchain_and_imageviews.vkGetPhysicalDeviceSurfaceCapabilitiesKHR : {d}", .{result});

    vkExtent = chooseSwapExtent(surfaceCap);
    if (vkExtent.width <= 0 or vkExtent.height <= 0) {
        __system.allocator.free(formats);
        return;
    }
    format = chooseSwapSurfaceFormat(formats);
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
        .imageExtent = vkExtent,
        .imageArrayLayers = 1,
        .imageUsage = vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .presentMode = presentMode,
        .preTransform = surfaceCap.currentTransform,
        .compositeAlpha = vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .clipped = 1,
        .oldSwapchain = std.mem.zeroes(vk.VkSwapchainKHR),
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

pub fn get_swapchain_image_lenghth() usize {
    return vk_swapchain_image_views.len;
}

pub fn recreate_swapchain(_recreate_window: bool) void {
    if (system.platform == .android and _recreate_window) {
        __android.vulkan_android_recreate_surface(vkInstance, &vkSurface);
    }
    wait_device_idle();

    cleanup_swapchain();
    create_swapchain_and_imageviews();
    if (vkExtent.width <= 0 or vkExtent.height <= 0) return;
    create_framebuffer();
}

pub var render_mutex: std.Thread.Mutex = .{};

pub fn drawFrame() void {
    var imageIndex: u32 = undefined;

    if (vkExtent.width <= 0 or vkExtent.height <= 0) {
        recreate_swapchain(false);
        if (vkExtent.width <= 0 or vkExtent.height <= 0) return;
    }

    if (graphics.render_commands != null) {
        var result = vk.vkAcquireNextImageKHR(vkDevice, vkSwapchain, std.math.maxInt(u64), vkImageAvailableSemaphore, null, &imageIndex);
        if (result == vk.VK_ERROR_OUT_OF_DATE_KHR) {
            recreate_swapchain(false);
            return;
        }
        system.handle_error(!(result != vk.VK_SUCCESS and result != vk.VK_SUBOPTIMAL_KHR), "__vulkan.drawFrame.vkAcquireNextImageKHR : {d}", .{result});

        var cmds = ArrayList(vk.VkCommandBuffer).init(__system.allocator);
        defer cmds.deinit();

        render_mutex.lock(); // command 기록 중에 값이 바뀌면 안된다.
        for (graphics.render_commands.?) |v| {
            if (@atomicLoad(bool, &v.*.__refesh, .monotonic)) {
                @atomicStore(bool, &v.*.__refesh, false, .monotonic);
                recordCommandBuffer(v);
            } else if (v.*.__refresh_framebuffer != vk_swapchain_frame_buffers[0]) { //TODO https://nvpro-samples.github.io/vk_inherited_viewport/docs/inherited.md.html 하면 안해도됨.
                v.*.__refresh_framebuffer = vk_swapchain_frame_buffers[0];
                recordCommandBuffer(v);
            }
            cmds.append(if (system.dbg) v.*.__command_buffers.?[imageIndex] else v.*.__command_buffers[imageIndex]) catch system.handle_error_msg2("__vulkan.drawFrame cmds.append");
        }
        render_mutex.unlock();

        const clearColor: vk.VkClearValue = .{ .color = .{ .float32 = .{ 0, 0, 0, 0 } } };
        const clearDeathStencil: vk.VkClearValue = .{ .depthStencil = .{ .stencil = 0, .depth = 0 } };

        const renderPassInfo: vk.VkRenderPassBeginInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
            .renderPass = vkRenderPass,
            .framebuffer = vk_swapchain_frame_buffers[imageIndex],
            .renderArea = .{ .offset = .{ .x = 0, .y = 0 }, .extent = vkExtent },
            .clearValueCount = 2,
            .pClearValues = &[_]vk.VkClearValue{ clearColor, clearDeathStencil },
        };

        const beginInfo: vk.VkCommandBufferBeginInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .flags = 0,
            .pInheritanceInfo = null,
        };

        result = vk.vkBeginCommandBuffer(vkCommandBuffer, &beginInfo);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.drawFrame.vkBeginCommandBuffer : {d}", .{result});

        vk.vkCmdBeginRenderPass(vkCommandBuffer, &renderPassInfo, vk.VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS);

        vk.vkCmdExecuteCommands(vkCommandBuffer, @intCast(cmds.items.len), cmds.items.ptr);

        vk.vkCmdEndRenderPass(vkCommandBuffer);

        result = vk.vkEndCommandBuffer(vkCommandBuffer);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.drawFrame.vkEndCommandBuffer : {d}", .{result});

        const waitStages: u32 = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        const submitInfo: vk.VkSubmitInfo = .{
            .waitSemaphoreCount = 1,
            .commandBufferCount = 1,
            .signalSemaphoreCount = 1,
            .pWaitSemaphores = &vkImageAvailableSemaphore,
            .pWaitDstStageMask = &waitStages,
            .pCommandBuffers = &vkCommandBuffer,
            .pSignalSemaphores = &vkRenderFinishedSemaphore,
        };
        render_mutex.lock(); // vkInFlightFence 동기화
        result = vk.vkResetFences(vkDevice, 1, &vkInFlightFence);
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.drawFrame.vkResetFences : {d}", .{result});

        result = vk.vkQueueSubmit(vkGraphicsQueue, 1, &submitInfo, vkInFlightFence);

        render_mutex.unlock();
        system.handle_error(result == vk.VK_SUCCESS, "__vulkan.drawFrame.vkQueueSubmit : {d}", .{result});

        const swapChains = [_]vk.VkSwapchainKHR{vkSwapchain};

        const presentInfo: vk.VkPresentInfoKHR = .{
            .sType = vk.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = 1,
            .swapchainCount = 1,
            .pWaitSemaphores = &vkRenderFinishedSemaphore,
            .pSwapchains = &swapChains,
            .pImageIndices = &imageIndex,
        };

        wait_for_fences();

        result = vk.vkQueuePresentKHR(vkPresentQueue, &presentInfo);

        if (result == vk.VK_ERROR_OUT_OF_DATE_KHR or result == vk.VK_SUBOPTIMAL_KHR) {
            recreate_swapchain(false);
        } else {
            system.handle_error(result == vk.VK_SUCCESS, "__vulkan.drawFrame.vkQueuePresentKHR : {d}", .{result});
        }
    }
}

pub fn wait_for_fences() void {
    const result = vk.vkWaitForFences(vkDevice, 1, &vkInFlightFence, vk.VK_TRUE, std.math.maxInt(u64));
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.wait_for_fences.vkWaitForFences : {d}", .{result});
}

pub fn wait_device_idle() void {
    const result = vk.vkDeviceWaitIdle(vkDevice);
    if (result != vk.VK_SUCCESS) system.print_error("__vulkan.vkDeviceWaitIdle : {d}", .{result});
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
        system.handle_error_msg2("__vulkan.transition_image_layout unsupported layout transition!");
    }

    vk.vkCmdPipelineBarrier(buf, source_stage, destination_stage, 0, 0, null, 0, null, 1, &barrier);

    end_single_time_commands(buf);
}
