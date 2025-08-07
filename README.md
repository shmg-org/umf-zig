# UMF Zig Parser

The Zig implementation of the [Universal Metadata Format](https://github.com/shmg-org/umf-specification).

## Example

```zig
const std = @import("std");
const umf = @import("umf");

const source = (
    \\ UMF Zig Parser
    \\
    \\ [ Github ]
    \\
    \\ Author: LmanTW
    \\ Language: Zig
);

var metadata = try umf.parse(source, allocator);
defer metadata.deinit();

std.debug.print("Value: {s}\n", .{metadata.get("Github", "Author").?});
```

## Installation

1. Fetch umf-zig.

```
zig fetch --save https://github.com/shmg-org/umf-zig.git
```

2. Add umf-zig as a dependency.

```zig
const umf = b.dependency("umf", .{
    .target = target,
    .optimize = optimize
});

exe.root_module.addImport("umf", umf);
```
