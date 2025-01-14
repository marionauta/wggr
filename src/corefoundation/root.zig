pub usingnamespace @import("data.zig");

pub const CFTypeRef = *extern opaque {};

pub extern fn CFRelease(cf: CFTypeRef) void;
