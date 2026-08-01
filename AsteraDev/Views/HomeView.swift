import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKey.showInCalendar.rawValue) private var showInCalendar: Bool = false
    @AppStorage(AppStorageKey.includePastPeriodsInCalendar.rawValue) private var includePastPeriodsInCalendar: Bool = false
    @AppStorage(AppStorageKey.notifyPeriodInThreeDays.rawValue) private var notifyPeriodInThreeDays: Bool = false
    @AppStorage(AppStorageKey.notifyPeriodToday.rawValue) private var notifyPeriodToday: Bool = false
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Cycle.startDate, order: .reverse) private var cycles: [Cycle]
    @Query(sort: \FlowEntry.day, order: .reverse) private var flowEntries: [FlowEntry]
    @Query(sort: \SymptomEntry.day, order: .reverse) private var symptomEntries: [SymptomEntry]

    @State private var showLogSheet = false
    @State private var showWhySheet = false
    @State private var editingCycleMode = false
    @State private var didOpenInitialSheet = false

    private var profile: UserProfile? { profiles.first }
    private var latestCycle: Cycle? { cycles.first }

    private var prediction: PeriodPrediction {
        BayesianPredictor.predict(
            lastStart: latestCycle?.startDate,
            observedLengths: cycles.observedLengths,
            cycleMode: profile?.cycleMode ?? .notSure
        )
    }

    private var cycleDay: Int? {
        SimplePredictor.cycleDay(for: latestCycle?.startDate)
    }

    private var todayFlow: FlowIntensity? {
        let calendar = Calendar.current
        return flowEntries.first { calendar.isDateInToday($0.day) }?.intensity
    }

    private var todaySymptoms: [SymptomCategory] {
        let calendar = Calendar.current
        return symptomEntries
            .filter { calendar.isDateInToday($0.day) && $0.category != .other }
            .map(\.category)
    }

    private var todayHasContent: Bool {
        todayFlow != nil || !todaySymptoms.isEmpty
    }

    private var activeMode: CycleMode { profile?.cycleMode ?? .notSure }

    var body: some View {
        Group {
            if activeMode == .pregnant {
                PregnantHomeView(
                    profile: profile,
                    latestCycle: latestCycle,
                    onSwitchMode: { editingCycleMode = true }
                )
            } else if activeMode.usesQuietHome {
                QuietHomeView(
                    profile: profile,
                    latestCycle: latestCycle,
                    onShowLog: { showLogSheet = true },
                    onSwitchMode: { editingCycleMode = true }
                )
            } else {
                cycleTrackingHome
            }
        }
        .sheet(isPresented: $showLogSheet) {
            LogSheet(
                date: Date(),
                onCancel: { showLogSheet = false },
                onSaved: { _ in
                    showLogSheet = false
                    syncCalendarIfEnabled()
                }
            )
        }
        .sheet(isPresented: $showWhySheet) {
            WhyThisPredictionSheet(
                prediction: prediction,
                lastStart: latestCycle?.startDate,
                observedLengths: cycles.observedLengths,
                cycleMode: profile?.cycleMode ?? .notSure,
                onDismiss: { showWhySheet = false }
            )
        }
        .sheet(isPresented: $editingCycleMode) {
            if let profile {
                CycleModeEditView(profile: profile, onDismiss: { editingCycleMode = false })
            }
        }
        .onChange(of: cycles.count) { _, _ in
            syncCalendarIfEnabled()
            rescheduleNotificationsIfEnabled()
        }
        .onChange(of: flowEntries.count) { _, _ in
            syncCalendarIfEnabled()
            rescheduleNotificationsIfEnabled()
        }
        .onAppear {
            #if DEBUG
            if !didOpenInitialSheet, ProcessInfo.processInfo.environment["ASTERA_OPEN_SHEET"] == "log" {
                didOpenInitialSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showLogSheet = true
                }
            } else if !didOpenInitialSheet, ProcessInfo.processInfo.environment["ASTERA_OPEN_SHEET"] == "why" {
                didOpenInitialSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showWhySheet = true
                }
            }
            #endif
        }
    }

    private var cycleTrackingHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
                header
                    .padding(.top, AsteraSpacing.md)

                Hairline()

                todayCard

                Hairline()

                nextPeriodCard

                Hairline()

                logSurface
            }
            .asteraEditorialMargins()
            .padding(.bottom, AsteraSpacing.md)
        }
        .asteraScreen()
    }

    @MainActor
    private func syncCalendarIfEnabled() {
        guard showInCalendar else { return }
        let predicts = activeMode.shouldPredictPeriods
        let payload = CalendarSyncService.makePayload(
            cycles: Array(cycles),
            prediction: prediction,
            predictsPeriods: predicts,
            includePastPeriods: includePastPeriodsInCalendar
        )
        Task.detached {
            try? CalendarSyncService.sync(payload)
        }
    }

    @MainActor
    private func rescheduleNotificationsIfEnabled() {
        guard activeMode.shouldPredictPeriods else {
            // Pregnant, post-loss, postpartum, surgical menopause, on T: clear any pending reminders.
            Task.detached { NotificationsService.clearAll() }
            return
        }
        var enabled: Set<NotificationCategory> = []
        if notifyPeriodInThreeDays { enabled.insert(.periodInThreeDays) }
        if notifyPeriodToday { enabled.insert(.periodToday) }
        guard !enabled.isEmpty else { return }
        let currentPrediction = prediction
        Task.detached {
            await NotificationsService.reschedule(prediction: currentPrediction, enabledCategories: enabled)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsLabel(text: Date().formatted(.dateTime.weekday(.wide).day(.defaultDigits).month(.wide)))
            Text(greeting)
                .font(.asteraSerif(34, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
        }
    }

    private var greeting: String {
        profile?.homeGreeting ?? "Hello."
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Today")
            if let cycleDay {
                HStack {
                    Spacer()
                    CyclePhaseRing(
                        cycleDay: cycleDay,
                        cycleLength: estimatedCycleLength
                    )
                    Spacer()
                }
                Text(cycleDayCaption(for: cycleDay))
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            } else {
                Text("No cycle logged yet.")
                    .font(.asteraSerif(22))
                    .foregroundStyle(AsteraColor.ink)
                Text("When your period starts, tap below. That's all it takes to begin.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AsteraSpacing.sm)
    }

    private var estimatedCycleLength: Int {
        let observed = cycles.observedLengths
        guard !observed.isEmpty else { return 28 }
        return Int(Double(observed.reduce(0, +)) / Double(observed.count))
    }

    private func cycleDayCaption(for day: Int) -> String {
        let phase = CyclePhase.phase(forDay: day, in: estimatedCycleLength)
        let startText = latestCycle?.startDate.formatted(.dateTime.day(.defaultDigits).month(.wide)) ?? "your last start"
        switch phase {
        case .menstrual:
            return "Your period. Counting from \(startText)."
        case .follicular:
            return "Follicular phase, often the higher-energy stretch. Counting from \(startText)."
        case .ovulation:
            return "Mid-cycle window. Counting from \(startText)."
        case .luteal:
            return "Luteal phase, the stretch before your next period. Counting from \(startText)."
        }
    }

    private var nextPeriodCard: some View {
        Button {
            showWhySheet = true
        } label: {
            VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                CapsLabel(text: PeriodPrediction.expectedLabel)
                Text(prediction.rangeText)
                    .font(.asteraNumeric(38, weight: .medium))
                    .foregroundStyle(AsteraColor.ink)
                HStack(spacing: 6) {
                    Text(prediction.confidenceLabel)
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.iron)
                    Spacer()
                    Text("why")
                        .font(.asteraSerifItalic(13))
                        .underline(true, color: AsteraColor.accent.opacity(0.4))
                        .foregroundStyle(AsteraColor.accent)
                }
            }
            .padding(.vertical, AsteraSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var logSurface: some View {
        if todayHasContent {
            loggedTodaySummary
        } else {
            logTodayButton
        }
    }

    private var loggedTodaySummary: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Logged today")
            HStack(alignment: .top, spacing: AsteraSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summaryText)
                        .font(.asteraSerif(18, weight: .regular))
                        .foregroundStyle(AsteraColor.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("edit today's log") {
                        showLogSheet = true
                    }
                    .buttonStyle(AsteraLinkButtonStyle())
                }
                Spacer()
            }
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var summaryText: String {
        var parts: [String] = []
        if let flow = todayFlow {
            parts.append("\(flow.lowercaseName) flow")
        }
        if !todaySymptoms.isEmpty {
            let names = todaySymptoms.prefix(3).map(\.lowercaseName).joined(separator: ", ")
            let extra = todaySymptoms.count > 3 ? " + \(todaySymptoms.count - 3) more" : ""
            parts.append(names + extra)
        }
        return parts.joined(separator: " · ")
    }

    private var logTodayButton: some View {
        Button {
            showLogSheet = true
        } label: {
            HStack {
                Text("Log today")
                    .font(.asteraSerif(17, weight: .medium))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(AsteraColor.vellum)
            .padding(.vertical, 18)
            .padding(.horizontal, AsteraSpacing.lg)
            .background(Capsule().fill(AsteraColor.ink))
        }
        .buttonStyle(.plain)
        .padding(.top, AsteraSpacing.sm)
    }
}
