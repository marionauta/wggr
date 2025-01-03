const types = @import("types.zig");
const bc = @import("bitmap_context.zig");
const img = @import("image.zig");
const font = @import("font.zig");

const CGFloat = types.CGFloat;
const CGRect = types.CGRect;

pub const CGContextRef = *extern opaque {
    pub fn fill_ellipse_in_rect(self: CGContextRef, rect: CGRect) void {
        CGContextFillEllipseInRect(self, rect);
    }

    pub fn fill_rect(self: CGContextRef, rect: CGRect) void {
        CGContextFillRect(self, rect);
    }

    pub fn stroke_rect(self: CGContextRef, rect: CGRect, width: f32) void {
        CGContextSetLineWidth(self, width);
        CGContextStrokeRect(self, rect);
    }

    pub fn get_width(self: CGContextRef) usize {
        return bc.CGBitmapContextGetWidth(self);
    }

    pub fn get_height(self: CGContextRef) usize {
        return bc.CGBitmapContextGetHeight(self);
    }
};

const CGInterpolationQuality = enum(i32) {
    kCGInterpolationNone = 1,
};

pub extern fn CGContextSaveGState(c: ?CGContextRef) void;
pub extern fn CGContextRestoreGState(c: ?CGContextRef) void;
pub extern fn CGContextTranslateCTM(c: ?CGContextRef, tx: CGFloat, ty: CGFloat) void;
pub extern fn CGContextScaleCTM(c: ?CGContextRef, sx: CGFloat, sy: CGFloat) void;
pub extern fn CGContextSetInterpolationQuality(c: ?CGContextRef, quality: CGInterpolationQuality) void;
pub extern fn CGContextSetRGBFillColor(c: ?CGContextRef, red: CGFloat, blue: CGFloat, green: CGFloat, alpha: CGFloat) void;
pub extern fn CGContextSetRGBStrokeColor(c: ?CGContextRef, red: CGFloat, blue: CGFloat, green: CGFloat, alpha: CGFloat) void;
pub extern fn CGContextFillEllipseInRect(c: ?CGContextRef, rect: CGRect) void;
pub extern fn CGContextFillRect(c: ?CGContextRef, rect: CGRect) void;
pub extern fn CGContextStrokeRect(c: ?CGContextRef, rect: CGRect) void;
/// Sets the line width for a graphics context.
/// The default line width is 1 unit. When stroked, the line straddles the path, with half of the total width on either side.
pub extern fn CGContextSetLineWidth(c: ?CGContextRef, width: CGFloat) void;
pub extern fn CGContextSetCharacterSpacing(c: ?CGContextRef, spacing: CGFloat) void;
pub extern fn CGContextSetFont(c: ?CGContextRef, font: font.CGFontRef) void;
pub extern fn CGContextSetFontSize(c: ?CGContextRef, size: CGFloat) void;
pub extern fn CGContextSetTextPosition(c: ?CGContextRef, x: CGFloat, y: CGFloat) void;
pub extern fn CGContextShowGlyphs(c: ?CGContextRef, g: [*]const font.CGGlyph, count: usize) void;
pub extern fn CGContextDrawImage(c: ?CGContextRef, rect: CGRect, image: img.CGImageRef) void;
