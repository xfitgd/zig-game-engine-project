const std = @import("std");
const system = @import("system.zig");
const builtin = @import("builtin");

const __android = @import("__android.zig");

const Self = @This();

pub const INVALID_FILE_HANDLE: std.fs.File.Handle = if (system.platform == .windows) @ptrCast(std.os.windows.INVALID_HANDLE_VALUE) else 0;

hFile: std.fs.File = .{ .handle = INVALID_FILE_HANDLE },

pub inline fn is_open(self: *Self) bool {
    return self.hFile.handle != INVALID_FILE_HANDLE;
}
pub inline fn open(self: *Self, path: []const u8, create_flags: std.fs.File.CreateFlags) !void {
    self.hFile = try std.fs.cwd().createFile(path, create_flags);
}
pub inline fn read(self: *Self, buffer: []u8) !usize {
    return try self.hFile.read(buffer);
}
pub inline fn write(self: *Self, buffer: []const u8) !usize {
    return try self.hFile.write(buffer);
}
pub inline fn writer(self: *Self) std.fs.File.Writer {
    return self.hFile.writer();
}
pub inline fn close(self: *Self) void {
    self.hFile.close();
    self.hFile.handle = INVALID_FILE_HANDLE;
}
pub inline fn seekTo(self: *Self, idx: i64) !void {
    try self.hFile.seekTo(idx);
}
pub inline fn seekBy(self: *Self, idx: i64) !void {
    try self.hFile.seekBy(idx);
}
pub inline fn seekFromEnd(self: *Self, idx: i64) !void {
    try self.hFile.seekFromEnd(idx);
}
pub inline fn writeCurrentStackTrace(self: *Self) void {
    const debug_info = std.debug.getSelfDebugInfo() catch system.unreachable2(); //재귀 호출 위험이 있어서 따로 에러 처리 안함.

    std.debug.writeCurrentStackTrace(self.*.writer(), debug_info, std.io.tty.detectConfig(self.*.hFile), @returnAddress()) catch system.unreachable2();
}
pub inline fn getPos(self: *Self) !u64 {
    try self.hFile.getPos();
}
pub inline fn size(self: *Self) !u64 {
    try self.hFile.getEndPos();
}
pub inline fn readA(self: *Self, T: type, a: *T) !usize {
    return try self.hFile.read(@as(u8[@sizeOf(T)], @ptrCast(a)));
}
pub inline fn writeA(self: *Self, T: type, a: *const T) !usize {
    return try self.hFile.write(@as(u8[@sizeOf(T)], @ptrCast(a)));
}

pub fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var __size: usize = 0;
    var buffer: []u8 = undefined;

    if (system.platform == .windows) {
        const _file = try std.fs.cwd().createFile(path, .{ .read = true, .truncate = false });
        defer _file.close();
        size = @intCast((try _file.stat()).size);

        buffer = try allocator.alloc(u8, size);

        _ = try _file.readAll(buffer);

        //system.print("size : {d}\n",.{size});

    } else if (system.platform == .android) {
        const asset = __android.android.AAssetManager_open(__android.get_AssetManager(), @ptrCast(path), __android.android.AASSET_MODE_STREAMING);

        __size = @intCast(__android.android.AAsset_getLength(asset));

        buffer = try allocator.alloc(u8, __size);

        var _read: usize = 0;
        while (_read < __size) {
            const i = __android.android.AAsset_read(asset, &buffer[_read], __size);
            if (i < 0) {
                return std.posix.UnexpectedError.Unexpected;
            } else if (i == 0) {
                break;
            }
            _read += @intCast(i);
        }

        __android.android.AAsset_close(asset);
    } else {
        @compileError("not support platform");
    }

    return buffer;
}
