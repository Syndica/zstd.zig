const std = @import("std");

const package_name = "zstd";
const package_path = "src/lib.zig";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const zstd_dep = b.dependency("zstd", .{});

    const zstd_lib = b.addStaticLibrary(.{
        .name = package_name,
        .target = target,
        .optimize = optimize,
    });
    zstd_lib.linkLibC();
    zstd_lib.addIncludePath(zstd_dep.path("lib"));
    zstd_lib.installHeader(zstd_dep.path("lib/zstd.h"), "zstd.h");
    zstd_lib.installHeader(zstd_dep.path("lib/zstd_errors.h"), "zstd_errors.h");

    const config_header = b.addConfigHeader(
        .{ .style = .blank },
        .{
            .ZSTD_CONFIG_H = {},
            .ZSTD_MULTITHREAD_SUPPORT_DEFAULT = null,
            .ZSTD_LEGACY_SUPPORT = null,
        },
    );
    zstd_lib.addConfigHeader(config_header);
    zstd_lib.addCSourceFiles(.{
        .root = zstd_dep.path("lib"),
        .files = &.{
            "common/debug.c",
            "common/entropy_common.c",
            "common/error_private.c",
            "common/fse_decompress.c",
            "common/pool.c",
            "common/threading.c",
            "common/xxhash.c",
            "common/zstd_common.c",

            "compress/zstd_double_fast.c",
            "compress/zstd_compress_literals.c",
            "compress/zstdmt_compress.c",
            "compress/zstd_opt.c",
            "compress/zstd_compress_sequences.c",
            "compress/zstd_lazy.c",
            "compress/hist.c",
            "compress/zstd_ldm.c",
            "compress/huf_compress.c",
            "compress/zstd_compress_superblock.c",
            "compress/zstd_compress.c",
            "compress/fse_compress.c",
            "compress/zstd_fast.c",

            "decompress/zstd_decompress.c",
            "decompress/zstd_ddict.c",
            "decompress/zstd_decompress_block.c",
            "decompress/huf_decompress.c",
        },
    });
    zstd_lib.addAssemblyFile(zstd_dep.path("lib/decompress/huf_decompress_amd64.S"));
    b.installArtifact(zstd_lib);

    const module = b.addModule(package_name, .{
        .root_source_file = b.path(package_path),
        .imports = &.{},
    });
    module.linkLibrary(zstd_lib);

    // tests
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/tests.zig"),
    });
    tests.linkLibrary(zstd_lib);

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&zstd_lib.step);
    test_step.dependOn(&run_tests.step);
}
