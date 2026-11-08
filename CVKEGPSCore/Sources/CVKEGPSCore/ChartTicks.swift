import Foundation

/// Axis values for a chart in display units: 1, 2, or 5 times a power of ten, so the labels are round numbers.
/// The chart values stay in SI units. The app converts the range to display units, calls `values`, and converts the
/// ticks back, so a speed axis in mph shows 10 and 20 mph, not 11.2 and 22.4 mph.
public enum ChartTicks {
    /// About `count` round values from `low` to `high`, both included when they are round.
    /// A range that is empty or not finite gives `low` only.
    public static func values(low: Double, high: Double, count: Int = 3) -> [Double] {
        guard low.isFinite, high.isFinite else { return [] }
        let lower = min(low, high)
        let upper = max(low, high)
        let range = upper - lower
        guard range > 0, count > 0 else { return [lower] }
        let rough = range / Double(count)
        let magnitude = pow(10, floor(log10(rough)))
        let normalized = rough / magnitude
        let step = (normalized < 1.5 ? 1 : normalized < 3 ? 2 : normalized < 7 ? 5 : 10) * magnitude
        var values: [Double] = []
        var index = (lower / step).rounded(.up)
        // A small tolerance keeps an end value that is round but not exact in binary.
        while index * step <= upper + step * 1e-9 {
            let value = index * step
            values.append(abs(value) < step * 1e-9 ? 0 : value)
            index += 1
        }
        return values
    }
}
