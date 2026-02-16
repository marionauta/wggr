pub const data = @import("data.zig");

pub const CFDataRef = data.CFDataRef;
pub const CFTypeRef = *opaque {};

pub extern fn CFRelease(cf: CFTypeRef) void;
