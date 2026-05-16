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
        (.custom, "something else", "Tell us what fits.")
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
        (.none, "Hello.", "Quiet and neutral. The default."),
        (.person, "Hey there.", "Warm without assuming anything."),
        (.woman, "Hey, lady.", "Used only if it feels right."),
        (.girl, "Hey, girlie 🌸", "A bit more sparkle."),
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
        (.partneredTracking, "a partner who tracks too", "We'll offer optional partner sync later."),
        (.partneredNotTracking, "a partner who doesn't", "We won't bug them about anything."),
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
        (.pcos, "PCOS", "We'll skip ovulation prompts unless you ask."),
        (.endometriosis, "endometriosis", "Wider bands, pain logging up front, no false certainty."),
        (.iud, "have an IUD", "We'll quietly accept lighter or absent bleeds."),
        (.hormonalBC, "on hormonal birth control", "Pill, patch, ring, implant, injection. Withdrawal or absent bleeds are both normal."),
        (.perimenopause, "perimenopause", "Variable cycles are expected, not a tracking failure."),
        (.surgicalMenopause, "after surgical menopause or hysterectomy", "Cycle predictions are off. The rest of the app stays useful."),
        (.pregnant, "pregnant", "We'll switch to a week-by-week view. Your cycle history stays."),
        (.postLoss, "after pregnancy loss", "We'll keep your history, exactly. Reminders stay quiet until you're ready."),
        (.ttc, "trying to conceive", "Fertility window with confidence bands. No countdown, no comparison."),
        (.postpartum, "postpartum", "Bodies take their time. We'll wait quietly until you're ready."),
        (.trackingOnT, "tracking on T", "Cycle changes on T are real. We'll log without forecasting bleeds."),
        (.notSure, "not sure yet", "That's completely fine. You can change this any time without losing anything.")
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
        onDismiss()
    }
}
