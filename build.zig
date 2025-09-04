const std = @import("std");

const LinkMode = if (@hasField(std.builtin.LinkMode, "static")) std.builtin.LinkMode else std.Build.Step.Compile.Linkage;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(LinkMode, "linkage", "whether to statically or dynamically link the library") orelse @as(LinkMode, if (target.result.isGnuLibC()) .dynamic else .static);

    const libxau_upstream = b.dependency("libxau", .{});
    const xorgproto_upstream = b.dependency("xorgproto", .{});

    const libxau_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const libxau = b.addLibrary(.{
        .name = "Xau",
        .root_module = libxau_mod,
        .linkage = linkage,
    });

    libxau.root_module.addIncludePath(libxau_upstream.path("include"));
    libxau.root_module.addIncludePath(xorgproto_upstream.path("include"));

    libxau.root_module.addCSourceFiles(.{
        .root = libxau_upstream.path("."),
        .files = &.{
            "AuDispose.c",
            "AuFileName.c",
            "AuGetAddr.c",
            "AuGetBest.c",
            "AuLock.c",
            "AuRead.c",
            "AuUnlock.c",
            "AuWrite.c",
        },
    });

    libxau.installHeadersDirectory(
        libxau_upstream.path("include/X11"),
        "X11",
        .{},
    );

    b.installArtifact(libxau);
}
