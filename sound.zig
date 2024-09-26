pub const miniaudio = @cImport({
    @cDefine("MINIAUDIO_IMPLEMENTATION", "");
    @cInclude("miniaudio/miniaudio.h");
    @cInclude("miniaudio/miniaudio_libopus.h");
    @cInclude("miniaudio/miniaudio_ex.h");
});

const system = @import("system.zig");
const std = @import("std");
const __system = @import("__system.zig");
const file = @import("file.zig");
const asset_file = @import("asset_file.zig");

var engine: miniaudio.ma_engine = undefined;
var pCustomBackendVTables: [][*c]miniaudio.ma_decoding_backend_vtable = undefined;
var resourceManager: miniaudio.ma_resource_manager = undefined;

var device: miniaudio.ma_device = undefined;
var decoder: miniaudio.ma_decoder = undefined;

pub fn start() void {
    if (system.dbg and __system.sound_started) system.handle_error_msg2("sound already started");
    if (system.dbg) __system.sound_started = true;

    pCustomBackendVTables = std.heap.c_allocator.alloc([*c]miniaudio.ma_decoding_backend_vtable, 1) catch unreachable;

    var resourceManagerConfig = miniaudio.ma_resource_manager_config_init();
    pCustomBackendVTables[0] = &miniaudio.g_ma_decoding_backend_vtable_libopus;
    resourceManagerConfig.ppCustomDecodingBackendVTables = @ptrCast(&pCustomBackendVTables[0]);
    resourceManagerConfig.customDecodingBackendCount = 1;
    resourceManagerConfig.pCustomDecodingBackendUserData = null;

    var result = miniaudio.ma_resource_manager_init(&resourceManagerConfig, &resourceManager);
    if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_resource_manager_init {d}", .{result});
    var engineConfig: miniaudio.ma_engine_config = miniaudio.ma_engine_config_init();
    engineConfig.pResourceManager = &resourceManager;

    result = miniaudio.ma_engine_init(&engineConfig, &engine);

    if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_engine_init {d}", .{result});
}

fn data_callback(pDevice: [*c]miniaudio.ma_device, pOutput: ?*anyopaque, pInput: ?*const anyopaque, frameCount: miniaudio.ma_uint32) callconv(.C) void {
    _ = pInput;
    const pDataSource: ?*miniaudio.ma_data_source = @ptrCast(pDevice.*.pUserData);
    if (pDataSource == null) {
        return;
    }
    _ = miniaudio.ma_data_source_read_pcm_frames(pDataSource, pOutput, frameCount, null);
}

///https://miniaud.io/docs/examples/custom_decoder.html
pub fn play_sound(path: []const u8) !void {
    if (system.dbg and !__system.sound_started) system.handle_error_msg2("sound not started");

    if (system.platform == .android) {
        var decoder_config = miniaudio.ma_decoder_config_init_default();
        decoder_config.ppCustomBackendVTables = @ptrCast(&pCustomBackendVTables[0]);
        decoder_config.customBackendCount = 1;

        const data = try asset_file.read_file(path, __system.allocator);

        var result = miniaudio.ma_decoder_init_memory(data.ptr, data.len, &decoder_config, &decoder);
        if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_decoder_init_memory {d}", .{result});

        var format: miniaudio.ma_format = undefined;
        var channels: miniaudio.ma_uint32 = undefined;
        var sampleRate: miniaudio.ma_uint32 = undefined;
        result = miniaudio.ma_data_source_get_data_format(&decoder, &format, &channels, &sampleRate, null, 0);
        if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_data_source_get_data_format {d}", .{result});

        var deviceConfig = miniaudio.ma_device_config_init(miniaudio.ma_device_type_playback);
        deviceConfig.playback.format = format;
        deviceConfig.playback.channels = channels;
        deviceConfig.sampleRate = sampleRate;
        deviceConfig.dataCallback = data_callback;
        deviceConfig.pUserData = &decoder;

        result = miniaudio.ma_device_init(null, &deviceConfig, &device);
        if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_device_init {d}", .{result});
        result = miniaudio.ma_device_start(&device);
        if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_device_start {d}", .{result});

        //miniaudio.ma_device_uninit(&device);
        //miniaudio.ma_decoder_uninit(&decoder);
    } else {
        const text = try std.mem.Allocator.dupeZ(std.heap.c_allocator, u8, path);
        defer std.heap.c_allocator.free(text);
        const result = miniaudio.ma_engine_play_sound(&engine, text.ptr, null);
        if (result != miniaudio.MA_SUCCESS) system.handle_error2("miniaudio.ma_engine_play_sound {d}", .{result});
    }
}

pub fn destroy() void {
    if (system.dbg and !__system.sound_started) system.handle_error_msg2("sound not started");
    miniaudio.ma_engine_uninit(&engine);
    std.heap.c_allocator.free(pCustomBackendVTables);
    if (system.dbg) __system.sound_started = false;
}
