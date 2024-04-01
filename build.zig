const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const ZSTD_C_PATH = "vendor/lib";
    const zstd_lib = b.addStaticLibrary(.{
        .name = "zstd",
        .target = target,
        .optimize = optimize,
    });
    zstd_lib.linkLibC();
    zstd_lib.addIncludePath(.{ .path = ZSTD_C_PATH });
    zstd_lib.installHeader(ZSTD_C_PATH ++ "/zstd.h", "zstd.h");
    zstd_lib.installHeader(ZSTD_C_PATH ++ "/zstd_errors.h", "zstd_errors.h");

    const config_header = b.addConfigHeader(
        .{
            .style = .{ .autoconf = .{ .path = "config.h.in" } },
        },
        .{
            .ZSTD_MULTITHREAD_SUPPORT_DEFAULT = null,
            .ZSTD_LEGACY_SUPPORT = null,
        },
    );
    zstd_lib.addConfigHeader(config_header);
    zstd_lib.addCSourceFiles(&.{
        ZSTD_C_PATH ++ "/common/debug.c",
        ZSTD_C_PATH ++ "/common/entropy_common.c",
        ZSTD_C_PATH ++ "/common/error_private.c",
        ZSTD_C_PATH ++ "/common/fse_decompress.c",
        ZSTD_C_PATH ++ "/common/pool.c",
        ZSTD_C_PATH ++ "/common/threading.c",
        ZSTD_C_PATH ++ "/common/xxhash.c",
        ZSTD_C_PATH ++ "/common/zstd_common.c",

        ZSTD_C_PATH ++ "/compress/zstd_double_fast.c",
        ZSTD_C_PATH ++ "/compress/zstd_compress_literals.c",
        ZSTD_C_PATH ++ "/compress/zstdmt_compress.c",
        ZSTD_C_PATH ++ "/compress/zstd_opt.c",
        ZSTD_C_PATH ++ "/compress/zstd_compress_sequences.c",
        ZSTD_C_PATH ++ "/compress/zstd_lazy.c",
        ZSTD_C_PATH ++ "/compress/hist.c",
        ZSTD_C_PATH ++ "/compress/zstd_ldm.c",
        ZSTD_C_PATH ++ "/compress/huf_compress.c",
        ZSTD_C_PATH ++ "/compress/zstd_compress_superblock.c",
        ZSTD_C_PATH ++ "/compress/zstd_compress.c",
        ZSTD_C_PATH ++ "/compress/fse_compress.c",
        ZSTD_C_PATH ++ "/compress/zstd_fast.c",

        ZSTD_C_PATH ++ "/decompress/zstd_decompress.c",
        ZSTD_C_PATH ++ "/decompress/zstd_ddict.c",
        ZSTD_C_PATH ++ "/decompress/zstd_decompress_block.c",
        ZSTD_C_PATH ++ "/decompress/huf_decompress.c",
    }, &.{});
    zstd_lib.addAssemblyFile(.{ .path = ZSTD_C_PATH ++ "/decompress/huf_decompress_amd64.S" });
    b.installArtifact(zstd_lib);

    // tests
    const tests = b.addTest(.{
        .name = "zstd-tests",
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/main.zig" },
    });
    tests.linkLibrary(zstd_lib);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&zstd_lib.step);

    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);
}
