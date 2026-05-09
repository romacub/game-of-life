const std = @import("std");

fn Field(comptime width: usize, comptime height: usize) type {
    return struct {
        const Self = @This();

        cells: [height][width]bool,

        pub fn empty() Self {
            const row = [_]bool{false} ** width;

            return .{
                .cells = [_][width]bool{row} ** height,
            };
        }

        pub fn get(self: *const Self, x: usize, y: usize) bool {
            return self.cells[y][x];
        }

        pub fn set(self: *Self, x: usize, y: usize, value: bool) void {
            self.cells[y][x] = value;
        }

        pub fn print(self: *const Self) void {
            printBorder(self);

            for (self.cells) |row| {
                std.debug.print("|", .{});
                for (row) |cell| std.debug.print("{s}", .{if (cell) "██" else "  "});
                std.debug.print("|\n", .{});
            }

            printBorder(self);
        }

        fn printBorder(_: *const Self) void {
            std.debug.print("+", .{});
            for (0..width) |_| std.debug.print("--", .{});
            std.debug.print("+\n", .{});
        }

        fn countNbors(self: *const Self, x: usize, y: usize) u8 {
            var result: u8 = 0;
            const x_start = if (x == 0) 0 else x - 1;
            const y_start = if (y == 0) 0 else y - 1;

            const x_end = @min(x + 2, width);
            const y_end = @min(y + 2, height);

            for (y_start..y_end) |dy| {
                for (x_start..x_end) |dx| {
                    if (dx == x and dy == y) {
                        continue;
                    }

                    if (self.get(dx, dy)) {
                        result += 1;
                    }
                }
            }
            return result;
        }

        pub fn next(self: *Self) void {
            var copy_field = Field(width, height).empty();

            for (0..width) |x| {
                for (0..height) |y| {
                    const nbors: u8 = self.countNbors(x, y);
                    if (self.get(x, y)) {
                        if (nbors < 2 or nbors > 3) {
                            copy_field.set(x, y, false);
                        } else {
                            copy_field.set(x, y, true);
                        }
                    } else {
                        if (nbors == 3) {
                            copy_field.set(x, y, true);
                        } else {
                            copy_field.set(x, y, false);
                        }
                    }
                }
            }
            self.cells = copy_field.cells;
        }

        pub fn clearScreen(_: *const Self) void {
            std.debug.print("\x1b[2J\x1b[H", .{});
        }
    };
}

pub fn main(init: std.process.Init) !void {
    var field = Field(44, 30).empty();

    field.set(24, 0, true);
    field.set(22, 1, true);
    field.set(24, 1, true);
    field.set(12, 2, true);
    field.set(13, 2, true);
    field.set(20, 2, true);
    field.set(21, 2, true);
    field.set(34, 2, true);
    field.set(35, 2, true);
    field.set(11, 3, true);
    field.set(15, 3, true);
    field.set(20, 3, true);
    field.set(21, 3, true);
    field.set(34, 3, true);
    field.set(35, 3, true);
    field.set(0, 4, true);
    field.set(1, 4, true);
    field.set(10, 4, true);
    field.set(16, 4, true);
    field.set(20, 4, true);
    field.set(21, 4, true);
    field.set(0, 5, true);
    field.set(1, 5, true);
    field.set(10, 5, true);
    field.set(14, 5, true);
    field.set(16, 5, true);
    field.set(17, 5, true);
    field.set(22, 5, true);
    field.set(24, 5, true);
    field.set(10, 6, true);
    field.set(16, 6, true);
    field.set(24, 6, true);
    field.set(11, 7, true);
    field.set(15, 7, true);
    field.set(12, 8, true);
    field.set(13, 8, true);


    for (0..10000) |_| {
        field.clearScreen();
        field.print();
        field.next();
        try init.io.sleep(.fromMilliseconds(40), .awake);
    }
}
