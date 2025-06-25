const Planet = struct {
    name: []const u8,
    temp: f32,
    distance: u32,

    pub fn fooConst(self: Planet) *const u32 {
        return &self.distance;
    }
    pub fn fooVar(self: *Planet) *u32 {
        return &self.distance;
    }
};

const std = @import("std");
test {
    const planetconst = Planet{
        .name = "Draccos",
        .temp = 15.7,
        .distance = 18922,
    };
    var planetvar = Planet{
        .name = "Exelamari",
        .temp = 419.2,
        .distance = 90000,
    };
    std.debug.print("{any}\n", .{@TypeOf(planetconst.distance)});
    std.debug.print("{any}\n", .{@TypeOf(&planetconst.distance)});
    std.debug.print("{any}\n", .{@TypeOf(planetvar.distance)});
    std.debug.print("{any}\n", .{@TypeOf(&planetvar.distance)});
    std.debug.print("{any}\n", .{@TypeOf(planetvar.fooConst())});
    std.debug.print("{any}\n", .{@TypeOf(planetconst.fooConst())});
    std.debug.print("{any}\n", .{@TypeOf(planetvar.fooVar())});
}
