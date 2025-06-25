const std = @import("std");

pub fn Library() type {
    const hashmap = @import("hashmap.zig");
    const linkedlist = @import("linkedlist.zig");

    return struct { //TODO create optional heap allocated linkedlist data or stack allocated
        //on creation. Modify linkedlist.zig and hashmap.zig
        const HASHMAP_SIZE = 16;

        books: hashmap.HashMap(usize, Book, true),
        employees: hashmap.HashMap(usize, Employee, false),
        members: hashmap.HashMap(usize, Member, true),

        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .allocator = allocator,
                .books = try hashmap.HashMap(usize, Book, true).init(HASHMAP_SIZE, allocator),
                .employees = try hashmap.HashMap(usize, Employee, false).init(HASHMAP_SIZE, allocator),
                .members = try hashmap.HashMap(usize, Member, true).init(HASHMAP_SIZE, allocator),
            };
        }
        pub fn deinit(self: *Self) void {
            self.books.deinit();
            self.employees.deinit();
            self.members.deinit();
        }

        pub fn loan(self: *Self, memberId: u32, ISBN: u32) !void {
            if (self.members.getPtr(memberId)) |member| {
                if (self.books.getPtr(ISBN)) |book| {
                    if (book.count > book.holders.count) {
                        try member.booksLoaned.prepend(book.ISBN, book.ISBN);
                        try book.holders.prepend(memberId, memberId);
                    } else {
                        std.debug.print("Book with ISBN {d} is currently unavailable\n", .{ISBN});
                    }
                } else {
                    std.debug.print("There is no book with ISBN {d} in the registry\n", .{ISBN});
                }
            } else {
                std.debug.print("There is no member with ID {d} in the registry\n", .{memberId});
            }
        }

        pub const Employee = struct {
            id: u32,
            salary: f32,

            pub fn hash(self: *const Employee, hashmap_size: u32) usize {
                return self.id % hashmap_size;
            }
        };

        pub const Member = struct {
            id: u32,
            booksLoaned: linkedlist.LinkedList(usize, u32, false), //need to make sure all fields are vaild
            //before inserting a new member into the library
            //
            //CARE!!! should booksLoaned have the data stack allocated??

            pub fn hash(self: *const Member, hashmap_size: u32) usize {
                return self.id % hashmap_size;
            }
            pub fn init(allocator: std.mem.Allocator, id: u32) !Member {
                return Member{
                    .id = id,
                    .booksLoaned = linkedlist.LinkedList(usize, u32, false).init(allocator),
                };
            }
            pub fn deinit(self: *Member) void {
                self.booksLoaned.deinit();
            }
            pub fn printLoaned(self: Member) void {
                self.booksLoaned.print();
            }
        };

        pub const Book = struct {
            ISBN: u32,
            count: u32,
            holders: linkedlist.LinkedList(u32, u32, false),

            pub fn hash(self: *const Book, hashmap_size: u32) usize {
                return self.ISBN % hashmap_size;
            }
            pub fn init(allocator: std.mem.Allocator, ISBN: u32, count: u32) !Book {
                return Book{
                    .ISBN = ISBN,
                    .count = count,
                    .holders = linkedlist.LinkedList(u32, u32, false).init(allocator),
                };
            }
            pub fn deinit(self2: *Book) void {
                self2.holders.deinit();
            }
        };
    };
}

test {
    std.debug.print("Testing Library\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var library = try Library().init(allocator);
    defer library.deinit();

    const member1 = try Library().Member.init(allocator, 1);
    const member2 = try Library().Member.init(allocator, 2);
    const member3 = try Library().Member.init(allocator, 3);
    const book1 = try Library().Book.init(allocator, 123, 2);
    const book2 = try Library().Book.init(allocator, 126, 3);

    try library.members.insert(member1.id, member1);
    try library.members.insert(member2.id, member2);
    try library.members.insert(member3.id, member3);
    try library.books.insert(book1.ISBN, book1);
    try library.books.insert(book2.ISBN, book2);
    try library.loan(1, 123);
    try library.loan(2, 123);
    try library.loan(3, 123);
    try library.loan(1, 126);
    if (library.members.get(member1.id)) |member| {
        member.printLoaned();
    }
}
