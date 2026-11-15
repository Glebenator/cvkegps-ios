import Testing
@testable import CVKEGPSCore

/// The axis values of the replay charts are round in the display unit.
struct ChartTicksTests {
    @Test func aSpeedAxisInMilesPerHourHasRoundValues() {
        // 0 to 12 m/s × 1.1 is 0 to 29.5 mph.
        #expect(ChartTicks.values(low: 0, high: 13.2 * 2.236_936) == [0, 10, 20])
    }

    @Test func aHeightAxisAroundAnAltitudeStepsBy5() {
        #expect(ChartTicks.values(low: 225, high: 235) == [225, 230, 235])
        #expect(ChartTicks.values(low: 224, high: 236) == [225, 230, 235])
    }

    @Test func anAccelerationAxisIsSymmetricAndIncludesZero() {
        #expect(ChartTicks.values(low: -3.3, high: 3.3) == [-2, 0, 2])
    }

    @Test func anEmptyOrInvalidRangeGivesOneOrNoValue() {
        #expect(ChartTicks.values(low: 5, high: 5) == [5])
        #expect(ChartTicks.values(low: .nan, high: 5).isEmpty)
    }
}
