const dp = @import("data_provider.zig");
const types = @import("types.zig");

pub const CGFontIndex = u16;
pub const CGGlyph = CGFontIndex;

pub const CGFontRef = *opaque {
    pub fn init(provider: dp.CGDataProviderRef) CGFontRef {
        return CGFontCreateWithDataProvider(provider);
    }

    pub fn deinit(self: CGFontRef) void {
        return CGFontRelease(self);
    }
};

pub extern fn CGFontCreateWithDataProvider(provider: dp.CGDataProviderRef) CGFontRef;
pub extern fn CGFontRelease(font: CGFontRef) void;
pub extern fn CGFontGetGlyphAdvances(font: CGFontRef, glyphs: [*]const CGGlyph, count: usize, advances: [*]c_int) bool;
pub extern fn CGFontGetUnitsPerEm(font: CGFontRef) c_int;
