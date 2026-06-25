const std = @import("std");
const runtime = @import("../runtime/root.zig");
const platform = @import("../platform/root.zig");

const max_mobile_command_name_bytes: usize = 128;

pub const EmbeddedApp = struct {
    app: runtime.App,
    runtime: runtime.Runtime,

    pub fn init(app: runtime.App, platform_value: platform.Platform) EmbeddedApp {
        return .{
            .app = app,
            .runtime = runtime.Runtime.init(.{ .platform = platform_value }),
        };
    }

    pub fn start(self: *EmbeddedApp) anyerror!void {
        try self.runtime.dispatchPlatformEvent(self.app, .app_start);
    }

    pub fn resize(self: *EmbeddedApp, surface: platform.Surface) anyerror!void {
        try self.runtime.dispatchPlatformEvent(self.app, .{ .surface_resized = surface });
    }

    pub fn frame(self: *EmbeddedApp) anyerror!void {
        try self.runtime.dispatchPlatformEvent(self.app, .frame_requested);
    }

    pub fn command(self: *EmbeddedApp, name: []const u8) anyerror!void {
        try self.runtime.dispatchCommand(self.app, .{
            .name = name,
            .source = .native_view,
            .window_id = 1,
            .view_label = "mobile-header",
        });
    }

    pub fn stop(self: *EmbeddedApp) anyerror!void {
        try self.runtime.dispatchPlatformEvent(self.app, .app_shutdown);
    }
};

const MobileHostApp = struct {
    null_platform: platform.NullPlatform,
    embedded: EmbeddedApp,
    last_error: ?anyerror = null,
    command_count: usize = 0,
    last_command_name: [max_mobile_command_name_bytes + 1]u8 = [_]u8{0} ** (max_mobile_command_name_bytes + 1),

    fn create() !*MobileHostApp {
        const allocator = std.heap.page_allocator;
        const self = try allocator.create(MobileHostApp);
        self.null_platform = platform.NullPlatform.init(.{});
        self.last_error = null;
        self.command_count = 0;
        self.last_command_name = [_]u8{0} ** (max_mobile_command_name_bytes + 1);
        self.embedded = EmbeddedApp.init(.{
            .context = self,
            .name = "zero-native-mobile",
            .source = platform.WebViewSource.html(mobile_html),
            .event_fn = handleEvent,
        }, self.null_platform.platform());
        return self;
    }

    fn handleEvent(context: *anyopaque, runtime_value: *runtime.Runtime, event: runtime.Event) anyerror!void {
        _ = runtime_value;
        const self: *MobileHostApp = @ptrCast(@alignCast(context));
        switch (event) {
            .command => |command_event| {
                self.command_count += 1;
                const count = @min(command_event.name.len, max_mobile_command_name_bytes);
                @memcpy(self.last_command_name[0..count], command_event.name[0..count]);
                self.last_command_name[count] = 0;
            },
            else => {},
        }
    }
};

const mobile_html =
    \\<!doctype html>
    \\<html>
    \\<body style="font-family: system-ui; padding: 2rem;">
    \\  <h1>zero-native mobile</h1>
    \\  <p>This content is loaded through the zero-native embedded C ABI.</p>
    \\</body>
    \\</html>
;

fn mobileApp(raw: ?*anyopaque) ?*MobileHostApp {
    const pointer = raw orelse return null;
    return @ptrCast(@alignCast(pointer));
}

fn recordError(self: *MobileHostApp, err: anyerror) void {
    self.last_error = err;
}

pub fn zero_native_app_create() ?*anyopaque {
    const self = MobileHostApp.create() catch return null;
    return self;
}

pub fn zero_native_app_destroy(app: ?*anyopaque) void {
    const self = mobileApp(app) orelse return;
    std.heap.page_allocator.destroy(self);
}

pub fn zero_native_app_start(app: ?*anyopaque) void {
    const self = mobileApp(app) orelse return;
    self.embedded.start() catch |err| recordError(self, err);
}

pub fn zero_native_app_stop(app: ?*anyopaque) void {
    const self = mobileApp(app) orelse return;
    self.embedded.stop() catch |err| recordError(self, err);
}

pub fn zero_native_app_resize(app: ?*anyopaque, width: f32, height: f32, scale: f32, surface: ?*anyopaque) void {
    const self = mobileApp(app) orelse return;
    self.embedded.resize(.{
        .size = .{ .width = width, .height = height },
        .scale_factor = scale,
        .native_handle = surface,
    }) catch |err| recordError(self, err);
}

pub fn zero_native_app_touch(app: ?*anyopaque, id: u64, phase: c_int, x: f32, y: f32, pressure: f32) void {
    _ = app;
    _ = id;
    _ = phase;
    _ = x;
    _ = y;
    _ = pressure;
}

pub fn zero_native_app_command(app: ?*anyopaque, name: ?[*]const u8, len: usize) void {
    const self = mobileApp(app) orelse return;
    const ptr = name orelse {
        recordError(self, error.InvalidCommand);
        return;
    };
    self.embedded.command(ptr[0..len]) catch |err| {
        recordError(self, err);
        return;
    };
    self.last_error = null;
}

pub fn zero_native_app_frame(app: ?*anyopaque) void {
    const self = mobileApp(app) orelse return;
    self.embedded.frame() catch |err| recordError(self, err);
}

pub fn zero_native_app_set_asset_root(app: ?*anyopaque, path: [*]const u8, len: usize) void {
    _ = app;
    _ = path;
    _ = len;
}

pub fn zero_native_app_last_command_count(app: ?*anyopaque) usize {
    const self = mobileApp(app) orelse return 0;
    return self.command_count;
}

pub fn zero_native_app_last_command_name(app: ?*anyopaque) [*:0]const u8 {
    const self = mobileApp(app) orelse return "";
    return @ptrCast(&self.last_command_name);
}

pub fn zero_native_app_last_error_name(app: ?*anyopaque) [*:0]const u8 {
    const self = mobileApp(app) orelse return "";
    const err = self.last_error orelse return "";
    return @errorName(err);
}

test "embedded app starts and loads source" {
    var null_platform = platform.NullPlatform.init(.{});
    var state: u8 = 0;
    var embedded = EmbeddedApp.init(.{
        .context = &state,
        .name = "embedded",
        .source = platform.WebViewSource.html("<p>Embedded</p>"),
    }, null_platform.platform());

    try embedded.start();
    try @import("std").testing.expectEqualStrings("<p>Embedded</p>", null_platform.loaded_source.?.bytes);
}

test "mobile C ABI dispatches native commands through embedded runtime" {
    const app = zero_native_app_create() orelse return error.TestUnexpectedResult;
    defer zero_native_app_destroy(app);

    zero_native_app_command(app, "mobile.refresh", "mobile.refresh".len);
    try std.testing.expectEqual(@as(usize, 1), zero_native_app_last_command_count(app));
    try std.testing.expectEqualStrings("mobile.refresh", std.mem.span(zero_native_app_last_command_name(app)));
    try std.testing.expectEqualStrings("", std.mem.span(zero_native_app_last_error_name(app)));

    zero_native_app_command(app, "", 0);
    try std.testing.expectEqualStrings("InvalidCommand", std.mem.span(zero_native_app_last_error_name(app)));

    zero_native_app_command(app, "mobile.open", "mobile.open".len);
    try std.testing.expectEqual(@as(usize, 2), zero_native_app_last_command_count(app));
    try std.testing.expectEqualStrings("mobile.open", std.mem.span(zero_native_app_last_command_name(app)));
    try std.testing.expectEqualStrings("", std.mem.span(zero_native_app_last_error_name(app)));
}
