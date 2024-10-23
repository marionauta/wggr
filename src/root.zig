const cf = @import("corefoundation/root.zig");
const cg = @import("coregraphics/root.zig");

const PlatformData = extern struct {
    context: ?cg.CGContextRef = null,
    last_tap: cg.CGPoint = cg.CGPoint.ZERO,
};

export var DATA: PlatformData = .{};

pub const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const BLACK = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const GRAY = Color{ .r = 130, .g = 130, .b = 130, .a = 255 };
pub const GREEN = Color{ .r = 0, .g = 228, .b = 48, .a = 255 };
pub const RED = Color{ .r = 230, .g = 41, .b = 55, .a = 255 };
pub const DARKGRAY = Color{ .r = 80, .g = 80, .b = 80, .a = 255 };
pub const WHITE = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };

pub const Rectangle = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
};

pub const Vector2 = extern struct {
    x: f32,
    y: f32,
};

pub export fn InitWindow(width: c_int, height: c_int, title: [*:0]const u8) void {
    _ = width;
    _ = height;
    _ = title;
    unreachable;
}

pub export fn CloseWindow() void {
    unreachable;
}

pub export fn SetTargetFPS(fps: c_int) void {
    _ = fps;
}

pub export fn GetFrameTime() f32 {
    unreachable;
}

pub export fn WindowShouldClose() bool {
    unreachable;
}

pub export fn GetScreenWidth() c_int {
    return @intCast(DATA.context.?.get_width());
}

pub export fn GetScreenHeight() c_int {
    return @intCast(DATA.context.?.get_height());
}

pub export fn BeginDrawing() void {}

pub export fn EndDrawing() void {
    DATA.last_tap = cg.CGPoint.ZERO;
}

pub export fn ClearBackground(color: Color) void {
    const rec = Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(GetScreenWidth()),
        .height = @floatFromInt(GetScreenHeight()),
    };
    DrawRectangleRec(rec, color);
}

pub export fn DrawRectangleRec(rec: Rectangle, color: Color) void {
    const rect = cg.CGRect{
        .origin = cg.CGPoint{ .x = rec.x, .y = rec.y },
        .size = cg.CGSize{ .width = rec.width, .height = rec.height },
    };
    set_rgba_color(DATA.context, color);
    DATA.context.?.fill_rect(into_cg_rect(rect));
}

pub fn MeasureText(text: [:0]const u8, fontSize: c_int) c_int {
    return fontSize * @as(c_int, @intCast(text.len));
}

pub fn DrawText(text: [:0]const u8, posX: c_int, posY: c_int, fontSize: c_int, color: Color) void {
    cg.CGContextSelectFont(DATA.context, "Helvetica", @floatFromInt(fontSize), .kCGEncodingMacRoman);
    set_rgba_color(DATA.context, color);
    const y = GetScreenHeight() - posY - fontSize;
    cg.CGContextShowTextAtPoint(DATA.context, @floatFromInt(posX), @floatFromInt(y), text, text.len);
}

pub const Image = extern struct {
    const FileType = enum {
        png,
    };
    data: [*]const u8,
    dataSize: c_int,
    fileType: FileType,

    pub fn deinit(self: Image) void {
        _ = self;
    }
};

pub export fn LoadImageFromMemory(fileType: [*:0]const u8, fileData: [*]const u8, dataSize: c_int) Image {
    _ = fileType; // ignore, use png always
    const image = Image{ .data = fileData, .dataSize = dataSize, .fileType = .png };
    return image;
}

pub export fn UnloadImage(image: Image) void {
    _ = image;
}

pub const Texture2D = cg.CGImageRef;

pub export fn LoadTextureFromImage(image: Image) Texture2D {
    const data = cf.CFDataCreate(null, image.data, image.dataSize);
    const provider = cg.CGDataProviderCreateWithCFData(data);
    return switch (image.fileType) {
        .png => cg.CGImageCreateWithPNGDataProvider(provider, null, false, .kCGRenderingIntentDefault),
    };
}

pub export fn UnloadTexture(texture: Texture2D) void {
    texture.deinit();
}

pub export fn DrawTexture(texture: Texture2D, posX: c_int, posY: c_int, tint: Color) void {
    const position = Vector2{ .x = @floatFromInt(posX), .y = @floatFromInt(posY) };
    DrawTextureEx(texture, position, 0, 1, tint);
}

pub export fn DrawTextureEx(texture: Texture2D, position: Vector2, rotation: f32, scale: f32, tint: Color) void {
    _ = rotation;
    _ = tint;
    const rect = cg.CGRect{
        .origin = .{
            .x = position.x,
            .y = position.y,
        },
        .size = .{
            .width = @as(cg.CGFloat, @floatFromInt(texture.get_width())) * scale,
            .height = @as(cg.CGFloat, @floatFromInt(texture.get_height())) * scale,
        },
    };
    cg.CGContextDrawImage(DATA.context, into_cg_rect(rect), texture);
}

pub export fn GetMousePosition() Vector2 {
    const last = DATA.last_tap;
    return Vector2{ .x = @floatCast(last.x), .y = @floatCast(last.y) };
}

pub const MouseButton = enum(c_int) {
    MOUSE_BUTTON_LEFT,
};

pub const MOUSE_BUTTON_LEFT = @intFromEnum(MouseButton.MOUSE_BUTTON_LEFT);

pub export fn IsMouseButtonDown(button: c_int) bool {
    _ = button;
    return false;
}

pub export fn IsMouseButtonReleased(button: c_int) bool {
    _ = button;
    const last = GetMousePosition();
    return last.x != 0 and last.y != 0;
}

pub export fn CheckCollisionPointRec(point: Vector2, rec: Rectangle) bool {
    _ = point;
    _ = rec;
    return false;
}

fn set_rgba_color(c: ?cg.CGContextRef, color: Color) void {
    cg.CGContextSetRGBFillColor(
        c,
        @as(cg.CGFloat, @floatFromInt(color.r)) / 255.0,
        @as(cg.CGFloat, @floatFromInt(color.g)) / 255.0,
        @as(cg.CGFloat, @floatFromInt(color.b)) / 255.0,
        @as(cg.CGFloat, @floatFromInt(color.a)) / 255.0,
    );
}

fn into_cg_point(point: cg.CGPoint) cg.CGPoint {
    const screen_height: cg.CGFloat = @floatFromInt(GetScreenHeight());
    return .{
        .x = point.x,
        .y = screen_height - point.y,
    };
}

fn into_cg_rect(rect: cg.CGRect) cg.CGRect {
    const screen_height: cg.CGFloat = @floatFromInt(GetScreenHeight());
    return .{
        .origin = .{
            .x = rect.origin.x,
            .y = screen_height - rect.origin.y - rect.size.height,
        },
        .size = rect.size,
    };
}
