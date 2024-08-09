pub const color_format = enum { RGB, BGR, RGBA, BGRA, ARGB, ABGR, Gray, RGB16, BGR16, RGBA16, BGRA16, ARGB16, ABGR16, Gray16, RGB32, BGR32, RGBA32, BGRA32, ARGB32, ABGR32, Gray32, RGB32F, BGR32F, RGBA32F, BGRA32F, ARGB32F, ABGR32F, Gray32F };

const std = @import("std");
const mem = @import("mem.zig");
const system = @import("system.zig");

pub const img_error = error{
    src_too_small,
    dest_too_small,
};
pub inline fn bit(fmt: color_format) c_int {
    return switch (fmt) {
        .RGB, .BGR => 24,
        .RGBA, .BGRA, .ABGR, .ARGB, .Gray32, .Gray32F => 32,
        .Gray => 8,
        .Gray16 => 16,
        .RGB16, .BGR16 => 48,
        .RGBA16, .BGRA16, .ABGR16, .ARGB16 => 64,
        .RGB32, .BGR32, .RGB32F, .BGR32F => 96,
        .RGBA32, .BGRA32, .ABGR32, .ARGB32, .RGBA32F, .BGRA32F, .ABGR32F, .ARGB32F => 128,
    };
}

pub fn cut(_src: anytype, _fmt: color_format, _src_width: u32, _src_height: u32, _dest: anytype, _dest_x: u32, _dest_y: u32, _dest_width: u32, _dest_height: u32) img_error!void {
    switch (_fmt) {
        .RGB, .BGR => {
            const src = mem.cvtarr(u8, _src);
            if (_src_height * _src_width * 3 > src.len) return img_error.src_too_small;
            const dest = mem.cvtarr(u8, _dest);
            if (_dest_height * _dest_width * 3 > dest.len) return img_error.dest_too_small;
            var w: u32 = 0;
            var h: u32 = 0;
            while (h < _dest_height) : (h += 1) {
                while (w < _dest_width) : (w += 1) {
                    const dest_idx = (h * _dest_width + w) * 3;
                    const src_idx = ((h + _dest_y) * _src_width + _dest_x + w) * 3;
                    dest.*[dest_idx] = src.*[src_idx];
                    dest.*[dest_idx + 1] = src.*[src_idx + 1];
                    dest.*[dest_idx + 2] = src.*[src_idx + 2];
                }
            }
        },
        //TODO 나머지 포멧도 구현
        else => {},
    }
}
