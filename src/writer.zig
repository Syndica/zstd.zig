const std = @import("std");

const Compressor = @import("compress.zig").Compressor;
const types = @import("types.zig");
const InBuffer = types.InBuffer;
const OutBuffer = types.OutBuffer;
const Error = @import("error.zig").Error;

pub inline fn writerCtx(
    inner_writer: anytype,
    compressor: *const Compressor,
    out_buffer: []u8,
) WriterCtx(@TypeOf(inner_writer)) {
    return .{
        .inner = inner_writer,
        .compressor = compressor,
        .out_buffer = out_buffer,
    };
}

pub fn WriterCtx(comptime InnerWriter: type) type {
    return struct {
        inner: InnerWriter,
        compressor: *const Compressor,
        out_buffer: []u8,
        const Self = @This();

        pub const Writer = std.io.Writer(Self, Error, zstdWrite);

        pub inline fn writer(ctx: Self) Writer {
            return .{ .context = ctx };
        }

        /// This must be called after writing all the data that has to be compressed.
        /// After doing so, all of the internal buffers of the compressor will have been
        /// flushed to the destination writer, allowing re-use and re-configuration of
        /// the referenced Compressor.
        pub fn finish(ctx: Self) Error!void {
            while (true) {
                var out_buffer: OutBuffer = .{
                    .dst = ctx.out_buffer.ptr,
                    .size = ctx.out_buffer.len,
                    .pos = 0,
                };
                var in_buffer: InBuffer = .{
                    .src = "",
                    .size = 0,
                    .pos = 0,
                };
                const remaining = try ctx.compressor.compressStream(&in_buffer, &out_buffer, .end);
                try ctx.inner.writeAll(out_buffer.dst[0..out_buffer.pos]);
                if (remaining == 0) break;
            }
        }

        fn zstdWrite(ctx: Self, bytes: []const u8) Error!usize {
            var in_buffer: InBuffer = .{
                .src = bytes.ptr,
                .size = bytes.len,
                .pos = 0,
            };
            while (true) {
                var out_buffer: OutBuffer = .{
                    .dst = ctx.out_buffer.ptr,
                    .size = ctx.out_buffer.len,
                    .pos = 0,
                };
                const remaining = try ctx.compressor.compressStream(&in_buffer, &out_buffer, .continue_);
                try ctx.inner.writeAll(out_buffer.dst[0..out_buffer.pos]);
                if (remaining == 0 or in_buffer.pos == in_buffer.size) break;
            }
            return bytes.len;
        }
    };
}
