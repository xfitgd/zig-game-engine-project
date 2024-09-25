const std = @import("std");
const unicode = std.unicode;
const system = @import("system.zig");
const freetype = @cImport({
    @cInclude("freetype/ft2build.h");
    @cInclude("freetype/freetype/freetype.h");
    @cInclude("freetype/freetype/ftoutln.h");
});
const geometry = @import("geometry.zig");
const math = @import("math.zig");
const point = math.point;

const Self = @This();

var library: freetype.FT_Library = null;

pub const font_error = error{
    undefined_char_code,
} || std.mem.Allocator.Error;

__face: freetype.FT_Face = null,

fn handle_error(code: freetype.FT_Error) void {
    if (code != freetype.FT_Err_Ok) {
        system.handle_error2("Code : {d}, msg : {s}\n", .{ code, freetype.FT_Error_String(code) });
    }
}

pub fn start() void {
    if (library != null) system.handle_error_msg2("font start failed");
    handle_error(freetype.FT_Init_FreeType(&library));
}

pub fn destroy() void {
    if (library == null) system.handle_error_msg2("font not started");
    _ = freetype.FT_Done_FreeType(library);
}

pub fn init(_font_data: []const u8, _face_index: freetype.FT_Long) Self {
    var font: Self = .{};
    handle_error(freetype.FT_New_Memory_Face(library, _font_data.ptr, @intCast(_font_data.len), _face_index, &font.__face));

    return font;
}

fn get_char_idx(self: Self, _char: u21) font_error!u32 {
    const idx = freetype.FT_Get_Char_Index(self.__face, @intCast(_char));
    if (idx != 0) return idx;

    system.print_error("undefined character code (charcode) : {d}, (char) : {u}\n", .{ @as(u32, @intCast(_char)), _char });
    return font_error.undefined_char_code;
}

fn load_glyph(self: Self, _char: u21) font_error!void {
    handle_error(freetype.FT_Load_Glyph(self.__face, try get_char_idx(self, _char), freetype.FT_LOAD_DEFAULT | freetype.FT_LOAD_NO_BITMAP));
}

fn next_j(orientation: freetype.FT_Orientation, j: usize, _start: usize, _zero: usize) usize {
    if (j == _zero) return _start;
    if (orientation == freetype.FT_ORIENTATION_FILL_RIGHT) {
        return j - 1;
    } else {
        return j + 1;
    }
}

///https://gencmurat.com/en/posts/zig-strings/
pub fn render_string(self: Self, _str: []const u8, allocator: std.mem.Allocator) !*geometry.polygon {
    var utf8 = (try std.unicode.Utf8View.init(_str)).iterator();

    const polygon = try allocator.alloc(geometry.polygon, 1);
    polygon[0].lines = try allocator.alloc([]geometry.line, 0);
    var i: u32 = 0;
    while (utf8.nextCodepoint()) |codepoint| {
        _ = try _render_char(self, codepoint, .{ @as(f32, @floatFromInt(i * 5)), 0 }, @ptrCast(polygon.ptr), allocator);
        i += 1;
    }
    return @ptrCast(polygon.ptr);
}

pub fn render_char(self: Self, _char: u21, offset: point, allocator: std.mem.Allocator) font_error!*geometry.polygon {
    const polygon = try allocator.alloc(geometry.polygon, 1);
    polygon[0].lines = try allocator.alloc([]geometry.line, 0);
    return _render_char(self, _char, offset, @ptrCast(polygon.ptr), allocator);
}

const font_user_data = struct {
    pen: point,
    offset: point,
    polygon: *geometry.polygon,
    idx: u32,
    idx2: u32,
    len: u32,
    allocator: std.mem.Allocator,
};

fn line_to(vec: [*c]const freetype.FT_Vector, user: ?*anyopaque) callconv(.C) c_int {
    const data: *font_user_data = @alignCast(@ptrCast(user.?));
    const end = point{
        @as(f32, @floatFromInt(vec.*.x)) / 64.0,
        @as(f32, @floatFromInt(vec.*.y)) / 64.0,
    };

    data.*.polygon.*.lines[data.*.idx - 1][data.*.idx2] = geometry.line.line_init(
        data.*.pen + data.*.offset,
        end + data.*.offset,
    );
    data.*.pen = end;

    data.*.idx2 += 1;
    return 0;
}
fn conic_to(vec: [*c]const freetype.FT_Vector, vec2: [*c]const freetype.FT_Vector, user: ?*anyopaque) callconv(.C) c_int {
    const data: *font_user_data = @alignCast(@ptrCast(user.?));
    const control0 = point{
        @as(f32, @floatFromInt(vec.*.x)) / 64.0,
        @as(f32, @floatFromInt(vec.*.y)) / 64.0,
    };
    const end = point{
        @as(f32, @floatFromInt(vec2.*.x)) / 64.0,
        @as(f32, @floatFromInt(vec2.*.y)) / 64.0,
    };

    data.*.polygon.*.lines[data.*.idx - 1][data.*.idx2] = geometry.line.quadratic_init(
        data.*.pen + data.*.offset,
        control0 + data.*.offset,
        end + data.*.offset,
    );
    data.*.pen = end;

    data.*.idx2 += 1;
    return 0;
}
fn cubic_to(vec: [*c]const freetype.FT_Vector, vec2: [*c]const freetype.FT_Vector, vec3: [*c]const freetype.FT_Vector, user: ?*anyopaque) callconv(.C) c_int {
    const data: *font_user_data = @alignCast(@ptrCast(user.?));

    data.*.polygon.*.lines[data.*.idx - 1][data.*.idx2] = .{
        .start = data.*.pen + data.*.offset,
        .control0 = point{
            @as(f32, @floatFromInt(vec.*.x)) / 64.0,
            @as(f32, @floatFromInt(vec.*.y)) / 64.0,
        } + data.*.offset,
        .control1 = point{
            @as(f32, @floatFromInt(vec2.*.x)) / 64.0,
            @as(f32, @floatFromInt(vec2.*.y)) / 64.0,
        } + data.*.offset,
        .end = point{
            @as(f32, @floatFromInt(vec3.*.x)) / 64.0,
            @as(f32, @floatFromInt(vec3.*.y)) / 64.0,
        } + data.*.offset,
    };

    data.*.idx2 += 1;
    return 0;
}
fn move_to(vec: [*c]const freetype.FT_Vector, user: ?*anyopaque) callconv(.C) c_int {
    const data: *font_user_data = @alignCast(@ptrCast(user.?));

    data.*.pen = point{
        @as(f32, @floatFromInt(vec.*.x)) / 64.0,
        @as(f32, @floatFromInt(vec.*.y)) / 64.0,
    };
    data.*.idx += 1;
    data.*.polygon.*.lines[data.*.idx - 1] = data.*.allocator.alloc(geometry.line, data.*.len) catch system.unreachable2();
    if (data.*.idx2 > 0) {
        data.*.polygon.*.lines[data.*.idx - 2] = data.*.allocator.realloc(data.*.polygon.*.lines[data.*.idx - 2], data.*.idx2) catch system.unreachable2();
    }
    data.*.idx2 = 0;
    return 0;
}

fn _render_char(self: Self, _char: u21, offset: point, polygon: *geometry.polygon, allocator: std.mem.Allocator) font_error!*geometry.polygon {
    try load_glyph(self, _char);

    //_ = freetype.FT_Render_Glyph(self.__face.*.glyph, freetype.FT_RENDER_MODE_NORMAL);

    const i: u32 = @intCast(polygon.*.lines.len);
    //var ii: usize = 0;
    polygon.*.lines = try allocator.realloc(polygon.*.lines, i + self.__face.*.glyph.*.outline.n_contours);
    if (system.dbg) {
        var d: usize = 0;
        while (d < self.__face.*.glyph.*.outline.n_points) : (d += 1) {
            system.print_debug("[{d}] {d},{d} tag {d}", .{
                d,
                @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[d].x)) / 64.0,
                @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[d].y)) / 64.0,
                self.__face.*.glyph.*.outline.tags[d],
            });
        }
    }

    const funcs: freetype.FT_Outline_Funcs = .{
        .line_to = line_to,
        .conic_to = conic_to,
        .move_to = move_to,
        .cubic_to = cubic_to,
    };

    var data: font_user_data = .{
        .pen = .{ 0, 0 },
        .offset = offset,
        .polygon = polygon,
        .idx = i,
        .idx2 = 0,
        .allocator = allocator,
        .len = self.__face.*.glyph.*.outline.n_points,
    };

    handle_error(freetype.FT_Outline_Decompose(&self.__face.*.glyph.*.outline, &funcs, &data));
    polygon.*.lines[data.idx - 1] = try allocator.realloc(polygon.*.lines[data.idx - 1], data.idx2);
    // while (i < polygon.*.lines.len) : ({
    //     i += 1;
    //     ii += 1;
    // }) {
    //     const __start: usize = if (ii == 0) 0 else self.__face.*.glyph.*.outline.contours[ii - 1] + 1;
    //     const __end: usize = self.__face.*.glyph.*.outline.contours[ii];
    //     polygon.*.lines[i] = try allocator.alloc(geometry.line, (__end + 1 - __start) * 2);
    //     var e: usize = 0;
    //     const orientation = freetype.FT_Outline_Get_Orientation(&self.__face.*.glyph.*.outline);
    //     var _start = if (orientation == freetype.FT_ORIENTATION_TRUETYPE) __end else __start;
    //     var _end = if (orientation == freetype.FT_ORIENTATION_TRUETYPE) __start else __end;
    //     const _end2 = _end;
    //     const _start2 = _start;

    //     while (self.__face.*.glyph.*.outline.tags[_start] & 1 == 0) {
    //         const temp = _start;
    //         _start = next_j(orientation, _start, _start2, _end2);
    //         _end = temp;
    //     }
    //     var j: usize = _start;
    //     var center_pt: ?point = null;

    //     while (true) : (e += 1) {
    //         const start_pt: point = center_pt orelse point{ @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[j].x)) / 64.0, @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[j].y)) / 64.0 } + offset;
    //         var nextj = if (center_pt != null) j else next_j(orientation, j, _start2, _end2);
    //         center_pt = null;
    //         if (self.__face.*.glyph.*.outline.tags[nextj] & 1 == 1) { //line
    //             const end_pt = self.__face.*.glyph.*.outline.points[nextj];
    //             polygon.*.lines[i][e] = geometry.line.line_init(
    //                 start_pt,
    //                 point{ @as(f32, @floatFromInt(end_pt.x)) / 64.0, @as(f32, @floatFromInt(end_pt.y)) / 64.0 } + offset,
    //             );
    //             system.print_debug("line {d},{d}", .{ j, nextj });
    //         } else {
    //             if (self.__face.*.glyph.*.outline.tags[nextj] & 2 == 1) { //cubic
    //                 const control0_pt: point = point{ @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].x)) / 64.0, @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].y)) / 64.0 } + offset;
    //                 nextj = next_j(orientation, nextj, _start2, _end2);
    //                 const control1_pt: point = point{ @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].x)) / 64.0, @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].y)) / 64.0 } + offset;
    //                 nextj = next_j(orientation, nextj, _start2, _end2);

    //                 var end_pt: point = undefined;

    //                 if (self.__face.*.glyph.*.outline.tags[nextj] & 1 == 0) {
    //                     center_pt = point{ @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].x)) / 64.0, @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].y)) / 64.0 } + offset;
    //                     center_pt = .{ control1_pt[0] + (center_pt.?[0] - control1_pt[0]) / 2, control1_pt[1] + (center_pt.?[1] - control1_pt[1]) / 2 };
    //                     end_pt = center_pt.?;
    //                 } else {
    //                     end_pt = point{ @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].x)) / 64.0, @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].y)) / 64.0 } + offset;
    //                 }
    //                 polygon.*.lines[i][e] = .{
    //                     .start = start_pt,
    //                     .control0 = control0_pt,
    //                     .control1 = control1_pt,
    //                     .end = end_pt,
    //                 };
    //                 system.print_debug("cubic {d},{d}", .{ j, nextj });
    //             } else { //quadratic
    //                 const control0_pt: point = point{ @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].x)) / 64.0, @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].y)) / 64.0 } + offset;
    //                 nextj = next_j(orientation, nextj, _start2, _end2);
    //                 var end_pt: point = undefined;

    //                 if (self.__face.*.glyph.*.outline.tags[nextj] & 1 == 0) {
    //                     center_pt = point{ @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].x)) / 64.0, @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].y)) / 64.0 } + offset;
    //                     center_pt = point{ control0_pt[0] + (center_pt.?[0] - control0_pt[0]) / 2, control0_pt[1] + (center_pt.?[1] - control0_pt[1]) / 2 };
    //                     end_pt = center_pt.?;
    //                 } else {
    //                     end_pt = point{ @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].x)) / 64.0, @as(f32, @floatFromInt(self.__face.*.glyph.*.outline.points[nextj].y)) / 64.0 } + offset;
    //                 }
    //                 polygon.*.lines[i][e] = geometry.line.quadratic_init(
    //                     start_pt,
    //                     control0_pt,
    //                     end_pt,
    //                 );
    //                 system.print_debug("quadratic {d},{d}", .{ j, nextj });
    //             }
    //         }

    //         j = nextj;
    //         if (e != 0 and j == _start) {
    //             e += 1;
    //             break;
    //         }
    //     }
    //}

    return polygon;
}

pub fn free_polygon(allocator: std.mem.Allocator, _polygon: *geometry.polygon) void {
    for (_polygon.*.lines) |value| {
        allocator.free(value);
    }
    allocator.free(_polygon.*.lines);
    allocator.free(_polygon[0..1]);
}

pub fn set_font_size(self: Self, _px_size: u32) void {
    if (self.__face == null) system.handle_error_msg2("ERR __face null(font not inited)");
    handle_error(freetype.FT_Set_Pixel_Sizes(self.__face, 0, _px_size));
}
