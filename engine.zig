const std = @import("std");
const builtin = @import("builtin");

pub const XfitPlatform = enum(u32) { windows, android, linux, mac, end };

//* User Setting
//크로스 플랫폼 빌드시 zig build -Dtarget=aarch64-windows(linux)
//x86_64-windows(linux)
// Android 쪽은 한번 테스트하고 안해서(Windows쪽 완성되면 할 예정) 버그 있을 겁니다.
const ANDROID_PATH = "C:/Android";
const ANDROID_NDK_PATH = std.fmt.comptimePrint("{s}/ndk/27.0.11718014", .{ANDROID_PATH});
const ANDROID_VER = 34;
const VULKAN_INC_PATH = "C:/vk/include";

//keystore 없으면 생성
//keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
const ANDROID_KEYSTORE = "debug.keystore";
//*

pub fn init(b: *std.Build, PLATFORM: XfitPlatform, OPTIMIZE: std.builtin.OptimizeMode, callback: fn (*std.Build.Step.Compile) void) void {
    const target = b.standardTargetOptions(.{});
    const build_options = b.addOptions();

    build_options.addOption(XfitPlatform, "platform", PLATFORM);

    const arch_text = comptime [_][]const u8{
        "aarch64-linux-android",
        //"arm-linux-androideabi", not support vulkan
        //"i686-linux-android",
        "x86_64-linux-android",
    };
    const out_arch_text = comptime [_][]const u8{
        "../lib/arm64-v8a",
        //"armeabi-v7a",
        //"x86",
        "../lib/x86_64",
    };
    const targets = [_]std.zig.CrossTarget{
        .{ .os_tag = .linux, .cpu_arch = .aarch64, .abi = .android, .cpu_features_add = std.Target.aarch64.featureSet(&.{.v8a}) },
        //.{ .os_tag = .linux, .cpu_arch = .arm, .abi = .android, .cpu_features_add = std.Target.arm.featureSet(&.{.v7a}) },
        //.{ .os_tag = .linux, .cpu_arch = .x86, .abi = .android },
        .{ .os_tag = .linux, .cpu_arch = .x86_64, .abi = .android },
    };

    var install_step: *std.Build.Step = b.default_step;
    install_step = b.step("shared lib build", "shared lib build");

    comptime var i = 0;
    inline while (i < targets.len) : (i += 1) {
        var result: *std.Build.Step.Compile = undefined;

        const build_options_module = build_options.createModule();

        if (PLATFORM == XfitPlatform.android) {
            result = b.addSharedLibrary(.{
                .target = b.resolveTargetQuery(targets[i]),
                .name = "XfitTest",
                .root_source_file = b.path("main.zig"),
                .optimize = OPTIMIZE,
                .pic = true,
            });
            //if (targets[i].cpu_arch == .x86) result.link_z_notext = true; //x86 only

            var contents = std.ArrayList(u8).init(b.allocator);
            var writer = contents.writer();
            writer.print("include_dir={s}\n", .{comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include", .{ANDROID_NDK_PATH})}) catch unreachable;
            writer.print("sys_include_dir={s}\n", .{comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/{s}", .{ ANDROID_NDK_PATH, arch_text[i] })}) catch unreachable;
            writer.print("crt_dir={s}\n", .{comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/{s}/{d}", .{ ANDROID_NDK_PATH, arch_text[i], ANDROID_VER })}) catch unreachable;
            writer.writeAll("msvc_lib_dir=\n") catch unreachable;
            writer.writeAll("kernel32_lib_dir=\n") catch unreachable;
            writer.writeAll("gcc_dir=\n") catch unreachable;
            const android_libc_step = b.addWriteFile("android-libc.conf", contents.items);
            result.setLibCFile(android_libc_step.files.items[0].getPath());
            install_step.dependOn(&android_libc_step.step);

            result.addSystemIncludePath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/{s}", .{ ANDROID_NDK_PATH, arch_text[i] }) });
            result.addSystemIncludePath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/lib/clang/18/include", .{ANDROID_NDK_PATH}) });
            result.addSystemIncludePath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include", .{ANDROID_NDK_PATH}) });
            result.addSystemIncludePath(b.path("."));

            result.addLibraryPath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/{s}/{d}", .{ ANDROID_NDK_PATH, arch_text[i], ANDROID_VER }) });

            result.linkSystemLibrary("android");
            result.linkSystemLibrary("vulkan");
            result.linkSystemLibrary("c");
            result.linkSystemLibrary("log");

            result.root_module.addImport("build_options", build_options_module);
            callback(result);

            install_step.dependOn(&b.addInstallArtifact(result, .{
                .dest_dir = .{ .override = .{ .custom = out_arch_text[i] } },
            }).step);
        } else if (PLATFORM == XfitPlatform.windows) {
            result = b.addExecutable(.{
                .target = target,
                .name = "XfitTest",
                .root_source_file = b.path("main.zig"),
                .optimize = OPTIMIZE,
            });
            result.linkLibC();

            result.addIncludePath(.{ .cwd_relative = VULKAN_INC_PATH });

            result.addObjectFile(b.path("zig-game-engine-project/lib/vulkan.lib"));
            result.subsystem = .Windows;

            result.root_module.addImport("build_options", build_options_module);

            callback(result);
            b.installArtifact(result);
        } else unreachable;
        if (PLATFORM != XfitPlatform.android) break;
    }

    var cmd: *std.Build.Step.Run = undefined;
    if (PLATFORM == XfitPlatform.android) {
        cmd = b.addSystemCommand(&.{ "compile", "android", ANDROID_PATH, std.fmt.comptimePrint("{d}", .{ANDROID_VER}) });
    } else {
        cmd = b.addSystemCommand(&.{"compile"});
    }
    cmd.step.dependOn(install_step);
    b.default_step.dependOn(&cmd.step);
}
