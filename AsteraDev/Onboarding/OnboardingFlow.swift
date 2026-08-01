import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKey.hasCompletedOnboarding.rawValue) private var hasCompletedOnboarding: Bool = false
    @AppStorage(AppStorageKey.requiresAppLock.rawValue) private var requiresAppLock: Bool = false

    @State private var step: OnboardingStep = .welcome
    @State private var draft = OnboardingDraft()

    var body: some View {
        ZStack {
            AsteraColor.vellum.ignoresSafeArea()
            content
                .id(step)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
        }
        .animation(.easeInOut(duration: 0.32), value: step)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            WelcomeView(onContinue: { advance() })
        case .pronouns:
            PronounsStep(
                draft: draft,
                onBack: { back() },
                onSkip: { advance() },
                onContinue: { advance() }
            )
        case .salutation:
            SalutationStep(
                draft: draft,
                onBack: { back() },
                onSkip: { advance() },
                onContinue: { advance() }
            )
        case .relationship:
            RelationshipStep(
                draft: draft,
                onBack: { back() },
                onSkip: { advance() },
                onContinue: { advance() }
            )
        case .cycleMode:
            CycleModeStep(
                draft: draft,
                onBack: { back() },
                onSkip: { advance() },
                onContinue: { advance() }
            )
        case .privacy:
            PrivacyStep(
                draft: draft,
                onBack: { back() },
                onSkip: { advance() },
                onContinue: { advance() }
            )
        case .cycleBasics:
            CycleBasicsStep(
                draft: draft,
                onBack: { back() },
                onSkip: { advance() },
                onContinue: { advance() }
            )
        case .firstPrediction:
            FirstPredictionStep(
                draft: draft,
                onBack: { back() },
                onFinish: { finish() }
            )
        }
    }

    private func advance() {
        if let next = step.next {
            step = next
        }
    }

    private func back() {
        if let previous = step.previous {
            step = previous
        }
    }

    private func finish() {
        persistDraft()
        requiresAppLock = draft.useAppLock
        // Defensive: if the entered birth year puts them below an age gate, force toggles off.
        AgeMode.reconcileAgeGatedSettings(birthYear: draft.birthYear)
        hasCompletedOnboarding = true
    }

    private func persistDraft() {
        let profile = UserProfile(
            pronouns: draft.pronouns,
            salutation: draft.salutation,
            relationshipStructure: draft.relationshipStructure,
            cycleMode: draft.cycleMode,
            birthYear: draft.birthYear
        )
        // Custom greeting overrides the salutation-based default if the user typed one.
        let trimmedGreeting = draft.customGreeting.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.customGreeting = trimmedGreeting.isEmpty ? nil : trimmedGreeting

        modelContext.insert(profile)

        if let lastStart = draft.lastPeriodStart {
            let cycle = Cycle(
                startDate: Calendar.current.startOfDay(for: lastStart),
                modeAtStart: draft.cycleMode
            )
            modelContext.insert(cycle)

            // Seed a flow entry on the period-start day so the calendar shows the bleed.
            // Default to medium. The user can refine this any time from the calendar.
            let flow = FlowEntry(
                day: Calendar.current.startOfDay(for: lastStart),
                intensity: .medium,
                source: .manual
            )
            flow.cycle = cycle
            modelContext.insert(flow)
        }

        try? modelContext.save()
    }
}

/// `CaseIterable` is load-bearing, not convenience: `EraseService` wipes `allCases`, and the list
/// it wiped used to be written out by hand. Four keys had been added since and none of them were
/// on it, so "wipes every setting" quietly left the logging preferences behind, including whether
/// sexual-activity logging was on, which is itself something a person may be erasing.
enum AppStorageKey: String, CaseIterable {
    case hasCompletedOnboarding
    case requiresAppLock
    case showInCalendar
    /// Whether the calendar gets your logged periods as well as the predicted one. Default false:
    /// a calendar can be shared, and history there says a great deal more than a forecast does.
    case includePastPeriodsInCalendar
    case syncToHealth
    case notifyPeriodInThreeDays
    case notifyPeriodToday
    /// Whether adult users have opted to see sex-related logging chips. Default true.
    /// Hard-gated off for teens regardless of this flag.
    case showSexualActivity
    /// Whether to show the cravings & appetite section in the log sheet. Default false (opt-in).
    /// People navigating eating disorders, or in recovery, often prefer to keep food talk
    /// out of cycle logging entirely.
    case showCravingsLogging
    /// Whether to show the symptoms section in the log sheet. Default true.
    /// Off lets someone with very easy cycles strip the log down to flow + notes.
    case showSymptomsLogging
    /// Whether to show the lifestyle section (exercise, alcohol, caffeine, travel, illness, medication, stress).
    /// Default false (opt-in). Useful if you want cycle/lifestyle correlations.
    case showLifestyleLogging
}
