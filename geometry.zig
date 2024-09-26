const std = @import("std");
const ArrayList = std.ArrayList;
const MemoryPool = std.heap.MemoryPool;
const DoublyLinkedList = std.DoublyLinkedList;
const math = @import("math.zig");
const system = @import("system.zig");

const point = math.point;
const vector = math.vector;

const dot3 = math.dot3;
const cross3 = math.cross3;
const sqrt = std.math.sqrt;
const pow = math.pow;

pub const curve_TYPE = enum {
    unknown,
    serpentine,
    loop,
    cusp,
    quadratic,
    line,
};

pub const line_error = error{
    is_point_not_line,
    is_not_curve,
    invaild_line,
    out_of_idx,
} || std.mem.Allocator.Error;

pub const polygon_error = error{
    is_not_polygon,
    invaild_polygon_line_counts,
    cant_polygon_match_holes,
} || line_error;

pub fn convert_quadratic_to_cubic0(_start: point, _control: point) point {
    return .{ _start[0] + (2.0 / 3.0) * (_control[0] - _start[0]), _start[1] + (2.0 / 3.0) * (_control[1] - _start[1]) };
}
pub fn convert_quadratic_to_cubic1(_end: point, _control: point) point {
    return .{ _end[0] + (2.0 / 3.0) * (_control[0] - _end[0]), _end[1] + (2.0 / 3.0) * (_control[1] - _end[1]) };
}

/// Algorithm from http://www.blackpawn.com/texts/pointinpoly/default.html
pub fn point_in_triangle(p: point, a: point, b: point, c: point) bool {
    const v0 = c - a;
    const v1 = b - a;
    const v2 = p - a;

    const dot00 = dot3(v0, v0);
    const dot01 = dot3(v0, v1);
    const dot02 = dot3(v0, v2);
    const dot11 = dot3(v1, v1);
    const dot12 = dot3(v1, v2);
    const denominator = dot00 * dot11 - dot01 * dot01;
    if (denominator == 0) {
        return false;
    }

    const inverseDenominator = 1.0 / denominator;
    const u = (dot11 * dot02 - dot01 * dot12) * inverseDenominator;
    const v = (dot00 * dot12 - dot01 * dot02) * inverseDenominator;

    return (u >= 0.0) and (v >= 0.0) and (u + v < 1.0);
}

pub fn point_in_line(p: point, l0: point, l1: point, result: ?*f32) bool {
    const a = l1[1] - l0[1];
    const b = l0[0] - l1[0];
    const c = l1[0] * l0[1] - l0[0] * l1[1];
    const _result = a * p[0] + b * p[1] + c;
    if (result != null) result.?.* = _result;
    return _result == 0 and p[0] >= @min(l0[0], l1[0]) and p[0] <= @max(l0[0], l1[0]) and p[1] >= @min(l0[1], l1[1]) and p[1] <= @max(l0[1], l1[1]);
}

pub fn point_in_vector(p: point, v0: point, v1: point, result: ?*f32) bool {
    const a = v1[1] - v0[1];
    const b = v0[0] - v1[0];
    const c = v1[0] * v0[1] - v0[0] * v1[1];
    const _result = a * p[0] + b * p[1] + c;
    if (result != null) result.?.* = _result;
    return _result == 0;
}

pub fn lines_intersect(a1: point, a2: point, b1: point, b2: point, result: ?*point) bool {
    const a = a2 - a1;
    const b = b2 - b1;
    const ab = a1 - b1;
    const aba = math.cross2(a, b);
    if (aba == 0.0) return false;
    const A = math.cross2(b, ab) / aba;
    const B = math.cross2(a, ab) / aba;
    if ((A <= 1.0) and (B <= 1.0) and (A >= 0.0) and (B >= 0.0)) {
        if (result != null) result.?.* = a1 + @as(point, @splat(A)) * (a2 - a1);
        return true;
    }
    return false;
}

pub fn point_distance_to_line(p: point, l0: point, l1: point) f32 {
    const xx1 = l1[0] - l0[0];
    const yy1 = l1[1] - l0[1];
    const xx2 = p[0] - l0[0];
    const yy2 = p[1] - l0[1];
    const z = (xx1 * yy2) - (xx2 - yy1);

    return z / sqrt((xx1 * xx1) + (yy1 * yy1));
}
///https://bowbowbow.tistory.com/24
pub fn point_in_polygon(p: point, pts: []point) bool {
    var i: usize = 0;
    //crosses는 점p와 오른쪽 반직선과 다각형과의 교점의 개수
    var crosses: usize = 0;
    while (i < pts.len) : (i += 1) {
        const j = (i + 1) % pts.len;
        //점 p가 선분 (pts[i], pts[j])의 y좌표 사이에 있음
        if ((pts[i][1] > p[1]) != (pts[j][1] > p[1])) {
            //atX는 점 p를 지나는 수평선과 선분 (pts[i], pts[j])의 교점
            const atx = (pts[j][0] - pts[i][0]) * (p[1] - pts[i][1]) / (pts[j][1] - pts[i][1]) + pts[i][0];
            //atX가 오른쪽 반직선과의 교점이 맞으면 교점의 개수를 증가시킨다.
            if (p[0] < atx) crosses += 1;
        }
    }
    return (crosses % 2) > 0;
}
pub fn line_in_polygon(a: point, b: point, pts: []point, check_inside_line: bool) bool {
    if (check_inside_line and point_in_polygon(a, pts)) return true; //반드시 점 ab가 다각형 내에 모두 있어야 선 ab와 다각형 선분이 교차하지 않는다. 따라서 b는 확인할 필요 없다.
    var i: usize = 0;
    var result: point = undefined;
    while (i < pts.len - 1) : (i += 1) {
        if (lines_intersect(pts[i], pts[i + 1], a, b, &result)) {
            if (math.compare_n(a, result) or math.compare_n(b, result)) continue;
            return true;
        }
    }
    if (lines_intersect(pts[pts.len - 1], pts[0], a, b, &result)) {
        if (math.compare_n(a, result) or math.compare_n(b, result)) return false;
        return true;
    }
    return false;
}
pub const circle = struct {
    p: point,
    radius: f32,
    pub fn circle_in_circle(a: @This(), b: circle) bool {
        return math.length_pow(a.p, b.p) <= math.pow(a.radius + b.radius, 2);
    }
    pub fn circle_in_point(c: @This(), p: point) bool {
        return math.length_pow(c.p, p.p) <= c.radius * c.radius;
    }
};

pub const polygon = struct {
    lines: [][]line,
    colors: ?[]vector = null,

    const node = struct {
        idx: u32,
        p: point,
    };
    const Dnode = DoublyLinkedList(*node).Node;

    /// out_vertices type is *ArrayList(shape_vertex_type), out_indices type is *ArrayList(idx_type)
    pub fn compute_polygon(self: polygon, allocator: std.mem.Allocator, out_vertices: anytype, out_indices: anytype) polygon_error!void {
        //var tt = std.time.Timer.start() catch system.unreachable2();

        if (self.lines[0].len < 3) return polygon_error.is_not_polygon;
        const __points = try allocator.alloc(ArrayList(node), self.lines.len);
        const __points2 = try allocator.alloc(ArrayList(point), self.lines.len);
        var __outside_polygon = try ArrayList(u32).initCapacity(allocator, self.lines.len);
        var __inside_polygon = try ArrayList([4]u32).initCapacity(allocator, self.lines.len);
        var i: u32 = 0;

        while (i < __points.len) : (i += 1) {
            __points[i] = ArrayList(node).init(allocator);
            __points2[i] = ArrayList(point).init(allocator);
        }
        defer {
            i = 0;
            while (i < __points.len) : (i += 1) {
                __points[i].deinit();
                __points2[i].deinit();
            }
            __inside_polygon.deinit();
            __outside_polygon.deinit();
            allocator.free(__points);
            allocator.free(__points2);
        }
        var j: u32 = 0;
        var count: u32 = 0;
        while (count < self.lines.len) : (count += 1) {
            i = 0;
            while (i < self.lines[count].len) : (i += 1) {
                const vv = try self.lines[count][i].compute_curve(out_vertices, out_indices, if (self.colors != null) self.colors.?[if (count > self.colors.?.len - 1) self.colors.?.len - 1 else count] else null, true);
                j = 0;
                while (j < vv) : (j += 1) {
                    try __points[count].append(.{
                        .p = out_vertices.*.items[out_vertices.*.items.len - (vv - j)].pos,
                        .idx = @intCast(out_vertices.*.items.len - (vv - j)),
                    });
                    try __points2[count].append(out_vertices.*.items[out_vertices.*.items.len - (vv - j)].pos);
                }
            }
            try __outside_polygon.append(count);
        }
        //system.print("compute_curve {d}\n", .{tt.lap()});
        count = 0;
        out: while (count < __outside_polygon.items.len) {
            const v = __outside_polygon.items[count];
            for (__outside_polygon.items) |g| {
                if (g != v) {
                    if (point_in_polygon(__points2[v].items[0], __points2[g].items)) {
                        try __inside_polygon.append(.{ v, g, 0, 0 }); //0:inside, 1:outside, i,j
                        _ = __outside_polygon.orderedRemove(count);
                        continue :out;
                    }
                }
            }
            count += 1;
        }
        count = 0;
        while (count < __inside_polygon.items.len) : (count += 1) {
            const v = __inside_polygon.items[count][0];
            j = 0;
            var maxX = std.math.floatMin(f32);
            while (j < __points[v].items.len) : (j += 1) {
                if (maxX <= __points[v].items[j].p[0]) {
                    maxX = __points[v].items[j].p[0];
                    __inside_polygon.items[count][3] = j;
                }
            }
            j = __inside_polygon.items[count][3];
            var check: bool = undefined;
            const g = __inside_polygon.items[count][1];
            i = 0;
            while (i < __points[g].items.len) : (i += 1) {
                check = true;
                if (__points[g].items[i].p[0] < __points[v].items[j].p[0] or __points[g].items[i].p[1] > __points[v].items[j].p[1]) {
                    check = false;
                } else {
                    var e: u32 = 0;
                    while (e < __points.len) : (e += 1) {
                        if (e != v) {
                            if (line_in_polygon(__points[g].items[i].p, __points[v].items[j].p, __points2[e].items, false)) {
                                check = false;
                                break;
                            }
                        }
                    }
                }
                if (check) {
                    __inside_polygon.items[count][2] = i;
                    break;
                }
            }

            if (!check) {
                return polygon_error.cant_polygon_match_holes;
            }
        }
        //system.print("find hole {d}\n", .{tt.lap()});
        var pt = DoublyLinkedList(*node){};
        var mem = MemoryPool(Dnode).init(allocator);
        defer mem.deinit();

        while (0 < __outside_polygon.items.len) {
            //tt.reset();
            const pop = __outside_polygon.pop();
            j = 0;
            while (j < __points[pop].items.len) : (j += 1) {
                const pn: *Dnode = mem.create() catch return polygon_error.OutOfMemory;
                pn.* = .{ .data = &__points[pop].items[j] };
                pt.append(pn);
            }
            j = 0;
            while (j < __inside_polygon.items.len) {
                if (__inside_polygon.items[j][1] == pop) {
                    var pp = pt.first;
                    var next: ?*Dnode = null;
                    while (pp != null) : (pp = pp.?.*.next) {
                        if (pp.?.*.data == &__points[pop].items[__inside_polygon.items[j][2]]) {
                            next = pp;
                            break;
                        }
                    }
                    if (next == null) system.unreachable2();
                    const start = __inside_polygon.items[j][3];
                    const end = if (__inside_polygon.items[j][3] == 0) @as(u32, @intCast(__points[__inside_polygon.items[j][0]].items.len - 1)) else __inside_polygon.items[j][3] - 1;

                    var e = start;
                    while (true) {
                        const pn: *Dnode = mem.create() catch return polygon_error.OutOfMemory;
                        pn.* = .{ .data = &__points[__inside_polygon.items[j][0]].items[e] };
                        pt.insertAfter(next.?, pn);
                        next = pn;
                        if (e == end) break;
                        e = if (e == __points[__inside_polygon.items[j][0]].items.len - 1) 0 else e + 1;
                    }
                    const pn: *Dnode = mem.create() catch return polygon_error.OutOfMemory;
                    pn.* = .{ .data = &__points[__inside_polygon.items[j][0]].items[__inside_polygon.items[j][3]] };
                    pt.insertAfter(next.?, pn);
                    next = pn;
                    const pn2: *Dnode = mem.create() catch return polygon_error.OutOfMemory;
                    pn2.* = .{ .data = &__points[pop].items[__inside_polygon.items[j][2]] };
                    pt.insertAfter(next.?, pn2);
                    _ = __inside_polygon.orderedRemove(j);
                } else {
                    j += 1;
                }
            }
            //system.print("insert {d}\n", .{tt.lap()});

            while (pt.len > 2) {
                const p = try refreshE(pt);
                if (p == null) {
                    if (pt.len > 3) system.print("null E pt.len {d}\n", .{pt.len});
                    break;
                }
                const next = p.?.*.next orelse pt.first.?;
                const prev = p.?.*.prev orelse pt.last.?;

                try out_indices.*.appendSlice(&.{ @intCast(prev.*.data.idx), @intCast(p.?.*.data.idx), @intCast(next.*.data.idx) });

                pt.remove(p.?);
                mem.destroy(p.?);
            }
            while (pt.len > 0) {
                const first = pt.first;
                pt.remove(first.?);
                mem.destroy(first.?);
            }
            //system.print("draw {d}\n", .{tt.lap()});
        }
    }
    fn refreshE(pt: DoublyLinkedList(*node)) polygon_error!?*DoublyLinkedList(*node).Node {
        var n = pt.first;
        while (n != null) : (n = n.?.*.next) {
            const result = try appendE(pt, n.?);
            if (result != null) return result;
        }
        return null;
    }
    fn appendE(pt: DoublyLinkedList(*node), p: *Dnode) polygon_error!?*DoublyLinkedList(*node).Node {
        const b = p;
        const c = b.*.next orelse pt.first.?;
        const a = b.*.prev orelse pt.last.?;

        const cross = math.cross2(b.*.data.*.p - a.*.data.*.p, c.*.data.*.p - b.*.data.*.p);
        if (cross > 0) return null; //180도 이상

        var nf: ?*DoublyLinkedList(*node).Node = c.next;
        const nl = a.*.prev orelse pt.last;

        while (true) : (nf = nf.?.*.next) {
            if (nf == null) nf = pt.first;
            if (point_in_triangle(nf.?.*.data.*.p, a.*.data.*.p, b.*.data.*.p, c.*.data.*.p)) {
                if (math.compare(nf.?.*.data.*.p, a.*.data.*.p) or math.compare(nf.?.*.data.*.p, b.*.data.*.p) or math.compare(nf.?.*.data.*.p, c.*.data.*.p)) {} else {
                    return null;
                }
            }
            if (nf == nl) break;
        }
        return b;
    }
};

pub const line = struct {
    const Self = @This();
    start: point,
    control0: point,
    control1: point,
    end: point,
    curve_type: curve_TYPE = curve_TYPE.unknown,

    pub fn quadratic_init(_start: point, _control01: point, _end: point) Self {
        return .{
            .start = _start,
            .control0 = convert_quadratic_to_cubic0(_start, _control01),
            .control1 = convert_quadratic_to_cubic1(_end, _control01),
            .end = _end,
            .curve_type = .quadratic,
        };
    }
    pub fn line_init(_start: point, _end: point) Self {
        return .{
            .start = _start,
            .control0 = _start,
            .control1 = _end,
            .end = _end,
            .curve_type = .line,
        };
    }
    //cubic curve default
    pub fn init(_start: point, _control0: point, _control1: point, _end: point) Self {
        return .{
            .start = _start,
            .control0 = _control0,
            .control1 = _control1,
            .end = _end,
        };
    }

    /// out_vertices type is *ArrayList(shape_vertex_type), out_indices type is *ArrayList(idx_type)
    pub fn compute_curve(self: *Self, out_vertices: anytype, out_indices: anytype, color: ?vector, make_extra_vertices: bool) line_error!u32 {
        return try __compute_curve(self, self.start, self.control0, self.control1, self.end, out_vertices, out_indices, color, -1, make_extra_vertices);
    }
    ///https://github.com/azer89/GPU_Curve_Rendering/blob/master/QtTestShader/CurveRenderer.cpp
    fn __compute_curve(self: *Self, _start: point, _control0: point, _control1: point, _end: point, out_vertices: anytype, out_idxs: anytype, color: ?vector, repeat: i32, make_extra_vertices: bool) line_error!u32 {
        var d1: f32 = undefined;
        var d2: f32 = undefined;
        var d3: f32 = undefined;
        if (self.*.curve_type == .line) {
            system.print_debug("line", .{});
            if (make_extra_vertices) {
                try out_vertices.*.resize(out_vertices.*.items.len + 1);
                out_vertices.*.items[out_vertices.*.items.len - 1].pos = _start;
                out_vertices.*.items[out_vertices.*.items.len - 1].uvw = .{ 1, 0, 0 };
                if (color != null) {
                    out_vertices.*.items[out_vertices.*.items.len - 1].color = color.?;
                }
                return 1;
            }
            return 0;
        }
        const cur_type = try __get_curve_type(_start, _control0, _control1, _end, &d1, &d2, &d3);
        self.*.curve_type = cur_type;

        var mat: math.matrix = undefined;
        var flip: bool = false;
        var artifact: i32 = 0;
        var subdiv: f32 = undefined;

        switch (cur_type) {
            .serpentine => {
                const t1 = sqrt(9.0 * d2 * d2 - 12 * d1 * d3);
                const ls = 3.0 * d2 - t1;
                const lt = 6.0 * d1;
                const ms = 3.0 * d2 + t1;
                const mt = lt;
                const ltMinusLs = lt - ls;
                const mtMinusMs = mt - ms;

                mat.e[0][0] = ls * ms;
                mat.e[0][1] = ls * ls * ls;
                mat.e[0][2] = ms * ms * ms;

                mat.e[1][0] = (1.0 / 3.0) * (3.0 * ls * ms - ls * mt - lt * ms);
                mat.e[1][1] = ls * ls * (ls - lt);
                mat.e[1][2] = ms * ms * (ms - mt);

                mat.e[2][0] = (1.0 / 3.0) * (lt * (mt - 2.0 * ms) + ls * (3.0 * ms - 2.0 * mt));
                mat.e[2][1] = ltMinusLs * ltMinusLs * ls;
                mat.e[2][2] = mtMinusMs * mtMinusMs * ms;

                mat.e[3][0] = ltMinusLs * mtMinusMs;
                mat.e[3][1] = -(ltMinusLs * ltMinusLs * ltMinusLs);
                mat.e[3][2] = -(mtMinusMs * mtMinusMs * mtMinusMs);

                flip = d1 < 0.0;
                system.print_debug("serpentine {}", .{flip});
            },
            .loop => {
                const t1 = sqrt(4.0 * d1 * d3 - 3.0 * d2 * d2);
                const ls = d2 - t1;
                const lt = 2.0 * d1;
                const ms = d2 + t1;
                const mt = lt;

                const ql = ls / lt;
                const qm = ms / mt;
                if (repeat == -1 and 0.0 < ql and ql < 1.0) {
                    artifact = 1;
                    subdiv = ql;
                    system.print_debug("loop(1)", .{});
                } else if (repeat == -1 and 0.0 < qm and qm < 1.0) {
                    artifact = 2;
                    subdiv = qm;
                    system.print_debug("loop(2)", .{});
                } else {
                    const ltMinusLs = lt - ls;
                    const mtMinusMs = mt - ms;

                    mat.e[0][0] = ls * ms;
                    mat.e[0][1] = ls * ls * ms;
                    mat.e[0][2] = ls * ms * ms;

                    mat.e[1][0] = (1.0 / 3.0) * (-ls * mt - lt * ms + 3.0 * ls * ms);
                    mat.e[1][1] = -(1.0 / 3.0) * ls * (ls * (mt - 3.0 * ms) + 2.0 * lt * ms);
                    mat.e[1][2] = -(1.0 / 3.0) * ms * (ls * (2.0 * mt - 3.0 * ms) + lt * ms);

                    mat.e[2][0] = (1.0 / 3.0) * (lt * (mt - 2.0 * ms) + ls * (3.0 * ms - 2.0 * mt));
                    mat.e[2][1] = (1.0 / 3.0) * (lt - ls) * (ls * (2.0 * mt - 3.0 * ms) + lt * ms);
                    mat.e[2][2] = (1.0 / 3.0) * (mt - ms) * (ls * (mt - 3.0 * ms) + 2.0 * lt * ms);

                    mat.e[3][0] = ltMinusLs * mtMinusMs;
                    mat.e[3][1] = -(ltMinusLs * ltMinusLs) * mtMinusMs;
                    mat.e[3][2] = -ltMinusLs * mtMinusMs * mtMinusMs;

                    if (repeat == -1) flip = ((d1 > 0.0001 and mat.e[0][0] < -0.0001) or (d1 < -0.0001 and mat.e[0][0] > 0.0001));
                    system.print_debug("loop flip {}", .{flip});
                }
            },
            .cusp => {
                const ls = d3;
                const lt = 3.0 * d2;
                const lsMinusLt = ls - lt;

                mat.e[0][0] = ls;
                mat.e[0][1] = ls * ls * ls;
                mat.e[0][2] = 1;

                mat.e[1][0] = ls - (1.0 / 3.0) * lt;
                mat.e[1][1] = ls * ls * lsMinusLt;
                mat.e[1][2] = 1;

                mat.e[2][0] = ls - (2.0 / 3.0) * lt;
                mat.e[2][1] = lsMinusLt * lsMinusLt * ls;
                mat.e[2][2] = 1;

                mat.e[3][0] = lsMinusLt;
                mat.e[3][1] = lsMinusLt * lsMinusLt * lsMinusLt;
                mat.e[3][2] = 1;
                system.print_debug("cusp {}", .{flip});
            },
            .quadratic => {
                mat.e[0][0] = 0;
                mat.e[0][1] = 0;
                mat.e[0][2] = 0;

                mat.e[1][0] = -(1.0 / 3.0);
                mat.e[1][1] = 0;
                mat.e[1][2] = (1.0 / 3.0);

                mat.e[2][0] = -(2.0 / 3.0);
                mat.e[2][1] = -(1.0 / 3.0);
                mat.e[2][2] = (2.0 / 3.0);

                mat.e[3][0] = -1;
                mat.e[3][1] = -1;
                mat.e[3][2] = 1;

                flip = d3 < 0.0;
                system.print_debug("quadratic {}", .{flip});
            },
            .line => {
                system.print_debug("line", .{});
                if (make_extra_vertices) {
                    try out_vertices.*.resize(out_vertices.*.items.len + 1);
                    out_vertices.*.items[out_vertices.*.items.len - 1].pos = _start;
                    out_vertices.*.items[out_vertices.*.items.len - 1].uvw = .{ 1, 0, 0 };
                    if (color != null) {
                        out_vertices.*.items[out_vertices.*.items.len - 1].color = color.?;
                    }
                    return 1;
                }
                return 0;
            },
            else => return line_error.is_not_curve,
        }

        if (artifact != 0) {
            const x01 = (_control0[0] - _start[0]) * subdiv + _start[0];
            const y01 = (_control0[1] - _start[1]) * subdiv + _start[1];

            const x12 = (_control1[0] - _control0[0]) * subdiv + _control0[0];
            const y12 = (_control1[1] - _control0[1]) * subdiv + _control0[1];

            const x23 = (_end[0] - _control1[0]) * subdiv + _control1[0];
            const y23 = (_end[1] - _control1[1]) * subdiv + _control1[1];

            const x012 = (x12 - x01) * subdiv + x01;
            const y012 = (y12 - y01) * subdiv + y01;

            const x123 = (x23 - x12) * subdiv + x12;
            const y123 = (y23 - y12) * subdiv + y12;

            const x0123 = (x123 - x012) * subdiv + x012;
            const y0123 = (y123 - y012) * subdiv + y012;

            _ = try __compute_curve(self, _start, .{ x01, y01 }, .{ x012, y012 }, .{ x0123, y0123 }, out_vertices, out_idxs, color, if (artifact == 1) 0 else 1, false);
            _ = try __compute_curve(self, .{ x0123, y0123 }, .{ x123, y123 }, .{ x23, y23 }, _end, out_vertices, out_idxs, color, if (artifact == 1) 1 else 0, false);

            var count: u32 = 0;

            if (!((d1 > 0 and mat.e[0][0] < 0) or (d1 < 0 and mat.e[0][0] > 0))) { //flip 상태가 아닐때만(안쪽 일때) 추가 삼각형 그리기
                system.print_debug("additional triangle", .{});
                const n: usize = out_vertices.items.len;
                if (n + 2 > std.math.maxInt(@TypeOf(out_idxs.items[0]))) return line_error.out_of_idx;
                const nn: @TypeOf(out_idxs.items[0]) = @intCast(n);
                try out_vertices.*.resize(n + 3);
                out_vertices.*.items[n].pos = _start;
                out_vertices.*.items[n + 1].pos = .{ x0123, y0123 };
                out_vertices.*.items[n + 2].pos = _end;

                out_vertices.*.items[n].uvw = .{ 1, 0, 0 };
                out_vertices.*.items[n + 1].uvw = .{ 1, 0, 0 };
                out_vertices.*.items[n + 2].uvw = .{ 1, 0, 0 };

                if (color != null) {
                    out_vertices.*.items[n].color = color.?;
                    out_vertices.*.items[n + 1].color = color.?;
                    out_vertices.*.items[n + 2].color = color.?;
                }

                try out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2 });

                if (make_extra_vertices) {
                    try out_vertices.*.resize(out_vertices.*.items.len + 1);
                    out_vertices.*.items[out_vertices.*.items.len - 1].pos = _start;
                    out_vertices.*.items[out_vertices.*.items.len - 1].uvw = .{ 1, 0, 0 };
                    if (color != null) {
                        out_vertices.*.items[out_vertices.*.items.len - 1].color = color.?;
                    }
                    count += 1;
                }
            } else {
                if (make_extra_vertices) {
                    try out_vertices.*.resize(out_vertices.*.items.len + 6);
                    out_vertices.*.items[out_vertices.*.items.len - 6].pos = _start;
                    out_vertices.*.items[out_vertices.*.items.len - 6].uvw = .{ 1, 0, 0 };

                    out_vertices.*.items[out_vertices.*.items.len - 5].pos = .{ x01, y01 };
                    out_vertices.*.items[out_vertices.*.items.len - 4].pos = .{ x012, y012 };
                    out_vertices.*.items[out_vertices.*.items.len - 3].pos = .{ x0123, y0123 };
                    out_vertices.*.items[out_vertices.*.items.len - 2].pos = .{ x123, y123 };
                    out_vertices.*.items[out_vertices.*.items.len - 1].pos = .{ x23, y23 };

                    out_vertices.*.items[out_vertices.*.items.len - 5].uvw = .{ 1, 0, 0 };
                    out_vertices.*.items[out_vertices.*.items.len - 4].uvw = .{ 1, 0, 0 };
                    out_vertices.*.items[out_vertices.*.items.len - 3].uvw = .{ 1, 0, 0 };
                    out_vertices.*.items[out_vertices.*.items.len - 2].uvw = .{ 1, 0, 0 };
                    out_vertices.*.items[out_vertices.*.items.len - 1].uvw = .{ 1, 0, 0 };
                    if (color != null) {
                        out_vertices.*.items[out_vertices.*.items.len - 6].color = color.?;
                        out_vertices.*.items[out_vertices.*.items.len - 5].color = color.?;
                        out_vertices.*.items[out_vertices.*.items.len - 4].color = color.?;
                        out_vertices.*.items[out_vertices.*.items.len - 3].color = color.?;
                        out_vertices.*.items[out_vertices.*.items.len - 2].color = color.?;
                        out_vertices.*.items[out_vertices.*.items.len - 1].color = color.?;
                    }
                    count += 6;
                }
            }
            return count;
        }
        if (repeat == 1) flip = !flip;

        if (flip) {
            mat.e[0][0] = -mat.e[0][0];
            mat.e[0][1] = -mat.e[0][1];
            mat.e[1][0] = -mat.e[1][0];
            mat.e[1][1] = -mat.e[1][1];
            mat.e[2][0] = -mat.e[2][0];
            mat.e[2][1] = -mat.e[2][1];
            mat.e[3][0] = -mat.e[3][0];
            mat.e[3][1] = -mat.e[3][1];
        }

        const n: usize = out_vertices.items.len;
        if (n + 3 > std.math.maxInt(@TypeOf(out_idxs.items[0]))) return line_error.out_of_idx;
        const nn: @TypeOf(out_idxs.items[0]) = @intCast(n);
        try out_vertices.*.resize(n + 4);
        out_vertices.*.items[n].pos = _start;
        out_vertices.*.items[n + 1].pos = _control0;
        out_vertices.*.items[n + 2].pos = _control1;
        out_vertices.*.items[n + 3].pos = _end;

        out_vertices.*.items[n].uvw = .{ mat.e[0][0], mat.e[0][1], mat.e[0][2] };
        out_vertices.*.items[n + 1].uvw = .{ mat.e[1][0], mat.e[1][1], mat.e[1][2] };
        out_vertices.*.items[n + 2].uvw = .{ mat.e[2][0], mat.e[2][1], mat.e[2][2] };
        out_vertices.*.items[n + 3].uvw = .{ mat.e[3][0], mat.e[3][1], mat.e[3][2] };

        if (color != null) {
            out_vertices.*.items[n].color = color.?;
            out_vertices.*.items[n + 1].color = color.?;
            out_vertices.*.items[n + 2].color = color.?;
            out_vertices.*.items[n + 3].color = color.?;
        }

        var count: u32 = 0;
        if (repeat == -1 and make_extra_vertices) {
            try out_vertices.*.resize(out_vertices.*.items.len + 1);
            out_vertices.*.items[out_vertices.*.items.len - 1].pos = _start;
            out_vertices.*.items[out_vertices.*.items.len - 1].uvw = .{ 1, 0, 0 };
            count += 1;
            if (color != null) {
                out_vertices.*.items[out_vertices.*.items.len - 1].color = color.?;
            }
            if (flip) {
                try out_vertices.*.resize(out_vertices.*.items.len + 2);
                out_vertices.*.items[out_vertices.*.items.len - 2].pos = _control0;
                out_vertices.*.items[out_vertices.*.items.len - 1].pos = _control1;
                out_vertices.*.items[out_vertices.*.items.len - 2].uvw = .{ 1, 0, 0 };
                out_vertices.*.items[out_vertices.*.items.len - 1].uvw = .{ 1, 0, 0 };
                if (color != null) {
                    out_vertices.*.items[out_vertices.*.items.len - 2].color = color.?;
                    out_vertices.*.items[out_vertices.*.items.len - 1].color = color.?;
                }
                count += 2;
            }
        }

        {
            var i: usize = 0;
            while (i < 4) : (i += 1) {
                var j: usize = i + 1;
                while (j < 4) : (j += 1) {
                    if (math.compare(out_vertices.*.items[n + i].pos, out_vertices.*.items[n + j].pos)) {
                        var indices: [3]@TypeOf(out_idxs.items[0]) = .{ nn, nn, nn };
                        var index: usize = 0;
                        var k: usize = 0;
                        while (k < 4) : (k += 1) {
                            if (k != j) {
                                indices[index] += @intCast(k);
                                index += 1;
                            }
                        }
                        //system.print_debug("1", .{});

                        try out_idxs.*.appendSlice(&.{ indices[0], indices[1], indices[2] });
                        return count;
                    }
                }
            }
        }
        {
            var i: usize = 0;
            while (i < 4) : (i += 1) {
                var indices: [3]@TypeOf(out_idxs.items[0]) = .{ nn, nn, nn };
                var index: usize = 0;
                var j: usize = 0;
                while (j < 4) : (j += 1) {
                    if (i != j) {
                        indices[index] += @intCast(j);
                        index += 1;
                    }
                }
                if (point_in_triangle(out_vertices.*.items[n + i].pos, out_vertices.*.items[indices[0]].pos, out_vertices.*.items[indices[1]].pos, out_vertices.*.items[indices[2]].pos)) {
                    var k: usize = 0;
                    //system.print_debug("2", .{});
                    while (k < 3) : (k += 1) {
                        try out_idxs.*.appendSlice(&.{ indices[k], indices[(k + 1) % 3], @intCast(nn + i) });
                    }
                    return count;
                }
            }
        }

        if (lines_intersect(_start, _control1, _control0, _end, null)) {
            if (math.length_pow(_control1, _start) < math.length_pow(_end, _control0)) {
                //system.print_debug("3", .{});
                try out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2, nn + 0, nn + 2, nn + 3 });
            } else {
                //system.print_debug("4", .{});
                try out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 3, nn + 1, nn + 2, nn + 3 });
            }
        } else if (lines_intersect(_start, _end, _control0, _control1, null)) {
            if (math.length_pow(_end, _start) < math.length_pow(_control1, _control0)) {
                //system.print_debug("5", .{});
                try out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 3, nn + 0, nn + 3, nn + 2 });
            } else {
                //system.print_debug("6", .{});
                try out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2, nn + 2, nn + 2, nn + 3 });
            }
        } else {
            if (math.length_pow(_control0, _start) < math.length_pow(_end, _control1)) {
                //system.print_debug("7", .{});
                try out_idxs.*.appendSlice(&.{ nn + 0, nn + 2, nn + 1, nn + 0, nn + 1, nn + 3 });
            } else {
                //system.print_debug("8", .{});
                try out_idxs.*.appendSlice(&.{ nn + 0, nn + 2, nn + 3, nn + 3, nn + 2, nn + 1 });
            }
        }
        return count;
    }
    pub fn get_curve_type(self: Self) line_error!curve_TYPE {
        var d1: f32 = undefined;
        var d2: f32 = undefined;
        var d3: f32 = undefined;
        return try __get_curve_type(self.start, self.control0, self.control1, self.end, &d1, &d2, &d3);
    }
    fn __get_curve_type(_start: point, _control0: point, _control1: point, _end: point, out_d1: *f32, out_d2: *f32, out_d3: *f32) line_error!curve_TYPE {
        const a1 = dot3(vector{ _start[0], _start[1], 1, 0 }, cross3(vector{ _end[0], _end[1], 1, 0 }, vector{ _control1[0], _control1[1], 1, 0 }));
        const a2 = dot3(vector{ _control0[0], _control0[1], 1, 0 }, cross3(vector{ _start[0], _start[1], 1, 0 }, vector{ _end[0], _end[1], 1, 0 }));
        const a3 = dot3(vector{ _control1[0], _control1[1], 1, 0 }, cross3(vector{ _control0[0], _control0[1], 1, 0 }, vector{ _start[0], _start[1], 1, 0 }));

        out_d1.* = a1 - 2 * a2 + 3 * a3;
        out_d2.* = -a2 + 3 * a3;
        out_d3.* = 3 * a3;
        // const dvec = math.normalize(vector{ out_d1.*, out_d2.*, out_d3.*, 0 });
        // out_d1.* = dvec[0];
        // out_d2.* = dvec[1];
        // out_d3.* = dvec[2];

        const D = (3 * (out_d2.* * out_d2.*) - 4 * out_d3.* * out_d1.*);
        const discr = out_d1.* * out_d1.* * D; //어떤 타입의 곡선인지 판별하는 값

        if (math.compare_n(_start, _control0) and math.compare_n(_control0, _control1) and math.compare_n(_control1, _end)) {
            return line_error.is_point_not_line;
        }

        if (std.math.approxEqAbs(f32, discr, 0, 0.0001)) {
            if (std.math.approxEqAbs(f32, out_d1.*, 0, 0.0001)) {
                if (std.math.approxEqAbs(f32, out_d2.*, 0, 0.0001)) {
                    if (std.math.approxEqAbs(f32, out_d3.*, 0, 0.0001)) return curve_TYPE.line;
                    return curve_TYPE.quadratic;
                }
            } else {
                return curve_TYPE.cusp;
            }
            if (D < -0.0001) return curve_TYPE.loop;
        }
        if (discr > 0.0001) return curve_TYPE.serpentine;
        return curve_TYPE.loop;
    }
};
