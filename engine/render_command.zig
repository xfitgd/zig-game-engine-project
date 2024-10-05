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
__command_buffers: []vk.VkCommandBuffer,
__refresh_framebuffer: vk.VkFramebuffer = undefined,
scene: ?[]*graphics.iobject = null,
const Self = @This();

pub fn init() Self {
    const self = Self{
        .__refresh_framebuffer = __vulkan.vk_swapchain_frame_buffers[0],
        .__command_buffers = __system.allocator.alloc(vk.VkCommandBuffer, __vulkan.get_swapchain_image_length()) catch
            system.handle_error_msg2("render_command.__command_buffers.alloc"),
    };
    const allocInfo: vk.VkCommandBufferAllocateInfo = .{
        .commandPool = __vulkan.vkCommandPool,
        .level = vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = @intCast(__vulkan.get_swapchain_image_length()),
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
    };

    const result = vk.vkAllocateCommandBuffers(
        __vulkan.vkDevice,
        &allocInfo,
        self.__command_buffers.ptr,
    );
    system.handle_error(result == vk.VK_SUCCESS, "render_command vkAllocateCommandBuffers vkCommandPool : {d}", .{result});

    return self;
}
pub fn deinit(self: *Self) void {
    vk.vkFreeCommandBuffers(__vulkan.vkDevice, __vulkan.vkCommandPool, @intCast(__vulkan.get_swapchain_image_length()), self.__command_buffers.ptr);
    __system.allocator.free(self.__command_buffers);
}

///render_command안의 scene(구성)이 바뀔때 마다 호출(scene 내의 iobject 내부 리소스 값이 바뀔경우는 해당없음)
pub fn refresh(self: *Self) void {
    @atomicStore(bool, &self.*.__refesh, true, .monotonic); //__refesh를 읽는 렌더링 부분은 이미 뮤텍스에 감싸져 있음
}

const ERROR = error{IsDestroying};

pub fn lock_for_update() ERROR!void {
    if (system.exiting()) return ERROR.IsDestroying;

    __vulkan.render_rwlock.lock();
}

pub fn unlock_for_update() void {
    __vulkan.render_rwlock.unlock();
}
