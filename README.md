# zstd.zig

Zig binding of Z Standard based on _`v1.5.2`_

## how to import 

in your `build.zig`:
```zig
pub fn build(b: *std.Build) void {
    // ...

    const zstd_dep = b.dependency("zstd", opts);
    const zstd_mod = zstd_dep.module("zstd");
    const zstd_c_lib = zstd_dep.artifact("zstd");

    const exec = ...

    // link it
    exec.addModule("zstd", zstd_mod);
    exec.linkLibrary(zstd_c_lib);

    // ...
}
```

## usage 
```zig
const ZstdReader = @import("zstd").Reader;
...

pub fn main() {
    const path = ...

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_stat = try file.stat();
    const file_size: u64 = @intCast(file_stat.size);
    var memory = try std.os.mmap(
        null,
        file_size,
        std.os.PROT.READ,
        std.os.MAP.PRIVATE,
        file.handle,
        0,
    );
    var decompressed_stream = try ZstdReader.init(memory);
    var reader = decompressed_stream.reader();

    ...
}
```
