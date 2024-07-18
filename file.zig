const std = @import("std");

const root = @import("root");

const __android = @import("__android.zig");

pub fn file() type {
    if (root.platform == root.XfitPlatform.windows) {
        return struct {
            const Self = @This();
            hFile: std.fs.File = .{ .handle = 0 },

            pub inline fn is_open(self: *Self) bool {
                return self.hFile.handle != 0;
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
            pub inline fn close(self: *Self) void {
                self.hFile.close();
                self.hFile.handle = 0;
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
        };
    } else if (root.platform == root.XfitPlatform.android) {
        //TODO 추후에 제대로 구현
        @compileError("구현 필요");
    } else {
        @compileError("not supported platform");
    }
}

pub fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var size: usize = 0;
    var buffer: []u8 = undefined;

    if (root.platform == root.XfitPlatform.windows) {
        const _file = try std.fs.cwd().createFile(path, .{ .read = true, .truncate = false });
        defer _file.close();
        size = @intCast((try _file.stat()).size);

        buffer = try allocator.alloc(u8, size);

        _ = try _file.readAll(buffer);

        //system.print("size : {d}\n",.{size});

    } else if (root.platform == root.XfitPlatform.android) {
        const asset = __android.android.AAssetManager_open(__android.get_AssetManager(), @ptrCast(path), __android.android.AASSET_MODE_STREAMING);

        size = @intCast(__android.android.AAsset_getLength(asset));

        buffer = try allocator.alloc(u8, size);

        var read: usize = 0;
        while (read < size) {
            const i = __android.android.AAsset_read(asset, &buffer[read], size);
            if (i < 0) {
                unreachable;
            } else if (i == 0) {
                break;
            }
            read += @intCast(i);
        }

        __android.android.AAsset_close(asset);
    } else {
        @compileError("not supported platform");
    }

    return buffer;
}
