const std = @import("std");

const Self = @This();

const cwebp = @cImport({
    @cInclude("webp/decode.h");
    @cInclude("webp/encode.h");
});

const img = @import("img.zig");

config: union {
    decode: cwebp.WebPDecoderConfig,
    encode: cwebp.WebPConfig,
} = undefined,

pub const webp_error = error{
    ///load_header
    WebPGetFeatures_error,
    ///load_header
    WebPInitDecoderConfig_error,
    ///decode
    WebPDecode_error,
    ///decode
    unsupport_decode_fmt_error,
};

pub fn width(self: *Self) u32 {
    return @max(0, self.*.config.decode.input.width);
}
pub fn height(self: *Self) u32 {
    return @max(0, self.*.config.decode.input.height);
}

///for decoding
pub fn load_header(self: *Self, data: []const u8) webp_error!void {
    if (cwebp.WebPInitDecoderConfig(&self.*.config.decode) == 0) return webp_error.WebPInitDecoderConfig_error;
    self.*.config.decode.options.no_fancy_upsampling = 1;
    if (cwebp.WebPGetFeatures(data.ptr, data.len, &self.*.config.decode.input) != cwebp.VP8_STATUS_OK) return webp_error.WebPGetFeatures_error;

    self.*.config.decode.options.scaled_width = self.*.config.decode.input.width;
    self.*.config.decode.options.scaled_height = self.*.config.decode.input.height;
}

pub fn decode(self: *Self, out_fmt: img.color_format, data: []const u8, out_data: []u8) webp_error!void {
    const bit = @divExact(img.bit(out_fmt), 8);
    switch (out_fmt) {
        .RGBA => self.*.config.decode.output.colorspace = cwebp.MODE_RGBA,
        .ARGB => self.*.config.decode.output.colorspace = cwebp.MODE_ARGB,
        .BGRA => self.*.config.decode.output.colorspace = cwebp.MODE_BGRA,
        .RGB => self.*.config.decode.output.colorspace = cwebp.MODE_RGB,
        .BGR => self.*.config.decode.output.colorspace = cwebp.MODE_BGR,
        else => return webp_error.unsupport_decode_fmt_error,
    }
    self.*.config.decode.output.u.RGBA.rgba = out_data.ptr;
    self.*.config.decode.output.u.RGBA.stride = self.*.config.decode.input.width * bit;
    self.*.config.decode.output.u.RGBA.size = @max(0, self.*.config.decode.output.u.RGBA.stride * self.*.config.decode.input.height);
    self.*.config.decode.output.is_external_memory = 1;

    if (cwebp.WebPDecode(data.ptr, data.len, &self.*.config.decode) != cwebp.VP8_STATUS_OK) return webp_error.WebPDecode_error;
    cwebp.WebPFreeDecBuffer(&self.*.config.decode.output);
}
