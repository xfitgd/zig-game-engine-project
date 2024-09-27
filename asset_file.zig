const std = @import("std");
const system = @import("system.zig");

const __android = @import("__android.zig");

const AAsset = __android.android.AAsset;

comptime {
    if (system.platform != .android) @compileError("asset_file only can use android.");
}

const Self = @This();

pub const INVALID_FILE_HANDLE: ?*AAsset = null;

handle: ?*AAsset = INVALID_FILE_HANDLE,

pub inline fn is_open(self: *Self) bool {
    return self.handle != INVALID_FILE_HANDLE;
}
// pub inline fn open(self: *Self, path: []const u8, create_flags: std.fs.File.CreateFlags) !void {
//     self.hFile = try std.fs.cwd().createFile(path, create_flags);
// }
// pub inline fn read(self: *Self, buffer: []u8) !usize {
//     return try self.hFile.read(buffer);
// }
pub inline fn close(self: *Self) void {
    if (self.handle == INVALID_FILE_HANDLE) {
        system.print_error("WARN Can't close INVALID_FILE_HANDLE(not open asset_file)\n", .{});
        return;
    }
    __android.android.AAsset_close(self.handle);
    self.handle = INVALID_FILE_HANDLE;
}
// pub inline fn seekTo(self: *Self, idx: i64) !void {
//     try self.hFile.seekTo(idx);
// }
// pub inline fn seekBy(self: *Self, idx: i64) !void {
//     try self.hFile.seekBy(idx);
// }
// pub inline fn seekFromEnd(self: *Self, idx: i64) !void {
//     try self.hFile.seekFromEnd(idx);
// }
// pub inline fn getPos(self: *Self) !u64 {
//     try self.hFile.getPos();
// }
// pub inline fn size(self: *Self) !u64 {
//     try self.hFile.getEndPos();
// }
// pub inline fn readA(self: *Self, T: type, a: *T) !usize {
//     return try self.hFile.read(@as(u8[@sizeOf(T)], @ptrCast(a)));
// }

pub fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var __size: usize = 0;
    var buffer: []u8 = undefined;

    const asset = __android.android.AAssetManager_open(__android.get_AssetManager(), @ptrCast(path), __android.android.AASSET_MODE_STREAMING);

    __size = @intCast(__android.android.AAsset_getLength(asset));

    buffer = try allocator.alloc(u8, __size);
    errdefer allocator.free(buffer);

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

    return buffer;
}
