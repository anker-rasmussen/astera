import SwiftUI

enum AsteraColor {
    static let accent = Color.accentColor
    static let vellum = Color("AsteraCream")
    static let ivory = Color("AsteraSurface")
    static let sage = Color("AsteraSage")
    static let gold = Color("AsteraGold")
    static let dustyRose = Color("AsteraDustyRose")
    static let ink = Color("AsteraInk")
    static let iron = Color("AsteraIron")

    static var hairline: Color { ink.opacity(0.14) }
}

enum AsteraSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let margin: CGFloat = 36
}

enum AsteraRadius {
    static let button: CGFloat = 999
}

extension Font {
    static func asteraSerif(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func asteraSerifItalic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif).italic()
    }
    static func asteraNumeric(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func asteraCaps(_ size: CGFloat = 11, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

struct CapsLabel: View {
    let text: String
    var tint: Color = AsteraColor.iron
    var body: some View {
        Text(text.uppercased())
            .font(.asteraCaps())
            .tracking(1.6)
            .foregroundStyle(tint)
    }
}

struct Hairline: View {
    var inset: CGFloat = 0
    var body: some View {
        Rectangle()
            .fill(AsteraColor.hairline)
            .frame(height: 0.5)
            .padding(.horizontal, inset)
    }
}

extension View {
    func asteraScreen() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(AsteraColor.vellum.ignoresSafeArea())
            .tint(AsteraColor.accent)
            .foregroundStyle(AsteraColor.ink)
    }

    func asteraEditorialMargins() -> some View {
        padding(.horizontal, AsteraSpacing.margin)
    }
}

struct AsteraPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.asteraSerif(17, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(isEnabled ? AsteraColor.vellum : AsteraColor.vellum.opacity(0.7))
            .background(
                Capsule(style: .continuous)
                    .fill(isEnabled ? AsteraColor.ink : AsteraColor.ink.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AsteraGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.asteraSerifItalic(15))
            .foregroundStyle(AsteraColor.iron)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

struct AsteraLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.asteraSerifItalic(15))
            .foregroundStyle(AsteraColor.accent)
            .underline(true, color: AsteraColor.accent.opacity(0.4))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
