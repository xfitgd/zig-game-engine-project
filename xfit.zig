pub const UNICODE = true;

const std = @import("std");

const root = @import("root");

const system = @import("system.zig");
const __system = @import("__system.zig");
const __windows = @import("__windows.zig");
const __vulkan = @import("__vulkan.zig");

pub fn xfit_main(init_setting: *const system.init_setting) void {
    __system.init_set = init_setting.*;

    if (root.platform == root.XfitPlatform.windows) {
        __windows.system_windows_start();
        __windows.windows_start();
        //vulkan_start, root.xfit_init()는 별도의 작업 스레드에서 호출(거기서 렌더링)

        __windows.windows_loop();
    } else if (root.platform == root.XfitPlatform.android) {
        __vulkan.vulkan_start();

        root.xfit_init();
    } else {
        @compileError("not supported platforms");
    }
}
