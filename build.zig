const std = @import("std");

const LinkMode = if (@hasField(std.builtin.LinkMode, "static")) std.builtin.LinkMode else std.Build.Step.Compile.Linkage;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(LinkMode, "linkage", "whether to statically or dynamically link the library") orelse @as(LinkMode, if (target.result.isGnuLibC()) .dynamic else .static);

    const libxauSource = b.dependency("libxau", .{});
    const xorgprotoSource = b.dependency("xorgproto", .{});

    const libxau_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const libxau = b.addLibrary(.{
        .name = "Xau",
        .root_module = libxau_mod,
        .linkage = linkage,
    });

    libxau.linkLibC();
    libxau.addIncludePath(libxauSource.path("include"));
    libxau.addIncludePath(xorgprotoSource.path("include"));

    libxau.addCSourceFiles(.{
        .root = libxauSource.path("."),
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

    {
        const headers_install = b.addInstallDirectory(.{
            .install_dir = .prefix,
            .install_subdir = "include/X11",
            .source_dir = libxauSource.path("include/X11"),
        });

        b.getInstallStep().dependOn(&headers_install.step);
    }

    b.installArtifact(libxau);
}
