const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");

    const zstd_dep = b.dependency("zstd", .{});

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/headers.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_c.addIncludePath(zstd_dep.path("lib"));

    const force_pic = b.option(bool, "force_pic", "Forces PIC enabled for this library");
    const zstd_lib = b.addLibrary(.{
        .name = "zstd",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = if (force_pic == true) true else null,
        }),
    });
    b.installArtifact(zstd_lib);

    zstd_lib.linkLibC();
    zstd_lib.installHeader(zstd_dep.path("lib/zstd.h"), "zstd.h");
    zstd_lib.installHeader(zstd_dep.path("lib/zstd_errors.h"), "zstd_errors.h");

    zstd_lib.root_module.addCMacro("ZSTD_MULTITHREAD", "");
    zstd_lib.root_module.addCMacro("ZSTD_STATIC_LINKING_ONLY", "");

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

    const zstd_mod = b.addModule("zstd", .{
        .root_source_file = b.path("src/lib.zig"),
    });
    zstd_mod.linkLibrary(zstd_lib);
    zstd_mod.addAnonymousImport("c", .{ .root_source_file = translate_c.getOutput() });

    const tests_exe = b.addTest(.{
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/tests.zig"),
        }),
    });
    tests_exe.root_module.addImport("zstd", zstd_mod);

    const tests_exe_run = b.addRunArtifact(tests_exe);
    test_step.dependOn(&tests_exe_run.step);
}
