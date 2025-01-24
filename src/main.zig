const std = @import("std");

const DataFrame = struct {
    header: [2]u8 = [2]u8{ 0xFF, 0xFF },
    id: u8,
    len: u8,
    instruction: u8,
    parameters: []u8,
    checksum: u64,

    fn init(id: u8, instruction: u8, parameters: []u8) DataFrame {
        return DataFrame{
            .id = id,
            .len = @intCast(2 + parameters.len),
            .instruction = instruction,
            .parameters = parameters,
            .checksum = 0x00,
        };
    }

    fn calculateChecksum(self: *DataFrame) void {
        var checksum: u64 = 0;
        checksum += self.id;
        checksum += self.len;
        checksum += self.instruction;
        for (self.parameters) |byte| {
            checksum += byte;
        }
        self.checksum = checksum;
    }

    fn toArray(self: DataFrame, allocator: std.mem.Allocator) ![]u8 {
        const data = try allocator.alloc(u8, 6 + self.parameters.len);
        data[0] = self.header[0];
        data[1] = self.header[1];
        data[2] = self.id;
        data[3] = self.len;
        data[4] = self.instruction;
        for (self.parameters, 0..) |byte, i| {
            data[5 + i] = byte;
        }
        data[data.len - 1] = @truncate(~self.checksum);
        return data;
    }
};

pub fn main() !void {
    var data = [_]u8{ 0x2A, 0x00, 0x02, 0x00, 0x00, 0x0F, 0x00 };
    var ar: []u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer allocator.free(ar);

    var frame = DataFrame.init(0x01, 0x03, data[0..]);
    frame.calculateChecksum();

    ar = try frame.toArray(allocator);

    for (ar) |byte| {
        std.debug.print("{x:0>2} ", .{byte});
    } else {
        std.debug.print("\n", .{});
    }
}
