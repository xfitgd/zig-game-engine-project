const std = @import("std");
const builtin = @import("builtin");
const engine = @import("engine/engine.zig");
pub const XfitPlatform = engine.XfitPlatform;

//* User Setting
//크로스 플랫폼 빌드시 zig build -Dtarget=aarch64-windows(linux)
//x86_64-windows(linux)
// Android 쪽은 한번 테스트하고 안해서(Windows쪽 완성되면 할 예정) 버그 있을 겁니다.
const PLATFORM = XfitPlatform.windows;
const OPTIMIZE = std.builtin.OptimizeMode.Debug;

const EXAMPLE: EXAMPLES = EXAMPLES.SHAPE2D;
//*

const examples = [_][]const u8{
    "main.zig",
    "main_shape2d.zig",
    "main_sound.zig",
};
const EXAMPLES = enum(usize) {
    IMAGE,
    SHAPE2D,
    SOUND,
};

fn callback(result: *std.Build.Step.Compile) void {
    //TODO 여기에 사용자 지정 라이브러리 등을 추가합니다.
    _ = result;
}

pub fn build(b: *std.Build) void {
    const platform = b.option(XfitPlatform, "platform", "build platform") orelse PLATFORM;
    b.release_mode = .fast;
    engine.init(b, b.path(examples[@intFromEnum(EXAMPLE)]), "engine", platform, b.standardOptimizeOption(.{ .preferred_optimize_mode = OPTIMIZE }), callback);
}
