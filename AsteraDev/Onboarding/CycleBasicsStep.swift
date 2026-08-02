import SwiftUI

struct CycleBasicsStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void



    var body: some View {
        OnboardingScaffold(
            title: "A few practical details.",
            subtitle: "Enough for a first estimate. Skip anything you'd rather not say.",
            currentStep: .cycleBasics,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            VStack(spacing: 0) {
                Hairline()
                lastPeriodSection
                Hairline()
                cycleLengthSection
                Hairline()
                birthYearSection
                Hairline()
            }
        }
    }

    private var lastPeriodSection: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Last period")
            if let date = draft.lastPeriodStart {
                HStack(alignment: .firstTextBaseline, spacing: AsteraSpacing.sm) {
                    Text(date.formatted(.dateTime.day(.defaultDigits).month(.wide).year(.defaultDigits)))
                        .font(.asteraSerif(26, weight: .regular))
                        .foregroundStyle(AsteraColor.ink)
                    Spacer()
                    Button("change") {
                        draft.lastPeriodStart = nil
                    }
                    .buttonStyle(AsteraLinkButtonStyle())
                }
                DatePicker(
                    "",
                    selection: Binding(
                        get: { draft.lastPeriodStart ?? Date() },
                        set: { draft.lastPeriodStart = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(AsteraColor.accent)
                .padding(.horizontal, -8)
            } else {
                Button {
                    draft.lastPeriodStart = Date()
                } label: {
                    HStack {
                        Text("Pick a date")
                            .font(.asteraSerifItalic(18))
                            .foregroundStyle(AsteraColor.accent)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13))
                            .foregroundStyle(AsteraColor.accent)
                    }
                }
                .buttonStyle(.plain)
                Text("If you can't remember, skip this. We'll use a sensible average until you log a real one.")
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var cycleLengthSection: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Typical cycle length")
            if draft.cycleLengthKnown {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(draft.typicalCycleLength)")
                        .font(.asteraNumeric(48, weight: .semibold))
                        .foregroundStyle(AsteraColor.ink)
                        .contentTransition(.numericText())
                    Text("days")
                        .font(.asteraSerifItalic(20))
                        .foregroundStyle(AsteraColor.iron)
                    Spacer()
                    HStack(spacing: AsteraSpacing.sm) {
                        circularStep(systemName: "minus") {
                            if draft.typicalCycleLength > 18 { draft.typicalCycleLength -= 1 }
                        }
                        circularStep(systemName: "plus") {
                            if draft.typicalCycleLength < 60 { draft.typicalCycleLength += 1 }
                        }
                    }
                }
                Button("I don't know") {
                    draft.cycleLengthKnown = false
                    draft.typicalCycleLength = 28
                }
                .buttonStyle(AsteraLinkButtonStyle())
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text("~28")
                        .font(.asteraNumeric(48, weight: .semibold))
                        .foregroundStyle(AsteraColor.ink.opacity(0.4))
                    Text("days")
                        .font(.asteraSerifItalic(20))
                        .foregroundStyle(AsteraColor.iron)
                    Spacer()
                    Button("set my length") {
                        draft.cycleLengthKnown = true
                    }
                    .buttonStyle(AsteraLinkButtonStyle())
                }
                Text("We'll use the population average for now. Most cycles fall somewhere between 21 and 35 days.")
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var birthYearSection: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Birth year")

            BirthYearField(year: $draft.birthYear)

            Text("This helps us frame things appropriately. Younger users see teen-mode framing, perimenopause-aged users see perimenopause language. It stays on this phone.")
                .font(.asteraSerifItalic(13))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private func circularStep(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
                .frame(width: 36, height: 36)
                .background(
                    Circle().strokeBorder(AsteraColor.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
