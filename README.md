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
