import CVKEGPSCore
import SwiftUI
import UIKit

/// The design-language colour tokens of the Android app, as dynamic colours for light and dark mode.
/// Electric blue is the one accent. Status, data, and brand colours never change.
enum Palette {
    static let accent = dynamic(light: 0x0A5CFF, dark: 0x6F9BFF, lightHigh: 0x0040B8, darkHigh: 0xA3BFFF)
    /// The fill of a prominent button. White text on it has a contrast of 5.3:1 in light mode and 4.9:1 in dark mode
    /// (8.7:1 and 6.6:1 with Increase Contrast).
    /// The dark `accent` is for text and icons on dark surfaces; white text on it is only 2.7:1.
    static let accentFill = dynamic(light: 0x0A5CFF, dark: 0x2F66F2, lightHigh: 0x0040B8, darkHigh: 0x1E4FD8)
    static let accentSubtle = dynamic(light: 0xE5EDFF, dark: 0x132552)
    static let brandApricotSubtle = dynamic(light: 0xFDE9DC, dark: 0x3A2012)
    static let ink = dynamic(light: 0x161A1F, dark: 0xE9EDF1, lightHigh: 0x000000, darkHigh: 0xFFFFFF)
    static let success = dynamic(light: 0x1A7F4B, dark: 0x5FD39A, lightHigh: 0x0F5C35, darkHigh: 0x8BE6B8)
    static let warning = dynamic(light: 0x9A5B00, dark: 0xF5B14C, lightHigh: 0x6E4000, darkHigh: 0xFFCB7A)
    static let warningSubtle = dynamic(light: 0xFBF0DC, dark: 0x33270F)
    static let danger = dynamic(light: 0xB42318, dark: 0xF97066, lightHigh: 0x8A1A12, darkHigh: 0xFFA39B)
    static let dangerSubtle = dynamic(light: 0xFDECEA, dark: 0x3A1614)
    static let inkMuted = dynamic(light: 0x5B6470, dark: 0x9FA9B4, lightHigh: 0x3E4651, darkHigh: 0xC4CCD5)
    static let surfaceSunken = dynamic(light: 0xEEF0F3, dark: 0x0D1014)
    static let background = dynamic(light: 0xF6F7F9, dark: 0x12161B)
    static let brandApricot = dynamic(light: 0xD9661F, dark: 0xF5A578)
    static let gradientEnd = dynamic(light: 0xC08D96, dark: 0xDBA2A8)

    /// The start and end markers. They keep their colours in both themes.
    static let startMarker = Color(rgb: 0x237A3B)
    static let endMarker = Color(rgb: 0xB62929)
    /// An old position.
    static let oldPosition = Color(rgb: SpeedRamp.noSpeed)

    /// A colour for light and dark mode. With Increase Contrast on, a token with `lightHigh` and `darkHigh` uses those
    /// stronger values. They have a contrast of 7:1 or more on `background`.
    static func dynamic(light: UInt32, dark: UInt32, lightHigh: UInt32? = nil, darkHigh: UInt32? = nil) -> Color {
        Color(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let high = traits.accessibilityContrast == .high
            if high, let strong = isDark ? darkHigh : lightHigh { return UIColor(rgb: strong) }
            return UIColor(rgb: isDark ? dark : light)
        })
    }

    /// The speed colour at `position`, from 0 (slow, dark) to 1 (fast, yellow). See ADR 0005.
    static func speed(_ position: Double?) -> Color {
        guard let position else { return Color(rgb: SpeedRamp.noSpeed) }
        let rgb = SpeedRamp.at(position)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}

extension Color {
    init(rgb: UInt32) {
        let components = SpeedRamp.components(rgb)
        self.init(red: components.red, green: components.green, blue: components.blue)
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        let components = SpeedRamp.components(rgb)
        self.init(red: components.red, green: components.green, blue: components.blue, alpha: 1)
    }
}

/// The 4-point spacing steps of the design language.
enum Space {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
}

/// A touch target is at least 44 points on iOS. The app uses 48, as on Android.
enum Size {
    static let touch: CGFloat = 48
}

/// The page behind the Speed tab: the brand gradient, soft enough that the glass and the values stay readable.
/// It does not move, so it costs no frames.
struct BrandBackdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        MeshGradient(width: 3, height: 3, points: [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5], [0.55, 0.45], [1, 0.5],
            [0, 1], [0.5, 1], [1, 1],
        ], colors: [
            Color(rgb: dark ? 0x1B2A55 : 0xD9E4FF), Color(rgb: dark ? 0x141B26 : 0xEEF2FB), Color(rgb: dark ? 0x12161B : 0xF6F7F9),
            Color(rgb: dark ? 0x162036 : 0xE6ECFA), Color(rgb: dark ? 0x12161B : 0xF6F7F9), Color(rgb: dark ? 0x2A1E1C : 0xF8EBE6),
            Color(rgb: dark ? 0x12161B : 0xF6F7F9), Color(rgb: dark ? 0x2E2022 : 0xF5E4E2), Color(rgb: dark ? 0x3A2416 : 0xFBE3D3),
        ])
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
