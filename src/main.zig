pub usingnamespace @import("compress.zig");
pub usingnamespace @import("decompress.zig");
pub usingnamespace @import("types.zig");
pub usingnamespace @import("error.zig");

const std = @import("std");
const c = @import("c.zig");
const comp = @import("compress.zig");
const types = @import("types.zig");
const decomp = @import("decompress.zig");
const testing = std.testing;
const test_str = @embedFile("types.zig");

pub fn version() std.SemanticVersion {
    return .{
        .major = c.ZSTD_VERSION_MAJOR,
        .minor = c.ZSTD_VERSION_MINOR,
        .patch = c.ZSTD_VERSION_RELEASE,
    };
}

test "refernece decls" {
    testing.refAllDeclsRecursive(comp);
}

test "compress/decompress" {
    var comp_out: [1024]u8 = undefined;
    var decomp_out: [1024]u8 = undefined;

    const compressed = try comp.compress(&comp_out, test_str, comp.minCompressionLevel());
    const decompressed = try decomp.decompress(&decomp_out, compressed);
    try testing.expectEqualStrings(test_str, decompressed);
}

test "compress with context" {
    var out: [1024]u8 = undefined;

    const compressor = try comp.Compressor.init(.{});
    defer compressor.deinit();

    _ = try compressor.compress(&out, test_str, comp.minCompressionLevel());
}

test "streaming compress" {
    var in_fbs = std.io.fixedBufferStream(test_str);

    var out: [test_str.len]u8 = undefined;
    var out_fbs = std.io.fixedBufferStream(&out);

    var in_buf = try testing.allocator.alloc(u8, comp.Compressor.recommInSize());
    var out_buf = try testing.allocator.alloc(u8, comp.Compressor.recommOutSize());
    defer testing.allocator.free(in_buf);
    defer testing.allocator.free(out_buf);

    const ctx = try comp.Compressor.init(.{
        .compression_level = 1,
        .checksum_flag = 1,
    });

    while (true) {
        const read = try in_fbs.read(in_buf);
        const is_last_chunk = (read < in_buf.len);

        var input = types.InBuffer{
            .src = in_buf.ptr,
            .size = read,
            .pos = 0,
        };

        while (true) {
            var output = types.OutBuffer{
                .dst = out_buf.ptr,
                .size = out_buf.len,
                .pos = 0,
            };
            const remaining = try ctx.compressStream(&input, &output, if (is_last_chunk) .end else .continue_);
            _ = try out_fbs.write(out_buf[0..output.pos]);

            if ((is_last_chunk and remaining == 0) or input.pos == read)
                break;
        }

        if (is_last_chunk)
            break;
    }

    var decomp_out: [test_str.len]u8 = undefined;
    const decompressed = try decomp.decompress(&decomp_out, out_fbs.getWritten());
    try std.testing.expectEqualStrings(test_str, decompressed);
}
