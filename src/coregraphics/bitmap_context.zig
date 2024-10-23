const CGContextRef = @import("context.zig").CGContextRef;

pub extern fn CGBitmapContextGetWidth(c: CGContextRef) usize;
pub extern fn CGBitmapContextGetHeight(c: CGContextRef) usize;
