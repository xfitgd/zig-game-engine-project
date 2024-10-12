const std = @import("std");
const graphics = @import("graphics.zig");
const system = @import("system.zig");

const animate_image = graphics.animate_image;

pub const animate_object = union(enum) {
    _image: animate_image,

    pub inline fn prev_frame(self: *animate_object) void {
        switch (self.*) {
            inline else => |*case| case.*.prev_frame(),
        }
    }
    pub inline fn map_update_frame(self: *animate_object) void {
        switch (self.*) {
            inline else => |*case| case.*.map_update_frame(),
        }
    }
    pub inline fn next_frame(self: *animate_object) void {
        switch (self.*) {
            inline else => |*case| case.*.next_frame(),
        }
    }
    pub inline fn set_frame(self: *animate_object, _frame: u32) void {
        switch (self.*) {
            inline else => |*case| case.*.set_frame(_frame),
        }
    }
    pub inline fn cur_frame(self: *animate_object) u32 {
        switch (self.*) {
            inline else => |*case| return case.*.frame,
        }
    }
    pub inline fn get_frame_count_build(self: *animate_object) u32 {
        switch (self.*) {
            inline else => |*case| return case.*.src.*.get_frame_count_build(),
        }
    }
    pub inline fn deinit(self: *animate_object) void {
        switch (self.*) {
            inline else => |*case| case.*.deinit(),
        }
    }
    pub inline fn build(self: *animate_object) void {
        switch (self.*) {
            inline else => |*case| case.*.build(),
        }
    }
    pub inline fn update(self: *animate_object) void {
        switch (self.*) {
            inline else => |*case| case.*.update(),
        }
    }
};

pub const multi_player = struct {
    objs: []*animate_object,
    playing: bool = false,
    target_fps: f32 = 30,
    __playing_dt: f32 = 0,
    loop: bool = true,

    pub fn update(self: *player, _dt: f64) void {
        if (self.*.playing) {
            const dt: f32 = @floatCast(_dt);
            self.*.__playing_dt += dt;
            while (self.*.__playing_dt >= 1 / self.*.target_fps) : (self.*.__playing_dt -= 1 / self.*.target_fps) {
                var isp: bool = false;
                for (self.*.objs) |v| {
                    if (self.*.loop or v.*.cur_frame() < v.*.get_frame_count_build() - 1) {
                        v.*.next_frame();
                        isp = true;
                    }
                }
                if (!isp) {
                    self.*.stop();
                    return;
                }
            }
        }
    }
    pub fn play(self: *player) void {
        self.*.playing = true;
        self.*.__playing_dt = 0.0;
    }
    pub fn stop(self: *player) void {
        self.*.playing = false;
    }
    pub fn set_frame(self: *player, _frame: u32) void {
        for (self.*.objs) |v| {
            v.*.set_frame(_frame);
        }
    }
    pub fn prev_frame(self: *animate_object) void {
        for (self.*.objs) |v| {
            v.*.prev_frame();
        }
    }
    pub fn next_frame(self: *animate_object) void {
        for (self.*.objs) |v| {
            v.*.next_frame();
        }
    }
};

pub const player = struct {
    obj: *animate_object,
    playing: bool = false,
    target_fps: f32 = 30,
    __playing_dt: f32 = 0,
    loop: bool = true,

    pub fn update(self: *player, _dt: f64) void {
        if (self.*.playing) {
            const dt: f32 = @floatCast(_dt);
            self.*.__playing_dt += dt;
            while (self.*.__playing_dt >= 1 / self.*.target_fps) : (self.*.__playing_dt -= 1 / self.*.target_fps) {
                if (self.*.loop or self.*.obj.*.cur_frame() < self.*.obj.*.get_frame_count_build() - 1) {
                    self.*.obj.*.next_frame();
                } else {
                    self.*.stop();
                    return;
                }
            }
        }
    }
    pub fn play(self: *player) void {
        self.*.playing = true;
        self.*.__playing_dt = 0.0;
    }
    pub fn stop(self: *player) void {
        self.*.playing = false;
    }
    pub fn set_frame(self: *player, _frame: u32) void {
        self.*.obj.*.set_frame(_frame);
    }
    pub fn prev_frame(self: *animate_object) void {
        self.*.obj.*.prev_frame();
    }
    pub fn next_frame(self: *animate_object) void {
        self.*.obj.*.next_frame();
    }
};
