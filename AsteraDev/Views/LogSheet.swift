import SwiftUI
import SwiftData

struct LogSheet: View {
    let date: Date
    var onCancel: () -> Void
    var onSaved: (Cycle?) -> Void

    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKey.syncToHealth.rawValue) private var syncToHealth: Bool = false
    @AppStorage(AppStorageKey.showSexualActivity.rawValue) private var showSexualActivity: Bool = false
    @AppStorage(AppStorageKey.showCravingsLogging.rawValue) private var showCravingsLogging: Bool = false
    @AppStorage(AppStorageKey.showSymptomsLogging.rawValue) private var showSymptomsLogging: Bool = true
    @AppStorage(AppStorageKey.showLifestyleLogging.rawValue) private var showLifestyleLogging: Bool = false
    @Query private var profiles: [UserProfile]

    @State private var draft: LogInput
    @State private var isSaving = false

    init(
        date: Date = Date(),
        initial: LogInput? = nil,
        onCancel: @escaping () -> Void,
        onSaved: @escaping (Cycle?) -> Void
    ) {
        self.date = date
        self.onCancel = onCancel
        self.onSaved = onSaved
        _draft = State(initialValue: initial ?? LogInput.empty(on: date))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Hairline().asteraEditorialMargins()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    flowSection
                    if showSymptomsLogging {
                        Hairline()
                        symptomsSection
                    }
                    if showCravingsLogging {
                        Hairline()
                        cravingsSection
                    }
                    if showLifestyleLogging {
                        Hairline()
                        miscSection
                    }
                    Hairline()
                    notesSection
                }
                .asteraEditorialMargins()
                .padding(.bottom, AsteraSpacing.xxl)
            }

            VStack(spacing: 0) {
                Hairline().asteraEditorialMargins()
                HStack(spacing: AsteraSpacing.md) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(AsteraGhostButtonStyle())
                        .frame(maxWidth: 120)

                    Button(action: save) {
                        HStack {
                            Text(saveLabel)
                            if !isSaving {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                        .font(.asteraSerif(17, weight: .medium))
                        .foregroundStyle(AsteraColor.vellum)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(AsteraColor.ink))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }
                .padding(.horizontal, AsteraSpacing.margin)
                .padding(.vertical, AsteraSpacing.md)
            }
        }
        .asteraScreen()
        .onAppear(perform: loadExisting)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                CapsLabel(text: dateLabel)
                Text(headlineText)
                    .font(.asteraSerif(30, weight: .medium))
                    .foregroundStyle(AsteraColor.ink)
                Text("Pick what fits. You can edit any time.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
            }
            Spacer()
            AsteraMark(size: 22, color: AsteraColor.accent.opacity(0.8))
        }
        .asteraEditorialMargins()
        .padding(.top, AsteraSpacing.lg)
        .padding(.bottom, AsteraSpacing.md)
    }

    private var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today · \(date.formatted(.dateTime.day(.defaultDigits).month(.wide)))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday · \(date.formatted(.dateTime.day(.defaultDigits).month(.wide)))"
        }
        return date.formatted(.dateTime.weekday(.wide).day(.defaultDigits).month(.wide))
    }

    private var headlineText: String {
        Calendar.current.isDateInToday(date) ? "How's today?" : "Logging an earlier day."
    }

    private var saveLabel: String {
        isSaving ? "Saving…" : "Save"
    }

    // MARK: - Flow

    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            CapsLabel(text: "Flow")
                .padding(.top, AsteraSpacing.lg)
                .padding(.bottom, AsteraSpacing.sm)

            Hairline()
            flowRow(label: "no flow today", subtitle: "Nothing to log.", selected: draft.flow == nil) {
                draft.flow = nil
            }
            Hairline()
            ForEach(FlowIntensity.allCases, id: \.self) { intensity in
                flowRow(
                    label: intensity.lowercaseName,
                    subtitle: flowDescription(for: intensity),
                    selected: draft.flow == intensity,
                    action: { draft.flow = intensity }
                )
                Hairline()
            }
        }
        .padding(.bottom, AsteraSpacing.lg)
    }

    private func flowRow(label: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AsteraSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if selected {
                            Circle().fill(AsteraColor.accent).frame(width: 6, height: 6)
                        }
                        Text(label)
                            .font(.asteraSerif(19, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? AsteraColor.ink : AsteraColor.ink.opacity(0.78))
                    }
                    Text(subtitle)
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.iron)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.vertical, AsteraSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func flowDescription(for intensity: FlowIntensity) -> String {
        switch intensity {
        case .spotting: return "A trace. Not full flow."
        case .light: return "Most of the day on one pad, tampon, or cup."
        case .medium: return "Changing every few hours."
        case .heavy: return "Soaking through quickly. Worth keeping track of."
        }
    }

    // MARK: - Symptoms

    private var hideSexual: Bool {
        if let p = profiles.first, AgeMode.hideSexualContent(birthYear: p.birthYear) { return true }
        return !showSexualActivity
    }

    private func visibleCategories(_ list: [SymptomCategory]) -> [SymptomCategory] {
        hideSexual ? list.filter { !$0.isSexualActivity } : list
    }

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "How you feel")
            symptomGrid(categories: visibleCategories(SymptomCategory.symptoms), severityEnabled: true)
            Text("Tap to add. Tap again to set how strong: one dot mild, two moderate, three severe.")
                .font(.asteraSerifItalic(13))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var cravingsSection: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Cravings")
            symptomGrid(categories: SymptomCategory.cravings, severityEnabled: false)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var miscSection: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Anything else")
            symptomGrid(categories: visibleCategories(SymptomCategory.miscellaneous), severityEnabled: false)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private func symptomGrid(categories: [SymptomCategory], severityEnabled: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: severityEnabled ? 130 : 110), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(categories, id: \.self) { cat in
                LogChip(
                    label: cat.lowercaseName,
                    severity: draft.symptoms[cat],
                    severityEnabled: severityEnabled,
                    onTap: { cycle(cat, severityEnabled: severityEnabled) }
                )
            }
        }
    }

    private func cycle(_ cat: SymptomCategory, severityEnabled: Bool) {
        let current = draft.symptoms[cat]
        if !severityEnabled {
            if current == nil {
                draft.symptoms[cat] = .mild
            } else {
                draft.symptoms.removeValue(forKey: cat)
            }
            return
        }
        switch current {
        case .none: draft.symptoms[cat] = .mild
        case .some(.mild): draft.symptoms[cat] = .moderate
        case .some(.moderate): draft.symptoms[cat] = .severe
        case .some(.severe): draft.symptoms.removeValue(forKey: cat)
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Notes")
            ZStack(alignment: .topLeading) {
                if draft.notes.isEmpty {
                    Text("Anything else worth keeping?")
                        .font(.asteraSerifItalic(16))
                        .foregroundStyle(AsteraColor.iron)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
                TextField("", text: $draft.notes, axis: .vertical)
                    .font(.asteraSerifItalic(16))
                    .foregroundStyle(AsteraColor.ink)
                    .tint(AsteraColor.accent)
                    .lineLimit(3...8)
                    .padding(.vertical, 4)
            }
            .frame(minHeight: 80, alignment: .topLeading)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    // MARK: - Persistence helpers

    private func loadExisting() {
        let existing = LogService.currentLog(forDay: date, context: modelContext)
        if existing.hasAnyContent {
            draft = existing
        } else {
            draft = LogInput(date: date, flow: nil, symptoms: [:], notes: "")
        }
    }

    private func save() {
        isSaving = true
        let mode = profiles.first?.cycleMode ?? .regular
        do {
            let cycle = try LogService.apply(draft, defaultMode: mode, context: modelContext)
            mirrorToHealthIfEnabled(cycle: cycle)
            onSaved(cycle)
        } catch {
            isSaving = false
        }
    }

    private func mirrorToHealthIfEnabled(cycle: Cycle?) {
        guard syncToHealth else { return }
        let calendar = Calendar.current
        let isCycleStart: Bool
        if let cycleStart = cycle?.startDate {
            isCycleStart = calendar.isDate(cycleStart, inSameDayAs: date)
        } else {
            isCycleStart = false
        }
        let intensity = draft.flow
        let day = date
        Task.detached {
            try? await HealthKitService.writeFlow(intensity: intensity, on: day, isCycleStart: isCycleStart)
        }
    }
}

/// One chip in the log sheet. Binary tap when `severityEnabled == false`; otherwise
/// taps cycle off → mild → moderate → severe → off and render dots accordingly.
private struct LogChip: View {
    let label: String
    let severity: SymptomSeverity?
    let severityEnabled: Bool
    let onTap: () -> Void

    private var isSelected: Bool { severity != nil }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.asteraSerif(15, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? AsteraColor.vellum : AsteraColor.ink.opacity(0.85))
                if severityEnabled, isSelected {
                    severityDots
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? AsteraColor.ink : Color.clear)
                    .overlay(
                        Capsule()
                            .strokeBorder(isSelected ? Color.clear : AsteraColor.hairline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityHint(Text(severityEnabled ? "Double tap to cycle severity from mild to severe and off." : "Double tap to toggle."))
    }

    private var accessibilityValue: String {
        guard severityEnabled, let severity else { return isSelected ? "logged" : "not logged" }
        switch severity {
        case .mild: return "mild"
        case .moderate: return "moderate"
        case .severe: return "severe"
        }
    }

    @ViewBuilder
    private var severityDots: some View {
        let level = severity?.rawValue ?? 0
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Circle()
                    .fill(i <= level ? AsteraColor.vellum : AsteraColor.vellum.opacity(0.28))
                    .frame(width: 4, height: 4)
            }
        }
    }
}
