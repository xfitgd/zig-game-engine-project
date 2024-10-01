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
const font = @import("engine/font.zig");
const file = @import("engine/file.zig");
const asset_file = @import("engine/asset_file.zig");
const webp = @import("engine/webp.zig");
const img = @import("engine/img.zig");

const file_ = if (system.platform == .android) asset_file else file;

const ArrayList = std.ArrayList;
const MemoryPool = std.heap.MemoryPool;
var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var allocator: std.mem.Allocator = undefined;

const math = @import("engine/math.zig");
const mem = @import("engine/mem.zig");
const graphics = @import("engine/graphics.zig");
const geometry = @import("engine/geometry.zig");

const matrix = math.matrix;

pub var objects: ArrayList(*graphics.iobject) = undefined;
pub var vertices_mem_pool: MemoryPool(graphics.dummy_vertices) = undefined;
pub var objects_mem_pool: MemoryPool(graphics.dummy_object) = undefined;
pub var indices_mem_pool: MemoryPool(graphics.dummy_indices) = undefined;

pub var g_proj: graphics.projection = undefined;
pub var g_camera: graphics.camera = undefined;

var font0: font = undefined;
var font0_data: []u8 = undefined;

var text_color: math.vector = .{ 1, 1, 1, 1 };

var shape_src: graphics.shape.source = undefined;
// var shape_src2: graphics.shape.source = undefined;
// var extra_src = [_]*graphics.shape.source{&shape_src2};
var image_src: graphics.image.source = undefined;

pub fn xfit_init() void {
    font.start();

    objects = ArrayList(*graphics.iobject).init(allocator);
    vertices_mem_pool = MemoryPool(graphics.dummy_vertices).init(allocator);
    objects_mem_pool = MemoryPool(graphics.dummy_object).init(allocator);
    indices_mem_pool = MemoryPool(graphics.dummy_indices).init(allocator);

    const object = graphics.take_object(*graphics.shape, &objects_mem_pool) catch system.handle_error_msg2("objects_mem_pool 1 OutOfMemory");
    g_proj = graphics.projection.init(.perspective, std.math.degreesToRadians(45)) catch |e| system.handle_error2("projection.init {s}", .{@errorName(e)});
    const object2 = graphics.take_object(*graphics.image, &objects_mem_pool) catch system.handle_error_msg2("objects_mem_pool 2 OutOfMemory");
    g_camera = graphics.camera.init(.{ 0, 0, -3, 1 }, .{ 0, 0, 0, 1 }, .{ 0, 1, 0, 1 });

    object.* = graphics.shape.init();
    shape_src = graphics.shape.source.init_for_alloc(allocator);
    shape_src.color = .{ 1, 1, 1, 1 };

    //shape_src2 = graphics.shape.source.init_for_alloc(allocator);
    //shape_src2.color = .{ 1, 0, 1, 1 };

    const vertices2 = graphics.take_vertices(*graphics.vertices(graphics.tex_vertex_2d), &vertices_mem_pool) catch system.handle_error_msg2("vertices_mem_pool OutOfMemory");
    const indices2 = graphics.take_indices(*graphics.indices, &indices_mem_pool) catch system.handle_error_msg2("indices_mem_pool OutOfMemory");
    object2.* = graphics.image.init();
    vertices2.* = graphics.vertices(graphics.tex_vertex_2d).init_for_alloc(allocator);
    indices2.* = graphics.indices.init_for_alloc(allocator);
    vertices2.*.array = allocator.alloc(graphics.tex_vertex_2d, 4) catch system.handle_error_msg2("vertices.*.array OutOfMemory");
    indices2.*.array = allocator.alloc(graphics.DEF_IDX_TYPE, 6) catch system.handle_error_msg2("indices.*.array OutOfMemory");

    @memcpy(vertices2.*.array.?, &[_]graphics.tex_vertex_2d{
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
    @memcpy(indices2.*.array.?, &[_]graphics.DEF_IDX_TYPE{ 0, 1, 2, 1, 3, 2 });
    vertices2.*.build(.read_gpu);
    indices2.*.build(.read_gpu);

    const data = file_.read_file("test.webp", allocator) catch |e| system.handle_error3("test.webp read_file", e);
    defer allocator.free(data);
    var img_decoder: webp = .{};
    img_decoder.load_header(data) catch |e| system.handle_error3("test.webp loadheader fail", e);

    image_src = .{
        .texture = .{},
        .vertices = vertices2,
        .indices = indices2,
    };
    image_src.texture.width = img_decoder.width();
    image_src.texture.height = img_decoder.height();
    image_src.texture.pixels = allocator.alloc(u8, img_decoder.width() * img_decoder.height() * 4) catch |e| system.handle_error3("_texture.pixels alloc", e);

    img_decoder.decode(.RGBA, data, image_src.texture.pixels.?) catch |e| system.handle_error3("test.webp decode", e);

    image_src.texture.build();

    object2.src = &image_src;

    font0_data = file_.read_file("SourceHanSerifK-ExtraLight.otf", allocator) catch |e| system.handle_error3("read_file font0_data", e);
    font0 = font.init(font0_data, 0);

    font0.render_string("Hello World!\n안녕하세요. break;", &shape_src, allocator) catch |e| system.handle_error3("font0.render_string", e);
    //font0.render_string("CONTINUE계속", &shape_src2, allocator) catch |e| system.handle_error3("font0.render_string", e);
    //font0.render_string_box("Hello World!\nbreak;byebyeseretedfegherjht", .{ 50, 30 }, .{ 0, 1, 1, 1 }, &shape_src, allocator) catch |e| system.handle_error3("font0.render_string", e);

    shape_src.build(.read_gpu);
    //shape_src2.build(.read_gpu);

    object.*.interface.transform.camera = &g_camera;
    object.*.interface.transform.projection = &g_proj;
    object.*.src = &shape_src;
    //object.*.extra_src = extra_src[0..1];
    object.*.interface.build(&object.*.interface, .readwrite_cpu);

    object.*.interface.transform.model = matrix.scaling(0.02, 0.02, 1.0).multiply(&matrix.translation(-1, 0, 0));
    object.*.interface.transform.map_update();

    object2.*.interface.transform.camera = &g_camera;
    object2.*.interface.transform.projection = &g_proj;
    object2.*.interface.build(&object2.*.interface, .readwrite_cpu);

    // object2.*.interface.transform.model = matrix.translation(-1, 0, 0);
    // object2.*.interface.transform.map_update();

    objects.append(&object2.*.interface) catch system.handle_error_msg2("objects.append(&object2s.*.interface)");
    objects.append(&object.*.interface) catch system.handle_error_msg2("objects.append(&object.*.interface)");

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
    shape_src.deinit_for_alloc();
    //shape_src2.deinit_for_alloc();

    image_src.vertices.*.deinit_for_alloc();
    image_src.indices.?.*.deinit_for_alloc();
    allocator.free(image_src.texture.pixels.?);
    image_src.texture.deinit();

    g_camera.deinit();
    g_proj.deinit();

    for (objects.items) |value| {
        value.*.deinit();
    }
    objects.deinit();
    vertices_mem_pool.deinit();
    objects_mem_pool.deinit();
    indices_mem_pool.deinit();

    font0.deinit();
    allocator.free(font0_data);
    font.destroy();
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
        .use_console = true,
    };
    gpa = .{};
    allocator = gpa.allocator(); //반드시 할당자는 main에서 초기화
    xfit.xfit_main(allocator, &init_setting);
}
