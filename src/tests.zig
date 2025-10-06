const std = @import("std");
const zstd = @import("zstd");

comptime {
    std.testing.refAllDecls(zstd);
}

test "writing & reading" {
    std.testing.log_level = std.log.Level.err;
    const allocator = std.testing.allocator;

    const test_data = blk: {
        var bytes: [32]u8 = undefined;
        @memset(&bytes, 0);

        var prng = std.Random.DefaultPrng.init(12346);
        prng.random().bytes(&bytes);

        break :blk bytes ++ "Foo Bar Baz".* ++ bytes;
    };

    var compressed_data: std.io.Writer.Allocating = .init(allocator);
    defer compressed_data.deinit();

    const compressor = try zstd.Compressor.init(.{});
    defer compressor.deinit();
    var buffer: [128]u8 = undefined;
    const writer_ctx = zstd.writerCtx(&compressed_data.writer, &compressor, &buffer);
    const writer = writer_ctx.writer();

    try writer.writeAll(&test_data);
    try writer_ctx.finish();

    try std.testing.expect(compressed_data.written().len <= test_data.len);

    var reader_state = try zstd.Reader.init(compressed_data.written());
    defer reader_state.deinit();
    const reader = reader_state.reader();

    const decompressed_data = try reader.readAllAlloc(std.testing.allocator, test_data.len * 2);
    defer std.testing.allocator.free(decompressed_data);

    try std.testing.expectEqualSlices(u8, &test_data, decompressed_data);
}
