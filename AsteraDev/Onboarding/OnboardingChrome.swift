import SwiftUI

extension OnboardingStep {
    var chapterNumeral: String? {
        switch self {
        case .welcome: return nil
        case .pronouns: return "I"
        case .salutation: return "II"
        case .relationship: return "III"
        case .cycleMode: return "IV"
        case .privacy: return "V"
        case .cycleBasics: return "VI"
        case .firstPrediction: return "VII"
        }
    }

    var chapterTitle: String? {
        switch self {
        case .welcome: return nil
        case .pronouns: return "your words"
        case .salutation: return "a name"
        case .relationship: return "your circle"
        case .cycleMode: return "where you are"
        case .privacy: return "privacy"
        case .cycleBasics: return "a few details"
        case .firstPrediction: return "first reading"
        }
    }
}

struct ChapterHeader: View {
    let step: OnboardingStep
    var body: some View {
        HStack(spacing: AsteraSpacing.sm) {
            if let numeral = step.chapterNumeral, let title = step.chapterTitle {
                Text(numeral)
                    .font(.asteraSerif(13, weight: .semibold))
                    .foregroundStyle(AsteraColor.accent)
                Text("·")
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
                Text(title)
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
            }
            Spacer()
        }
    }
}

struct OnboardingScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    let currentStep: OnboardingStep
    let continueLabel: String
    let canContinue: Bool
    let showSkip: Bool
    let onBack: (() -> Void)?
    let onSkip: (() -> Void)?
    let onContinue: () -> Void
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        currentStep: OnboardingStep,
        continueLabel: String = "Continue",
        canContinue: Bool = true,
        showSkip: Bool = true,
        onBack: (() -> Void)? = nil,
        onSkip: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.currentStep = currentStep
        self.continueLabel = continueLabel
        self.canContinue = canContinue
        self.showSkip = showSkip
        self.onBack = onBack
        self.onSkip = onSkip
        self.onContinue = onContinue
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    if let onBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(AsteraColor.iron)
                        }
                    }
                    Spacer()
                }
                ChapterHeader(step: currentStep)
                    .padding(.horizontal, 40)
            }
            .padding(.horizontal, AsteraSpacing.lg)
            .padding(.top, AsteraSpacing.md)

            Hairline()
                .padding(.horizontal, AsteraSpacing.margin)
                .padding(.top, AsteraSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
                    VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                        Text(title)
                            .font(.asteraSerif(34, weight: .medium))
                            .foregroundStyle(AsteraColor.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if let subtitle {
                            Text(subtitle)
                                .font(.asteraSerifItalic(16))
                                .foregroundStyle(AsteraColor.iron)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.top, AsteraSpacing.lg)

                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .asteraEditorialMargins()
                .padding(.bottom, AsteraSpacing.xl)
            }

            VStack(spacing: 0) {
                Hairline()
                    .asteraEditorialMargins()
                HStack {
                    if showSkip, let onSkip {
                        Button("Skip", action: onSkip)
                            .buttonStyle(AsteraGhostButtonStyle())
                    } else {
                        Spacer().frame(width: 60)
                    }
                    Spacer()
                    Button(action: onContinue) {
                        HStack(spacing: 6) {
                            Text(continueLabel)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .buttonStyle(AsteraLinkButtonStyle())
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.35)
                }
                .asteraEditorialMargins()
                .padding(.vertical, AsteraSpacing.md)
            }
        }
        .asteraScreen()
    }
}

struct HairlineRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    /// Optional, because the rows that are not a choice between options have nothing to select.
    let identifier: String?
    let action: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        identifier: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.identifier = identifier
        self.action = action
        self.trailing = trailing
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AsteraSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if isSelected {
                            Circle()
                                .fill(AsteraColor.accent)
                                .frame(width: 6, height: 6)
                        }
                        Text(title)
                            .font(.asteraSerif(20, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? AsteraColor.ink : AsteraColor.ink.opacity(0.78))
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.asteraSerifItalic(14))
                            .foregroundStyle(AsteraColor.iron)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(1)
                    }
                }
                Spacer(minLength: AsteraSpacing.sm)
                trailing()
            }
            .padding(.vertical, AsteraSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Rows that are not a choice fall back to the empty identifier they would have had anyway.
        .accessibilityIdentifier(identifier ?? "")
        // Lets a test read which option is selected instead of inferring it from the copy.
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct HairlineList<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(spacing: 0) {
            Hairline()
            content()
        }
    }
}
