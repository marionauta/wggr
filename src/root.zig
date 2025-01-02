const std = @import("std");
const cf = @import("corefoundation/root.zig");
const cg = @import("coregraphics/root.zig");

const PlatformData = extern struct {
    context: ?cg.CGContextRef = null,
    frame_time: f32 = 0,
    last_tap: cg.CGPoint = cg.CGPoint.ZERO,
    last_wheel_move: f32 = 0,
    window_focused: bool = true,
    current_camera: Camera2D = Camera2D.default(),
};

export var DATA: PlatformData = .{};

pub const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

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

pub const KEY_ONE = 49;
pub const KEY_SPACE = 32;
pub const KEY_P = 80;
pub const KEY_W = 87;

pub export fn IsWindowFocused() bool {
    return DATA.window_focused;
}

pub export fn GetFrameTime() f32 {
    return DATA.frame_time;
}

pub export fn GetScreenWidth() c_int {
    return @intCast(DATA.context.?.get_width());
}

pub export fn GetScreenHeight() c_int {
    return @intCast(DATA.context.?.get_height());
}

pub export fn BeginDrawing() void {
    cg.CGContextSetInterpolationQuality(DATA.context, .kCGInterpolationNone);
}

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

/// Draw a color-filled circle (Vector version)
pub export fn DrawCircleV(center: Vector2, radius: f32, color: Color) void {
    const camera = DATA.current_camera;
    const rect = cg.CGRect{
        .origin = cg.CGPoint{
            .x = (center.x - radius) + camera.offset.x,
            .y = (center.y - radius) + camera.offset.y,
        },
        .size = cg.CGSize{ .width = radius * 2, .height = radius * 2 },
    };
    set_rgba_fill_color(DATA.context, color);
    if (DATA.context) |ctx| ctx.fill_ellipse_in_rect(into_cg_rect(rect));
}

/// Draw a color-filled rectangle
pub export fn DrawRectangleRec(rec: Rectangle, color: Color) void {
    const camera = DATA.current_camera;
    const rect = cg.CGRect{
        .origin = cg.CGPoint{
            .x = rec.x + camera.offset.x,
            .y = rec.y + camera.offset.y,
        },
        .size = cg.CGSize{ .width = rec.width, .height = rec.height },
    };
    if (DATA.context) |ctx| {
        set_rgba_fill_color(DATA.context, color);
        ctx.fill_rect(into_cg_rect(rect));
    }
}

/// Draw rectangle outline with extended parameters
pub export fn DrawRectangleLinesEx(rec: Rectangle, lineThick: f32, color: Color) void {
    const camera = DATA.current_camera;
    const rect = cg.CGRect{
        .origin = cg.CGPoint{
            .x = rec.x + camera.offset.x,
            .y = rec.y + camera.offset.y,
        },
        .size = cg.CGSize{ .width = rec.width, .height = rec.height },
    };
    if (DATA.context) |ctx| {
        set_rgba_stroke_color(DATA.context, color);
        ctx.stroke_rect(into_cg_rect(rect), lineThick);
    }
}

/// Measure string size for Font
pub fn MeasureTextEx(font: Font, text: [:0]const u8, fontSize: f32, spacing: f32) Vector2 {
    const units: f32 = @floatFromInt(cg.CGFontGetUnitsPerEm(font.font));
    var res = Vector2{ .y = fontSize };
    var glyph = [1]cg.CGGlyph{0};
    var advance = [1]c_int{0};
    for (text) |char| {
        glyph[0] = font.glyph(char);
        if (!cg.CGFontGetGlyphAdvances(font.font, &glyph, 1, &advance)) {
            return res;
        }
        res.x += spacing + @as(f32, @floatFromInt(advance[0])) / units * fontSize;
    }
    return res;
}

/// Draw text using font and additional parameters
pub fn DrawTextEx(font: Font, text: [:0]const u8, position: Vector2, fontSize: f32, spacing: f32, tint: Color) void {
    const ctx = DATA.context orelse return;
    cg.CGContextSetFont(ctx, font.font);
    cg.CGContextSetFontSize(ctx, fontSize);
    cg.CGContextSetCharacterSpacing(ctx, spacing);
    set_rgba_fill_color(ctx, tint);
    const point = into_cg_point(.{ .x = position.x, .y = position.y + fontSize });
    cg.CGContextSetTextPosition(ctx, point.x, point.y);
    var glyphs = std.ArrayList(cg.CGGlyph).initCapacity(std.heap.c_allocator, text.len) catch return;
    defer glyphs.deinit();
    for (text) |char| {
        glyphs.append(font.glyph(char)) catch return;
    }
    cg.CGContextShowGlyphs(ctx, glyphs.items.ptr, glyphs.items.len);
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

    const screen_height: cg.CGFloat = @floatFromInt(GetScreenHeight());

    // TODO: flipping only works in the Y axis.
    // flip the image if the source width or height is negative.
    const y_flipped = source.height < 0;
    const x_flipped = false;

    const _source = cg.CGRect{
        .origin = .{ .x = source.x, .y = source.y },
        .size = .{ .width = @abs(source.width), .height = @abs(source.height) },
    };
    const cropped = cg.CGImageCreateWithImageInRect(texture, _source);
    defer cropped.deinit();

    var rect = cg.CGRect{
        .origin = .{
            .x = dest.x - origin.x + DATA.current_camera.offset.x,
            .y = dest.y - origin.y + DATA.current_camera.offset.y - (if (source.height < 0) dest.height else 0),
        },
        .size = .{
            .height = dest.height,
            .width = dest.width,
        },
    };

    const ctx = DATA.context orelse return;
    cg.CGContextSaveGState(ctx);
    defer cg.CGContextRestoreGState(ctx);
    if (y_flipped or x_flipped) {
        cg.CGContextTranslateCTM(ctx, 0, screen_height);
        cg.CGContextScaleCTM(ctx, 1, if (y_flipped) -1 else 1);
        rect.origin.y = screen_height - rect.origin.y - rect.size.height;
    }
    cg.CGContextDrawImage(ctx, into_cg_rect(rect), cropped);
}

pub const Font = extern struct {
    font: cg.CGFontRef,
    offset: u16,

    fn glyph(self: Font, char: u8) cg.CGGlyph {
        return char - self.offset;
    }
};

pub export fn LoadFontFromMemory(fileType: [*:0]const u8, fileData: [*]const u8, dataSize: c_int, fontSize: c_int, codepoints: ?[*]c_int, codepointCount: c_int) Font {
    _ = fileType;
    _ = fontSize;
    _ = codepoints;
    const data = cf.CFDataCreate(null, fileData, dataSize);
    const provider = cg.CGDataProviderCreateWithCFData(data);
    return .{
        .font = cg.CGFontCreateWithDataProvider(provider),
        .offset = @intCast(codepointCount),
    };
}

pub export fn UnloadFont(font: Font) void {
    font.font.deinit();
}

pub export fn GetMousePosition() Vector2 {
    const last = DATA.last_tap;
    return Vector2{ .x = @floatCast(last.x), .y = @floatCast(last.y) };
}

pub const MouseButton = enum(c_int) {
    MOUSE_BUTTON_LEFT,
};

pub const MOUSE_BUTTON_LEFT = @intFromEnum(MouseButton.MOUSE_BUTTON_LEFT);

/// Check if a mouse button has been pressed once (currently the same as IsMouseButtonReleased)
pub export fn IsMouseButtonPressed(button: c_int) bool {
    return IsMouseButtonReleased(button);
}

/// Check if a mouse button is being pressed (currently always false)
pub export fn IsMouseButtonDown(button: c_int) bool {
    _ = button;
    return false;
}

/// Check if a mouse button has been released once
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

/// Check collision between circle and rectangle
pub export fn CheckCollisionCircleRec(center: Vector2, radius: f32, rec: Rectangle) bool {
    const recCenterX = rec.x + rec.width / 2.0;
    const recCenterY = rec.y + rec.height / 2.0;

    const dx = @abs(center.x - recCenterX);
    const dy = @abs(center.y - recCenterY);

    if (dx > (rec.width / 2.0 + radius)) {
        return false;
    }
    if (dy > (rec.height / 2.0 + radius)) {
        return false;
    }

    if (dx <= (rec.width / 2.0)) {
        return true;
    }
    if (dy <= (rec.height / 2.0)) {
        return true;
    }

    const cornerDistanceSq = (dx - rec.width / 2.0) * (dx - rec.width / 2.0) +
        (dy - rec.height / 2.0) * (dy - rec.height / 2.0);

    return (cornerDistanceSq <= (radius * radius));
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

pub export fn IsKeyPressed(key: c_int) bool {
    _ = key;
    return false;
}

pub export fn IsKeyReleased(key: c_int) bool {
    _ = key;
    return false;
}

fn set_rgba_fill_color(c: ?cg.CGContextRef, color: Color) void {
    cg.CGContextSetRGBFillColor(
        c,
        @as(cg.CGFloat, @floatFromInt(color.r)) / 255.0,
        @as(cg.CGFloat, @floatFromInt(color.g)) / 255.0,
        @as(cg.CGFloat, @floatFromInt(color.b)) / 255.0,
        @as(cg.CGFloat, @floatFromInt(color.a)) / 255.0,
    );
}

fn set_rgba_stroke_color(c: ?cg.CGContextRef, color: Color) void {
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
