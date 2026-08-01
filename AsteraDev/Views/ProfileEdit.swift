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
            title: Pronouns.question,
            subtitle: "We use these everywhere in the app, never assumed.",
            canSave: canSave,
            onCancel: onDismiss,
            onSave: save
        ) {
            HairlineList {
                ForEach(Pronouns.choices) { option in
                    HairlineRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: pendingPronouns == option.value,
                        identifier: option.accessibilityID,
                        action: { pendingPronouns = option.value }
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
            title: Salutation.question,
            subtitle: "This shows at the top of Home every time you open the app.",
            canSave: canSave,
            onCancel: onDismiss,
            onSave: save
        ) {
            HairlineList {
                ForEach(Salutation.choices) { option in
                    HairlineRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: pending == option.value,
                        identifier: option.accessibilityID,
                        action: { pending = option.value }
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

    init(profile: UserProfile, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.onDismiss = onDismiss
        _pending = State(initialValue: profile.relationshipStructure)
    }

    var body: some View {
        EditScaffold(
            title: RelationshipStructure.question,
            subtitle: RelationshipStructure.questionSubtitle,
            canSave: true,
            onCancel: onDismiss,
            onSave: save
        ) {
            HairlineList {
                ForEach(RelationshipStructure.choices) { option in
                    HairlineRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: pending == option.value,
                        identifier: option.accessibilityID,
                        action: { pending = option.value }
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

    private var options: [ProfileChoice<CycleMode>] {
        CycleMode.choices(hidingFertilityContent: profile.hideFertilityContent)
    }

    init(profile: UserProfile, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.onDismiss = onDismiss
        _pending = State(initialValue: profile.cycleMode)
    }

    var body: some View {
        EditScaffold(
            title: CycleMode.question,
            subtitle: "You can change states any time. Your history stays. Switching modes never deletes anything.",
            canSave: true,
            onCancel: onDismiss,
            onSave: save
        ) {
            HairlineList {
                ForEach(options) { option in
                    HairlineRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: pending == option.value,
                        identifier: option.accessibilityID,
                        action: { pending = option.value }
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
