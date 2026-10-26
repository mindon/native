//! Compile-time byte repetition for terminal test data.

pub inline fn bytes(comptime pattern: []const u8, comptime count: usize) []const u8 {
    @setEvalBranchQuota(@intCast(pattern.len * count * 2 + 1000));
    return comptime blk: {
        var result: [pattern.len * count]u8 = undefined;
        for (0..count) |i| {
            @memcpy(result[i * pattern.len ..][0..pattern.len], pattern);
        }
        const frozen = result;
        break :blk &frozen;
    };
}
