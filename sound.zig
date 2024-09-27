pub const miniaudio = @cImport({
    @cDefine("MINIAUDIO_IMPLEMENTATION", "");
    @cInclude("miniaudio/miniaudio.h");
    @cInclude("miniaudio/miniaudio_libopus.h");
    @cInclude("miniaudio/miniaudio_libvorbis.h");
    @cInclude("miniaudio/miniaudio_ex.h"); //https://miniaud.io/docs/examples/custom_decoder.html
});

const system = @import("system.zig");
const std = @import("std");
const __system = @import("__system.zig");
const file = @import("file.zig");
const asset_file = @import("asset_file.zig");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const file_ = if (system.platform == .android) asset_file else file;
const Self = @This();

var engine: miniaudio.ma_engine = undefined;
var pCustomBackendVTables: [2][*c]miniaudio.ma_decoding_backend_vtable = .{ undefined, undefined };
var resourceManager: miniaudio.ma_resource_manager = undefined;
var sounds: AutoHashMap(*Self, *Self) = undefined;
var g_mutex: std.Thread.Mutex = .{};
var g_sem: std.Thread.Semaphore = .{};
var g_this: *Self = undefined;

__sound: ?miniaudio.ma_sound = null,
__audio_buf: miniaudio.ma_audio_buffer = undefined,
out_data: []u8 = undefined,
format: miniaudio.ma_format = undefined,
channels: miniaudio.ma_uint32 = undefined,
sampleRate: miniaudio.ma_uint32 = undefined,
size_in_frames: miniaudio.ma_uint64 = undefined,
allocated: bool = false,

pub fn start() void {
    if (system.dbg and __system.sound_started) system.handle_error_msg2("sound already started");
    __system.sound_started = true;

    sounds = AutoHashMap(*Self, *Self).init(__system.allocator);

    var resourceManagerConfig = miniaudio.ma_resource_manager_config_init();
    pCustomBackendVTables[0] = &miniaudio.g_ma_decoding_backend_vtable_libopus;
    pCustomBackendVTables[1] = &miniaudio.g_ma_decoding_backend_vtable_libvorbis;
    resourceManagerConfig.ppCustomDecodingBackendVTables = @ptrCast(&pCustomBackendVTables[0]);
    resourceManagerConfig.customDecodingBackendCount = 2;
    resourceManagerConfig.pCustomDecodingBackendUserData = null;

    var result = miniaudio.ma_resource_manager_init(&resourceManagerConfig, &resourceManager);
    if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_resource_manager_init {d}", .{result});
    var engineConfig: miniaudio.ma_engine_config = miniaudio.ma_engine_config_init();
    engineConfig.pResourceManager = &resourceManager;

    result = miniaudio.ma_engine_init(&engineConfig, &engine);

    if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_engine_init {d}", .{result});

    _ = std.Thread.spawn(.{}, callback_thread, .{}) catch unreachable;
}

// fn data_callback(pDevice: [*c]miniaudio.ma_device, pOutput: ?*anyopaque, pInput: ?*const anyopaque, frameCount: miniaudio.ma_uint32) callconv(.C) void {
//     _ = pInput;
//     const pDataSource: ?*miniaudio.ma_data_source = @ptrCast(pDevice.*.pUserData);
//     if (pDataSource == null) {
//         return;
//     }
//     _ = miniaudio.ma_data_source_read_pcm_frames(pDataSource, pOutput, frameCount, null);
// }
fn end_callback(userdata: ?*anyopaque, sound: [*c]miniaudio.ma_sound) callconv(.C) void {
    _ = sound;
    const self: *Self = @alignCast(@ptrCast(userdata.?));

    g_mutex.lock();
    g_this = self;
    g_mutex.unlock();
    g_sem.post();
}

fn callback_thread() void {
    while (@atomicLoad(bool, &__system.sound_started, .acquire)) {
        g_sem.wait();
        if (!@atomicLoad(bool, &__system.sound_started, .acquire)) break;
        g_mutex.lock();
        g_this.*.deinit();
        if (g_this.*.allocated) __system.allocator.destroy(g_this);
        _ = sounds.remove(g_this);
        g_mutex.unlock();
    }
}

pub fn play_sound(path: []const u8, volume: f32, out_sound: ?*Self) !void {
    if (!@atomicLoad(bool, &__system.sound_started, .acquire)) return;

    var self: *Self = undefined;
    if (out_sound == null) {
        self = try __system.allocator.create(Self);
        self.* = .{ .allocated = true };
        errdefer __system.allocator.destroy(self);
    } else {
        self = out_sound.?;
        self.* = .{};
    }

    var decoder: miniaudio.ma_decoder = undefined;
    var decoder_config = miniaudio.ma_decoder_config_init_default();
    decoder_config.ppCustomBackendVTables = @ptrCast(&pCustomBackendVTables[0]);
    decoder_config.customBackendCount = 2;

    const data = try file_.read_file(path, __system.allocator);
    defer __system.allocator.free(data);

    var result = miniaudio.ma_decoder_init_memory(data.ptr, data.len, &decoder_config, &decoder);
    if (result != miniaudio.MA_SUCCESS) {
        system.print_error("miniaudio.ma_decoder_init_memory {d}\n", .{result});
        return std.posix.UnexpectedError.Unexpected;
    }
    defer _ = miniaudio.ma_decoder_uninit(&decoder);

    result = miniaudio.ma_data_source_get_data_format(&decoder, &self.*.format, &self.*.channels, &self.*.sampleRate, null, 0);
    if (result != miniaudio.MA_SUCCESS) {
        system.print_error("miniaudio.ma_data_source_get_data_format {d}\n", .{result});
        return std.posix.UnexpectedError.Unexpected;
    }
    var output: ?*anyopaque = undefined;

    result = miniaudio.ma_decode_memory(data.ptr, data.len, &decoder_config, &self.*.size_in_frames, &output);

    if (result != miniaudio.MA_SUCCESS) {
        system.print_error("miniaudio.ma_decode_memory {d}\n", .{result});
        return std.posix.UnexpectedError.Unexpected;
    }
    self.*.out_data = @as([*]u8, @ptrCast(output.?))[0 .. self.*.size_in_frames * self.*.channels];

    const audio_buf_config: miniaudio.ma_audio_buffer_config = .{
        .channels = self.*.channels,
        .format = self.*.format,
        .sampleRate = self.*.sampleRate,
        .pData = self.*.out_data.ptr,
        .sizeInFrames = self.*.size_in_frames,
    };
    result = miniaudio.ma_audio_buffer_init(&audio_buf_config, &self.*.__audio_buf);
    if (result != miniaudio.MA_SUCCESS) {
        system.print_error("miniaudio.ma_audio_buffer_init {d}\n", .{result});
        return std.posix.UnexpectedError.Unexpected;
    }

    self.*.__sound = undefined;
    var sound_config = miniaudio.ma_sound_config_init();
    sound_config.endCallback = end_callback;
    sound_config.pEndCallbackUserData = @ptrCast(self);
    sound_config.pDataSource = &self.*.__audio_buf;

    result = miniaudio.ma_sound_init_ex(&engine, &sound_config, &self.*.__sound.?);
    if (result != miniaudio.MA_SUCCESS) {
        system.print_error("miniaudio.ma_sound_init_from_data_source {d}\n", .{result});
        return std.posix.UnexpectedError.Unexpected;
    }
    miniaudio.ma_sound_set_volume(&self.*.__sound.?, volume);

    result = miniaudio.ma_sound_start(&self.__sound.?);
    if (result != miniaudio.MA_SUCCESS) {
        system.print_error("miniaudio.ma_sound_start {d}\n", .{result});
        return std.posix.UnexpectedError.Unexpected;
    }
    g_mutex.lock();
    try sounds.put(self, self);
    g_mutex.unlock();
}

pub fn deinit(self: *Self) void {
    if (system.dbg and self.*.__sound == null) system.handle_error_msg2("sound not inited cant deinit");
    miniaudio.ma_sound_uninit(&self.*.__sound.?);
    miniaudio.ma_audio_buffer_uninit(&self.*.__audio_buf);
    self.*.__sound = null;
    std.c.free(self.*.out_data.ptr);
}

pub fn destroy() void {
    if (system.dbg and !__system.sound_started) system.handle_error_msg2("sound not started");
    @atomicStore(bool, &__system.sound_started, false, .release);
    miniaudio.ma_engine_uninit(&engine);

    g_mutex.lock();
    var it = sounds.valueIterator();
    while (it.next()) |v| {
        std.c.free(v.*.*.out_data.ptr);
        if (v.*.*.allocated) __system.allocator.destroy(v.*);
    }
    g_mutex.unlock();
    sounds.deinit();
}
