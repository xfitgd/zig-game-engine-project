const std = @import("std");
const graphics = @import("graphics.zig");
const system = @import("system.zig");
const window = @import("window.zig");
const __system = @import("__system.zig");

const math = @import("math.zig");
const geometry = @import("geometry.zig");

const rect = math.rect;
const mem = @import("mem.zig");
const point = math.point;
const vector = math.vector;
const matrix = math.matrix;
const matrix_error = math.matrix_error;
const center_pt_pos = graphics.center_pt_pos;

pub const iarea_type = enum {
    rect,
    polygon,
};

pub const iarea = union(iarea_type) {
    rect: rect,
    polygon: []point,
};
