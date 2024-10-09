const std = @import("std");

const __windows = @import("__windows.zig");
const __system = @import("__system.zig");
const raw_input = @import("raw_input.zig");
const __raw_input = @import("__raw_input.zig");
const system = @import("system.zig");

const win32 = __windows.win32;

pub const XBOX_BUTTONS = packed struct {
    A: bool,
    B: bool,
    X: bool,
    Y: bool,

    DPAD_UP: bool,
    DPAD_DOWN: bool,
    DPAD_LEFT: bool,
    DPAD_RIGHT: bool,

    START: bool,
    BACK: bool,
    GUIDE: bool,

    LEFT_THUMB: bool,
    RIGHT_THUMB: bool,

    LEFT_SHOULDER: bool,
    RIGHT_SHOULDER: bool,
};

pub const XBOX_STATE = struct {
    device_idx: u32,
    packet: u32,
    left_trigger: u8,
    right_trigger: u8,
    left_thumb_x: i16,
    left_thumb_y: i16,
    right_thumb_x: i16,
    right_thumb_y: i16,
    buttons: XBOX_BUTTONS,
};

pub const XBOX_WIN_GUID = raw_input.GUID{
    .Data1 = 0xec87f1e3,
    .Data2 = 0xc13b,
    .Data3 = 0x4100,
    .Data4 = [8]u8{ 0xb5, 0xf7, 0x8b, 0x84, 0xd5, 0x42, 0x60, 0xcb },
};

pub const XBOX_MAX_CONTROLLERS = 16;
const XBOX_DPAD_UP = 0x0001;
const XBOX_DPAD_DOWN = 0x0002;
const XBOX_DPAD_LEFT = 0x0004;
const XBOX_DPAD_RIGHT = 0x0008;
const XBOX_START = 0x0010; // or "view"
const XBOX_BACK = 0x0020; // or "menu"
const XBOX_LEFT_THUMB = 0x0040;
const XBOX_RIGHT_THUMB = 0x0080;
const XBOX_LEFT_SHOULDER = 0x0100;
const XBOX_RIGHT_SHOULDER = 0x0200;
const XBOX_GUIDE = 0x0400; // or "xbox" button
const XBOX_A = 0x1000;
const XBOX_B = 0x2000;
const XBOX_X = 0x4000;
const XBOX_Y = 0x8000;
const XBOX_OUT_PACKET_SIZE = 29;

const XBOX_IN = [_]u8{ 0x01, 0x01, 0x00 };
const XBOX_CONTROL_CODE: u32 = 0x8000e00c;

const CallbackFn = *const fn (state: XBOX_STATE) void;
const ChangeDeviceFn = *const fn (_device_idx: u32, add_or_remove: bool) void;

const USER_DATA = struct {
    fn_: CallbackFn,
    change_fn_: ChangeDeviceFn,
};

var raw: raw_input = .{ .handle = undefined };
var out_data: [XBOX_OUT_PACKET_SIZE]u8 = undefined;

fn change_fn(_device_idx: u32, add_or_remove: bool, _user_data: ?*anyopaque) void {
    const data: *USER_DATA = @alignCast(@ptrCast(_user_data.?));
    data.*.change_fn_(_device_idx, add_or_remove);
}

pub fn start(_change_fn: ChangeDeviceFn) raw_input.ERROR!void {
    raw = .{ .handle = undefined };
    const data: *anyopaque = @ptrCast(__system.allocator.create(USER_DATA) catch system.handle_error_msg2("xbox_pad_input create USER_DATA"));
    @as(*USER_DATA, @alignCast(@ptrCast(data))).*.change_fn_ = _change_fn;
    try raw.init(XBOX_MAX_CONTROLLERS, &XBOX_WIN_GUID, change_fn, data);
}

pub fn destroy() void {
    const data = @as(*__raw_input, @alignCast(@ptrCast(raw.handle))).*.user_data;
    __system.allocator.destroy(@as(*USER_DATA, @alignCast(@ptrCast(data.?))));
    raw.deinit();
}

fn callback(out: []u8, device_idx: u32, _user_data: ?*anyopaque) void {
    const data: *USER_DATA = @alignCast(@ptrCast(_user_data.?));
    var state: XBOX_STATE = undefined;
    state.device_idx = device_idx;
    state.packet = std.mem.bytesToValue(u32, &out[5]);
    const buttons: u16 = std.mem.bytesToValue(u16, &out[11]);
    state.left_trigger = out[13];
    state.right_trigger = out[14];
    state.left_thumb_x = std.mem.bytesToValue(i16, &out[15]);
    state.left_thumb_y = std.mem.bytesToValue(i16, &out[17]);
    state.right_thumb_x = std.mem.bytesToValue(i16, &out[19]);
    state.right_thumb_y = std.mem.bytesToValue(i16, &out[21]);

    state.buttons.A = buttons & XBOX_A != 0;
    state.buttons.B = buttons & XBOX_B != 0;
    state.buttons.X = buttons & XBOX_X != 0;
    state.buttons.Y = buttons & XBOX_Y != 0;
    state.buttons.DPAD_LEFT = buttons & XBOX_DPAD_LEFT != 0;
    state.buttons.DPAD_RIGHT = buttons & XBOX_DPAD_RIGHT != 0;
    state.buttons.DPAD_DOWN = buttons & XBOX_DPAD_DOWN != 0;
    state.buttons.DPAD_UP = buttons & XBOX_DPAD_UP != 0;
    state.buttons.BACK = buttons & XBOX_BACK != 0;
    state.buttons.GUIDE = buttons & XBOX_GUIDE != 0;
    state.buttons.START = buttons & XBOX_START != 0;
    state.buttons.LEFT_THUMB = buttons & XBOX_LEFT_THUMB != 0;
    state.buttons.RIGHT_THUMB = buttons & XBOX_RIGHT_THUMB != 0;
    state.buttons.LEFT_SHOULDER = buttons & XBOX_LEFT_SHOULDER != 0;
    state.buttons.RIGHT_SHOULDER = buttons & XBOX_RIGHT_SHOULDER != 0;
    data.*.fn_(state);
}

pub fn set_callback(_fn: CallbackFn) void {
    const data = @as(*__raw_input, @alignCast(@ptrCast(raw.handle))).*.user_data;
    @as(*USER_DATA, @alignCast(@ptrCast(data.?))).*.fn_ = _fn;

    raw.set_callback(callback, XBOX_IN[0..XBOX_IN.len], out_data[0..XBOX_OUT_PACKET_SIZE], XBOX_CONTROL_CODE);
}

pub const XBOX_VIBRATION = struct {
    left_trigger: u8 = 0,
    right_trigger: u8 = 0,
    left_rumble: u8 = 0,
    right_rumble: u8 = 0,
    on_time: u8 = 10,
    off_time: u8 = 0,
    repeat: u8 = 1,
};

pub fn set_vibration(
    device_idx: u32,
    vib: XBOX_VIBRATION,
) !u32 {
    const data: [9]u8 = .{
        0x03,
        0x0F,
        vib.left_trigger,
        vib.right_trigger,
        vib.left_rumble,
        vib.right_rumble,
        vib.on_time,
        vib.off_time,
        vib.repeat,
    };
    return try raw.set(device_idx, data[0..data.len]);
}
