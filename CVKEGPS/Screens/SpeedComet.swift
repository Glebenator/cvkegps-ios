import CVKEGPSCore
import SwiftUI

/// The GPS comet around the speed circle: a thin rim on the circle edge and a soft glow outside it.
/// The rim is electric blue at the direction of travel and changes to dusty rose around the circle.
/// A wider and softer glow shows a less accurate position. The comet is decoration, so VoiceOver does not read it.
/// When the comet value changes, the comet eases to the new value in about 0.3 s. The direction turns the shorter way
/// around the circle. With Reduce Motion, the comet changes at once.
/// Between changes, nothing moves. The comet has no timer and no repeating animation.
struct SpeedComet: View {
    var comet: GpsComet
    /// The diameter of the speed circle. The comet draws outside it, at most `reach` from its edge.
    var diameter: CGFloat

    /// The maximum distance from the circle edge for the rim, the glow, and the blur together.
    static let reach: CGFloat = 24

    /// The resting comet is blue at the top left and rose at the bottom right, as the app icon.
    private static let restingToward = 7 * Double.pi / 4
    private static let restingFocus = 1.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The direction of the blue part, clockwise from the top, in radians. It is not limited to one turn, so that each
    /// change can go the shorter way around the circle.
    @State private var toward: Double
    @State private var focus: Double

    init(comet: GpsComet, diameter: CGFloat) {
        self.comet = comet
        self.diameter = diameter
        let (toward, focus) = Self.target(comet.direction)
        _toward = State(initialValue: toward)
        _focus = State(initialValue: focus)
    }

    var body: some View {
        let animation: Animation? = reduceMotion ? nil : .easeOut(duration: 0.3)
        CometRing(toward: toward, focus: focus, glow: CGFloat(min(max(comet.glow, 0), 1)), diameter: diameter)
            .frame(width: diameter + 2 * Self.reach, height: diameter + 2 * Self.reach)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .animation(animation, value: comet.glow)
            .onChange(of: comet.direction) { _, direction in
                let (target, newFocus) = Self.target(direction)
                let full = 2 * Double.pi
                // The change from the current direction to the new direction, from −π to π: the shorter way.
                var turn = (target - toward).truncatingRemainder(dividingBy: full)
                if turn > .pi { turn -= full } else if turn < -.pi { turn += full }
                withAnimation(animation) {
                    toward += turn
                    focus = newFocus
                }
            }
    }

    /// Gives the direction and the focus of the blue part. The resting comet has fixed values, so the change between
    /// resting and pointing also eases.
    private static func target(_ direction: GpsComet.Direction) -> (toward: Double, focus: Double) {
        switch direction {
        case .resting: (restingToward, restingFocus)
        case let .pointing(screenRadians, focus): (screenRadians, focus)
        }
    }
}

/// The rim and the glow. SwiftUI animates the direction and the focus through `animatableData`, so the colours
/// around the circle change in each frame of an ease. The glow width, blur, and opacity animate as view properties.
private struct CometRing: View, Animatable {
    var toward: Double
    var focus: Double
    var glow: CGFloat
    var diameter: CGFloat

    private static let stopCount = 72
    private static let rimWidth: CGFloat = 2.5
    /// With Increase Contrast, the rim is wider and fully opaque. It stays in `SpeedComet.reach`.
    private static let contrastRimWidth: CGFloat = 3.5
    /// The glow width and blur at glow 0. At glow 1, the width is 2 times and the blur is 3 times these values.
    private static let glowWidth: CGFloat = 5
    private static let glowBlur: CGFloat = 1.5
    /// The visible blur reaches about 3 times the blur radius. This must stay in `SpeedComet.reach` at glow 1.
    private static let blurExtent: CGFloat = 3

    @Environment(\.colorSchemeContrast) private var contrast

    nonisolated var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(toward, focus) }
        set {
            toward = newValue.first
            focus = newValue.second
        }
    }

    var body: some View {
        let width = Self.glowWidth * (1 + glow)
        let blur = Self.glowBlur * (1 + 2 * glow)
        let increased = contrast == .increased
        let rim = increased ? Self.contrastRimWidth : Self.rimWidth
        let gradient = self.gradient
        ZStack {
            // The stroke is on a circle that is larger by the width, so the glow starts at the circle edge and goes out.
            Circle()
                .stroke(gradient, lineWidth: width)
                .frame(width: diameter + width, height: diameter + width)
                .blur(radius: blur)
                .opacity((0.5 - 0.2 * glow) * (increased ? 0.6 : 1))
            // The rim starts at the circle edge and goes out, so the material of the circle does not cover it.
            Circle()
                .strokeBorder(gradient, lineWidth: rim)
                .frame(width: diameter + 2 * rim, height: diameter + 2 * rim)
                .opacity(increased ? 1 : 0.95)
        }
    }

    /// Gives the colours around the circle, clockwise from the top. The last stop is the same as the first stop.
    private var gradient: AngularGradient {
        let last = Self.stopCount - 1
        let stops = (0...last).map { index in
            let location = Double(index) / Double(last)
            let weight = pow((1 + cos(location * 2 * Double.pi - toward)) / 2, focus)
            return Gradient.Stop(color: Palette.accent.mix(with: Palette.gradientEnd, by: 1 - weight), location: location)
        }
        return AngularGradient(stops: stops, center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))
    }
}
