const cf = @import("../corefoundation/root.zig");

pub const CGDataProviderRef = *extern opaque {};

pub extern fn CGDataProviderCreateWithCFData(data: cf.CFDataRef) CGDataProviderRef;
