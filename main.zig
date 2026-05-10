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

        fn append(buffer: []u8, len: *usize, text: []const u8) void {
            @memcpy(buffer[len.* .. len.* + text.len], text);
            len.* += text.len;
        }

        pub fn print(self: *const Self, init: std.process.Init, alive_char: []const u8, dead_char: []const u8) !void {
            var buffer: [8192]u8 = undefined;
            var len: usize = 0;

            append(&buffer, &len, "\x1b[H");

            self.printBorder(&buffer, &len);

            for (self.cells) |row| {
                append(&buffer, &len, "|");
                for (row) |cell| {
                    append(&buffer, &len, if (cell) alive_char else dead_char);
                    append(&buffer, &len, if (cell) alive_char else dead_char);
                }
                append(&buffer, &len, "|\n");
            }

            self.printBorder(&buffer, &len);

            try std.Io.File.stdout().writeStreamingAll(init.io, buffer[0..len]);
        }

        fn printBorder(_: *const Self, buffer: []u8, len: *usize) void {
            append(buffer, len, "+");
            for (0..width) |_| {
                append(buffer, len, "--");
            }
            append(buffer, len, "+\n");
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

fn usage(programm_name: [:0]const u8) void {
    std.debug.print(
        \\<name> <mode> [options]
        \\
        \\Usage:
        \\  {s} --help                  print this message
        \\  {s} run                     run simulation with default settings
        \\  {s} run --steps N           specify the amount of steps simulation will last. set -1 for simulation to be endless
        \\  {s} run --delay MS          specify the period of time that will be awaited after each step
        \\  {s} run --alive-cell CHAR   specify what char will be printed to display alive cell
        \\  {s} run --dead-cell CHAR    specify what char will be printed to display dead cell
        \\
        \\Example:
        \\  {s} run --steps 1000 --delay 40
        \\
    , .{ programm_name, programm_name, programm_name, programm_name, programm_name, programm_name, programm_name });
}

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    // parse edge cases
    if (args.len == 1 or std.mem.eql(u8, args[1], "--help")) {
        usage(args[0]);
        return;
    }

    // parse mode
    if (!std.mem.eql(u8, args[1], "run")) {
        usage(args[0]);
        std.debug.panic("Expected mode, found '{s}'", .{args[1]});
    } // only run mode is available for now

    // parse options
    var args_index: u8 = 2;
    var STEPS: i64 = -1;
    var DELAY: i64 = 40;
    var ALIVE_CHAR: []const u8 = "█";
    var DEAD_CHAR: []const u8 = " ";
    while (args_index < args.len) {
        if (std.mem.eql(u8, args[args_index], "--help")) {
            usage(args[0]);
            return;
        } else if (std.mem.eql(u8, args[args_index], "--steps")) {
            if (args.len == args_index) {
                usage(args[0]);
                std.debug.panic("expected an int value (>= -1) for --steps option, got EOF", .{});
            }
            args_index += 1;
            STEPS = std.fmt.parseInt(i64, args[args_index], 10) catch |err| {
                usage(args[0]);
                std.debug.panic("expected an int value (>= -1) for --steps option, got '{s}': {}", .{ args[args_index], err });
            };
            if (STEPS < -1) {
                usage(args[0]);
                std.debug.panic("expected an int value (>= -1) for --steps option, got '{s}'", .{args[args_index]});
            }
        } else if (std.mem.eql(u8, args[args_index], "--delay")) {
            if (args.len == args_index) {
                usage(args[0]);
                std.debug.panic("expected an int value for --delay option, got EOF", .{});
            }
            args_index += 1;
            DELAY = std.fmt.parseInt(i64, args[args_index], 10) catch |err| {
                usage(args[0]);
                std.debug.panic("expected an int value for --delay option, got '{s}': {}", .{ args[args_index], err });
            };
        } else if (std.mem.eql(u8, args[args_index], "--alive-cell")) {
            if (args.len == args_index) {
                usage(args[0]);
                std.debug.panic("expected an unsigned int value for --alive-cell option, got EOF", .{});
            }
            args_index += 1;
            ALIVE_CHAR = args[args_index];
        } else if (std.mem.eql(u8, args[args_index], "--dead-cell")) {
            if (args.len == args_index) {
                usage(args[0]);
                std.debug.panic("expected an unsigned int value for --dead-cell option, got EOF", .{});
            }
            args_index += 1;
            DEAD_CHAR = args[args_index];
        } else {
            if (args_index == args.len) {
                break;
            }
            std.debug.panic("unknown argument: '{s}'", .{args[args_index]});
        }

        args_index += 1;
    }

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

    while (STEPS != 0) {
        field.clearScreen();
        try field.print(init, ALIVE_CHAR, DEAD_CHAR);
        field.next();
        try init.io.sleep(.fromMilliseconds(DELAY), .awake);
        STEPS -= 1;
    }
}
