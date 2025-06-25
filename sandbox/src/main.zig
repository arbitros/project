const std = @import("std");

pub fn main() !void {
    const Car = struct {
        engine: u32,
        name: u8,
    };

    const Node = struct {
        data: Car,
        next: ?*Node,
    };
}
