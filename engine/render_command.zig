const std = @import("std");

const system = @import("system.zig");
const __system = @import("__system.zig");

const dbg = system.dbg;

const __vulkan_allocator = @import("__vulkan_allocator.zig");

const _allocator = __system.allocator;

const __vulkan = @import("__vulkan.zig");
const vk = __vulkan.vk;

const graphics = @import("graphics.zig");

__refesh: bool = false,
__command_buffers: if (dbg) ?[]vk.VkCommandBuffer else []vk.VkCommandBuffer = if (dbg) null else undefined,
__refresh_framebuffer: vk.VkFramebuffer = undefined,
scene: ?[]*graphics.iobject = null,
const Self = @This();

pub fn init() Self {
    const self = Self{
        .__refresh_framebuffer = __vulkan.vk_swapchain_frame_buffers[0],
        .__command_buffers = __system.allocator.alloc(vk.VkCommandBuffer, __vulkan.get_swapchain_image_lenghth()) catch |e| system.handle_error3("render_command alloc", e),
    };
    const allocInfo: vk.VkCommandBufferAllocateInfo = .{
        .commandPool = __vulkan.vkCommandPool,
        .level = vk.VK_COMMAND_BUFFER_LEVEL_SECONDARY,
        .commandBufferCount = @intCast(__vulkan.get_swapchain_image_lenghth()),
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
    };

    const result = vk.vkAllocateCommandBuffers(
        __vulkan.vkDevice,
        &allocInfo,
        if (dbg) self.__command_buffers.?.ptr else self.__command_buffers.ptr,
    );
    system.handle_error(result == vk.VK_SUCCESS, "render_command vkAllocateCommandBuffers vkCommandPool : {d}", .{result});

    return self;
}
pub fn deinit(self: *Self) void {
    if (dbg and self.*.__command_buffers == null) system.handle_error_msg2("render command.free cant null commandbuffer free");
    vk.vkFreeCommandBuffers(__vulkan.vkDevice, __vulkan.vkCommandPool, @intCast(__vulkan.get_swapchain_image_lenghth()), if (dbg) self.__command_buffers.?.ptr else self.__command_buffers.ptr);
    __system.allocator.free(if (dbg) self.__command_buffers.? else self.*.__command_buffers);

    if (dbg) self.*.__command_buffers = null;
}

///render_command안의 scene(구성)이 바뀔때 마다 호출(scene 내의 iobject 내부 리소스 값이 바뀔경우는 해당없음)
pub fn refresh(self: *Self) void {
    if (dbg and self.*.__command_buffers == null) system.handle_error_msg2("render command.refresh commandbuffer null");
    @atomicStore(bool, &self.*.__refesh, true, .release);
}

const ERROR = error{IsDestroying};

pub fn lock_for_update() ERROR!void {
    __vulkan.render_mutex.lock();
    if (__vulkan.vkInFlightFence == null) {
        return ERROR.IsDestroying;
    }
    const result = vk.vkWaitForFences(__vulkan.vkDevice, 1, &__vulkan.vkInFlightFence, vk.VK_TRUE, std.math.maxInt(u64));
    system.handle_error(result == vk.VK_SUCCESS, "__vulkan.wait_for_fences.vkWaitForFences : {d}", .{result});
}

pub fn unlock_for_update() void {
    __vulkan.render_mutex.unlock();
}
