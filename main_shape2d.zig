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

var shape_src: graphics.shape.source = .{};

pub fn xfit_init() void {
    font.start();

    objects = ArrayList(*graphics.iobject).init(allocator);
    vertices_mem_pool = MemoryPool(graphics.dummy_vertices).init(allocator);
    objects_mem_pool = MemoryPool(graphics.dummy_object).init(allocator);
    indices_mem_pool = MemoryPool(graphics.dummy_indices).init(allocator);
    const vertices = graphics.take_vertices(*graphics.vertices(graphics.color_vertex_2d), &vertices_mem_pool) catch system.handle_error_msg2("vertices_mem_pool OutOfMemory");
    const curve_vertices = graphics.take_vertices(*graphics.vertices(graphics.shape_color_vertex_2d), &vertices_mem_pool) catch system.handle_error_msg2("vertices_mem_pool OutOfMemory");
    const indices = graphics.take_indices(*graphics.indices, &indices_mem_pool) catch system.handle_error_msg2("indices_mem_pool OutOfMemory");
    const curve_indices = graphics.take_indices(*graphics.indices, &indices_mem_pool) catch system.handle_error_msg2("indices_mem_pool OutOfMemory");
    const object = graphics.take_object(*graphics.shape, &objects_mem_pool) catch system.handle_error_msg2("objects_mem_pool 1 OutOfMemory");
    g_proj = graphics.projection.init(.perspective, std.math.degreesToRadians(45)) catch |e| system.handle_error2("projection.init {s}", .{@errorName(e)});
    g_camera = graphics.camera.init(.{ 0, 0, -3, 1 }, .{ 0, 0, 0, 1 }, .{ 0, 1, 0, 1 });

    object.* = graphics.shape.init();
    vertices.* = graphics.vertices(graphics.color_vertex_2d).init_for_alloc(allocator);
    curve_vertices.* = graphics.vertices(graphics.shape_color_vertex_2d).init_for_alloc(allocator);
    indices.* = graphics.indices.init_for_alloc(allocator);
    curve_indices.* = graphics.indices.init_for_alloc(allocator);
    shape_src.vertices = vertices;
    shape_src.curve_vertices = curve_vertices;
    shape_src.indices = indices;
    shape_src.curve_indices = curve_indices;

    font0_data = file_.read_file("BinggraeⅡ.otf", allocator) catch |e| system.handle_error3("read_file font0_data", e);
    font0 = font.init(font0_data, 0);

    var tt = std.time.Timer.start() catch system.unreachable2();
    font0.render_string("Hello World!\nbreak;", .{ 0, 1, 1, 0.5 }, &shape_src, allocator) catch |e| system.handle_error3("font0.render_string", e);
    //font0.render_string_box("Hello World!\nbreak;byebyeseretedfegherjht", .{ 50, 30 }, .{ 0, 1, 1, 1 }, &shape_src, allocator) catch |e| system.handle_error3("font0.render_string", e);
    system.print("render string {d}", .{tt.lap()});

    shape_src.build_all(.read_gpu);

    for ([_]*graphics.shape{object}) |value| {
        value.*.interface.transform.camera = &g_camera;
        value.*.interface.transform.projection = &g_proj;
        value.*.src = &shape_src;
        value.*.interface.build(.readwrite_cpu);

        value.*.interface.transform.model = matrix.scaling(0.02, 0.02, 1.0).multiply(&matrix.translation(-1, 0, 0));
        value.*.interface.transform.map_update();
        objects.append(&value.*.interface) catch system.handle_error_msg2("objects.append(&value.*.interface)");
    }

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
    shape_src.vertices.?.deinit_for_alloc();
    shape_src.curve_vertices.?.deinit_for_alloc();
    shape_src.indices.?.deinit_for_alloc();
    shape_src.curve_indices.?.deinit_for_alloc();

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
