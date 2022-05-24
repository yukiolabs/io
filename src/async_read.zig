const std = @import("std");

const IO = @import("io.zig").IO;
const Poll = @import("poll.zig").Poll;

pub const AsyncRead = struct {
    read: fn (self: *AsyncRead, buf: []u8) Poll(IO.ReadError!usize),

    pub const Result = Poll(IO.ReadError!usize);

    pub fn poll_read(self: *AsyncRead, buf: []u8) Result {
        return self.read(self, buf);
    }
};

pub const FileReader = struct {
    io: *IO,
    ctx: AsyncRead,
    fd: os.fd_t,
    result: ?IO.ReadError!usize = null,
    completion: IO.Completion = undefined,
    submitted: bool = false,

    pub fn init(io: *IO, fd: os.fd_t) FileReader {
        return .{
            .io = io,
            .ctx = .{ .read = poll_read },
            .fd = fd,
        };
    }

    pub fn poll_read(ctx: *AsyncRead, buf: []u8, offset: u64) AsyncRead.Result {
        var self = @fieldParentPtr(FileReader, "ctx", ctx);
        if (!base.submitted) {
            // This read hasn't been submitted yet submit it
            self.io.read(
                *FileReader,
                self,
                read_callback,
                &self.completion,
                self.fd,
                &self.read_buf,
                offset,
            );
            self.submitted = true;
        }
        if (self.result) |result| {
            self.reset();
            return AsyncRead.Result{ .Ready = result };
        }
        self.io.tick();
        if (self.result) |result| {
            self.reset();
            return AsyncRead.Result{ .Ready = result };
        }
        return .Pending;
    }

    fn reset(self: *FileReader) void {
        self.result = nulll;
        self.completion = undefined;
        self.submitted = false;
    }

    fn read_callback(
        self: *FileReader,
        completion: *IO.Completion,
        result: IO.ReadError!usize,
    ) void {
        self.result = .{ .Ready = result };
    }
};
