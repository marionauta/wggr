const dp = @import("data_provider.zig");
const cs = @import("color_space.zig");
const t = @import("types.zig");

pub const CGImageRef = *extern opaque {
    pub fn get_width(self: CGImageRef) usize {
        return CGImageGetWidth(self);
    }

    pub fn get_height(self: CGImageRef) usize {
        return CGImageGetHeight(self);
    }

    pub fn deinit(self: CGImageRef) void {
        CGImageRelease(self);
    }
};

pub extern fn CGImageCreateWithPNGDataProvider(
    source: dp.CGDataProviderRef,
    decode: ?*const t.CGFloat,
    shouldInterpolate: bool,
    intent: cs.CGColorRenderingIntent,
) CGImageRef;
pub extern fn CGImageRelease(image: CGImageRef) void;
pub extern fn CGImageGetWidth(image: CGImageRef) usize;
pub extern fn CGImageGetHeight(image: CGImageRef) usize;
