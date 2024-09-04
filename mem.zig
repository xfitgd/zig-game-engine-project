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
pub inline fn align_ptr_cast(dest_type: type, src: anytype) dest_type {
    return @as(dest_type, @ptrCast(@alignCast(src)));
}
pub inline fn u8arr(src: anytype) *[@sizeOf(@TypeOf(src))]u8 {
    return @as(*[@sizeOf(@TypeOf(src))]u8, @constCast(@ptrCast(&src)));
}
pub inline fn cvtarr(comptime dest_type: type, src: anytype) *[@divFloor(@sizeOf(@TypeOf(src)), @sizeOf(dest_type))]dest_type {
    return @as(*[@divFloor(@sizeOf(@TypeOf(src)), @sizeOf(dest_type))]u8, @constCast(@ptrCast(&src)));
}

// pub const Check = enum { ok, leak };

// pub const dummy_allocator = struct {
//     const Self = @This();
//     const stack = struct { trace: std.builtin.StackTrace, addr: [4]usize };
//     list: AutoHashMap(*anyopaque, *stack),
//     pool: MemoryPool(stack),
//     mutex: std.Thread.Mutex = .{},
//     pub fn alloc(self: *Self) *anyopaque {
//         self.mutex.lock();
//         defer self.mutex.unlock();
//         const node: *stack = self.*.pool.create() catch unreachable;
//         node.*.trace.instruction_addresses = &node.*.addr;
//         std.debug.captureStackTrace(null, &node.*.trace);
//         self.*.list.put(@ptrCast(node), node) catch unreachable;
//         return @ptrCast(node);
//     }
//     pub fn free(self: *Self, alloc_code: *anyopaque) void {
//         self.mutex.lock();
//         defer self.mutex.unlock();
//         _ = self.*.list.fetchRemove(alloc_code) orelse unreachable;
//         self.*.pool.destroy(align_ptr_cast(*stack, alloc_code));
//     }
//     pub fn init(allocator: std.mem.Allocator) Self {
//         return Self{
//             .list = AutoHashMap(*anyopaque, *stack).init(allocator),
//             .pool = MemoryPool(stack).init(allocator),
//         };
//     }
//     pub fn deinit(self: *Self) Check {
//         self.mutex.lock();
//         defer self.mutex.unlock();
//         var it = self.*.list.iterator();
//         var next = it.next();
//         var is_leak = false;
//         while (next != null) {
//             if (!is_leak) {
//                 system.print("Dummy Memory Leak !!!!!!!!!!!!!!!!!!!!\n", .{});
//             }
//             std.debug.dumpStackTrace(next.?.value_ptr.*.*.trace);
//             is_leak = true;
//             system.print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n", .{});
//             next = it.next();
//         }
//         self.list.deinit();
//         self.pool.deinit();
//         return if (is_leak) .leak else .ok;
//     }
// };
