const root = @import("root.zig");

pub const CFDataRef = *extern opaque {
    pub fn deinit(self: ?CFDataRef) void {
        if (self == null) return;
        return root.CFRelease(@ptrCast(self));
    }
};

pub extern fn CFDataCreate(allocator: ?*opaque {}, bytes: [*]const u8, length: c_int) CFDataRef;
