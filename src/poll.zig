/// Indecates if the current value is available or current task has been
/// scheduled and the value will be avaliableat some point.
pub fn Poll(
    comptime T: type,
) type {
    return union(enum) {
        Ready: T,
        Pending,
    };
}
