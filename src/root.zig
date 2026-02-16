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
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,

    fn is(self: Color, other: Color) bool {
        return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a;
    }

    fn is_white(self: Color) bool {
        return self.is(.{ .r = 255, .g = 255, .b = 255, .a = 255 });
    }
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
    const ctx = DATA.context orelse return 0;
    return @intCast(ctx.get_width());
}

pub export fn GetScreenHeight() c_int {
    const ctx = DATA.context orelse return 0;
    return @intCast(ctx.get_height());
}

pub export fn BeginDrawing() void {
    cg.context.CGContextSetInterpolationQuality(DATA.context, .kCGInterpolationNone);
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
    if (DATA.context) |ctx| {
        ctx.set_fill_color(color);
        ctx.fill_ellipse_in_rect(into_cg_rect(rect));
    }
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
        ctx.set_fill_color(color);
        ctx.fill_rect(into_cg_rect(rect));
    }
}

/// Draw rectangle outline with extended parameters
pub export fn DrawRectangleLinesEx(rec: Rectangle, lineThick: f32, color: Color) void {
    const camera = DATA.current_camera;
    const rect = cg.CGRect{
        .origin = cg.CGPoint{
            .x = rec.x + (lineThick / 2) + camera.offset.x,
            .y = rec.y + (lineThick / 2) + camera.offset.y,
        },
        .size = cg.CGSize{
            .width = rec.width - lineThick,
            .height = rec.height - lineThick,
        },
    };
    if (DATA.context) |ctx| {
        ctx.set_stroke_color(color);
        ctx.stroke_rect(into_cg_rect(rect), lineThick);
    }
}

/// Measure string size for Font
pub fn MeasureTextEx(font: Font, text: [:0]const u8, fontSize: f32, spacing: f32) Vector2 {
    const units: f32 = @floatFromInt(cg.font.CGFontGetUnitsPerEm(font.font));
    var res = Vector2{ .y = fontSize };
    var glyph = [1]cg.CGGlyph{0};
    var advance = [1]c_int{0};
    for (text) |char| {
        glyph[0] = font.glyph(char);
        if (!cg.font.CGFontGetGlyphAdvances(font.font, &glyph, 1, &advance)) {
            return res;
        }
        res.x += spacing + @as(f32, @floatFromInt(advance[0])) / units * fontSize;
    }
    return res;
}

/// Draw text using font and additional parameters
pub fn DrawTextEx(font: Font, text: [:0]const u8, position: Vector2, fontSize: f32, spacing: f32, tint: Color) void {
    const ctx = DATA.context orelse return;
    cg.context.CGContextSetFont(ctx, font.font);
    cg.context.CGContextSetFontSize(ctx, fontSize);
    cg.context.CGContextSetCharacterSpacing(ctx, spacing);
    ctx.set_fill_color(tint);
    const point = into_cg_point(.{ .x = position.x, .y = position.y + fontSize });
    cg.context.CGContextSetTextPosition(ctx, point.x, point.y);
    const allocator = std.heap.c_allocator;
    var glyphs = std.ArrayList(cg.CGGlyph).initCapacity(allocator, text.len) catch return;
    defer glyphs.deinit(allocator);
    for (text) |char| {
        glyphs.append(allocator, font.glyph(char)) catch return;
    }
    cg.context.CGContextShowGlyphs(ctx, glyphs.items.ptr, glyphs.items.len);
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
    const data = cf.data.CFDataCreate(null, image.data, image.dataSize);
    defer data.deinit();
    const provider = cg.data_provider.CGDataProviderCreateWithCFData(data);
    defer provider.deinit();
    return switch (image.fileType) {
        .png => cg.image.CGImageCreateWithPNGDataProvider(provider, null, false, .kCGRenderingIntentDefault),
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

/// Draw a part of a texture defined by a rectangle.
/// `rotation` is intentionally ignored.
pub export fn DrawTexturePro(texture: Texture2D, source: Rectangle, dest: Rectangle, origin: Vector2, rotation: f32, tint: Color) void {
    _ = rotation;

    const screen_height: cg.CGFloat = @floatFromInt(GetScreenHeight());

    // TODO: flipping only works in the Y axis.
    // flip the image if the source width or height is negative.
    const y_flipped = source.height < 0;
    const x_flipped = false;

    const _source = cg.CGRect{
        .origin = .{ .x = source.x, .y = source.y },
        .size = .{ .width = @abs(source.width), .height = @abs(source.height) },
    };
    const cropped = cg.image.CGImageCreateWithImageInRect(texture, _source);
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
    cg.context.CGContextSaveGState(ctx);
    defer cg.context.CGContextRestoreGState(ctx);
    if (y_flipped or x_flipped) {
        cg.context.CGContextTranslateCTM(ctx, 0, screen_height);
        cg.context.CGContextScaleCTM(ctx, 1, if (y_flipped) -1 else 1);
        rect.origin.y = screen_height - rect.origin.y - rect.size.height;
    }
    const cg_rect = into_cg_rect(rect);
    cg.context.CGContextDrawImage(ctx, cg_rect, cropped);

    if (!tint.is_white()) {
        cg.context.CGContextSetBlendMode(ctx, .multiply);
        defer cg.context.CGContextSetBlendMode(ctx, .normal);
        // The following line has terrible performance
        // cg.context.CGContextClipToMask(ctx, cg_rect, cropped);
        ctx.set_fill_color(tint);
        ctx.fill_rect(cg_rect);
    }
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
    const data = cf.data.CFDataCreate(null, fileData, dataSize);
    defer data.deinit();
    const provider = cg.data_provider.CGDataProviderCreateWithCFData(data);
    defer provider.deinit();
    return .{
        .font = cg.font.CGFontCreateWithDataProvider(provider),
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

pub export fn IsKeyPressed(key: c_int) bool {
    _ = key;
    return false;
}

pub export fn IsKeyReleased(key: c_int) bool {
    _ = key;
    return false;
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
