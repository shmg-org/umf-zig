const std = @import("std");

// The metadata.
pub const Metadata = struct {
    allocator: std.mem.Allocator,
    media_name: []const u8,

    global: std.BufMap,
    groups: std.StringHashMap(std.BufMap),

    // Initialize a metadata.
    pub fn init(media_name: []const u8, allocator: std.mem.Allocator) !Metadata {
        return .{
            .allocator = allocator,
            .media_name = try allocator.dupe(u8, media_name),

            .global = std.BufMap.init(allocator),
            .groups = std.StringHashMap(std.BufMap).init(allocator)
        };
    }

    // Deinitialize the metadata.
    pub fn deinit(self: *Metadata) void {
        var group_iterator = self.groups.iterator(); 

        while (group_iterator.next()) |group| {
            group.value_ptr.deinit();
        }

        self.allocator.free(self.media_name);
        self.global.deinit();
        self.groups.deinit();
    }

    // Check if a field exists.
    pub fn has(self: *Metadata, header: []const u8, name: []const u8) bool {
        return self.get(header, name) != null;
    }

    // Get a field.
    pub fn get(self: *Metadata, header: []const u8, name: []const u8) ?[]const u8 {
        if (self.groups.get(header)) |group| {
            if (group.get(name)) |value| {
                return value;
            }
        }

        return self.global.get(name);
    }

    // Set a field.
    pub fn set(self: *Metadata, header: ?[]const u8, name: []const u8, value: []const u8) !void {
        if (header == null) {
            try self.global.put(name, value);
        } else { 
            if (self.groups.getEntry(header orelse unreachable)) |entry| {
                try entry.value_ptr.put(name, value);
            } else {
                var fields = std.BufMap.init(self.allocator);
                errdefer fields.deinit();

                try fields.put(name, value);
                try self.groups.put(header orelse unreachable, fields);
            }
        }
    }

    // Stringify the metadata.
    pub fn stringify (self: *Metadata, allocator: std.mem.Allocator) ![]const u8 {
        var array_list = std.ArrayList(u8).init(allocator);
        errdefer array_list.deinit();

        var writer = array_list.writer();
        try writer.print("{s}\n", .{self.media_name});

        if (self.global.count() > 0) {
            _ = try writer.write("\n");

            var field_iterator = self.global.iterator();

            while (field_iterator.next()) |field| {
                try writer.print("{s}: {s}\n", .{field.key_ptr.*, field.value_ptr.*});
            }
        }

        var group_iterator = self.groups.iterator();

        while (group_iterator.next()) |group| {
            try writer.print("\n[ {s} ]\n", .{group.key_ptr.*});

            if (group.value_ptr.count() > 0) {
                _ = try writer.write("\n");

                var field_iterator = group.value_ptr.iterator();

                while (field_iterator.next()) |field| {
                    try writer.print("{s}: {s}\n", .{field.key_ptr.*, field.value_ptr.*});
                }
            }
        }

        return try array_list.toOwnedSlice();
    }
};

// Parse a metadata.
pub fn parse (source: []const u8, allocator: std.mem.Allocator) !Metadata {
    var line_iterator = std.mem.splitScalar(u8, source, '\n');
    var header: ?[]const u8 = null;

    const media_name = result: {
        const line = line_iterator.next() orelse {
            return error.EmptyMediaName;
        };

        break :result std.mem.trim(u8, line, " ");
    };


    if (media_name.len == 0) {
        return error.EmptyMediaName;
    }

    var metadata = try Metadata.init(media_name, allocator);
    errdefer metadata.deinit();

    while (line_iterator.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " ");

        if (trimmed.len == 0 or trimmed[0] == '#') {
            continue;
        } else if (trimmed[0] == '[' and trimmed[trimmed.len - 1] == ']') {
            header = std.mem.trim(u8, trimmed[1..trimmed.len - 1], " "); 

            if (header.len == 0) {
                return error.EmptyHeaderName;
            }
        } else if (std.mem.indexOfScalar(u8, trimmed, ':')) |separator_index| {
            const name = std.mem.trim(u8, trimmed[0..separator_index], " ");
            const value = std.mem.trim(u8, trimmed[separator_index + 1..], " "); 

            try metadata.set(header, name, value);
        } else {
            return error.InvalidLine;
        }
    }

    return metadata;
}

// The main function :3
pub fn main() !void {
    var debug = std.heap.DebugAllocator(.{}).init;
    defer _ = debug.deinit();

    const allocator = debug.allocator();

    const source = (
        \\ UMF Zig Parser
        \\
        \\ [ Github ]
        \\
        \\ Author: LmanTW
        \\ Language: Zig
    );

    var metadata = try parse(source, allocator);
    defer metadata.deinit();

    std.debug.print("Value: {s}\n", .{metadata.get("Github", "Author").?});
 }
