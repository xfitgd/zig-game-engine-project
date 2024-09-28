// !! windows platform only do not change
pub const UNICODE = false;
// !! android platform only do not change
comptime {
    if (@import("engine/system.zig").platform == .android)
        _ = @import("engine/__android.zig").android.ANativeActivity_createFunc;
}
// !!

const std = @import("std");
const xfit = @import("engine/xfit.zig");
const system = @import("engine/system.zig");
const builtin = @import("builtin");

const ArrayList = std.ArrayList;
const MemoryPool = std.heap.MemoryPool;
var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var allocator: std.mem.Allocator = undefined;

const math = @import("engine/math.zig");
const mem = @import("engine/mem.zig");
const file = @import("engine/file.zig");
const asset_file = @import("engine/asset_file.zig");
const webp = @import("engine/webp.zig");
const img = @import("engine/img.zig");
const graphics = @import("engine/graphics.zig");

const file_ = if (system.platform == .android) asset_file else file;

const matrix = math.matrix;

pub var objects: ArrayList(*graphics.iobject) = undefined;
pub var vertices_mem_pool: MemoryPool(graphics.dummy_vertices) = undefined;
pub var objects_mem_pool: MemoryPool(graphics.dummy_object) = undefined;
pub var indices_mem_pool: MemoryPool(graphics.dummy_indices) = undefined;
pub var textures_mem_pool: MemoryPool(graphics.texture) = undefined;

pub var g_proj: graphics.projection = undefined;
pub var g_camera: graphics.camera = undefined;

pub fn xfit_init() void {
    objects = ArrayList(*graphics.iobject).init(allocator);
    vertices_mem_pool = MemoryPool(graphics.dummy_vertices).init(allocator);
    objects_mem_pool = MemoryPool(graphics.dummy_object).init(allocator);
    indices_mem_pool = MemoryPool(graphics.dummy_indices).init(allocator);
    textures_mem_pool = MemoryPool(graphics.texture).init(allocator);

    const vertices = graphics.take_vertices(*graphics.vertices(graphics.tex_vertex_2d), &vertices_mem_pool) catch system.handle_error_msg2("vertices_mem_pool OutOfMemory");
    const indices = graphics.take_indices(*graphics.indices, &indices_mem_pool) catch system.handle_error_msg2("indices_mem_pool OutOfMemory");
    const object = graphics.take_object(*graphics.image2d, &objects_mem_pool) catch system.handle_error_msg2("objects_mem_pool 1 OutOfMemory");
    const object2 = graphics.take_object(*graphics.image2d, &objects_mem_pool) catch system.handle_error_msg2("objects_mem_pool 2 OutOfMemory");
    const object3 = graphics.take_object(*graphics.image2d, &objects_mem_pool) catch system.handle_error_msg2("objects_mem_pool 3 OutOfMemory");
    const _texture: *graphics.texture = textures_mem_pool.create() catch system.handle_error_msg2("textures_mem_pool OutOfMemory");
    g_proj = graphics.projection.init(.perspective, std.math.degreesToRadians(45)) catch |e| system.handle_error3("projection.init", e);
    g_camera = graphics.camera.init(.{ 0, 0, -3, 1 }, .{ 0, 0, 0, 1 }, .{ 0, 1, 0, 1 });

    object.* = graphics.image2d.init();
    object2.* = graphics.image2d.init();
    object3.* = graphics.image2d.init();
    vertices.* = graphics.vertices(graphics.tex_vertex_2d).init_for_alloc(allocator);
    indices.* = graphics.indices.init_for_alloc(allocator);
    vertices.*.array = allocator.alloc(graphics.tex_vertex_2d, 4) catch system.handle_error_msg2("vertices.*.array OutOfMemory");
    indices.*.array = allocator.alloc(graphics.DEF_IDX_TYPE, 6) catch system.handle_error_msg2("indices.*.array OutOfMemory");

    @memcpy(vertices.*.array, &[_]graphics.tex_vertex_2d{
        .{
            .pos = .{ -0.5, 0.5 },
            .uv = .{ 0, 0 },
        },
        .{
            .pos = .{ 0.5, 0.5 },
            .uv = .{ 1, 0 },
        },
        .{
            .pos = .{ -0.5, -0.5 },
            .uv = .{ 0, 1 },
        },
        .{
            .pos = .{ 0.5, -0.5 },
            .uv = .{ 1, 1 },
        },
    });
    @memcpy(indices.*.array, &[_]graphics.DEF_IDX_TYPE{ 0, 1, 2, 1, 3, 2 });
    vertices.*.build(.read_gpu);
    indices.*.build(.read_gpu);

    const data = file_.read_file("test.webp", allocator) catch |e| system.handle_error3("test.webp read_file", e);
    defer allocator.free(data);
    var img_decoder: webp = .{};
    img_decoder.load_header(data) catch |e| system.handle_error3("test.webp loadheader fail", e);
    _texture.* = .{};
    _texture.*.width = img_decoder.width();
    _texture.*.height = img_decoder.height();
    _texture.*.pixels = allocator.alloc(u8, img_decoder.width() * img_decoder.height() * 4) catch |e| system.handle_error3("_texture.pixels alloc", e);

    img_decoder.decode(.RGBA, data, _texture.*.pixels) catch |e| system.handle_error3("test.webp decode", e);

    _texture.build();

    for ([3]*graphics.image2d{ object, object2, object3 }) |value| {
        value.*.interface.transform.camera = &g_camera;
        value.*.interface.transform.projection = &g_proj;
        value.*.vertices = vertices;
        value.*.indices = indices;
        value.*.texture = _texture;
        value.*.build(.readwrite_cpu);
        objects.append(&value.*.interface) catch |e| system.handle_error3("_texture.pixels.resize", e);
    }
    object2.*.interface.transform.model = matrix.translation(-3, 0, 3);
    object3.*.interface.transform.model = matrix.translation(3, 0, 3);
    object2.*.interface.transform.map_update();
    object3.*.interface.transform.map_update();

    graphics.scene = &objects.items;
    graphics.scene = &objects.items;
}

///윈도우 크기 바뀔때 xfit_update 바로 전 호출
pub fn xfit_size_update() void {
    //system.print_debug("size update", .{});
    g_proj.init_matrix(.perspective, std.math.degreesToRadians(45)) catch |e| system.handle_error3("g_proj.init_matrix", e);
    g_proj.map_update();
}

pub fn xfit_update() void {}

pub fn xfit_size() void {}

///before system clean
pub fn xfit_destroy() void {
    const ivertices = objects.items[0].*.get_ivertices(objects.items[0]);
    const iindices = objects.items[0].*.get_iindices(objects.items[0]);
    const _texture = objects.items[0].*.get_texture(objects.items[0]);
    ivertices.?.*.deinit_for_alloc(ivertices.?);
    iindices.?.*.deinit_for_alloc(iindices.?);
    allocator.free(_texture.?.*.pixels);
    _texture.?.*.deinit();

    g_camera.deinit();
    g_proj.deinit();

    for (objects.items) |value| {
        value.*.deinit();
    }
    objects.deinit();
    vertices_mem_pool.deinit();
    objects_mem_pool.deinit();
    indices_mem_pool.deinit();
    textures_mem_pool.deinit();
}

///after system clean
pub fn xfit_clean() void {
    if (system.dbg and gpa.deinit() != .ok) unreachable;
}

pub fn xfit_activate(is_activate: bool, is_pause: bool) void {
    _ = is_activate;
    _ = is_pause;
}

pub fn xfit_closing() bool {
    return true;
}

pub fn main() void {
    const init_setting: system.init_setting = .{
        .window_width = 640,
        .window_height = 480,
    };
    gpa = .{};
    allocator = gpa.allocator(); //반드시 할당자는 main에서 초기화
    xfit.xfit_main(allocator, &init_setting);
}
