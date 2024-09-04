const std = @import("std");
const builtin = @import("builtin");

///_num에서 _multiple 배수 중 가까운 값을 구합니다.
pub fn round_up(comptime T: type, _num: T, _multiple: T) T {
    if (_multiple == 0)
        return _num;

    const remainder: T = @abs(_num) % _multiple;
    if (remainder == 0)
        return _num;

    if (_num < 0) {
        return -(@abs(_num) - remainder);
    } else {
        return _num + _multiple - remainder;
    }
}

pub inline fn test_number_type(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Int, .Float, .ComptimeInt, .ComptimeFloat => {},
        else => {
            @compileError("not a number type");
        },
    }
}
pub inline fn test_float_type(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => {},
        else => {
            @compileError("not a float number type");
        },
    }
}

pub inline fn pow(v0: anytype, p: anytype) @TypeOf(v0) {
    return std.math.pow(@TypeOf(v0), v0, p);
}

pub fn rect_(comptime T: type) type {
    test_number_type(T);
    return struct {
        const Self = @This();
        left: T,
        right: T,
        top: T,
        bottom: T,

        pub inline fn width(self: *Self) T {
            return @intCast(@abs(self.right - self.left));
        }
        pub inline fn height(self: *Self) T {
            return @intCast(@abs(self.top - self.bottom));
        }
        pub fn init(_left: T, _right: T, _top: T, _bottom: T) Self {
            return Self{
                .left = _left,
                .right = _right,
                .top = _top,
                .bottom = _bottom,
            };
        }
    };
}

pub const rect = rect_(f32);
pub const recti = rect_(i32);

pub const point = [2]f32;
pub const pointu = [2]u32;
pub const pointi = [2]i32;
pub const point3d = [3]f32;
pub const vector = @Vector(4, f32);

pub fn length_sq(p1: anytype, p2: anytype) @TypeOf(p1[0]) {
    comptime var i = 0;
    var result: @TypeOf(p1[0]) = 0;
    inline while (i < p1.len) : (i += 1) {
        result += pow(p1[i] - p2[i], 2);
    }
    return result;
}

pub inline fn dot3(v0: vector, v1: vector) f32 {
    const dot = v0 * v1;
    return dot[0] + dot[1] + dot[2];
}
pub inline fn normalize3(v: vector) vector {
    return v * (@as(vector, @splat(1)) / @as(vector, @splat(std.math.sqrt(dot3(v, v)))));
}
pub inline fn cross3(v0: vector, v1: vector) vector {
    var xmm0 = @shuffle(f32, v0, undefined, [4]i32{ 1, 2, 0, 3 });
    var xmm1 = @shuffle(f32, v1, undefined, [4]i32{ 2, 0, 1, 3 });
    var result = xmm0 * xmm1;
    xmm0 = @shuffle(f32, xmm0, undefined, [4]i32{ 1, 2, 0, 3 });
    xmm1 = @shuffle(f32, xmm1, undefined, [4]i32{ 2, 0, 1, 3 });
    result = result - xmm0 * xmm1;
    result[3] = 0;
    return result;
}

pub const matrix3x3 = matrix_(f32, 3, 3);

pub const matrix_error = error{ not_exist_inverse_matrix, invaild_near_far, sfov_0, far_near_0, near_far_0, aspect_0, w_0, h_0 };

pub fn compare_n(n: anytype, i: anytype) bool {
    switch (@typeInfo(@TypeOf(n, i))) {
        .Float, .ComptimeFloat => {
            return std.math.approxEqAbs(@TypeOf(n, i), n, i, std.math.floatEps(f32));
        },
        .Int, .ComptimeInt => {
            return n == i;
        },
        .Array => {
            var e: usize = 0;
            while (e < n.len) : (e += 1) {
                if (!compare_n(n[e], i[e])) return false;
            }
            return true;
        },
        else => {
            @compileError("not a number type");
        },
    }
}
inline fn mulAdd(comptime T: type, v0: @Vector(4, T), v1: @Vector(4, T), v2: @Vector(4, T)) @Vector(4, T) {
    if (@typeInfo(T) == .Float or @typeInfo(T) == .ComptimeFloat) {
        return @mulAdd(@Vector(4, T), v0, v1, v2);
    } else {
        return v0 * v1 + v2;
    }
}

pub const matrix = matrix4x4(f32);

///https://github.com/zig-gamedev/zig-gamedev/blob/main/libs/zmath/src/zmath.zig
pub fn matrix4x4(comptime T: type) type {
    test_number_type(T);
    return struct {
        const Self = @This();
        e: [4]vector,

        pub fn init() Self {
            return Self{
                .e = .{.{0} ** 4} ** 4,
            };
        }
        pub inline fn translation(x: T, y: T, z: T) Self {
            return Self{
                .e = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ x, y, z, 1 },
                },
            };
        }
        pub inline fn translation_transpose(x: T, y: T, z: T) Self {
            return Self{
                .e = .{
                    .{ 1, 0, 0, x },
                    .{ 0, 1, 0, y },
                    .{ 0, 0, 1, z },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        pub inline fn translation_inverse(x: T, y: T, z: T) Self {
            return translation(-x, -y, -z);
        }
        pub inline fn translation_transpose_inverse(x: T, y: T, z: T) Self {
            return translation_transpose(-x, -y, -z);
        }
        pub inline fn scaling(x: T, y: T, z: T) Self {
            return Self{
                .e = .{
                    .{ x, 0, 0, 0 },
                    .{ 0, y, 0, 0 },
                    .{ 0, 0, z, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        pub inline fn rocationX(angle: T) Self {
            test_float_type(T);
            const c = std.cos(angle);
            const s = std.sin(angle);
            return Self{
                .e = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, c, s, 0 },
                    .{ 0, -s, c, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        pub inline fn rocationY(angle: T) Self {
            test_float_type(T);
            const c = std.cos(angle);
            const s = std.sin(angle);
            return Self{
                .e = .{
                    .{ c, 0, -s, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ s, 0, c, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        pub inline fn rocationZ(angle: T) Self {
            test_float_type(T);
            const c = std.cos(angle);
            const s = std.sin(angle);
            return Self{
                .e = .{
                    .{ c, s, 0, 0 },
                    .{ -s, c, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        pub inline fn rocationX_inverse(angle: T) Self {
            test_float_type(T);
            const c = std.cos(angle);
            const s = std.sin(angle);
            return Self{
                .e = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, c, -s, 0 },
                    .{ 0, s, c, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        pub inline fn rocationY_inverse(angle: T) Self {
            test_float_type(T);
            const c = std.cos(angle);
            const s = std.sin(angle);
            return Self{
                .e = .{
                    .{ c, 0, s, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ -s, 0, c, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        pub inline fn rocationZ_inverse(angle: T) Self {
            test_float_type(T);
            const c = std.cos(angle);
            const s = std.sin(angle);
            return Self{
                .e = .{
                    .{ c, -s, 0, 0 },
                    .{ s, c, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        pub const rocationX_transpose = rocationX_inverse;
        pub const rocationY_transpose = rocationY_inverse;
        pub const rocationZ_transpose = rocationZ_inverse;
        pub fn scaling_inverse(x: T, y: T, z: T) Self {
            test_float_type(T);
            return translation(1 / x, 1 / y, 1 / z);
        }
        ///Vulkan 으로 테스트 완료
        pub fn perspectiveFovLhVulkan(fovy: T, aspect: T, near: T, far: T) matrix_error!Self {
            var res = try perspectiveFovLh(fovy, aspect, near, far);
            res.e[1][1] *= -1;
            return res;
        }
        pub fn perspectiveFovLh(fovy: T, aspect: T, near: T, far: T) matrix_error!Self {
            test_float_type(T);
            const sfov = std.math.sin(0.5 * fovy);
            const cfov = std.math.cos(0.5 * fovy);

            if (!(near > 0.0 and far > 0.0 and far > near)) return matrix_error.invaild_near_far;
            if (compare_n(sfov, 0)) return matrix_error.sfov_0;
            if (compare_n((far - near), 0)) return matrix_error.far_near_0;
            if (compare_n(aspect, 0)) return matrix_error.aspect_0;
            // assert(!approxEqAbs(f32, scfov[0], 0.0, 0.001));
            // assert(!approxEqAbs(f32, far, near, 0.001));
            // assert(!approxEqAbs(f32, aspect, 0.0, 0.01));

            const h = cfov / sfov;
            const w = h / aspect;
            const r = far / (far - near);
            return Self{ .e = .{
                .{ w, 0, 0, 0 },
                .{ 0, h, 0, 0 },
                .{ 0, 0, r, 1 },
                .{ 0, 0, -r * near, 0 },
            } };
        }
        pub fn perspectiveFovRh(fovy: T, aspect: T, near: T, far: T) matrix_error!Self {
            test_float_type(T);
            const sfov = std.math.sin(0.5 * fovy);
            const cfov = std.math.cos(0.5 * fovy);

            if (!(near > 0.0 and far > 0.0 and far > near)) return matrix_error.invaild_near_far;
            if (compare_n(sfov, 0)) return matrix_error.sfov_0;
            if (compare_n((near - far), 0)) return matrix_error.near_far_0;
            if (compare_n(aspect, 0)) return matrix_error.aspect_0;
            // assert(!approxEqAbs(f32, scfov[0], 0.0, 0.001));
            // assert(!approxEqAbs(f32, far, near, 0.001));
            // assert(!approxEqAbs(f32, aspect, 0.0, 0.01));

            const h = cfov / sfov;
            const w = h / aspect;
            const r = far / (near - far);
            return Self{ .e = .{
                .{ w, 0, 0, 0 },
                .{ 0, h, 0, 0 },
                .{ 0, 0, r, -1 },
                .{ 0, 0, r * near, 0 },
            } };
        }
        /// Produces Z values in [-1.0, 1.0] range (OpenGL defaults)
        pub fn perspectiveFovRhGL(fovy: T, aspect: T, near: T, far: T) matrix_error!Self {
            test_float_type(T);
            const sfov = std.math.sin(0.5 * fovy);
            const cfov = std.math.cos(0.5 * fovy);

            if (!(near > 0.0 and far > 0.0 and far > near)) return matrix_error.invaild_near_far;
            if (compare_n(sfov, 0)) return matrix_error.sfov_0;
            if (compare_n((near - far), 0)) return matrix_error.near_far_0;
            if (compare_n(aspect, 0)) return matrix_error.aspect_0;
            // assert(!approxEqAbs(f32, scfov[0], 0.0, 0.001));
            // assert(!approxEqAbs(f32, far, near, 0.001));
            // assert(!approxEqAbs(f32, aspect, 0.0, 0.01));

            const h = cfov / sfov;
            const w = h / aspect;
            const r = near - far;
            return Self{ .e = .{
                .{ w, 0, 0, 0 },
                .{ 0, h, 0, 0 },
                .{ 0, 0, (near + far) / r, -1 },
                .{ 0, 0, 2 * near * far / r, 0 },
            } };
        }
        ///Vulkan 으로 테스트 완료
        pub fn orthographicLhVulkan(w: T, h: T, near: T, far: T) matrix_error!Self {
            var res = try orthographicLh(w, h, near, far);
            res.e[1][1] *= -1;
            return res;
        }
        pub fn orthographicLh(w: T, h: T, near: T, far: T) matrix_error!Self {
            test_float_type(T);
            // assert(!approxEqAbs(f32, w, 0.0, 0.001));
            // assert(!approxEqAbs(f32, h, 0.0, 0.001));
            // assert(!approxEqAbs(f32, far, near, 0.001));
            if (compare_n((far - near), 0)) return matrix_error.far_near_0;
            if (compare_n(w, 0)) return matrix_error.w_0;
            if (compare_n(h, 0)) return matrix_error.h_0;

            const r = 1 / (far - near);
            return Self{
                .e = .{
                    .{ 2 / w, 0, 0, 0 },
                    .{ 0, 2 / h, 0, 0 },
                    .{ 0, 0, r, 0 },
                    .{ 0, 0, -r * near, 1 },
                },
            };
        }
        pub fn orthographicRh(w: T, h: T, near: T, far: T) matrix_error!Self {
            test_float_type(T);
            // assert(!approxEqAbs(f32, w, 0.0, 0.001));
            // assert(!approxEqAbs(f32, h, 0.0, 0.001));
            // assert(!approxEqAbs(f32, far, near, 0.001));
            if (compare_n((near - far), 0)) return matrix_error.near_far_0;
            if (compare_n(w, 0)) return matrix_error.w_0;
            if (compare_n(h, 0)) return matrix_error.h_0;

            const r = 1 / (near - far);
            return Self{
                .e = .{
                    .{ 2 / w, 0, 0, 0 },
                    .{ 0, 2 / h, 0, 0 },
                    .{ 0, 0, r, 0 },
                    .{ 0, 0, r * near, 1 },
                },
            };
        }
        ///w좌표는 신경 x
        pub fn lookToLh(eyepos: vector, eyedir: vector, updir: vector) Self {
            test_float_type(T);
            const az = normalize3(eyedir);
            const ax = normalize3(cross3(updir, az));
            const ay = normalize3(cross3(az, ax));
            return .{
                .e = .{
                    .{ ax[0], ay[0], az[0], 0 },
                    .{ ax[1], ay[1], az[1], 0 },
                    .{ ax[2], ay[2], az[2], 0 },
                    .{ -dot3(ax, eyepos), -dot3(ay, eyepos), -dot3(az, eyepos), 1 },
                },
            };
        }
        ///w좌표는 신경 x
        pub fn lookToRh(eyepos: vector, eyedir: vector, updir: vector) Self {
            return lookToLh(eyepos, -eyedir, updir);
        }
        ///Vulkan 으로 테스트 완료, w좌표는 신경 x
        pub fn lookAtLh(eyepos: vector, focuspos: vector, updir: vector) Self {
            return lookToLh(eyepos, focuspos - eyepos, updir);
        }
        ///w좌표는 신경 x
        pub fn lookAtRh(eyepos: vector, focuspos: vector, updir: vector) Self {
            return lookToLh(eyepos, eyepos - focuspos, updir);
        }

        pub fn identity() Self {
            return Self{
                .e = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };
        }
        inline fn dot4(v0: vector, v1: vector) T {
            const xmm0 = v0 * v1; // | x0*x1 | y0*y1 | z0*z1 | w0*w1 |
            return xmm0[0] + xmm0[1] + xmm0[2] + xmm0[3];
        }

        pub fn multiply(self: *const Self, _matrix: *const Self) Self {
            var result: Self = undefined;
            comptime var row = 0;
            inline while (row < 4) : (row += 1) {
                const vx = @shuffle(T, self.*.e[row], undefined, [4]i32{ 0, 0, 0, 0 });
                const vy = @shuffle(T, self.*.e[row], undefined, [4]i32{ 1, 1, 1, 1 });
                const vz = @shuffle(T, self.*.e[row], undefined, [4]i32{ 2, 2, 2, 2 });
                const vw = @shuffle(T, self.*.e[row], undefined, [4]i32{ 3, 3, 3, 3 });
                result.e[row] = mulAdd(T, vx, _matrix.*.e[0], vz * _matrix.*.e[2]) + mulAdd(T, vy, _matrix.*.e[1], vw * _matrix.*.e[3]);
            }
            return result;
        }
        pub fn addition(self: *const Self, _matrix: *const Self) Self {
            var result: Self = undefined;
            comptime var row = 0;
            inline while (row < 4) : (row += 1) {
                result.e[row] = self.*.e[row] + _matrix.*.e[row];
            }
            return result;
        }
        pub fn subtract(self: *const Self, _matrix: *const Self) Self {
            var result: Self = undefined;
            comptime var row = 0;
            inline while (row < 4) : (row += 1) {
                result.e[row] = self.*.e[row] - _matrix.*.e[row];
            }
            return result;
        }
        pub fn transpose(self: *const Self) Self {
            const temp1 = @shuffle(T, self.*.e[0], self.*.e[1], [4]i32{ 0, 1, ~@as(i32, 0), ~@as(i32, 1) });
            const temp3 = @shuffle(T, self.*.e[0], self.*.e[1], [4]i32{ 2, 3, ~@as(i32, 2), ~@as(i32, 3) });
            const temp2 = @shuffle(T, self.*.e[2], self.*.e[3], [4]i32{ 0, 1, ~@as(i32, 0), ~@as(i32, 1) });
            const temp4 = @shuffle(T, self.*.e[2], self.*.e[3], [4]i32{ 2, 3, ~@as(i32, 2), ~@as(i32, 3) });
            return Self{ .e = .{
                @shuffle(T, temp1, temp2, [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) }),
                @shuffle(T, temp1, temp2, [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) }),
                @shuffle(T, temp3, temp4, [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) }),
                @shuffle(T, temp3, temp4, [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) }),
            } };
        }
        pub fn format(self: *const Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;

            try writer.print("{s}\n", .{@typeName(Self)});

            comptime var i = 0;
            inline while (i < 4) : (i += 1) {
                try writer.print("{{{d}, {d}, {d}, {d}}}\n", .{ self.e[i][0], self.e[i][1], self.e[i][2], self.e[i][3] });
            }
        }

        pub fn determinant(self: *const Self) T {
            var v0 = @shuffle(T, self.*.e[2], undefined, [4]i32{ 1, 0, 0, 0 });
            var v1 = @shuffle(T, self.*.e[3], undefined, [4]i32{ 2, 2, 1, 1 });
            var v2 = @shuffle(T, self.*.e[2], undefined, [4]i32{ 1, 0, 0, 0 });
            var v3 = @shuffle(T, self.*.e[3], undefined, [4]i32{ 3, 3, 3, 2 });
            var v4 = @shuffle(T, self.*.e[2], undefined, [4]i32{ 2, 2, 1, 1 });
            var v5 = @shuffle(T, self.*.e[3], undefined, [4]i32{ 3, 3, 3, 2 });

            var p0 = v0 * v1;
            var p1 = v2 * v3;
            var p2 = v4 * v5;

            v0 = @shuffle(T, self.*.e[2], undefined, [4]i32{ 2, 2, 1, 1 });
            v1 = @shuffle(T, self.*.e[3], undefined, [4]i32{ 1, 0, 0, 0 });
            v2 = @shuffle(T, self.*.e[2], undefined, [4]i32{ 3, 3, 3, 2 });
            v3 = @shuffle(T, self.*.e[3], undefined, [4]i32{ 1, 0, 0, 0 });
            v4 = @shuffle(T, self.*.e[2], undefined, [4]i32{ 3, 3, 3, 2 });
            v5 = @shuffle(T, self.*.e[3], undefined, [4]i32{ 2, 2, 1, 1 });

            p0 = mulAdd(-v0, v1, p0);
            p1 = mulAdd(-v2, v3, p1);
            p2 = mulAdd(-v4, v5, p2);

            v0 = @shuffle(T, self.*.e[1], undefined, [4]i32{ 3, 3, 3, 2 });
            v1 = @shuffle(T, self.*.e[1], undefined, [4]i32{ 2, 2, 1, 1 });
            v2 = @shuffle(T, self.*.e[1], undefined, [4]i32{ 1, 0, 0, 0 });

            const s = self.e[0] * vector{ 1, -1, 1, -1 };
            var r = v0 * p0;
            r = mulAdd(-v1, p1, r);
            r = mulAdd(v2, p2, r);
            return dot4(s, r);
        }
        pub fn inverse(self: *const Self) !Self {
            const mt = transpose(self);
            var v0: [4]vector = undefined;
            var v1: [4]vector = undefined;

            v0[0] = @shuffle(T, mt.e[2], undefined, [4]i32{ 0, 0, 1, 1 });
            v1[0] = @shuffle(T, mt.e[3], undefined, [4]i32{ 2, 3, 2, 3 });
            v0[1] = @shuffle(T, mt.e[0], undefined, [4]i32{ 0, 0, 1, 1 });
            v1[1] = @shuffle(T, mt.e[1], undefined, [4]i32{ 2, 3, 2, 3 });
            v0[2] = @shuffle(T, mt.e[2], mt.e[0], [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) });
            v1[2] = @shuffle(T, mt.e[3], mt.e[1], [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) });

            var d0 = v0[0] * v1[0];
            var d1 = v0[1] * v1[1];
            var d2 = v0[2] * v1[2];

            v0[0] = @shuffle(T, mt.e[2], undefined, [4]i32{ 2, 3, 2, 3 });
            v1[0] = @shuffle(T, mt.e[3], undefined, [4]i32{ 0, 0, 1, 1 });
            v0[1] = @shuffle(T, mt.e[0], undefined, [4]i32{ 2, 3, 2, 3 });
            v1[1] = @shuffle(T, mt.e[1], undefined, [4]i32{ 0, 0, 1, 1 });
            v0[2] = @shuffle(T, mt.e[2], mt.e[0], [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) });
            v1[2] = @shuffle(T, mt.e[3], mt.e[1], [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) });

            d0 = mulAdd(T, -v0[0], v1[0], d0);
            d1 = mulAdd(T, -v0[1], v1[1], d1);
            d2 = mulAdd(T, -v0[2], v1[2], d2);

            v0[0] = @shuffle(T, mt.e[1], undefined, [4]i32{ 1, 2, 0, 1 });
            v1[0] = @shuffle(T, d0, d2, [4]i32{ ~@as(i32, 1), 1, 3, 0 });
            v0[1] = @shuffle(T, mt.e[0], undefined, [4]i32{ 2, 0, 1, 0 });
            v1[1] = @shuffle(T, d0, d2, [4]i32{ 3, ~@as(i32, 1), 1, 2 });
            v0[2] = @shuffle(T, mt.e[3], mt.e[0], [4]i32{ 1, 2, 0, 1 });
            v1[2] = @shuffle(T, d1, d2, [4]i32{ ~@as(i32, 3), 1, 3, 0 });
            v0[3] = @shuffle(T, mt.e[2], mt.e[1], [4]i32{ 2, 0, 1, 0 });
            v1[3] = @shuffle(T, d1, d2, [4]i32{ 3, ~@as(i32, 3), 1, 2 });

            var c0 = v0[0] * v1[0];
            var c2 = v0[1] * v1[1];
            var c4 = v0[2] * v1[2];
            var c6 = v0[3] * v1[3];

            v0[0] = @shuffle(T, mt.e[1], undefined, [4]i32{ 2, 3, 1, 2 });
            v1[0] = @shuffle(T, d0, d2, [4]i32{ 3, 0, 1, ~@as(i32, 0) });
            v0[1] = @shuffle(T, mt.e[0], undefined, [4]i32{ 3, 2, 3, 1 });
            v1[1] = @shuffle(T, d0, d2, [4]i32{ 2, 1, ~@as(i32, 0), 0 });
            v0[2] = @shuffle(T, mt.e[3], undefined, [4]i32{ 2, 3, 1, 2 });
            v1[2] = @shuffle(T, d1, d2, [4]i32{ 3, 0, 1, ~@as(i32, 2) });
            v0[3] = @shuffle(T, mt.e[2], undefined, [4]i32{ 3, 2, 3, 1 });
            v1[3] = @shuffle(T, d1, d2, [4]i32{ 2, 1, ~@as(i32, 2), 0 });

            c0 = mulAdd(T, -v0[0], v1[0], c0);
            c2 = mulAdd(T, -v0[1], v1[1], c2);
            c4 = mulAdd(T, -v0[2], v1[2], c4);
            c6 = mulAdd(T, -v0[3], v1[3], c6);

            v0[0] = @shuffle(T, mt.e[1], undefined, [4]i32{ 3, 0, 3, 0 });
            v1[0] = @shuffle(T, d0, d2, [4]i32{ 2, ~@as(i32, 1), ~@as(i32, 0), 2 });
            v0[1] = @shuffle(T, mt.e[0], undefined, [4]i32{ 1, 3, 0, 2 });
            v1[1] = @shuffle(T, d0, d2, [4]i32{ ~@as(i32, 1), 0, 3, ~@as(i32, 0) });
            v0[2] = @shuffle(T, mt.e[3], undefined, [4]i32{ 3, 0, 3, 0 });
            v1[2] = @shuffle(T, d1, d2, [4]i32{ 2, ~@as(i32, 3), ~@as(i32, 2), 2 });
            v0[3] = @shuffle(T, mt.e[2], undefined, [4]i32{ 1, 3, 0, 2 });
            v1[3] = @shuffle(T, d1, d2, [4]i32{ ~@as(i32, 3), 0, 3, ~@as(i32, 2) });

            const c1 = mulAdd(T, -v0[0], v1[0], c0);
            const c3 = mulAdd(T, v0[1], v1[1], c2);
            const c5 = mulAdd(T, -v0[2], v1[2], c4);
            const c7 = mulAdd(T, v0[3], v1[3], c6);

            c0 = mulAdd(T, v0[0], v1[0], c0);
            c2 = mulAdd(T, -v0[1], v1[1], c2);
            c4 = mulAdd(T, v0[2], v1[2], c4);
            c6 = mulAdd(T, -v0[3], v1[3], c6);

            var mr = Self{ .e = [4]vector{
                .{ c0[0], c1[1], c0[2], c1[3] },
                .{ c2[0], c3[1], c2[2], c3[3] },
                .{ c4[0], c5[1], c4[2], c5[3] },
                .{ c6[0], c7[1], c6[2], c7[3] },
            } };

            const det = dot4(mr.e[0], mt.e[0]);

            if (compare_n(det, 0)) {
                return matrix_error.not_exist_inverse_matrix;
            }

            const scale = @as(vector, @splat(det));
            mr.e[0] /= scale;
            mr.e[1] /= scale;
            mr.e[2] /= scale;
            mr.e[3] /= scale;

            return mr;
        }
    };
}

///  row ↕, col ↔
pub fn matrix_(comptime T: type, row: comptime_int, col: comptime_int) type {
    test_number_type(T);

    return struct {
        const Self = @This();
        e: [row][col]T,

        pub fn init() Self {
            return Self{
                .e = .{.{0} ** col} ** row,
            };
        }
        pub fn identity() Self {
            if (col == row) { //identity matrix
                var result: Self = undefined;
                comptime var i = 0;
                inline while (i < row) : (i += 1) {
                    comptime var j = 0;
                    inline while (j < col) : (j += 1) {
                        if (i == j) {
                            result.e[i][j] = 1;
                        } else {
                            result.e[i][j] = 0;
                        }
                    }
                }
                return result;
            } else {
                @compileError("identity : not a identity matrix");
            }
        }
        pub fn addition(self: *const Self, _matrix: *const Self) Self {
            var result: Self = self;
            comptime var r = 0;
            comptime var c = 0;
            inline while (r < row) : (r += 1) {
                c = 0;
                inline while (c < col) : (c += 1) {
                    result.e[r][c] += _matrix.e[r][c];
                }
            }
            return result;
        }
        pub fn subtract(self: *const Self, _matrix: *const Self) Self {
            var result: Self = self;
            comptime var r = 0;
            comptime var c = 0;
            inline while (r < row) : (r += 1) {
                c = 0;
                inline while (c < col) : (c += 1) {
                    result.e[r][c] -= _matrix.e[r][c];
                }
            }
            return result;
        }
        ///[row x COL] = [row x col][col x COL] COL 은 _matrix 행렬의 열(column) 갯수입니다.
        pub fn multiply(self: *const Self, COL: comptime_int, _matrix: *const matrix(T, col, COL)) matrix(T, row, COL) {
            var result: matrix(T, row, COL) = matrix(T, row, COL).init();
            comptime var r = 0;
            comptime var c = 0;
            comptime var n = 0;
            inline while (r < row) : (r += 1) {
                c = 0;
                inline while (c < COL) : (c += 1) {
                    n = 0;
                    inline while (n < COL) : (n += 1) {
                        result.e[r][c] += self.*.e[r][n] * _matrix.e[n][c];
                    }
                }
            }
            return result;
        }
        fn swap_row(self: *Self, i: isize, j: isize) void {
            if (i == j) return;
            var k: usize = 0;
            while (k < row) : (k += 1) {
                std.mem.swap(T, &self.e[@intCast(i)][k], &self.e[@intCast(j)][k]);
            }
        }
        pub fn transpose(self: *Self) matrix(T, col, row) {
            var result: matrix(T, col, row) = undefined;
            var r: i32 = 0;
            while (r < row) : (r += 1) {
                var c: i32 = 0;
                while (c < col) : (c += 1) {
                    result.e[c][r] = self.*.e[r][c];
                }
            }
            return result;
        }
        fn det(n: comptime_int, _matrix: [n][n]T) T {
            if (n == 1) return _matrix[0][0];

            var minor_matrix: [n][n - 1][n - 1]T = undefined;
            var k: usize = 0;
            while (k < n) : (k += 1) {
                var i: usize = 0;
                while (i < (n - 1)) : (i += 1) {
                    var j: usize = 0;
                    while (j < n) : (j += 1) {
                        if (j < k) {
                            minor_matrix[k][i][j] = _matrix[i + 1][j];
                        } else if (j > k) {
                            minor_matrix[k][i][j - 1] = _matrix[i + 1][j];
                        }
                    }
                }
            }
            var sum: T = 0;
            var test_: T = 1;
            k = 0;
            while (k < n) : (k += 1) {
                sum += test_ * _matrix[0][k] * det(n - 1, minor_matrix[k]);
                test_ *= -1;
            }
            return sum;
        }
        ///https://nate9389.tistory.com/63
        pub fn determinant(self: *const Self) T {
            if (col != row) @compileError("determinant : not a identity matrix");
            return det(row, self.e);
        }
        ///https://blog.naver.com/lovebuthate/221153359469
        pub fn inverse(self: *Self) !Self {
            if (col != row) @compileError("inverse : not a identity matrix");

            const nn = col; // 행 열이 어짜피 같으므로 nn 변수로 통일
            var a: Self = self.*;
            var b: Self = identity();
            var k: isize = 0;
            while (k < nn) : (k += 1) {
                var t = k - 1;
                while (t + 1 < nn and self.e[@intCast(t + 1)][@intCast(k)] == 0) : (t += 1) {}
                if (t == k - 1) t += 1;
                if (t == nn - 1 and compare_n(self.e[@intCast(t)][@intCast(k)], 0)) return matrix_error.not_exist_inverse_matrix;
                a.swap_row(k, t);
                b.swap_row(k, t);
                const d = a.e[@intCast(k)][@intCast(k)];
                var j: usize = 0;
                //k행 k열에 해당하는 수로 k행의 각 숫자를 나눔
                while (j < nn) : (j += 1) {
                    a.e[@intCast(k)][j] /= d;
                    b.e[@intCast(k)][j] /= d;
                }
                //k행을 제외한 다른 행에 숫자를 곱하고 더하는 과정
                var i: usize = 0;
                while (i < nn) : (i += 1) {
                    if (i != k) {
                        const m = a.e[i][@intCast(k)];
                        var ii: usize = 0;
                        while (ii < nn) : (ii += 1) {
                            if (ii >= k) a.e[i][ii] -= a.e[@intCast(k)][ii] * m;
                            b.e[i][ii] -= b.e[@intCast(k)][ii] * m;
                        }
                    }
                }
            }
            return b;
        }
        pub fn format(self: *const Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;

            try writer.print("{s}\n", .{@typeName(Self)});

            comptime var i = 0;
            inline while (i < row) : (i += 1) {
                comptime var j = 0;
                try writer.print("{{", .{});
                inline while (j < col - 1) : (j += 1) {
                    try writer.print("{d}, ", .{self.e[i][j]});
                }
                try writer.print("{d}}}\n", .{self.e[i][j]});
            }
        }
    };
}
