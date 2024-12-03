const cf = @import("corefoundation/root.zig");
const cg = @import("coregraphics/root.zig");

const PlatformData = extern struct {
    context: ?cg.CGContextRef = null,
    frame_time: f32 = 0,
    last_tap: cg.CGPoint = cg.CGPoint.ZERO,
    last_wheel_move: f32 = 0,
    current_camera: Camera2D = Camera2D.default(),
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
    x: f32 = 0,
    y: f32 = 0,
};

pub const Camera2D = extern struct {
    offset: Vector2 = .{},
    target: Vector2 = .{},
    rotation: f32 = 0,
    zoom: f32 = 0,

    fn default() Camera2D {
        return .{ .zoom = 1 };
    }
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
    unreachable;
}

pub export fn GetFrameTime() f32 {
    return DATA.frame_time;
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
    DATA.last_wheel_move = 0;
}

pub export fn BeginMode2D(camera: Camera2D) void {
    DATA.current_camera = camera;
}

pub export fn EndMode2D() void {
    DATA.current_camera = Camera2D.default();
}

pub export fn ClearBackground(color: Color) void {
    const camera = DATA.current_camera;
    const rec = Rectangle{
        .x = 0 - camera.offset.x,
        .y = 0 - camera.offset.y,
        .width = @floatFromInt(GetScreenWidth()),
        .height = @floatFromInt(GetScreenHeight()),
    };
    DrawRectangleRec(rec, color);
}

pub export fn DrawRectangleRec(rec: Rectangle, color: Color) void {
    const camera = DATA.current_camera;
    const rect = cg.CGRect{
        .origin = cg.CGPoint{
            .x = rec.x + camera.offset.x,
            .y = rec.y + camera.offset.y,
        },
        .size = cg.CGSize{ .width = rec.width, .height = rec.height },
    };
    set_rgba_color(DATA.context, color);
    if (DATA.context) |ctx| ctx.fill_rect(into_cg_rect(rect));
}

pub fn MeasureText(text: [:0]const u8, fontSize: c_int) c_int {
    // TODO: currently approximated for Helvetica, calculate better.
    const letter_width = @as(f32, @floatFromInt(fontSize)) * 0.5;
    const length = @as(f32, @floatFromInt(text.len));
    return @intFromFloat(letter_width * length);
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
    const source = Rectangle{
        .width = @floatFromInt(texture.get_width()),
        .height = @floatFromInt(texture.get_height()),
    };
    const dest = Rectangle{
        .x = position.x,
        .y = position.y,
        .width = source.width * scale,
        .height = source.height * scale,
    };
    // TODO: right now all calls to `pro` create a copy of the image.
    DrawTexturePro(texture, source, dest, Vector2{}, rotation, tint);
}

pub export fn DrawTexturePro(texture: Texture2D, source: Rectangle, dest: Rectangle, origin: Vector2, rotation: f32, tint: Color) void {
    // TODO: rotation and tint are ignored.
    _ = rotation;
    _ = tint;

    // raylib flips the image if the source width or height is negative.
    const x_scale: cg.CGFloat = if (source.width > 0) 1 else -1;
    const x_offset: cg.CGFloat = if (x_scale == 1) 0 else (@as(f32, @floatFromInt(GetScreenWidth())) - dest.width);
    const y_scale: cg.CGFloat = if (source.height > 0) 1 else -1;
    // TODO: this is just a hardcoded value, calculate better
    const y_offset: cg.CGFloat = if (y_scale == 1) 0 else (@as(f32, @floatFromInt(GetScreenHeight()))) - dest.y + dest.height + 90;

    const _source = cg.CGRect{
        .origin = .{ .x = source.x, .y = source.y },
        .size = .{ .width = @abs(source.width), .height = @abs(source.height) },
    };
    const cropped = cg.CGImageCreateWithImageInRect(texture, _source);
    defer cropped.deinit();

    const rect = cg.CGRect{
        .origin = .{
            .x = dest.x - origin.x + DATA.current_camera.offset.x,
            .y = dest.y - origin.y + DATA.current_camera.offset.y,
        },
        .size = .{
            .height = dest.height,
            .width = dest.width,
        },
    };

    CGContextSaveGState(DATA.context);
    CGContextTranslateCTM(DATA.context, x_offset, y_offset);
    CGContextScaleCTM(DATA.context, x_scale, y_scale);
    cg.CGContextDrawImage(DATA.context, into_cg_rect(rect), cropped);
    CGContextRestoreGState(DATA.context);
}

extern fn CGContextSaveGState(c: ?cg.CGContextRef) void;
extern fn CGContextRestoreGState(c: ?cg.CGContextRef) void;

extern fn CGContextTranslateCTM(c: ?cg.CGContextRef, tx: cg.CGFloat, ty: cg.CGFloat) void;
extern fn CGContextScaleCTM(c: ?cg.CGContextRef, sx: cg.CGFloat, sy: cg.CGFloat) void;

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

pub export fn GetMouseWheelMove() f32 {
    return DATA.last_wheel_move;
}

/// Check collision between two rectangles
pub export fn CheckCollisionRecs(rec1: Rectangle, rec2: Rectangle) bool {
    return ((rec1.x < (rec2.x + rec2.width) and (rec1.x + rec1.width) > rec2.x) and (rec1.y < (rec2.y + rec2.height) and (rec1.y + rec1.height) > rec2.y));
}

/// Check if point is inside rectangle
pub export fn CheckCollisionPointRec(point: Vector2, rec: Rectangle) bool {
    return (point.x >= rec.x) and (point.x < (rec.x + rec.width)) and (point.y >= rec.y) and (point.y < (rec.y + rec.height));
}

/// Get collision rectangle for two rectangles collision
pub export fn GetCollisionRec(rec1: Rectangle, rec2: Rectangle) Rectangle {
    var overlap = Rectangle{};

    const left = if (rec1.x > rec2.x) rec1.x else rec2.x;
    const right1 = rec1.x + rec1.width;
    const right2 = rec2.x + rec2.width;
    const right = if (right1 < right2) right1 else right2;
    const top = if (rec1.y > rec2.y) rec1.y else rec2.y;
    const bottom1 = rec1.y + rec1.height;
    const bottom2 = rec2.y + rec2.height;
    const bottom = if (bottom1 < bottom2) bottom1 else bottom2;

    if ((left < right) and (top < bottom)) {
        overlap.x = left;
        overlap.y = top;
        overlap.width = right - left;
        overlap.height = bottom - top;
    }

    return overlap;
}

pub export fn IsKeyReleased(key: c_int) bool {
    _ = key;
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
