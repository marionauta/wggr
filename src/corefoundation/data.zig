pub const CFDataRef = *extern opaque {};

pub extern fn CFDataCreate(allocator: ?*opaque {}, bytes: [*]const u8, length: c_int) CFDataRef;
