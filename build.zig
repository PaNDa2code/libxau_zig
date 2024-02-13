const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.Build.Step.Compile.Linkage, "linkage", "whether to statically or dynamically link the library") orelse .static;

    const libxauSource = b.dependency("libxau", .{});
    const xorgprotoSource = b.dependency("xorgproto", .{});

    const libxau = std.Build.Step.Compile.create(b, .{
        .name = "Xau",
        .root_module = .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        },
        .kind = .lib,
        .linkage = linkage,
    });

    libxau.addIncludePath(libxauSource.path("include"));
    libxau.addIncludePath(xorgprotoSource.path("include"));

    libxau.addCSourceFiles(.{
        .files = &.{
            libxauSource.path("AuDispose.c").getPath(libxauSource.builder),
            libxauSource.path("AuFileName.c").getPath(libxauSource.builder),
            libxauSource.path("AuGetAddr.c").getPath(libxauSource.builder),
            libxauSource.path("AuGetBest.c").getPath(libxauSource.builder),
            libxauSource.path("AuLock.c").getPath(libxauSource.builder),
            libxauSource.path("AuRead.c").getPath(libxauSource.builder),
            libxauSource.path("AuUnlock.c").getPath(libxauSource.builder),
            libxauSource.path("AuWrite.c").getPath(libxauSource.builder),
        },
    });

    {
        const headers: []const []const u8 = &.{
            "X11/Xauth.h",
        };

        for (headers) |header| {
            const install_file = b.addInstallFileWithDir(libxauSource.path(b.pathJoin(&.{ "include", header })), .header, header);
            b.getInstallStep().dependOn(&install_file.step);
            libxau.installed_headers.append(&install_file.step) catch @panic("OOM");
        }
    }

    b.installArtifact(libxau);
}
