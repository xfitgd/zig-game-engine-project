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
const image_util = @import("engine/image_util.zig");
const window = @import("engine/window.zig");
const animator = @import("engine/animator.zig");
const input = @import("engine/input.zig");

const lua = @import("engine/lua.zig");

const timer_callback = @import("engine/timer_callback.zig");

const file_ = if (system.platform == .android) asset_file else file;

const ArrayList = std.ArrayList;
const MemoryPoolExtra = std.heap.MemoryPoolExtra;
var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var allocator: std.mem.Allocator = undefined;

const math = @import("engine/math.zig");
const mem = @import("engine/mem.zig");
const graphics = @import("engine/graphics.zig");
const render_command = @import("engine/render_command.zig");
const geometry = @import("engine/geometry.zig");

const matrix = math.matrix;

pub var objects: ArrayList(*graphics.iobject) = undefined;
pub var vertices_mem_pool: MemoryPoolExtra(graphics.dummy_vertices, .{}) = undefined;
pub var objects_mem_pool: MemoryPoolExtra(graphics.iobject, .{}) = undefined;
pub var indices_mem_pool: MemoryPoolExtra(graphics.dummy_indices, .{}) = undefined;

pub var g_proj: graphics.projection = .{};
pub var g_camera: graphics.camera = undefined;

var font0: font = undefined;
var font0_data: []u8 = undefined;

var shape_src: graphics.shape.source = undefined;
var shape_src2: graphics.shape.source = undefined;
var extra_src = [_]*graphics.shape.source{&shape_src2};
var image_src: graphics.texture = undefined;
var anim_image_src: graphics.texture_array = undefined;
var cmd: *render_command = undefined;
var cmd2: *render_command = undefined;
var cmds: [2]*render_command = .{ undefined, undefined };

var color_trans: graphics.color_transform = undefined;

const player = animator.player;
const animate_object = animator.animate_object;

var anim: player = .{
    .target_fps = 10,
    .obj = undefined,
};

pub const CANVAS_W: f32 = 1280;
pub const CANVAS_H: f32 = 720;

// fn error_func(text: []u8, stack_trace: []u8) void {
//     var fs: file = .{};
//     fs.open("xfit_err.log", .{
//         .truncate = false,
//     }) catch unreachable;
//     _ = fs.write(text) catch unreachable;
//     _ = fs.write(stack_trace) catch unreachable;
//     fs.close();
// }

pub fn xfit_init() void {
    // const luaT = lua.c.luaL_newstate();
    // defer lua.c.lua_close(luaT);
    // lua.c.luaL_openlibs(luaT);

    // var ress = lua.c.luaL_loadfilex(luaT, "test.lua", null);
    // ress = lua.c.lua_pcallk(luaT, 0, 0, 0, 0, null);
    // ress = lua.c.lua_getglobal(luaT, "Printhello");
    // ress = lua.c.lua_pcallk(luaT, 0, 0, 0, 0, null);

    //system.set_error_handling_func(error_func);

    font.start();

    objects = ArrayList(*graphics.iobject).init(allocator);
    vertices_mem_pool = MemoryPoolExtra(graphics.dummy_vertices, .{}).init(allocator);
    objects_mem_pool = MemoryPoolExtra(graphics.iobject, .{}).init(allocator);
    indices_mem_pool = MemoryPoolExtra(graphics.dummy_indices, .{}).init(allocator);

    g_proj.init_matrix_orthographic(CANVAS_W, CANVAS_H) catch |e| system.handle_error2("projection.init {s}", .{@errorName(e)});
    g_proj.build(.readwrite_cpu);

    const text_shape = objects_mem_pool.create() catch system.handle_error_msg2("objects_mem_pool 1 OutOfMemory");
    const img = objects_mem_pool.create() catch system.handle_error_msg2("objects_mem_pool 2 OutOfMemory");
    const anim_img = objects_mem_pool.create() catch system.handle_error_msg2("objects_mem_pool 3 OutOfMemory");
    g_camera = graphics.camera.init(.{ 0, 0, -3, 1 }, .{ 0, 0, 0, 1 }, .{ 0, 1, 0, 1 });

    text_shape.* = .{ ._shape = .{} };
    shape_src = graphics.shape.source.init_for_alloc(allocator);
    shape_src.color = .{ 1, 1, 1, 0.5 };

    shape_src2 = graphics.shape.source.init_for_alloc(allocator);
    shape_src2.color = .{ 1, 0, 1, 1 };

    img.* = .{ ._image = graphics.image.init() };
    anim_img.* = .{ ._anim_image = graphics.animate_image.init() };

    const data = file_.read_file("test.webp", allocator) catch |e| system.handle_error3("test.webp read_file", e);
    defer allocator.free(data);
    var img_decoder: webp = .{};
    img_decoder.load_header(data) catch |e| system.handle_error3("test.webp loadheader fail", e);

    image_src = graphics.texture.init();
    image_src.width = img_decoder.width();
    image_src.height = img_decoder.height();
    image_src.pixels = allocator.alloc(u8, img_decoder.width() * img_decoder.height() * 4) catch |e| system.handle_error3("_texture.pixels alloc", e);

    img_decoder.decode(.RGBA, data, image_src.pixels.?) catch |e| system.handle_error3("test.webp decode", e);

    const anim_data = file_.read_file("wasp.webp", allocator) catch |e| system.handle_error3("wasp.webp read_file", e);
    defer allocator.free(anim_data);
    img_decoder.load_anim_header(anim_data) catch |e| system.handle_error3("wasp.webp load_anim_header fail", e);

    anim_image_src = graphics.texture_array.init();
    anim_image_src.sampler = graphics.texture_array.get_default_nearest_sampler();
    anim_image_src.width = img_decoder.width();
    anim_image_src.height = img_decoder.height();
    anim_image_src.frames = img_decoder.frame_count();
    anim_image_src.pixels = allocator.alloc(u8, img_decoder.size(.RGBA)) catch |e| system.handle_error3("anim_image_src.pixels alloc", e);

    img_decoder.decode(.RGBA, data, anim_image_src.pixels.?) catch |e| system.handle_error3("wasp.webp decode", e);

    anim_image_src.build();
    image_src.build();

    img.*._image.src = &image_src;
    anim_img.*._anim_image.src = &anim_image_src;

    font0_data = file_.read_file("SourceHanSerifK-ExtraLight.otf", allocator) catch |e| system.handle_error3("read_file font0_data", e);
    font0 = font.init(font0_data, 0);

    font0.render_string("Hello World!\n안녕하세요. break;", &shape_src, allocator) catch |e| system.handle_error3("font0.render_string", e);
    // var t1 = std.time.Timer.start() catch unreachable;
    // font0.render_string("Hello World!\n안녕하세요. break;", &shape_src, allocator) catch |e| system.handle_error3("font0.render_string", e);
    // system.print("{d}", .{t1.lap()});
    font0.render_string("CONTINUE계속", &shape_src2, allocator) catch |e| system.handle_error3("font0.render_string", e);
    // font0.render_string_box("Hello World!\nbreak;byebyeseretedfegherjht", .{ 50, 30 }, &shape_src, allocator) catch |e| system.handle_error3("font0.render_string", e);

    shape_src2.build(.read_gpu, .readwrite_cpu);

    text_shape.*._shape.transform.camera = &g_camera;
    text_shape.*._shape.transform.projection = &g_proj;
    text_shape.*._shape.src = &shape_src;
    text_shape.*._shape.extra_src = extra_src[0..1];

    text_shape.*._shape.transform.model = matrix.scaling(5, 5, 1.0).multiply(&matrix.translation(-200, 0, 0));
    //text_shape.*.build();

    color_trans = graphics.color_transform.init();
    color_trans.color_mat.e = .{
        .{ -1, 0, 0, 0 },
        .{ 0, -1, 0, 0 },
        .{ 0, 0, -1, 0 },
        .{ 1, 1, 1, 1 },
    };
    color_trans.build(.read_gpu);

    img.*._image.color_tran = &color_trans;
    img.*._image.transform.camera = &g_camera;
    img.*._image.transform.projection = &g_proj;
    img.*._image.transform.model = matrix.scaling(
        @as(f32, @floatFromInt(image_src.width)) * 2,
        @as(f32, @floatFromInt(image_src.height)) * 2,
        1.0,
    );
    img.*.build();

    anim_img.*._anim_image.transform.camera = &g_camera;
    anim_img.*._anim_image.transform.projection = &g_proj;
    anim_img.*._anim_image.transform.model = matrix.scaling(
        @as(f32, @floatFromInt(anim_image_src.width)),
        @as(f32, @floatFromInt(anim_image_src.height)),
        1.0,
    ).multiply(&matrix.translation(300, -200, 0));
    anim_img.*.build();

    objects.append(img) catch system.handle_error_msg2("objects.append(img)");
    objects.append(text_shape) catch system.handle_error_msg2("objects.append(text_shape)");
    objects.append(anim_img) catch system.handle_error_msg2("objects.append(anim_img)");

    cmd = render_command.init();
    cmd.*.scene = objects.items[0..2];
    cmd2 = render_command.init();
    cmd2.*.scene = objects.items[2..objects.items.len];

    cmds[0] = cmd;
    cmds[1] = cmd2;
    graphics.render_cmd = cmds[0..cmds.len];

    anim.obj = @ptrCast(objects.items[2]);
    anim.play();

    var start_sem: std.Thread.Semaphore = .{};

    input.set_key_down_func(key_down);

    _ = timer_callback.start2(
        system.sec_to_nano_sec2(0, 10, 0, 0),
        0,
        move_callback,
        .{},
        move_start_callback,
        null,
        .{&start_sem},
        .{},
    ) catch |e| system.handle_error3("timer_callback.start", e);

    start_sem.wait();
}

fn key_down(_key: input.key) void {
    if (_key == input.key.F4) {
        if (window.get_screen_mode() == .WINDOW) {
            const monitor = system.get_monitor_from_window();
            monitor.*.set_fullscreen_mode(monitor.*.primary_resolution.?);
        } else {
            window.set_window_mode();
        }
    }
}

fn move_start_callback(start_sem: *std.Thread.Semaphore) bool {
    shape_src.build(.read_gpu, .readwrite_cpu);
    cmd.scene.?[1].*.build();

    start_sem.*.post();
    return true;
}
//다른 스레드에서 테스트 xfit_update에서 해도됨.
fn move_callback() !bool {
    if (!system.exiting()) {
        cmd.scene.?[1].*._shape.transform.model = matrix.scaling(5, 5, 1.0).multiply(&matrix.translation(-200 + dx, 0, 0));
    } else return false;

    shape_src.color[3] += 0.005;
    if (shape_src.color[3] >= 1.0) shape_src.color[3] = 0;

    cmd.scene.?[1].*._shape.transform.map_update();
    shape_src.map_color_update();

    dx += 1;
    if (dx >= 200) dx = 0;
    return true;
}

var dx: f32 = 0;
pub fn xfit_update() void {
    anim.update(system.dt());
}

pub fn xfit_size() void {
    g_proj.init_matrix_orthographic(CANVAS_W, CANVAS_H) catch |e| system.handle_error3("g_proj.init_matrix", e);

    g_proj.map_update();
}

///before system clean
pub fn xfit_destroy() void {
    shape_src.deinit_for_alloc();
    shape_src2.deinit_for_alloc();

    allocator.free(image_src.pixels.?);
    allocator.free(anim_image_src.pixels.?);
    image_src.deinit();
    anim_image_src.deinit();

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

    cmd.deinit();
    cmd2.deinit();
    color_trans.deinit();
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
