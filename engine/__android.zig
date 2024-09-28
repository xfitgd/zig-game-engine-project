const std = @import("std");
const expect = std.testing.expect;

const root = @import("root");
const __vulkan = @import("__vulkan.zig");

const system = @import("system.zig");
const __system = @import("__system.zig");

pub const c_allocator = std.heap.c_allocator;

pub const android = @import("include/android.zig");

inline fn LOGI(fmt: [*c]const u8, args: anytype) c_int {
    return @call(.auto, android.__android_log_print, .{ android.ANDROID_LOG_INFO, "xfit", fmt } ++ args);
}
pub inline fn LOGE(fmt: [*c]const u8, args: anytype) c_int {
    return @call(.auto, android.__android_log_print, .{ android.ANDROID_LOG_ERROR, "xfit", fmt } ++ args);
}
inline fn LOGW(fmt: [*c]const u8, args: anytype) c_int {
    return @call(.auto, android.__android_log_print, .{ android.ANDROID_LOG_WARN, "xfit", fmt } ++ args);
}
pub inline fn LOGV(fmt: [*c]const u8, args: anytype) c_int {
    return @call(.auto, android.__android_log_print, .{ android.ANDROID_LOG_VERBOSE, "xfit", fmt } ++ args);
}
pub inline fn LOGD(fmt: [*c]const u8, args: anytype) c_int {
    return @call(.auto, android.__android_log_print, .{ android.ANDROID_LOG_DEBUG, "xfit", fmt } ++ args);
}

const LooperEvent = enum(i32) {
    LOOPER_ID_MAIN = 1,
    LOOPER_ID_INPUT = 2,
    LOOPER_ID_USER = 3,
};

const AppEvent = enum(i8) {
    APP_CMD_INPUT_CHANGED,
    APP_CMD_INIT_WINDOW,
    APP_CMD_TERM_WINDOW,
    APP_CMD_WINDOW_RESIZED,
    APP_CMD_WINDOW_REDRAW_NEEDED,
    APP_CMD_CONTENT_RECT_CHANGED,
    APP_CMD_GAINED_FOCUS,
    APP_CMD_LOST_FOCUS,
    APP_CMD_CONFIG_CHANGED,
    APP_CMD_LOW_MEMORY,
    APP_CMD_START,
    APP_CMD_RESUME,
    APP_CMD_SAVE_STATE,
    APP_CMD_PAUSE,
    APP_CMD_STOP,
    APP_CMD_DESTROY,
};

const android_poll_source = struct {
    id: i32,
    process: ?*const fn (?*android_poll_source) void,
};

const saved_state = struct {
    angle: f32 = 0,
    x: i32 = 0,
    y: i32 = 0,
};

const android_app = struct {
    userdata: ?*anyopaque = null,
    on_app_cmd: ?*const fn (AppEvent) void = null,
    on_input_event: ?*const fn (?*android.AInputEvent) i32 = null,
    activity: ?*android.ANativeActivity = null,
    config: ?*android.AConfiguration = null,
    savedState: ?[]u8 = null,
    savedStateSize: usize = 0,
    looper: ?*android.ALooper = null,
    input_queue: ?*android.AInputQueue = null,
    window: ?*android.ANativeWindow = null,
    contentRect: android.ARect = std.mem.zeroes(android.ARect),
    activityState: AppEvent = AppEvent.APP_CMD_INPUT_CHANGED,
    destroryRequested: bool = false,
    msgread: i32 = 0,
    msgwrite: i32 = 0,

    cache_dir: ?[]u8 = null,

    cmd_poll_source: android_poll_source = std.mem.zeroes(android_poll_source),
    input_poll_source: android_poll_source = std.mem.zeroes(android_poll_source),

    running: bool = false,
    stateSaved: bool = false,
    destroyed: bool = false,
    pendingInputQueue: ?*android.AInputQueue = null,
    pendingWindow: ?*android.ANativeWindow = null,
    pendingContentRect: android.ARect = std.mem.zeroes(android.ARect),

    thread: std.Thread = undefined,
    mutex: std.Thread.Mutex = .{},
    cond: std.Thread.Condition = .{},

    sensor_manager: ?*android.ASensorManager = null,
    accelerometer_sensor: ?*const android.ASensor = null,
    sensor_event_queue: ?*android.ASensorEventQueue = null,

    width: i32 = 0,
    height: i32 = 0,
    savedata: saved_state = std.mem.zeroes(saved_state),

    inited: bool = false,
    paused: bool = false,
};

var app: android_app = .{};

pub fn get_AssetManager() ?*android.AAssetManager {
    return app.activity.?.*.assetManager;
}

pub fn vulkan_android_start(vkInstance: __vulkan.vk.VkInstance, vkSurface: *__vulkan.vk.VkSurfaceKHR) void {
    const androidSurfaceCreateInfo: __vulkan.vk.VkAndroidSurfaceCreateInfoKHR = .{ .window = @ptrCast(app.window), .flags = 0 };
    const result = __vulkan.vk.vkCreateAndroidSurfaceKHR(@ptrCast(vkInstance), &androidSurfaceCreateInfo, null, @ptrCast(vkSurface));

    system.handle_error(result == __vulkan.vk.VK_SUCCESS, "vkCreateAndroidSurfaceKHR code : {d}", .{result});
}

pub fn vulkan_android_recreate_surface(vkInstance: __vulkan.vk.VkInstance, vkSurface: *__vulkan.vk.VkSurfaceKHR) void {
    __vulkan.vk.vkDestroySurfaceKHR(@ptrCast(vkInstance), @as(*__vulkan.vk.VkSurfaceKHR, @ptrCast(vkSurface)).*, null);

    vulkan_android_start(vkInstance, vkSurface);
}

fn init_android() void {
    root.main();
}

fn draw_android() void {
    __system.loop();
}

fn destroy_android() void {
    __vulkan.wait_for_fences();
    root.xfit_destroy();
    __vulkan.vulkan_destroy();

    __system.destroy();
}

fn android_app_write_cmd(cmd: AppEvent) void {
    const _cmd = [_]i8{@intFromEnum(cmd)};
    _ = std.posix.write(app.msgwrite, @ptrCast(&_cmd)) catch |e| system.handle_error3("android_app_write_cmd std.posix.write", e);
}

fn onConfigurationChanged(_activity: [*c]android.ANativeActivity) callconv(.C) void {
    _ = LOGV("ConfigurationChanged: %p", .{_activity});
    android_app_write_cmd(AppEvent.APP_CMD_CONFIG_CHANGED);
}

pub fn get_device_width() u32 {
    const width = android.ANativeWindow_getWidth(app.window);
    return @max(0, width);
}
pub fn get_device_height() u32 {
    const height = android.ANativeWindow_getHeight(app.window);
    return @max(0, height);
}
pub fn get_cache_dir() []const u8 {
    return app.cache_dir orelse system.handle_error_msg2("get_cache_dir null");
}
pub fn get_file_dir() []const u8 {
    if (app.activity.?.*.internalDataPath == null) system.handle_error_msg2("get_file_dir null");
    return app.activity.?.*.internalDataPath[0..std.mem.len(app.activity.?.*.internalDataPath)];
}

fn onSaveInstanceState(_activity: [*c]android.ANativeActivity, _out_len: [*c]usize) callconv(.C) ?*anyopaque {
    _ = LOGV("SaveInstanceState: %p", .{_activity});

    var savedState: ?*anyopaque = null;

    app.mutex.lock();
    app.stateSaved = false;
    android_app_write_cmd(AppEvent.APP_CMD_SAVE_STATE);
    while (!app.stateSaved) {
        app.cond.wait(&app.mutex);
    }
    if (app.savedState != null) {
        savedState = @ptrCast(app.savedState);
        _out_len.* = app.savedStateSize;
        app.savedState = null;
        app.savedStateSize = 0;
    }
    app.mutex.unlock();

    return savedState;
}
fn onContentRectChanged(_activity: [*c]android.ANativeActivity, _rect: [*c]const android.ARect) callconv(.C) void {
    _ = _activity;
    _ = LOGV("ContentRectChanged: l=%d,t=%d,r=%d,b=%d", .{ _rect.*.left, _rect.*.top, _rect.*.right, _rect.*.bottom });

    app.mutex.lock();
    app.contentRect = _rect.*;
    app.mutex.unlock();

    android_app_write_cmd(AppEvent.APP_CMD_CONTENT_RECT_CHANGED);
}
fn android_app_free() void {
    app.mutex.lock();
    android_app_write_cmd(AppEvent.APP_CMD_DESTROY);
    while (!app.destroyed) {
        app.cond.wait(&app.mutex);
    }
    app.mutex.unlock();

    std.posix.close(app.msgread);
    std.posix.close(app.msgwrite);
}
fn android_app_set_activity_state(_cmd: AppEvent) void {
    app.mutex.lock();
    android_app_write_cmd(_cmd);
    while (app.activityState != _cmd) {
        app.cond.wait(&app.mutex);
    }
    app.mutex.unlock();
}
fn android_app_set_input(_queue: ?*android.AInputQueue) void {
    app.mutex.lock();
    app.pendingInputQueue = _queue;

    android_app_write_cmd(AppEvent.APP_CMD_INPUT_CHANGED);
    while (app.input_queue != app.pendingInputQueue) {
        app.cond.wait(&app.mutex);
    }
    app.mutex.unlock();
}
fn android_app_set_window(_window: ?*android.ANativeWindow) void {
    app.mutex.lock();
    if (app.pendingWindow != null) {
        android_app_write_cmd(AppEvent.APP_CMD_TERM_WINDOW);
    }
    app.pendingWindow = _window;
    if (_window != null) {
        android_app_write_cmd(AppEvent.APP_CMD_INIT_WINDOW);
    }
    while (app.window != app.pendingWindow) {
        app.cond.wait(&app.mutex);
    }
    app.mutex.unlock();
}
fn print_cur_config() void {
    var lang = [2]u8{ 0, 0 };
    var country = [2]u8{ 0, 0 };
    android.AConfiguration_getLanguage(app.config, @ptrCast(&lang));
    android.AConfiguration_getCountry(app.config, @ptrCast(&country));

    _ = LOGV("Config: mcc=%d mnc=%d lang=%c%c cnt=%c%c orien=%d touch=%d dens=%d keys=%d nav=%d keysHid=%d navHid=%d sdk=%d size=%d long=%d modetype=%d modenight=%d", .{ android.AConfiguration_getMcc(app.config), android.AConfiguration_getMnc(app.config), lang[0], lang[1], country[0], country[1], android.AConfiguration_getOrientation(app.config), android.AConfiguration_getTouchscreen(app.config), android.AConfiguration_getDensity(app.config), android.AConfiguration_getKeyboard(app.config), android.AConfiguration_getNavigation(app.config), android.AConfiguration_getKeysHidden(app.config), android.AConfiguration_getNavHidden(app.config), android.AConfiguration_getSdkVersion(app.config), android.AConfiguration_getScreenSize(app.config), android.AConfiguration_getScreenLong(app.config), android.AConfiguration_getUiModeType(app.config), android.AConfiguration_getUiModeNight(app.config) });
}

fn onDestroy(_activity: [*c]android.ANativeActivity) callconv(.C) void {
    _ = LOGV("Destroy: %p", .{_activity});
    android_app_free();
}
fn onInputQueueCreated(_activity: [*c]android.ANativeActivity, _queue: ?*android.AInputQueue) callconv(.C) void {
    _ = LOGV("InputQueueCreated: %p -- %p", .{ _activity, _queue });
    android_app_set_input(_queue);
}
fn onInputQueueDestroyed(_activity: [*c]android.ANativeActivity, _queue: ?*android.AInputQueue) callconv(.C) void {
    _ = LOGV("InputQueueDestroyed: %p -- %p", .{ _activity, _queue });
    android_app_set_input(null);
}
fn onLowMemory(_activity: [*c]android.ANativeActivity) callconv(.C) void {
    _ = LOGV("LowMemory: %p", .{_activity});
    android_app_write_cmd(AppEvent.APP_CMD_LOW_MEMORY);
}
fn onNativeWindowCreated(_activity: [*c]android.ANativeActivity, _window: ?*android.ANativeWindow) callconv(.C) void {
    _ = LOGV("NativeWindowCreated: %p -- %p", .{ _activity, _window });
    android_app_set_window(_window);
}
fn onNativeWindowDestroyed(_activity: [*c]android.ANativeActivity, _window: ?*android.ANativeWindow) callconv(.C) void {
    _ = LOGV("NativeWindowDestroyed: %p -- %p", .{ _activity, _window });
    android_app_set_window(null);
}
fn onNativeWindowRedrawNeeded(_activity: [*c]android.ANativeActivity, _window: ?*android.ANativeWindow) callconv(.C) void {
    _ = LOGV("NativeWindowRedrawNeeded: %p -- %p", .{ _activity, _window });
    android_app_write_cmd(AppEvent.APP_CMD_WINDOW_REDRAW_NEEDED);
}
fn onNativeWindowResized(_activity: [*c]android.ANativeActivity, _window: ?*android.ANativeWindow) callconv(.C) void {
    _ = LOGV("NativeWindowRedrawNeeded: %p -- %p", .{ _activity, _window });
    android_app_write_cmd(AppEvent.APP_CMD_WINDOW_RESIZED);
}
fn onPause(_activity: [*c]android.ANativeActivity) callconv(.C) void {
    _ = LOGV("Pause: %p", .{_activity});
    android_app_set_activity_state(AppEvent.APP_CMD_PAUSE);
}
fn onResume(_activity: [*c]android.ANativeActivity) callconv(.C) void {
    _ = LOGV("Resume: %p", .{_activity});
    android_app_set_activity_state(AppEvent.APP_CMD_RESUME);
}
fn onStart(_activity: [*c]android.ANativeActivity) callconv(.C) void {
    _ = LOGV("Start: %p", .{_activity});
    android_app_set_activity_state(AppEvent.APP_CMD_START);
}
fn onStop(_activity: [*c]android.ANativeActivity) callconv(.C) void {
    _ = LOGV("Stop: %p", .{_activity});
    android_app_set_activity_state(AppEvent.APP_CMD_STOP);
}
fn onWindowFocusChanged(_activity: [*c]android.ANativeActivity, _focused: i32) callconv(.C) void {
    _ = LOGV("NativeWindowRedrawNeeded: %p -- %d", .{ _activity, _focused });
    android_app_write_cmd(if (_focused != 0) AppEvent.APP_CMD_GAINED_FOCUS else AppEvent.APP_CMD_LOST_FOCUS);
}

fn android_app_read_cmd() u8 {
    var cmd = [1]u8{0};
    cmd[0] = 0;
    if (std.posix.read(app.msgread, &cmd) catch unreachable != @sizeOf(u8)) {
        _ = LOGE("No data on command pipe!", .{});
        return 255;
    }
    if (cmd[0] == @intFromEnum(AppEvent.APP_CMD_SAVE_STATE)) {
        free_saved_state();
    }
    return cmd[0];
}

fn android_app_pre_exec_cmd(_cmd: u8) void {
    switch (@as(AppEvent, @enumFromInt(_cmd))) {
        AppEvent.APP_CMD_INPUT_CHANGED => {
            _ = LOGV("APP_CMD_INPUT_CHANGED", .{});
            app.mutex.lock();
            if (app.input_queue != null) {
                android.AInputQueue_detachLooper(app.input_queue);
            }
            app.input_queue = app.pendingInputQueue;
            if (app.input_queue != null) {
                _ = LOGV("Attaching input queue to looper", .{});
                android.AInputQueue_attachLooper(app.input_queue, app.looper, @intFromEnum(LooperEvent.LOOPER_ID_INPUT), null, &app.input_poll_source);
            }
            app.cond.broadcast();
            app.mutex.unlock();
        },
        AppEvent.APP_CMD_INIT_WINDOW => {
            _ = LOGV("APP_CMD_INIT_WINDOW", .{});
            app.mutex.lock();
            app.window = app.pendingWindow;
            app.cond.broadcast();
            app.mutex.unlock();
        },
        AppEvent.APP_CMD_TERM_WINDOW => {
            _ = LOGV("APP_CMD_TERM_WINDOW", .{});
            app.cond.broadcast();
        },
        AppEvent.APP_CMD_RESUME, AppEvent.APP_CMD_START, AppEvent.APP_CMD_PAUSE, AppEvent.APP_CMD_STOP => {
            _ = LOGV("activityState=%d", .{_cmd});
            app.mutex.lock();
            app.activityState = @enumFromInt(_cmd);
            app.cond.broadcast();
            app.mutex.unlock();
        },
        AppEvent.APP_CMD_CONFIG_CHANGED => {
            _ = LOGV("APP_CMD_CONFIG_CHANGED", .{});
            android.AConfiguration_fromAssetManager(app.config, app.activity.?.*.assetManager);
            print_cur_config();
        },
        AppEvent.APP_CMD_DESTROY => {
            _ = LOGV("APP_CMD_DESTROY", .{});
            app.destroryRequested = true;
        },
        else => {},
    }
}

fn android_app_post_exec_cmd(_cmd: u8) void {
    switch (@as(AppEvent, @enumFromInt(_cmd))) {
        AppEvent.APP_CMD_TERM_WINDOW => {
            _ = LOGV("APP_CMD_TERM_WINDOW", .{});
            app.mutex.lock();
            app.window = null;
            app.cond.broadcast();
            app.mutex.unlock();
        },
        AppEvent.APP_CMD_SAVE_STATE => {
            _ = LOGV("APP_CMD_SAVE_STATE", .{});
            app.mutex.lock();
            app.stateSaved = true;
            app.cond.broadcast();
            app.mutex.unlock();
        },
        AppEvent.APP_CMD_RESUME => {
            free_saved_state();
        },
        else => {},
    }
}

fn free_saved_state() void {
    app.mutex.lock();
    if (app.savedState != null) {
        c_allocator.free(@as(?[]u8, @ptrCast(app.savedState)).?);
        app.savedState = null;
        app.savedStateSize = 0;
    }
    app.mutex.unlock();
}

fn process_cmd(_source: ?*android_poll_source) void {
    _ = _source;

    const cmd: u8 = android_app_read_cmd();
    android_app_pre_exec_cmd(cmd);
    if (app.on_app_cmd != null) app.on_app_cmd.?(@enumFromInt(cmd));
    android_app_post_exec_cmd(cmd);
}
fn process_input(_source: ?*android_poll_source) void {
    _ = _source;
    var event: ?*android.AInputEvent = null;
    while (android.AInputQueue_getEvent(app.input_queue, &event) >= 0) {
        //_ = LOGV("New input event: type=%d", .{android.AInputEvent_getType(event)});
        if (android.AInputQueue_preDispatchEvent(app.input_queue, event) != 0) {
            continue;
        }
        var handled: c_int = 0;
        if (app.on_input_event != null) handled = app.on_input_event.?(event);
        android.AInputQueue_finishEvent(app.input_queue, event, handled);
    }
}

fn engine_handle_cmd(_cmd: AppEvent) void {
    switch (_cmd) {
        AppEvent.APP_CMD_SAVE_STATE => {
            app.savedStateSize = @sizeOf(saved_state);
            app.savedState = @as([*]u8, @ptrCast(c_allocator.alloc(u8, app.savedStateSize) catch |e| system.handle_error3("engine_handle_cmd c_allocator.alloc app.savedState", e)))[0..app.savedStateSize];
            @memcpy(app.savedState.?, std.mem.asBytes(&app.savedata));
        },
        AppEvent.APP_CMD_INIT_WINDOW => {
            if (app.window != null) {
                if (!app.inited) {
                    init_android();
                    app.inited = true;
                } else {
                    __vulkan.recreate_swapchain(true);
                }
            }
        },
        AppEvent.APP_CMD_WINDOW_RESIZED => {
            __vulkan.recreate_swapchain(false);
        },
        AppEvent.APP_CMD_TERM_WINDOW => {},
        AppEvent.APP_CMD_GAINED_FOCUS => {
            if (app.accelerometer_sensor != null) {
                _ = android.ASensorEventQueue_enableSensor(app.sensor_event_queue, app.accelerometer_sensor);
                _ = android.ASensorEventQueue_setEventRate(app.sensor_event_queue, app.accelerometer_sensor, (1000 / 60) * 1000);
            }
            app.paused = false;
            __system.pause.store(false, std.builtin.AtomicOrder.monotonic);
            __system.activated.store(false, std.builtin.AtomicOrder.monotonic);
            root.xfit_activate(false, false);
        },
        AppEvent.APP_CMD_LOST_FOCUS => {
            if (app.accelerometer_sensor != null) {
                _ = android.ASensorEventQueue_disableSensor(app.sensor_event_queue, app.accelerometer_sensor);
            }
            __system.pause.store(true, std.builtin.AtomicOrder.monotonic);
            __system.activated.store(true, std.builtin.AtomicOrder.monotonic);
            root.xfit_activate(true, true);
        },
        else => {},
    }
}

fn engine_draw_frame() void {
    draw_android();
}

fn engine_handle_input(_event: ?*android.AInputEvent) i32 {
    if (android.AInputEvent_getType(_event) == android.AINPUT_EVENT_TYPE_MOTION) {
        app.savedata.x = @intFromFloat(android.AMotionEvent_getX(_event, 0));
        app.savedata.y = @intFromFloat(android.AMotionEvent_getY(_event, 0));
        return 1;
    }
    return 0;
}

fn AcquireASensorManagerInstance() ?*android.ASensorManager {
    var env: [*c]android.JNIEnv = null;
    _ = app.activity.?.*.vm.*.*.AttachCurrentThread.?(app.activity.?.*.vm, &env, null);

    const android_content_context = env.*.*.GetObjectClass.?(env, app.activity.?.*.clazz);
    const mid_get_package_name = env.*.*.GetMethodID.?(env, android_content_context, "getPackageName", "()Ljava/lang/String;");
    const package_name: android.jstring = env.*.*.CallObjectMethod.?(env, app.activity.?.*.clazz, mid_get_package_name);

    const native_package_name = env.*.*.GetStringUTFChars.?(env, package_name, null);
    const mgr = android.ASensorManager_getInstanceForPackage(native_package_name);

    env.*.*.ReleaseStringUTFChars.?(env, package_name, native_package_name);
    _ = app.activity.?.*.vm.*.*.DetachCurrentThread.?(app.activity.?.*.vm);

    if (mgr != null) return mgr;
    return android.ASensorManager_getInstance();
}

fn OnSensorEvent(fd: c_int, events: c_int, data: ?*anyopaque) callconv(.C) c_int {
    _ = fd;
    _ = events;
    _ = data;

    var event: android.ASensorEvent = undefined;
    while (android.ASensorEventQueue_getEvents(app.sensor_event_queue, &event, 1) > 0) {
        // _ = LOGI("accelerometer: x=%f y=%f z=%f", .{ event.unnamed_0.unnamed_0.acceleration.unnamed_0.unnamed_0.x, event.unnamed_0.unnamed_0.acceleration.unnamed_0.unnamed_0.y, event.unnamed_0.unnamed_0.acceleration.unnamed_0.unnamed_0.z });
    }

    // From the docs:
    //
    // Implementations should return 1 to continue receiving callbacks, or 0 to
    // have this file descriptor and callback unregistered from the looper.
    return 1;
}

fn set_cache_path() void {
    var env: [*c]android.JNIEnv = null;
    _ = app.activity.?.*.vm.*.*.AttachCurrentThread.?(app.activity.?.*.vm, &env, null);

    const android_content_context = env.*.*.GetObjectClass.?(env, app.activity.?.*.clazz);
    const getCacheDir = env.*.*.GetMethodID.?(env, android_content_context, "getCacheDir", "()Ljava/io/File;");
    const cache_dir = env.*.*.CallObjectMethod.?(env, app.activity.?.*.clazz, getCacheDir);

    const fileClass = env.*.*.FindClass.?(env, "java/io/File");
    const getPath = env.*.*.GetMethodID.?(env, fileClass, "getPath", "()Ljava/lang/String;");
    const cache_path_string: android.jstring = env.*.*.CallObjectMethod.?(env, cache_dir, getPath);

    const cache_path_chars = env.*.*.GetStringUTFChars.?(env, cache_path_string, null);
    app.cache_dir = c_allocator.alloc(u8, std.mem.len(cache_path_chars)) catch |e| system.handle_error3("anrdoid_app_entry c_allocator.alloc app.cache_dir", e);
    @memcpy(app.cache_dir.?, cache_path_chars[0..app.cache_dir.?.len]);
    env.*.*.ReleaseStringUTFChars.?(env, cache_path_string, cache_path_chars);

    _ = app.activity.?.*.vm.*.*.DetachCurrentThread.?(app.activity.?.*.vm);
}

fn anrdoid_app_entry() void {
    app.config = android.AConfiguration_new();

    android.AConfiguration_fromAssetManager(app.config, app.activity.?.*.assetManager);

    print_cur_config();

    app.cmd_poll_source.id = @intFromEnum(LooperEvent.LOOPER_ID_MAIN);
    app.cmd_poll_source.process = process_cmd;
    app.input_poll_source.id = @intFromEnum(LooperEvent.LOOPER_ID_INPUT);
    app.input_poll_source.process = process_input;

    app.looper = android.ALooper_prepare(android.ALOOPER_PREPARE_ALLOW_NON_CALLBACKS);
    _ = android.ALooper_addFd(app.looper, app.msgread, @intFromEnum(LooperEvent.LOOPER_ID_MAIN), android.ALOOPER_EVENT_INPUT, null, &app.cmd_poll_source);

    app.mutex.lock();
    app.running = true;
    app.cond.broadcast();
    app.mutex.unlock();

    app.on_app_cmd = engine_handle_cmd;
    app.on_input_event = engine_handle_input;

    set_cache_path();

    app.sensor_manager = AcquireASensorManagerInstance();
    app.accelerometer_sensor = android.ASensorManager_getDefaultSensor(app.sensor_manager, android.ASENSOR_TYPE_ACCELEROMETER);

    app.sensor_event_queue = android.ASensorManager_createEventQueue(app.sensor_manager, app.looper, @intFromEnum(LooperEvent.LOOPER_ID_USER), OnSensorEvent, null);

    if (app.savedState != null) {
        @memcpy(std.mem.asBytes(&app.savedata), app.savedState.?);
    }

    while (true) {
        var ident: i32 = undefined;
        var source: ?*android_poll_source = null;
        ident = android.ALooper_pollOnce(if (app.paused) -1 else 0, null, null, @ptrCast(&source));
        if (ident == android.ALOOPER_POLL_ERROR) system.handle_error_msg2("ALooper_pollOnce");

        if (source != null) {
            source.?.*.process.?(source);
        }

        if (app.destroryRequested) {
            destroy_android();
            break;
        }
        if (app.inited) {
            engine_draw_frame();
        }
    }

    free_saved_state();
    app.mutex.lock();
    if (app.input_queue != null) {
        android.AInputQueue_detachLooper(app.input_queue);
    }
    c_allocator.free(app.cache_dir.?);
    android.AConfiguration_delete(app.config);
    app.destroyed = true;
    app.cond.broadcast();
    app.mutex.unlock();
    // Can't touch android_app(app) object after this.
}

/// Actual application entry point
export fn ANativeActivity_onCreate(_activity: [*c]android.ANativeActivity, _savedState: ?*anyopaque, _savedStateSize: usize) callconv(.C) void {
    _activity.*.callbacks.*.onConfigurationChanged = onConfigurationChanged;
    _activity.*.callbacks.*.onContentRectChanged = onContentRectChanged;
    _activity.*.callbacks.*.onDestroy = onDestroy;
    _activity.*.callbacks.*.onInputQueueCreated = onInputQueueCreated;
    _activity.*.callbacks.*.onInputQueueDestroyed = onInputQueueDestroyed;
    _activity.*.callbacks.*.onLowMemory = onLowMemory;
    _activity.*.callbacks.*.onNativeWindowCreated = onNativeWindowCreated;
    _activity.*.callbacks.*.onNativeWindowDestroyed = onNativeWindowDestroyed;
    _activity.*.callbacks.*.onNativeWindowRedrawNeeded = onNativeWindowRedrawNeeded;
    _activity.*.callbacks.*.onNativeWindowResized = onNativeWindowResized;
    _activity.*.callbacks.*.onPause = onPause;
    _activity.*.callbacks.*.onResume = onResume;
    _activity.*.callbacks.*.onSaveInstanceState = onSaveInstanceState;
    _activity.*.callbacks.*.onStart = onStart;
    _activity.*.callbacks.*.onStop = onStop;
    _activity.*.callbacks.*.onWindowFocusChanged = onWindowFocusChanged;

    _activity.*.instance = @ptrCast(@constCast(&app));

    app.activity = _activity;

    if (_savedState != null and _savedStateSize != 0) {
        app.savedStateSize = _savedStateSize;

        app.savedState = @as([*]u8, @ptrCast(c_allocator.alloc(u8, app.savedStateSize) catch |e| system.handle_error3("ANativeActivity_onCreate c_allocator.alloc app.savedState", e)))[0..app.savedStateSize];

        @memcpy(app.savedState.?, @as(?[*]u8, @ptrCast(_savedState)).?);
    }

    const pipe = std.posix.pipe() catch |e| system.handle_error3("ANativeActivity_onCreate std.posix.pipe", e);
    app.msgread = pipe[0];
    app.msgwrite = pipe[1];

    app.thread = std.Thread.spawn(.{}, anrdoid_app_entry, .{}) catch |e| system.handle_error3("ANativeActivity_onCreate std.Thread.spawn", e);

    app.mutex.lock();
    while (!app.running) {
        app.cond.wait(&app.mutex);
    }
    app.mutex.unlock();

    root.xfit_clean();
    __system.real_destroy();
}
