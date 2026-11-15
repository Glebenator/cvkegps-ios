import Foundation
import Testing
@testable import CVKEGPSCore

/// The GPS comet shows the accuracy as glow and the travel direction relative to the phone.
struct GpsCometTests {
    private func reading(
        accuracy: Double?, speed: Double? = 10, bearingDegrees: Double? = 90, bearingAccuracyDegrees: Double? = 5
    ) -> GpsReading {
        GpsReading(
            speedMetersPerSecond: speed, accuracyMeters: accuracy, elapsedNanos: 1,
            bearingRadians: bearingDegrees.map { $0 * .pi / 180 },
            bearingAccuracyRadians: bearingAccuracyDegrees.map { $0 * .pi / 180 }
        )
    }

    private func heading(_ degrees: Double, accuracy: Double = 5) -> PhoneHeading {
        .current(trueRadians: degrees * .pi / 180, accuracyRadians: accuracy * .pi / 180)
    }

    private func direction(_ comet: GpsComet?) -> GpsComet.Direction? { comet?.direction }

    @Test func isHiddenWhenNotLive() {
        #expect(GpsComet.make(reading: reading(accuracy: 3), live: false, heading: .unavailable) == nil)
    }

    @Test func isHiddenWithoutReading() {
        #expect(GpsComet.make(reading: nil, live: true, heading: .unavailable) == nil)
    }

    @Test func accuracyLimitIs50Metres() {
        #expect(GpsComet.make(reading: reading(accuracy: 50.0), live: true, heading: .unavailable) != nil)
        for bad in [50.1, -1, Double.infinity, Double.nan] as [Double?] + [nil] {
            #expect(GpsComet.make(reading: reading(accuracy: bad), live: true, heading: .unavailable) == nil)
        }
    }

    @Test func glowScale() throws {
        func glow(_ accuracy: Double) throws -> Double {
            try #require(GpsComet.make(reading: reading(accuracy: accuracy), live: true, heading: .unavailable)).glow
        }
        #expect(try glow(3) == 0)
        #expect(try glow(1) == 0)
        #expect(try glow(50) == 1)
        #expect(abs(try glow((3.0 * 50.0).squareRoot()) - 0.5) < 0.001)
    }

    @Test func restsWithoutCompass() {
        #expect(direction(GpsComet.make(reading: reading(accuracy: 3), live: true, heading: .unavailable)) == .resting)
    }

    @Test func restsWhenSlow() {
        #expect(direction(GpsComet.make(reading: reading(accuracy: 3, speed: 0.9), live: true, heading: heading(0))) == .resting)
        guard case .pointing = direction(GpsComet.make(reading: reading(accuracy: 3, speed: 1.0), live: true, heading: heading(0))) else {
            Issue.record("A speed of 1 m/s must give a direction")
            return
        }
    }

    @Test func restsWithoutCourse() {
        let comet = GpsComet.make(reading: reading(accuracy: 3, bearingDegrees: nil), live: true, heading: heading(0))
        #expect(direction(comet) == .resting)
    }

    @Test func compassAccuracyEdge() {
        func isPointing(_ accuracy: Double) -> Bool {
            if case .pointing = direction(GpsComet.make(reading: reading(accuracy: 3), live: true, heading: heading(0, accuracy: accuracy))) {
                return true
            }
            return false
        }
        #expect(isPointing(30))
        #expect(!isPointing(30.1))
        #expect(!isPointing(-1))
    }

    @Test func directionIsRelativeToThePhone() throws {
        func degrees(travel: Double, heading headingDegrees: Double) throws -> Double {
            let comet = GpsComet.make(reading: reading(accuracy: 3, bearingDegrees: travel), live: true, heading: heading(headingDegrees))
            guard case let .pointing(radians, _)? = comet?.direction else { throw Failure.notPointing }
            #expect(radians >= 0 && radians < 2 * .pi)
            return radians * 180 / .pi
        }
        #expect(abs(try degrees(travel: 90, heading: 0) - 90) < 1e-9)
        #expect(abs(try degrees(travel: 350, heading: 10) - 340) < 1e-9)
        #expect(abs(try degrees(travel: 10, heading: 350) - 20) < 1e-9)
        #expect(abs(try degrees(travel: 0, heading: 0) - 0) < 1e-9)
    }

    @Test func focus() throws {
        func focus(course: Double?, heading headingAccuracy: Double) throws -> Double {
            let comet = GpsComet.make(
                reading: reading(accuracy: 3, bearingAccuracyDegrees: course), live: true, heading: heading(0, accuracy: headingAccuracy)
            )
            guard case let .pointing(_, focus)? = comet?.direction else { throw Failure.notPointing }
            return focus
        }
        #expect(try focus(course: 1, heading: 1) == 14)
        #expect(try focus(course: 45, heading: 0) == 2)
        let expected = 14 - 12 * log(10) / log(22.5)
        #expect(abs(try focus(course: nil, heading: 0) - expected) < 0.001)
    }

    @Test func compassPoints() {
        func point(_ degrees: Double) -> CompassPoint { CompassPoint(radians: degrees * .pi / 180) }
        #expect(point(0) == .north)
        #expect(point(22.4) == .north)
        #expect(point(22.6) == .northEast)
        #expect(point(359) == .north)
        #expect(point(180) == .south)
        #expect(point(270) == .west)
        #expect(point(-90) == .west)
    }

    @Test func compassPointOfNonFiniteAngleIsNorth() {
        #expect(CompassPoint(radians: .nan) == .north)
        #expect(CompassPoint(radians: .infinity) == .north)
        #expect(CompassPoint(radians: -.infinity) == .north)
    }

    private enum Failure: Error { case notPointing }
}
