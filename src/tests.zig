const std = @import("std");
const lib = @import("lib.zig");

test {
    std.testing.log_level = std.log.Level.err;
    std.testing.refAllDecls(lib);
}

test "writing & reading" {
    const test_data = blk: {
        var bytes: [32]u8 = undefined;
        @memset(&bytes, 0);

        var prng = std.Random.DefaultPrng.init(12346);
        prng.random().bytes(&bytes);

        break :blk bytes ++ "Foo Bar Baz".* ++ bytes;
    };

    var compressed_data = std.ArrayList(u8).init(std.testing.allocator);
    defer compressed_data.deinit();

    const compressor = try lib.Compressor.init(.{});
    defer compressor.deinit();
    var buffer: [128]u8 = undefined;
    const writer_ctx = lib.writerCtx(compressed_data.writer(), &compressor, &buffer);
    const writer = writer_ctx.writer();

    try writer.writeAll(&test_data);
    try writer_ctx.finish();

    try std.testing.expect(compressed_data.items.len <= test_data.len);

    var reader_state = try lib.Reader.init(compressed_data.items);
    defer reader_state.deinit();
    const reader = reader_state.reader();

    const decompressed_data = try reader.readAllAlloc(std.testing.allocator, test_data.len * 2);
    defer std.testing.allocator.free(decompressed_data);

    try std.testing.expectEqualSlices(u8, &test_data, decompressed_data);
}
