import Foundation

/// The direction that the phone points to, from the compass.
public enum PhoneHeading: Hashable, Sendable {
    case unavailable
    /// The heading is clockwise from true north. Both values are in radians.
    case current(trueRadians: Double, accuracyRadians: Double)
}

/// The GPS comet on the rim of the speed circle. The glow shows the position accuracy.
/// The direction shows where the user travels, relative to the top of the phone screen.
public struct GpsComet: Hashable, Sendable {
    public enum Direction: Hashable, Sendable {
        /// The comet has no usable direction.
        case resting
        /// `screenRadians` is clockwise from the top of the screen, in [0, 2π). `focus` is 14 (sure) to 2 (unsure).
        case pointing(screenRadians: Double, focus: Double)
    }

    /// 0 is an accuracy of 3 m or better. 1 is an accuracy of 50 m.
    public var glow: Double
    public var direction: Direction

    private static let bestAccuracyMeters = 3.0
    private static let maxCompassAccuracyRadians = Double.pi / 6
    private static let unknownCourseAccuracyDegrees = 20.0

    /// Gives the comet for a live reading. Gives nil when the reading is missing, old, or not accurate enough.
    public static func make(reading: GpsReading?, live: Bool, heading: PhoneHeading) -> GpsComet? {
        guard live, let reading, let accuracy = reading.accuracyMeters, accuracy.isFinite, accuracy >= 0,
              accuracy <= UsabilityLimits.maxHorizontalErrorMeters else { return nil }
        let span = log(UsabilityLimits.maxHorizontalErrorMeters) - log(bestAccuracyMeters)
        let glow = min(max((log(max(accuracy, bestAccuracyMeters)) - log(bestAccuracyMeters)) / span, 0), 1)
        return GpsComet(glow: glow, direction: direction(reading: reading, heading: heading))
    }

    private static func direction(reading: GpsReading, heading: PhoneHeading) -> Direction {
        guard let travel = reading.travelRadians,
              case let .current(headingRadians, headingAccuracy) = heading,
              headingRadians.isFinite, headingAccuracy.isFinite,
              headingAccuracy >= 0, headingAccuracy <= maxCompassAccuracyRadians else { return .resting }
        let full = 2 * Double.pi
        var screen = (travel - headingRadians).truncatingRemainder(dividingBy: full)
        if screen < 0 { screen += full }
        if screen >= full { screen = 0 }
        let courseDegrees = reading.bearingAccuracyRadians.flatMap { $0.isFinite && $0 >= 0 ? $0 * 180 / .pi : nil }
            ?? unknownCourseAccuracyDegrees
        let headingDegrees = headingAccuracy * 180 / .pi
        let uncertainty = (courseDegrees * courseDegrees + headingDegrees * headingDegrees).squareRoot()
        let sureness = min(max((log(max(uncertainty, 1e-9)) - log(2.0)) / (log(45.0) - log(2.0)), 0), 1)
        return .pointing(screenRadians: screen, focus: 14 - 12 * sureness)
    }
}

extension GpsReading {
    /// The direction of travel. Nil when the course is missing or the speed is below 1 m/s.
    public var travelRadians: Double? {
        guard let bearing = bearingRadians, bearing.isFinite, let speed = speedMetersPerSecond, speed >= 1 else { return nil }
        return bearing
    }
}

/// The eight compass points.
public enum CompassPoint: CaseIterable, Sendable {
    case north, northEast, east, southEast, south, southWest, west, northWest

    /// Each point covers a sector of 45° that is centred on it. The angle is clockwise from north.
    /// An angle that is not a finite number gives north.
    public init(radians: Double) {
        guard radians.isFinite else {
            self = .north
            return
        }
        let full = 2 * Double.pi
        var angle = radians.truncatingRemainder(dividingBy: full)
        if angle < 0 { angle += full }
        let index = Int(((angle + Double.pi / 8) / (Double.pi / 4)).rounded(.down)) % Self.allCases.count
        self = Self.allCases[index]
    }
}
