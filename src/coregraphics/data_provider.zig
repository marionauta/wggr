const cf = @import("../corefoundation/root.zig");

pub const CGDataProviderRef = *extern opaque {
    pub fn deinit(self: CGDataProviderRef) void {
        return CGDataProviderRelease(@ptrCast(self));
    }
};

pub extern fn CGDataProviderCreateWithCFData(data: cf.CFDataRef) CGDataProviderRef;
pub extern fn CGDataProviderRelease(provider: CGDataProviderRef) void;
