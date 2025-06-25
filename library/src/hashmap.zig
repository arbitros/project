const std = @import("std");
const linkedlist = @import("linkedlist.zig");

pub fn HashMap(comptime K: type, comptime T: type, useHeap: bool) type {
    return struct {
        const Self = @This();
        const DEFAULT_LOAD_FACTOR = 0.75;

        size: usize,
        elements: usize,
        load: f32,
        load_capacity: f32,
        table: []linkedlist.LinkedList(K, T, useHeap),
        allocator: std.mem.Allocator,

        pub fn init(size: usize, allocator: std.mem.Allocator) !Self {
            const table = try allocator.alloc(linkedlist.LinkedList(K, T, useHeap), size); // causes memory leak somehow

            for (table) |*list| {
                list.* = linkedlist.LinkedList(K, T, useHeap).init(allocator);
            }

            const elements = 0;

            return Self{
                .size = size,
                .elements = elements,
                .allocator = allocator,
                .table = table,
                .load = elements / size,
                .load_capacity = DEFAULT_LOAD_FACTOR,
            };
        }
        pub fn deinit(self: *Self) void {
            for (self.table) |*list| {
                list.deinit();
            }
            self.allocator.free(self.table);
        }
        pub fn insert(self: *Self, key: K, data: T) anyerror!void {
            const hash_idx = self.hash(key);
            if (self.table[hash_idx].has(key)) {
                self.table[hash_idx].remove(key);
                try self.table[hash_idx].prepend(key, data);
                return;
            }
            try self.table[hash_idx].prepend(key, data);
            self.elements += 1;
            try self.update();
        }
        pub fn remove(self: *Self, key: K) void {
            const hash_idx = self.hash(key);
            self.table[hash_idx].remove(key);
            self.elements -= 1;
        }
        pub fn has(self: *Self, key: K) bool {
            const hash_id = self.hash(key);
            return self.table[hash_id].has(key);
        }
        pub fn get(self: *const Self, key: K) ?*const T {
            const hash_idx = self.hash(key);
            return self.table[hash_idx].get(key);
        }

        pub fn getPtr(self: *Self, key: K) ?*T {
            const hash_idx = self.hash(key);
            return self.table[hash_idx].getPtr(key);
        }
        fn hash(self: *const Self, key: K) usize {
            const hash_id = blk: {
                const type_info = @typeInfo(K);
                if (type_info == .int) {
                    break :blk @as(usize, key) % self.size;
                } else if (@hasDecl(K, "hash")) {
                    break :blk key.hash(self.size);
                } else if (@hasDecl(K, "to_integer")) {
                    break :blk key.to_integer() % self.size;
                } else {
                    @compileError("type " + @TypeOf(T) + " has no bijection to the numerals!");
                }
            };
            return hash_id;
        }
        fn update(self: *Self) !void {
            if (self.load > self.load_capacity) {
                try self.resize();
            }
            self.load = @as(f32, @floatFromInt(self.elements)) / @as(f32, @floatFromInt(self.size));
        }

        fn resize(self: *Self) anyerror!void { //TODO resolve unexpected behaviour
            const Pair = linkedlist.LinkedList(K, T, useHeap).Pair;

            const new_size = self.size * 2;
            const table = try self.allocator.alloc(linkedlist.LinkedList(K, T, useHeap), new_size);
            var unloaded: []Pair = try self.allocator.alloc(Pair, self.elements);
            defer self.allocator.free(unloaded);

            for (table) |*list| {
                list.* = linkedlist.LinkedList(K, T, useHeap).init(self.allocator);
            }

            for (self.table) |*list| {
                for (0..list.count) |i| {
                    if (list.pop()) |popped| {
                        unloaded[i] = popped;
                    } else {
                        return error.Error;
                    }
                }
                list.deinit();
            }
            self.allocator.free(self.table);

            self.table = table;
            self.size = new_size;

            for (0..self.elements) |i| {
                try self.table[self.hash(unloaded[i].key)].prepend(unloaded[i].key, unloaded[i].data);
            }
        }

        pub fn print(self: *Self) void {
            for (self.table, 1..) |list, i| {
                if (list.head != null) {
                    std.debug.print("list {}:\n", .{i});
                }
                list.print();
            }
        }
    };
}
test "heap" {
    std.debug.print("Testing HashMap Heap\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var hashmap = try HashMap(u32, linkedlist.Planet, true).init(32, allocator);
    defer hashmap.deinit();

    try hashmap.insert(5, linkedlist.Planet{ .id = 7, .temp = 14.8 });
    try hashmap.insert(4, linkedlist.Planet{ .id = 7, .temp = 14.8 });
    try hashmap.insert(2, linkedlist.Planet{ .id = 7, .temp = 14.8 });
    hashmap.print();
    try hashmap.insert(1, linkedlist.Planet{ .id = 5, .temp = 16.8 });
    try hashmap.insert(3, linkedlist.Planet{ .id = 8, .temp = 12.8 });
    hashmap.print();
}

test {
    std.debug.print("Testing HashMap\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var hashmap = try HashMap(u32, f32, false).init(4, allocator);
    defer hashmap.deinit();

    try hashmap.insert(5, 4.5);
    try hashmap.insert(9, 5.5);
    try std.testing.expect(hashmap.has(5));
    hashmap.print();

    try hashmap.resize();
    hashmap.print();
}
