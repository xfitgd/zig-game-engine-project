const std = @import("std");
const builtin = @import("builtin");
const system = @import("system.zig");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const MemoryPool = std.heap.MemoryPool;

//TODO 검증되지 않음

pub inline fn memcpy_nonarray(dest: anytype, src: anytype) void {
    @memcpy(std.mem.asBytes(dest), std.mem.asBytes(src));
}
//// pub inline fn align_ptr_cast(dest_type: type, src: anytype) dest_type {
////     return @as(dest_type, @ptrCast(@alignCast(src)));
//// }
// ///src 타입 배열(Slice)을 u8 배열(Slice)로 변환한다. use std.mem.sliceAsBytes
//// pub inline fn u8arr(src: anytype) []u8 {
////     return @as([*]u8, @ptrCast(src.ptr))[0..@divFloor(@sizeOf(@TypeOf(src)), @sizeOf(u8))];
//// }
///src 타입 배열(Slice)을 dest_type 타입 배열(Slice)로 변환한다.
pub inline fn cvtarr(comptime dest_type: type, src: anytype) []dest_type {
    return @as([*]dest_type, src.ptr)[0..@divFloor(@sizeOf(@TypeOf(src)), @sizeOf(dest_type))];
}

pub const check_alloc = struct {
    const Self = @This();
    __check_alloc: if (system.dbg) ?[]bool else void = if (system.dbg) null,
    allocator: if (system.dbg) std.mem.Allocator else void = if (system.dbg) undefined,

    pub fn init(self: *Self, _allocator: std.mem.Allocator) void {
        if (system.dbg) {
            self.*.allocator = _allocator;
            if (self.*.__check_alloc != null) system.handle_error_msg2("alloc __check_alloc already alloc");
            self.*.__check_alloc = self.*.allocator.alloc(bool, 1) catch |e| system.handle_error3("alloc __check_alloc", e);
        }
    }
    pub fn deinit(self: *Self) void {
        if (system.dbg) {
            if (self.*.__check_alloc == null) system.handle_error_msg2("free __check_alloc is null");
            self.*.allocator.free(self.*.__check_alloc.?);
        }
    }
};

pub const check_init = struct {
    const Self = @This();
    __check_init: if (system.dbg) bool else void = if (system.dbg) false,

    pub fn init(self: *Self) void {
        if (system.dbg) {
            if (self.*.__check_init) system.handle_error_msg2("__check_init already init");
            self.*.__check_init = true;
        }
    }
    pub fn deinit(self: *Self) void {
        if (system.dbg) {
            if (!self.*.__check_init) system.handle_error_msg2("__check_init not init");
            self.*.__check_init = false;
        }
    }
};
