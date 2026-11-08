import CVKEGPSCore
import SwiftUI

/// The GPS comet around the speed circle: a thin rim on the circle edge and a soft glow outside it.
/// The rim is electric blue at the direction of travel and changes to dusty rose around the circle.
/// A wider and softer glow shows a less accurate position. The comet is decoration, so VoiceOver does not read it.
/// The comet changes only when the comet value changes. It has no timer and no repeating animation.
struct SpeedComet: View {
    var comet: GpsComet
    /// The diameter of the speed circle. The comet draws outside it, at most `reach` from its edge.
    var diameter: CGFloat

    /// The maximum distance from the circle edge for the rim, the glow, and the blur together.
    static let reach: CGFloat = 24

    private static let stopCount = 72
    private static let rimWidth: CGFloat = 2.5
    /// The glow width and blur at glow 0. At glow 1, the width is 2 times and the blur is 3 times these values.
    private static let glowWidth: CGFloat = 5
    private static let glowBlur: CGFloat = 1.5
    /// The visible blur reaches about 3 times the blur radius. This must stay in `reach` at glow 1.
    private static let blurExtent: CGFloat = 3
    /// The resting comet is blue at the top left and rose at the bottom right, as the app icon.
    private static let restingToward = 7 * Double.pi / 4
    private static let restingFocus = 1.5

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let glow = CGFloat(min(max(comet.glow, 0), 1))
        let width = Self.glowWidth * (1 + glow)
        let blur = Self.glowBlur * (1 + 2 * glow)
        let increased = contrast == .increased
        let gradient = self.gradient
        ZStack {
            // The stroke is on a circle that is larger by the width, so the glow starts at the circle edge and goes out.
            Circle()
                .stroke(gradient, lineWidth: width)
                .frame(width: diameter + width, height: diameter + width)
                .blur(radius: blur)
                .opacity((0.5 - 0.2 * glow) * (increased ? 0.6 : 1))
            // The rim is outside the circle edge, so the material of the circle does not cover it.
            Circle()
                .strokeBorder(gradient, lineWidth: Self.rimWidth)
                .frame(width: diameter + 2 * Self.rimWidth, height: diameter + 2 * Self.rimWidth)
                .opacity(increased ? 1 : 0.95)
        }
        .frame(width: diameter + 2 * Self.reach, height: diameter + 2 * Self.reach)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: comet)
    }

    /// Gives the colours around the circle, clockwise from the top. The last stop is the same as the first stop.
    private var gradient: AngularGradient {
        let (toward, focus) = switch comet.direction {
        case .resting: (Self.restingToward, Self.restingFocus)
        case let .pointing(screenRadians, focus): (screenRadians, focus)
        }
        let last = Self.stopCount - 1
        let stops = (0...last).map { index in
            let location = Double(index) / Double(last)
            let weight = pow((1 + cos(location * 2 * Double.pi - toward)) / 2, focus)
            return Gradient.Stop(color: Palette.accent.mix(with: Palette.gradientEnd, by: 1 - weight), location: location)
        }
        return AngularGradient(stops: stops, center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))
    }
}

