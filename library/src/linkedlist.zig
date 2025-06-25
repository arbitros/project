const std = @import("std");

pub fn LinkedList(comptime K: type, comptime T: type, useHeap: bool) type {
    return struct {
        const Self = @This();

        const DataType = if (useHeap) *T else T;

        pub const Node = struct {
            key: K,
            data: DataType,
            next: ?*Node,
        };

        count: u32,
        head: ?*Node,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            if (useHeap) {
                if (!@hasDecl(T, "deinit")) {
                    @compileError("type " + @TypeOf(T) + " does not have a deinit function");
                }
            }
            return Self{
                .allocator = allocator,
                .head = null,
                .count = 0,
            };
        }
        pub fn deinit(self: *Self) void {
            if (useHeap) {
                var current_node = self.head;
                while (current_node) |current| {
                    current.data.*.deinit();
                    self.allocator.destroy(current.data);
                    const next = current.next;
                    self.allocator.destroy(current);
                    current_node = next;
                }
            } else {
                var current_node = self.head;
                while (current_node) |current| {
                    const next = current.next;
                    self.allocator.destroy(current);
                    current_node = next;
                }
                self.head = null;
            }
        }

        pub fn prepend(self: *Self, key: K, data: T) !void {
            if (useHeap) {
                const node = try self.allocator.create(Node);
                const data_ptr = try self.allocator.create(T);
                node.key = key;
                node.data = data_ptr;
                node.data.* = data;
                node.next = self.head;
                self.head = node;
                self.count += 1;
            } else {
                const node = try self.allocator.create(Node);
                node.key = key;
                node.data = data;
                node.next = self.head;
                self.head = node;
                self.count += 1;
            }
        }

        pub fn has(self: *Self, key: K) bool {
            var current_node = self.head;
            while (current_node) |current| {
                if (current.key == key) {
                    return true;
                } else {
                    current_node = current.next;
                }
            }
            return false;
        }

        pub fn get(self: *const Self, key: K) ?*const T {
            var current_node = self.head;
            while (current_node) |current| {
                if (current.key == key) {
                    if (useHeap) {
                        return current.data;
                    } else {
                        return &current.data;
                    }
                } else {
                    current_node = current.next;
                }
            }
            return null;
        }
        pub fn getPtr(self: *Self, key: K) ?*T {
            var current_node = self.head;
            while (current_node) |current| {
                if (current.key == key) {
                    if (useHeap) {
                        return current.data;
                    } else {
                        return &current.data;
                    }
                } else {
                    current_node = current.next;
                }
            }
            return null;
        }

        pub fn remove(self: *Self, key: K) void {
            var current_node = self.head;
            var previous_node: ?*Node = null;
            while (current_node) |current| {
                if (current.key == key) {
                    if (previous_node) |previous| {
                        previous.next = current.next;
                    } else {
                        self.head = current.next;
                    }
                    if (useHeap) {
                        current.data.deinit();
                        self.allocator.destroy(current.data);
                    }
                    self.allocator.destroy(current);
                    self.count -= 1;
                    break;
                } else {
                    previous_node = current;
                    current_node = current.next;
                }
            }
        }
        pub const Pair = struct {
            key: K,
            data: T,
        };

        pub fn pop(self: *Self) ?Pair {
            if (self.head) |head| {
                const pair = Pair{
                    .data = if (useHeap) head.data.* else head.data,
                    .key = head.key,
                };
                if (useHeap) {
                    head.data.deinit();
                    self.allocator.destroy(head.data);
                }
                self.head = head.next;
                self.allocator.destroy(head);
                return pair;
            } else {
                return null;
            }
        }

        pub fn print(self: Self) void {
            var current_node = self.head;
            var i: u32 = 1;
            while (current_node) |current| {
                std.debug.print("Object {d}: Key: {any} Data: {any}\n", .{ i, current.key, if (useHeap) current.data.* else current.data });
                i += 1;
                current_node = current.next;
            }
        }
    };
}
pub const Planet = struct {
    id: u32,
    temp: f32,
    pub fn deinit(self: *Planet) void {
        _ = self.id;
    }
};

test "heap" {
    std.debug.print("Testing linkedlist heap version\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = LinkedList(u32, Planet, true).init(allocator);
    defer list.deinit();

    try list.prepend(5, Planet{ .id = 5, .temp = 15.7 });
    list.print();
}

test "linkedlist" {
    std.debug.print("Testing linkedlist\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = LinkedList(u32, bool, false).init(allocator);
    defer list.deinit();

    try list.prepend(5, true);
    try list.prepend(7, false);
    try list.prepend(9, true);
    try list.prepend(13, false);
    try std.testing.expect(list.has(7));
    list.print();
    list.remove(7);
    list.print();

    const data = list.pop();
    std.debug.print("{any}", .{data});
}
