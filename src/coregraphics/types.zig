const builtin = @import("builtin");

pub const CGFloat = if (builtin.abi == .ilp32) f32 else f64;

pub const CGPoint = extern struct {
    x: CGFloat,
    y: CGFloat,

    pub const ZERO = CGPoint{ .x = 0, .y = 0 };
};

pub const CGSize = extern struct {
    width: CGFloat,
    height: CGFloat,
};

pub const CGRect = extern struct {
    origin: CGPoint,
    size: CGSize,

    pub fn init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) CGRect {
        return .{
            .origin = CGPoint{ .x = x, .y = y },
            .size = CGSize{ .width = width, .height = height },
        };
    }
};
