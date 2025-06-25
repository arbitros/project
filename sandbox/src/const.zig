const planet = struct {
    id: u32,
    temp: f32,
};

test {
    var laser: ?planet = planet{
        .id = 1,
        .temp = 5,
    };

    if (laser) |*_laser| {
        _laser.id = 2;
    }

