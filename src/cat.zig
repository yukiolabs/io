const std = @import("std");

const IO = @import("io.zig").IO;
const file = @import("async_read.zig");

pub fn main() !void {
    var io = try IO.init(32, 0);
    defer io.deinit();
    var args = std.process.args();
    _ = args.next();
    const f = try std.fs.cwd().openFile(args.next().?, .{});
    defer f.close();

    var file_reader = file.FileReader.init(&io, f.handle);
    var r = &file_reader.ctx;
    var buf: [10]u8 = undefined;
    var out = std.io.getStdOut().writer();
    while (true) {
        switch (r.poll_read(&buf)) {
            .Pending => {},
            .Ready => |result| {
                const size = result catch |e| return e;
                if (size == 0) break;
                try out.writeAll(buf[0..size]);
            },
        }
    }
}
