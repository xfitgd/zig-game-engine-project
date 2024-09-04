const std = @import("std");
const system = @import("system.zig");
const freetype = @cImport({
    @cInclude("freetype/ft2build.h");
    @cInclude("freetype/freetype/freetype.h");
});

const Self = @This();

const library: freetype.FT_Library = null;

pub const font_error = error{
    undefined_char_code,
};

__face: freetype.FT_Face = null,

fn handle_error(code: freetype.FT_Error) void {
    if (code != freetype.FT_Err_Ok) {
        system.print_error("ERR Code : {d}, msg : {s}\n", .{ code, freetype.FT_Error_String(code) });
        unreachable;
    }
}

pub fn start() void {
    if (library != null) unreachable;
    handle_error(freetype.FT_Init_FreeType(&library));
}

pub fn destroy() void {
    if (library == null) unreachable;
    freetype.FT_Done_FreeType(library);
}

pub fn init(_font_data: []const u8, _face_index: freetype.FT_Long) Self {
    var font: Self = .{};
    handle_error(freetype.FT_New_Memory_Face(library, _font_data.ptr, _font_data.len, _face_index, &font.__face));

    return font;
}

pub fn get_char_idx(self: Self, _char: u21) font_error!u32 {
    const idx = freetype.FT_Get_Char_Index(self.__face, @intCast(_char));
    if (idx != 0) return idx;

    system.print_debug("ERR undefined character code (charcode) : {d}, (char) : {s}\n", .{ _char, _char });
    return font_error.undefined_char_code;
}

pub fn set_font_size(self: Self, _px_size: u32) void {
    if (self.__face == null) {
        system.print_error("ERR __face null(font not inited)\n", .{});
        unreachable;
    }
    handle_error(freetype.FT_Set_Pixel_Sizes(self.__face, 0, _px_size));
}
