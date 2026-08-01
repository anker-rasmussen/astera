import SwiftUI
import SwiftData

enum ProfileField: String, Identifiable, CaseIterable {
    case pronouns
    case salutation
    case relationship
    case cycleMode
    case birthYear
    var id: String { rawValue }
}

struct ProfileEditSheet: View {
    let field: ProfileField
    let profile: UserProfile
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch field {
        case .pronouns:
            PronounsEditView(profile: profile, onDismiss: onDismiss)
        case .salutation:
            SalutationEditView(profile: profile, onDismiss: onDismiss)
        case .relationship:
            RelationshipEditView(profile: profile, onDismiss: onDismiss)
        case .cycleMode:
            CycleModeEditView(profile: profile, onDismiss: onDismiss)
        case .birthYear:
            BirthYearEditView(profile: profile, onDismiss: onDismiss)
        }
    }
}

// MARK: - Edit scaffold

struct EditScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(AsteraGhostButtonStyle())
                    .accessibilityIdentifier("profileEdit.cancel")
                Spacer()
                Button(action: onSave) {
                    HStack(spacing: 4) {
                        Text("Save")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .buttonStyle(AsteraLinkButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.4)
                .accessibilityIdentifier("profileEdit.save")
            }
            .asteraEditorialMargins()
            .padding(.top, AsteraSpacing.md)

            Hairline().asteraEditorialMargins().padding(.top, AsteraSpacing.sm)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
                    VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                        Text(title)
                            .font(.asteraSerif(28, weight: .medium))
                            .foregroundStyle(AsteraColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if let subtitle {
                            Text(subtitle)
                                .font(.asteraSerifItalic(15))
                                .foregroundStyle(AsteraColor.iron)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    content()
                }
                .asteraEditorialMargins()
                .padding(.top, AsteraSpacing.xl)
                .padding(.bottom, AsteraSpacing.xl)
            }
        }
        .asteraScreen()
    }
}

// MARK: - Pronouns

struct PronounsEditView: View {
    let profile: UserProfile
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext

    @State private var pendingPronouns: Pronouns
    @State private var pendingCustom: String

    private let options: [(Pronouns, String, String)] = [
        (.sheHer, "she / her", "She is on day 14 of her cycle."),
        (.heHim, "he / him", "He is on day 14 of his cycle."),
        (.theyThem, "they / them", "They are on day 14 of their cycle."),
        (.custom, "something else", "Whatever fits.")
    ]

    init(profile: UserProfile, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.onDismiss = onDismiss
        _pendingPronouns = State(initialValue: profile.pronouns)
        _pendingCustom = State(initialValue: profile.customPronouns ?? "")
    }

    private var canSave: Bool {
        pendingPronouns != .custom || !pendingCustom.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        EditScaffold(
            title: "What words should we use?",
            subtitle: "We use these everywhere in the app, never assumed.",
            canSave: canSave,
            onCancel: onDismiss,
            onSave: save
        ) {
            HairlineList {
                ForEach(options, id: \.0) { option in
                    HairlineRow(
                        title: option.1,
                        subtitle: option.2,
                        isSelected: pendingPronouns == option.0,
                        action: { pendingPronouns = option.0 }
                    )
                    Hairline()
                }
                if pendingPronouns == .custom {
                    HStack {
                        TextField("Your words", text: $pendingCustom)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.asteraSerif(20))
                            .foregroundStyle(AsteraColor.ink)
                            .tint(AsteraColor.accent)
                    }
                    .padding(.vertical, AsteraSpacing.md)
                    Hairline()
                }
            }
        }
    }

    private func save() {
        profile.pronouns = pendingPronouns
        profile.customPronouns = pendingPronouns == .custom ? pendingCustom.trimmingCharacters(in: .whitespaces) : nil
        profile.modifiedAt = Date()
        try? modelContext.save()
        onDismiss()
    }
}

// MARK: - Salutation

struct SalutationEditView: View {
    let profile: UserProfile
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext

    @State private var pending: Salutation
    @State private var pendingCustomGreeting: String

    private let options: [(Salutation, String, String)] = [
        (.none, "Hello.", "Quiet, neutral, the default."),
        (.person, "Hey there.", "Warm, no assumptions."),
        (.woman, "Hey, lady.", "If that feels right."),
        (.girl, "Hey, girlie 🌸", "A little more familiar."),
        (.custom, "use my own words", "Type the exact greeting you want.")
    ]

    init(profile: UserProfile, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.onDismiss = onDismiss
        _pending = State(initialValue: profile.salutation)
        _pendingCustomGreeting = State(initialValue: profile.customGreeting ?? "")
    }

    private var canSave: Bool {
        pending != .custom || !pendingCustomGreeting.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        EditScaffold(
            title: "How should we greet you?",
            subtitle: "This shows at the top of Home every time you open the app.",
            canSave: canSave,
            onCancel: onDismiss,
            onSave: save
        ) {
            HairlineList {
                ForEach(options, id: \.0) { option in
                    HairlineRow(
                        title: option.1,
                        subtitle: option.2,
                        isSelected: pending == option.0,
                        action: { pending = option.0 }
                    )
                    Hairline()
                }
                if pending == .custom {
                    HStack {
                        TextField("e.g. \"Hey lovely.\"", text: $pendingCustomGreeting)
                            .textInputAutocapitalization(.sentences)
                            .font(.asteraSerif(20))
                            .foregroundStyle(AsteraColor.ink)
                            .tint(AsteraColor.accent)
                    }
                    .padding(.vertical, AsteraSpacing.md)
                    Hairline()
                }
            }
        }
    }

    private func save() {
        profile.salutation = pending
        if pending == .custom {
            let trimmed = pendingCustomGreeting.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.customGreeting = trimmed.isEmpty ? nil : trimmed
        } else {
            profile.customGreeting = nil
        }
        profile.modifiedAt = Date()
        try? modelContext.save()
        onDismiss()
    }
}

// MARK: - Relationship

struct RelationshipEditView: View {
    let profile: UserProfile
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext

    @State private var pending: RelationshipStructure

    private let options: [(RelationshipStructure, String, String)] = [
        (.single, "just me", "The simplest setup."),
        (.partneredTracking, "a partner who tracks too", "Partner sync is coming later, if you'd like it."),
        (.partneredNotTracking, "a partner who doesn't", "Nobody is going to bug them about anything."),
        (.polyamorous, "polyamorous", "Same options. No assumptions about structure.")
    ]

    init(profile: UserProfile, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.onDismiss = onDismiss
        _pending = State(initialValue: profile.relationshipStructure)
    }

    var body: some View {
        EditScaffold(
            title: "Who's in this with you?",
            subtitle: "Affects only optional partner features.",
            canSave: true,
            onCancel: onDismiss,
            onSave: save
        ) {
            HairlineList {
                ForEach(options, id: \.0) { option in
                    HairlineRow(
                        title: option.1,
                        subtitle: option.2,
                        isSelected: pending == option.0,
                        action: { pending = option.0 }
                    )
                    Hairline()
                }
            }
        }
    }

    private func save() {
        profile.relationshipStructure = pending
        profile.modifiedAt = Date()
        try? modelContext.save()
        onDismiss()
    }
}

// MARK: - Cycle mode

struct CycleModeEditView: View {
    let profile: UserProfile
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext

    @State private var pending: CycleMode

    private let allOptions: [(CycleMode, String, String)] = [
        (.regular, "regular cycles", "Usually within a few days of the same length."),
        (.irregular, "irregular cycles", "Length varies a lot, with no clear pattern."),
        (.pcos, "PCOS", "Ovulation prompts stay off unless you ask for them."),
        (.endometriosis, "endometriosis", "Pain logging up front, wider confidence bands, and no pretending to know more than we do."),
        (.iud, "have an IUD", "Lighter or absent bleeds are normal here, not a missed period."),
        (.hormonalBC, "on hormonal birth control", "Pill, patch, ring, implant, or injection. Withdrawal bleeds and absent bleeds are both normal."),
        (.perimenopause, "perimenopause", "Variable cycles are expected, not a tracking failure."),
        (.surgicalMenopause, "after surgical menopause or hysterectomy", "No cycle predictions. The rest of the app is still here for you."),
        (.pregnant, "pregnant", "We'll switch to a week-by-week view. Your cycle history stays right where it is."),
        (.postLoss, "after pregnancy loss", "Your history stays exactly as it was. Cycle reminders go quiet until you tell us you're ready."),
        (.ttc, "trying to conceive", "A fertility window with confidence bands. No countdown, no comparison."),
        (.postpartum, "postpartum", "Periods come back when they come back. No \"late\" alerts here."),
        (.trackingOnT, "tracking on T", "Cycle changes on T are real and varied. No bleed forecasts."),
        (.notSure, "not sure yet", "That's completely fine. You can change this any time, and nothing you log gets lost.")
    ]

    private var options: [(CycleMode, String, String)] {
        profile.hideFertilityContent ? allOptions.filter { $0.0 != .ttc } : allOptions
    }

    init(profile: UserProfile, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.onDismiss = onDismiss
        _pending = State(initialValue: profile.cycleMode)
    }

    var body: some View {
        EditScaffold(
            title: "Where are you right now?",
            subtitle: "You can change states any time. Your history stays. Switching modes never deletes anything.",
            canSave: true,
            onCancel: onDismiss,
            onSave: save
        ) {
            HairlineList {
                ForEach(options, id: \.0) { option in
                    HairlineRow(
                        title: option.1,
                        subtitle: option.2,
                        isSelected: pending == option.0,
                        action: { pending = option.0 }
                    )
                    Hairline()
                }
            }
        }
    }

    private func save() {
        profile.cycleMode = pending
        profile.modifiedAt = Date()
        try? modelContext.save()
        onDismiss()
    }
}

// MARK: - Birth year

struct BirthYearEditView: View {
    let profile: UserProfile
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext

    @State private var text: String
    @FocusState private var focused: Bool

    init(profile: UserProfile, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.onDismiss = onDismiss
        _text = State(initialValue: String(profile.birthYear))
    }

    private var typedYear: Int? {
        Int(text.trimmingCharacters(in: .whitespaces))
    }

    var body: some View {
        EditScaffold(
            title: "Birth year",
            subtitle: "Helps tailor things like teen-mode and perimenopause framing. We never share this.",
            canSave: typedYear != nil,
            onCancel: onDismiss,
            onSave: save
        ) {
            VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                HStack(alignment: .firstTextBaseline, spacing: AsteraSpacing.sm) {
                    TextField("\(profile.birthYear)", text: $text)
                        .accessibilityIdentifier("profileEdit.birthYear.field")
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .font(.asteraNumeric(48, weight: .medium))
                        .foregroundStyle(AsteraColor.ink)
                        .tint(AsteraColor.accent)
                        .frame(maxWidth: 160, alignment: .leading)
                        .onChange(of: text) { _, newValue in
                            let digits = newValue.filter(\.isNumber).prefix(4)
                            if digits != Substring(newValue) {
                                text = String(digits)
                            }
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") { focused = false }
                                    .font(.asteraSerif(15, weight: .medium))
                                    .foregroundStyle(AsteraColor.accent)
                            }
                        }
                    if let year = typedYear {
                        let age = Calendar.current.component(.year, from: Date()) - year
                        Text("(\(age))")
                            .font(.asteraSerifItalic(18))
                            .foregroundStyle(AsteraColor.iron)
                    }
                    Spacer()
                }
                .onAppear { focused = true }
                Hairline()
            }
        }
    }

    private func save() {
        guard let year = typedYear else { return }
        profile.birthYear = year
        profile.modifiedAt = Date()
        try? modelContext.save()
        // If lowering the year crossed an age gate, clear any toggles that should now be hidden.
        AgeMode.reconcileAgeGatedSettings(birthYear: year)
        onDismiss()
    }
}
