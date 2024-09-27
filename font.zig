const std = @import("std");
const unicode = std.unicode;
const system = @import("system.zig");
const __system = @import("__system.zig");
pub const freetype = @cImport({
    @cInclude("freetype/ft2build.h");
    @cInclude("freetype/freetype/freetype.h");
    @cInclude("freetype/freetype/ftoutln.h");
});
const geometry = @import("geometry.zig");
const graphics = @import("graphics.zig");
const math = @import("math.zig");
const point = math.point;
const vector = math.vector;

const AutoHashMap = std.AutoHashMap;

const Self = @This();

var library: freetype.FT_Library = null;

pub const font_error = error{
    undefined_char_code,
} || std.mem.Allocator.Error;

pub const char_data = struct {
    raw_p: ?graphics.raw_polygon = null,
    advance: point,
    left: f32,
    top: f32,
    allocator: std.mem.Allocator,
};

__char_array: AutoHashMap(u21, char_data),
__face: freetype.FT_Face = null,

fn handle_error(code: freetype.FT_Error) void {
    if (code != freetype.FT_Err_Ok) {
        system.handle_error2("Code : {d}, msg : {s}\n", .{ code, freetype.FT_Error_String(code) });
    }
}

pub fn start() void {
    if (system.dbg and __system.font_started) system.handle_error_msg2("font already started");
    if (system.dbg) __system.font_started = true;
    handle_error(freetype.FT_Init_FreeType(&library));
}

pub fn destroy() void {
    if (system.dbg and !__system.font_started) system.handle_error_msg2("font not started");
    _ = freetype.FT_Done_FreeType(library);
    if (system.dbg) __system.font_started = false;
}

pub fn init(_font_data: []const u8, _face_index: freetype.FT_Long) Self {
    var font: Self = .{
        .__char_array = AutoHashMap(u21, char_data).init(__system.allocator),
    };
    handle_error(freetype.FT_New_Memory_Face(library, _font_data.ptr, @intCast(_font_data.len), _face_index, &font.__face));

    return font;
}

pub fn deinit(self: *Self) void {
    var it = self.*.__char_array.valueIterator();
    while (it.next()) |v| {
        if (v.*.raw_p != null) {
            v.*.allocator.free(v.*.raw_p.?.vertices);
            v.*.allocator.free(v.*.raw_p.?.indices);
        }
    }
    self.*.__char_array.deinit();
}

pub fn clear_char_array(self: *Self) void {
    const allocator = self.*.__char_array.allocator;
    deinit(self);
    self.*.__char_array = AutoHashMap(u21, char_data).init(allocator);
}

fn get_char_idx(self: *Self, _char: u21) font_error!u32 {
    const idx = freetype.FT_Get_Char_Index(self.*.__face, @intCast(_char));
    if (idx != 0) return idx;

    system.print_error("undefined character code (charcode) : {d}, (char) : {u}\n", .{ @as(u32, @intCast(_char)), _char });
    return font_error.undefined_char_code;
}

fn load_glyph(self: *Self, _char: u21) font_error!void {
    handle_error(freetype.FT_Load_Glyph(self.*.__face, try get_char_idx(self, _char), freetype.FT_LOAD_DEFAULT | freetype.FT_LOAD_NO_BITMAP));
}

pub fn render_string(self: *Self, _str: []const u8, color: vector, out_polygon: *graphics.raw_polygon, allocator: std.mem.Allocator) !void {
    out_polygon.*.vertices = try allocator.alloc(graphics.color_vertex_2d, 0);
    out_polygon.*.indices = try allocator.alloc(u32, 0);
    //https://gencmurat.com/en/posts/zig-strings/
    var utf8 = (try std.unicode.Utf8View.init(_str)).iterator();
    var offset: point = .{ 0, 0 };
    while (utf8.nextCodepoint()) |codepoint| {
        if (codepoint == '\n') {
            offset[1] -= @as(f32, @floatFromInt(self.*.__face.*.glyph.*.metrics.height)) / 64.0 * 1.3;
            offset[0] = 0;
            continue;
        }
        try _render_char(self, codepoint, out_polygon, &offset, null, .{ 1, 1 }, color, allocator);
    }
}

pub fn render_string_box(self: *Self, _str: []const u8, area: math.point, color: vector, out_polygon: *graphics.raw_polygon, allocator: std.mem.Allocator) !void {
    out_polygon.*.vertices = try allocator.alloc(graphics.color_vertex_2d, 0);
    out_polygon.*.indices = try allocator.alloc(u32, 0);
    //https://gencmurat.com/en/posts/zig-strings/
    var utf8 = (try std.unicode.Utf8View.init(_str)).iterator();
    var offset: point = .{ 0, 0 };
    while (utf8.nextCodepoint()) |codepoint| {
        if (offset[1] <= -area[1]) break;
        if (codepoint == '\n') {
            offset[1] -= @as(f32, @floatFromInt(self.*.__face.*.glyph.*.metrics.height)) / 64.0 * 1.3;
            offset[0] = 0;
            continue;
        }
        try _render_char(self, codepoint, out_polygon, &offset, area, .{ 1, 1 }, color, allocator);
    }
}

fn _render_char(self: *Self, char: u21, out_polygon: *graphics.raw_polygon, offset: *point, area: ?math.point, scale: point, color: vector, allocator: std.mem.Allocator) !void {
    var char_d: ?*char_data = self.*.__char_array.getPtr(char);

    if (char_d != null) {} else {
        try load_glyph(self, char);
        var char_d2: char_data = undefined;

        var poly: geometry.polygon = .{ .lines = try allocator.alloc([]geometry.line, self.*.__face.*.glyph.*.outline.n_contours) };
        defer {
            for (poly.lines) |v| {
                allocator.free(v);
            }
            allocator.free(poly.lines);
        }

        if (system.dbg) {
            var d: usize = 0;
            while (d < self.__face.*.glyph.*.outline.n_points) : (d += 1) {
                system.print_debug("[{d}] {d},{d} tag {d}", .{
                    d,
                    @as(f32, @floatFromInt(self.*.__face.*.glyph.*.outline.points[d].x)) / 64.0,
                    @as(f32, @floatFromInt(self.*.__face.*.glyph.*.outline.points[d].y)) / 64.0,
                    self.*.__face.*.glyph.*.outline.tags[d],
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
            .polygon = &poly,
            .idx = 0,
            .idx2 = 0,
            .allocator = allocator,
            .len = self.*.__face.*.glyph.*.outline.n_points,
        };

        if (freetype.FT_Outline_Decompose(&self.*.__face.*.glyph.*.outline, &funcs, &data) != freetype.FT_Err_Ok) {
            return font_error.OutOfMemory;
        }
        if (data.idx == 0) {
            char_d2.raw_p = null;
        } else {
            poly.lines[data.idx - 1] = try allocator.realloc(poly.lines[data.idx - 1], data.idx2);

            var vertices_array = std.ArrayList(graphics.color_vertex_2d).init(allocator);
            var indices_array = std.ArrayList(u32).init(allocator);
            defer {
                vertices_array.deinit();
                indices_array.deinit();
            }

            try poly.compute_polygon(allocator, &vertices_array, &indices_array);

            char_d2.raw_p = .{
                .vertices = try allocator.alloc(graphics.color_vertex_2d, vertices_array.items.len),
                .indices = try allocator.alloc(u32, indices_array.items.len),
            };
            @memcpy(char_d2.raw_p.?.vertices, vertices_array.items);
            @memcpy(char_d2.raw_p.?.indices, indices_array.items);
        }
        char_d2.advance[0] = @as(f32, @floatFromInt(self.*.__face.*.glyph.*.advance.x)) / 64.0;
        char_d2.advance[1] = @as(f32, @floatFromInt(self.*.__face.*.glyph.*.advance.y)) / 64.0;
        char_d2.left = @as(f32, @floatFromInt(self.*.__face.*.glyph.*.bitmap_left)) / 64.0;
        char_d2.top = @as(f32, @floatFromInt(self.*.__face.*.glyph.*.bitmap_top)) / 64.0;

        char_d2.allocator = allocator;
        try self.*.__char_array.put(char, char_d2);
        char_d = &char_d2;
    }
    if (area != null and offset.*[0] + char_d.?.*.advance[0] * scale[0] >= area.?[0]) {
        offset.*[1] -= @as(f32, @floatFromInt(self.*.__face.*.glyph.*.metrics.height)) / 64.0 * 1.3;
        offset.*[0] = 0;
        if (offset.*[1] <= -area.?[1]) return;
    }
    if (char_d.?.raw_p == null) {} else {
        const len = out_polygon.*.vertices.len;
        out_polygon.*.vertices = try allocator.realloc(out_polygon.*.vertices, len + char_d.?.raw_p.?.vertices.len);
        @memcpy(out_polygon.*.vertices[len..], char_d.?.raw_p.?.vertices);
        var i: usize = len;
        while (i < out_polygon.*.vertices.len) : (i += 1) {
            out_polygon.*.vertices[i].pos *= scale;
            out_polygon.*.vertices[i].pos += (offset.* + point{ char_d.?.*.left, char_d.?.*.top }) * scale;
            out_polygon.*.vertices[i].color = color;
        }
        const ilen = out_polygon.*.indices.len;
        out_polygon.*.indices = try allocator.realloc(out_polygon.*.indices, ilen + char_d.?.raw_p.?.indices.len);
        @memcpy(out_polygon.*.indices[ilen..], char_d.?.raw_p.?.indices);
        i = ilen;
        while (i < out_polygon.*.indices.len) : (i += 1) {
            out_polygon.*.indices[i] += @intCast(len);
        }
    }
    offset.*[0] += char_d.?.*.advance[0] * scale[0];
    offset.*[1] -= char_d.?.*.advance[1] * scale[1];
}

pub fn free_raw_polygon(allocator: std.mem.Allocator, _polygon: *graphics.raw_polygon) void {
    allocator.free(_polygon.*.vertices);
    allocator.free(_polygon.*.indices);
}

const font_user_data = struct {
    pen: point,
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
        data.*.pen,
        end,
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
        data.*.pen,
        control0,
        end,
    );
    data.*.pen = end;

    data.*.idx2 += 1;
    return 0;
}
fn cubic_to(vec: [*c]const freetype.FT_Vector, vec2: [*c]const freetype.FT_Vector, vec3: [*c]const freetype.FT_Vector, user: ?*anyopaque) callconv(.C) c_int {
    const data: *font_user_data = @alignCast(@ptrCast(user.?));
    const control0 = point{
        @as(f32, @floatFromInt(vec.*.x)) / 64.0,
        @as(f32, @floatFromInt(vec.*.y)) / 64.0,
    };
    const control1 = point{
        @as(f32, @floatFromInt(vec2.*.x)) / 64.0,
        @as(f32, @floatFromInt(vec2.*.y)) / 64.0,
    };
    const end = point{
        @as(f32, @floatFromInt(vec3.*.x)) / 64.0,
        @as(f32, @floatFromInt(vec3.*.y)) / 64.0,
    };

    data.*.polygon.*.lines[data.*.idx - 1][data.*.idx2] = .{
        .start = data.*.pen,
        .control0 = control0,
        .control1 = control1,
        .end = end,
    };
    data.*.pen = end;

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
    data.*.polygon.*.lines[data.*.idx - 1] = data.*.allocator.alloc(geometry.line, data.*.len) catch return -1;
    if (data.*.idx2 > 0) {
        data.*.polygon.*.lines[data.*.idx - 2] = data.*.allocator.realloc(data.*.polygon.*.lines[data.*.idx - 2], data.*.idx2) catch return -1;
    }
    data.*.idx2 = 0;
    return 0;
}
