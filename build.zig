const std = @import("std");

// Build the package.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("umf-zig", .{
        .root_source_file = b.path("./src/main.zig"),

        .target = target,
        .optimize = optimize
    });

    const exe = b.addExecutable(.{
        .name = "umf-zig",
        .root_source_file = b.path("./src/main.zig"),

        .target = target,
        .optimize = optimize
    });

    const run_step = b.step("run", "Run and test the package");
    const run_exe = b.addRunArtifact(exe);
    run_step.dependOn(&run_exe.step);
}
