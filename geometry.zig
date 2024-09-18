const std = @import("std");
const ArrayList = std.ArrayList;
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
    ///직선에 대한 처리를 따로한다.
    is_not_curve,
    invaild_line,
    out_of_idx,
};

pub const polygon_error = error{
    is_not_polygon,
    invaild_polygon_line_counts,
    invaild_polygon_arc_180,
} || line_error;

pub fn convert_quadratic_to_cubic0(_start: point, _control: point) point {
    return .{ _start[0] + (2.0 / 3.0) * (_control[0] - _start[0]), _start[1] + (2.0 / 3.0) * (_control[1] - _start[1]) };
}
pub fn convert_quadratic_to_cubic1(_end: point, _control: point) point {
    return .{ _end[0] + (2.0 / 3.0) * (_control[0] - _end[0]), _end[1] + (2.0 / 3.0) * (_control[1] - _end[1]) };
}

pub inline fn sub(a: anytype, b: anytype) @TypeOf(a, b) {
    if (@typeInfo(@TypeOf(a, b)) == .vector) {
        return a - b;
    } else if (@typeInfo(@TypeOf(a, b)) == .array) {
        math.test_number_type(@typeInfo(@TypeOf(a, b)).array.child);
        if (a.len != b.len) @compileError("a, b len must same");

        comptime var i = 0;
        var result: @TypeOf(a, b) = undefined;
        inline while (i < a.len) : (i += 1) {
            result[i] = a[i] - b[i];
        }
        return result;
    } else {
        @compileError("not a vector, array type");
    }
}

pub inline fn add(a: anytype, b: anytype) @TypeOf(a, b) {
    if (@typeInfo(@TypeOf(a, b)) == .vector) {
        return a + b;
    } else if (@typeInfo(@TypeOf(a, b)) == .array) {
        math.test_number_type(@typeInfo(@TypeOf(a, b)).array.child);
        if (a.len != b.len) @compileError("a, b len must same");

        comptime var i = 0;
        var result: @TypeOf(a, b) = undefined;
        inline while (i < a.len) : (i += 1) {
            result[i] = a[i] + b[i];
        }
        return result;
    } else {
        @compileError("not a vector, array type");
    }
}

pub inline fn mul(a: anytype, b: anytype) @TypeOf(a, b) {
    if (@typeInfo(@TypeOf(a, b)) == .vector) {
        return a * b;
    } else if (@typeInfo(@TypeOf(a, b)) == .array) {
        math.test_number_type(@typeInfo(@TypeOf(a, b)).array.child);
        if (a.len != b.len) @compileError("a, b len must same");

        comptime var i = 0;
        var result: @TypeOf(a, b) = undefined;
        inline while (i < a.len) : (i += 1) {
            result[i] = a[i] * b[i];
        }
        return result;
    } else {
        @compileError("not a vector, array type");
    }
}

pub inline fn div(a: anytype, b: anytype) @TypeOf(a, b) {
    if (@typeInfo(@TypeOf(a, b)) == .vector) {
        return a / b;
    } else if (@typeInfo(@TypeOf(a, b)) == .array) {
        math.test_number_type(@typeInfo(@TypeOf(a, b)).array.child);
        if (a.len != b.len) @compileError("a, b len must same");

        comptime var i = 0;
        var result: @TypeOf(a, b) = undefined;
        inline while (i < a.len) : (i += 1) {
            result[i] = a[i] / b[i];
        }
        return result;
    } else {
        @compileError("not a vector, array type");
    }
}

/// Algorithm from http://www.blackpawn.com/texts/pointinpoly/default.html
pub fn point_in_triangle(p: anytype, a: anytype, b: anytype, c: anytype) bool {
    if (@typeInfo(@TypeOf(p, a, b, c)) == .vector) {
        if (@typeInfo(@TypeOf(p, a, b, c)).vector.len != 2) @compileError("vector len must 2");
    } else if (@typeInfo(@TypeOf(p, a, b, c)) == .array) {
        math.test_number_type(@typeInfo(@TypeOf(p, a, b, c)).array.child);
        if (!(p.len == 2 and 2 == a.len and 2 == b.len and 2 == c.len)) @compileError("array len must 2");
    } else {
        @compileError("not a vector, array type");
    }
    const v0 = sub(c, a);
    const v1 = sub(b, a);
    const v2 = sub(p, a);

    const dot00 = dot3(v0, v0);
    const dot01 = dot3(v0, v1);
    const dot02 = dot3(v0, v2);
    const dot11 = dot3(v1, v1);
    const dot12 = dot3(v1, v2);
    const denominator = dot00 * dot11 - dot01 * dot01;
    if (denominator == 0) return false;

    const inverseDenominator = 1.0 / denominator;
    const u = (dot11 * dot02 - dot01 * dot12) * inverseDenominator;
    const v = (dot00 * dot12 - dot01 * dot02) * inverseDenominator;

    return (u > 0.0) and (v > 0.0) and (u + v < 1.0);
}

///반환 값이 result 0이고 is_in true면 정확히 선 위에 있다
pub fn point_in_line(p: point, l0: point, l1: point) struct { result: f32, is_in: bool } {
    const a = l1[1] - l0[1];
    const b = l0[0] - l1[0];
    const c = l1[0] * l0[1] - l0[0] * l1[1];
    const result = a * p[0] + b * p[1] + c;
    return .{
        .result = result,
        .is_in = p[0] >= @min(l0[0], l1[0]) and p[0] <= @max(l0[0], l1[0]) and p[1] >= @min(l0[1], l1[1]) and p[1] <= @max(l0[1], l1[1]),
    };
}

inline fn __orientation(p1: point, p2: point, p3: point) i32 {
    const crossProduct = (p2[1] - p1[1]) * (p3[0] - p2[0]) - (p3[1] - p2[1]) * (p2[0] - p1[0]);
    return if (crossProduct < 0.0) -1 else (if (crossProduct > 0.0) 1 else 0);
}

pub fn lines_intersect(p1: point, q1: point, p2: point, q2: point) bool {
    return (__orientation(p1, q1, p2) != __orientation(p1, q1, q2) and __orientation(p2, q2, p1) != __orientation(p2, q2, q1));
}

pub fn point_distance_to_line(p: point, l0: point, l1: point) f32 {
    const xx1 = l1[0] - l0[0];
    const yy1 = l1[1] - l0[1];
    const xx2 = p[0] - l0[0];
    const yy2 = p[1] - l0[1];
    const z = (xx1 * yy2) - (xx2 - yy1);

    return z / sqrt((xx1 * xx1) + (yy1 * yy1));
}

pub const polygon = struct {
    ///0번 폴리곤 이후는 전부 구멍(0번 폴리곤 내부에 있어야함)
    lines: ArrayList(line),
    polygon_line_counts: ArrayList(u32),
    color: vector = .{ 1, 1, 1, 1 },

    const node = struct {
        idx: u32,
        p: point,
    };

    pub fn init(allocator: std.mem.Allocator) polygon {
        return .{
            .lines = ArrayList(line).init(allocator),
            .polygon_line_counts = ArrayList(u32).init(allocator),
        };
    }
    pub fn deinit(self: polygon) void {
        self.lines.deinit();
    }
    /// out_vertices type is *ArrayList(shape_vertex_type), out_indices type is *ArrayList(idx_type)
    pub fn compute_polygon(self: polygon, allocator: std.mem.Allocator, out_vertices: anytype, out_indices: anytype) polygon_error!void {
        if (self.lines.items.len < 2) return polygon_error.is_not_polygon;
        var count: u32 = 0;
        for (self.polygon_line_counts.items) |value| {
            if (count + value > self.lines.items.len) return polygon_error.invaild_polygon_line_counts;
            if (self.lines.items[count].start != self.lines.items[count + value].end) return polygon_error.is_not_polygon;
            count += value;
        }
        const __points = ArrayList(node).init(allocator);
        defer __points.deinit();
        const __polygon_point_counts = ArrayList(u32).initCapacity(allocator, self.polygon_line_counts.items.len) catch |e| system.handle_error3("compute_polygon __polygon_point_counts.initCapacity", e);
        defer __polygon_point_counts.deinit();
        __polygon_point_counts.append(0) catch |e| system.handle_error3("compute_polygon __polygon_point_counts.append(0) (1)", e);
        __polygon_point_counts.items[0] = 0;

        const pitem = &__polygon_point_counts.items;

        count = 0;
        for (self.lines.items) |*value| {
            value.*.compute_curve(out_vertices, out_indices) catch |e| {
                if (e != line_error.is_not_curve) return e;
            };
            const ii: u32 = @intCast(out_vertices.items.len);
            out_vertices.*.append(.{ .pos = value.*.start, .uvw = .{ 1, 0, 0 } }) catch |e| system.handle_error3("compute_polygon out_vertices.*.append(.{ .pos = value.*.start, .uvw = .{ 1, 0, 0 } })", e);
            __points.append(.{ .p = value.*.start, .idx = ii }) catch |e| system.handle_error3("compute_polygon  __points.append(value.*.start)", e);
            pitem.*[pitem.*.len - 1] += 1;
            if (0.0 > point_distance_to_line(value.*.control0, value.*.start, value.*.end)) {
                out_vertices.*.append(.{ .pos = value.*.control0, .uvw = .{ 1, 0, 0 } }) catch |e| system.handle_error3("compute_polygon out_vertices.*.append(.{ .pos = value.*.control0, .uvw = .{ 1, 0, 0 } })", e);
                __points.append(.{ .p = value.*.control0, .idx = ii + 1 }) catch |e| system.handle_error3("compute_polygon  __points.append(value.*.control0)", e);
                pitem.*[pitem.*.len - 1] += 1;
            }
            if (0.0 > point_distance_to_line(value.*.control1, value.*.start, value.*.end)) {
                out_vertices.*.append(.{ .pos = value.*.control1, .uvw = .{ 1, 0, 0 } }) catch |e| system.handle_error3("compute_polygon out_vertices.*.append(.{ .pos = value.*.control1, .uvw = .{ 1, 0, 0 } })", e);
                __points.append(.{ .p = value.*.control1, .idx = ii + 2 }) catch |e| system.handle_error3("compute_polygon  __points.append(value.*.control1)", e);
                pitem.*[pitem.*.len - 1] += 1;
            }
            count += 1;
            if (count >= self.polygon_line_counts.items[pitem.*.len - 1]) {
                __polygon_point_counts.append(0) catch |e| system.handle_error3("compute_polygon __polygon_point_counts.append(0) (2)", e);
                count = 0;
            }
        }

        const pt = DoublyLinkedList(node){};
        for (__points.items) |*value| {
            pt.append(value);
        }

        const R = DoublyLinkedList(node){};
        const C = DoublyLinkedList(node){};
        const E = DoublyLinkedList(node){};
        {
            var n = pt.first;

            const p1 = pt.last.?.*.data.p - n.?.*.data.p;
            const p2 = n.?.*.next.?.*.data.p - n.?.*.data.p;

            const a = pt.last.?.*.data.p;
            const b = n.?.*.data.p;
            const c = n.?.*.next.?.*.data.p;

            const cross = math.cross2(p1, p2);
            if (cross < 0) { //0 ~ 180 미만
                C.append(n.?);
            } else if (cross == 0) {
                return polygon_error.invaild_polygon_arc_180;
            } else { //180 ~ 360
                R.append(n.?);
            }
            var nf = n.?.*.next.?.*.next;
            const nl = pt.last.?.*.prev;
            nf = nf.?.*.next;
            while (nf != nl and nf) : (nf = nf.?.*.next) {
                if (!point_in_triangle(nf.?.*.data.p, a, b, c)) E.append(nf);
            }
            while (n) : (n = n.?.*.next) {}
        }
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
    pub fn compute_curve(self: *Self, out_vertices: anytype, out_indices: anytype) line_error!void {
        return __compute_curve(self, self.start, self.control0, self.control1, self.end, out_vertices, out_indices, -1);
    }
    ///https://github.com/azer89/GPU_Curve_Rendering/blob/master/QtTestShader/CurveRenderer.cpp
    fn __compute_curve(self: *Self, _start: point, _control0: point, _control1: point, _end: point, out_vertices: anytype, out_idxs: anytype, repeat: i32) line_error!void {
        var d1: f32 = undefined;
        var d2: f32 = undefined;
        var d3: f32 = undefined;
        if (self.*.curve_type == .line) return line_error.is_not_curve; //곡선이 아니니 계산하지 않는다.(polygon에서 그려준다. 직선이 모여야 도형이 되므로)
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

                flip = d1 < 0;
                system.print_debug("serpentine", .{});
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

                    if (repeat == -1) flip = ((d1 > 0 and mat.e[0][0] < 0) or (d1 < 0 and mat.e[0][0] > 0));
                    system.print_debug("loop", .{});
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
                system.print_debug("cusp", .{});
            },
            .quadratic => {
                mat.e[0][0] = 0;
                mat.e[0][1] = 0;
                mat.e[0][2] = 0;

                mat.e[1][0] = (1.0 / 3.0);
                mat.e[1][1] = 0;
                mat.e[1][2] = (1.0 / 3.0);

                mat.e[2][0] = (2.0 / 3.0);
                mat.e[2][1] = (1.0 / 3.0);
                mat.e[2][2] = (2.0 / 3.0);

                mat.e[3][0] = 1;
                mat.e[3][1] = 1;
                mat.e[3][2] = 1;

                flip = d3 < 0;
                system.print_debug("quadratic", .{});
            },
            .line => return,
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

            try __compute_curve(self, _start, .{ x01, y01 }, .{ x012, y012 }, .{ x0123, y0123 }, out_vertices, out_idxs, if (artifact == 1) 0 else 1);
            try __compute_curve(self, .{ x0123, y0123 }, .{ x123, y123 }, .{ x23, y23 }, _end, out_vertices, out_idxs, if (artifact == 1) 1 else 0);

            if (!((d1 > 0 and mat.e[0][0] < 0) or (d1 < 0 and mat.e[0][0] > 0))) { //flip 상태가 아닐때만(안쪽 일때) 추가 삼각형 그리기
                system.print_debug("additional triangle", .{});
                const n: usize = out_vertices.items.len;
                if (n + 2 > std.math.maxInt(@TypeOf(out_idxs.items[0]))) return line_error.out_of_idx;
                const nn: @TypeOf(out_idxs.items[0]) = @intCast(n);
                out_vertices.*.resize(n + 3) catch |e| system.handle_error3("__compute_curve out_vertices.*.resize(n + 3)", e);
                out_vertices.*.items[n].pos = _start;
                out_vertices.*.items[n + 1].pos = .{ x0123, y0123 };
                out_vertices.*.items[n + 2].pos = _end;

                out_vertices.*.items[n].uvw = .{ 1, 0, 0 };
                out_vertices.*.items[n + 1].uvw = .{ 1, 0, 0 };
                out_vertices.*.items[n + 2].uvw = .{ 1, 0, 0 };

                out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2 }) catch |e| system.handle_error3("__compute_curve out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2 })", e);
            }
            return;
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
        out_vertices.*.resize(n + 4) catch |e| system.handle_error3("__compute_curve out_vertices.*.resize(n + 4)", e);
        out_vertices.*.items[n].pos = _start;
        out_vertices.*.items[n + 1].pos = _control0;
        out_vertices.*.items[n + 2].pos = _control1;
        out_vertices.*.items[n + 3].pos = _end;

        out_vertices.*.items[n].uvw = .{ mat.e[0][0], mat.e[0][1], mat.e[0][2] };
        out_vertices.*.items[n + 1].uvw = .{ mat.e[1][0], mat.e[1][1], mat.e[1][2] };
        out_vertices.*.items[n + 2].uvw = .{ mat.e[2][0], mat.e[2][1], mat.e[2][2] };
        out_vertices.*.items[n + 3].uvw = .{ mat.e[3][0], mat.e[3][1], mat.e[3][2] };

        {
            var i: usize = 0;
            while (i < 4) : (i += 1) {
                var j: usize = i + 1;
                while (j < 4) : (j += 1) {
                    if (math.compare_n(out_vertices.*.items[n + i].pos, out_vertices.*.items[n + j].pos)) {
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

                        out_idxs.*.appendSlice(&.{ indices[0], indices[1], indices[2] }) catch |e| system.handle_error3("__compute_curve out_idxs.*.appendSlice(&.{ indices[0], indices[1], indices[2] })", e);
                        return;
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
                        out_idxs.*.appendSlice(&.{ indices[k], indices[(k + 1) % 3], @intCast(nn + i) }) catch |e| system.handle_error3("__compute_curve out_idxs.*.appendSlice(&.{ indices[k], indices[(k + 1) % 3], @intCast(nn + i) })", e);
                    }
                    return;
                }
            }
        }

        if (lines_intersect(_start, _control1, _control0, _end)) {
            if (math.length_sq(_control1, _start) < math.length_sq(_end, _control0)) {
                //system.print_debug("3", .{});
                out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2, nn + 0, nn + 2, nn + 3 }) catch |e| system.handle_error3("__compute_curve out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2, nn + 0, nn + 2, nn + 3 })", e);
            } else {
                //system.print_debug("4", .{});
                out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 3, nn + 1, nn + 2, nn + 3 }) catch |e| system.handle_error3("__compute_curve out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 3, nn + 1, nn + 2, nn + 3 })", e);
            }
        } else if (lines_intersect(_start, _end, _control0, _control1)) {
            if (math.length_sq(_end, _start) < math.length_sq(_control1, _control0)) {
                //system.print_debug("5", .{});
                out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 3, nn + 0, nn + 3, nn + 2 }) catch |e| system.handle_error3("__compute_curve  out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 3, nn + 0, nn + 3, nn + 2 })", e);
            } else {
                //system.print_debug("6", .{});
                out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2, nn + 2, nn + 2, nn + 3 }) catch |e| system.handle_error3("__compute_curve out_idxs.*.appendSlice(&.{ nn + 0, nn + 1, nn + 2, nn + 2, nn + 2, nn + 3 })", e);
            }
        } else {
            if (math.length_sq(_control0, _start) < math.length_sq(_end, _control1)) {
                //system.print_debug("7", .{});
                out_idxs.*.appendSlice(&.{ nn + 0, nn + 2, nn + 1, nn + 0, nn + 1, nn + 3 }) catch |e| system.handle_error3("__compute_curve out_idxs.*.appendSlice(&.{ nn + 0, nn + 2, nn + 1, nn + 0, nn + 1, nn + 3 })", e);
            } else {
                //system.print_debug("8", .{});
                out_idxs.*.appendSlice(&.{ nn + 0, nn + 2, nn + 3, nn + 3, nn + 2, nn + 1 }) catch |e| system.handle_error3("__compute_curve out_idxs.*.appendSlice(&.{ nn + 0, nn + 2, nn + 3, nn + 3, nn + 2, nn + 1 })", e);
            }
        }
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

        if (math.compare_n(discr, 0.0)) {
            if (math.compare_n(out_d1.*, 0.0)) {
                if (math.compare_n(out_d2.*, 0.0)) {
                    if (math.compare_n(out_d3.*, 0.0)) return curve_TYPE.line;
                    return curve_TYPE.quadratic;
                }
            } else {
                return curve_TYPE.cusp;
            }
            if (D < -std.math.floatEps(f32)) return curve_TYPE.loop;
        }
        if (discr > std.math.floatEps(f32)) return curve_TYPE.serpentine;
        return curve_TYPE.loop;
    }
};
