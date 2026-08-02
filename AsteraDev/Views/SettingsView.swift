import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKey.requiresAppLock.rawValue) private var requiresAppLock: Bool = false
    @AppStorage(AppStorageKey.showInCalendar.rawValue) private var showInCalendar: Bool = false
    @AppStorage(AppStorageKey.includePastPeriodsInCalendar.rawValue) private var includePastPeriodsInCalendar: Bool = false
    @AppStorage(AppStorageKey.syncToHealth.rawValue) private var syncToHealth: Bool = false
    @AppStorage(AppStorageKey.notifyPeriodInThreeDays.rawValue) private var notifyPeriodInThreeDays: Bool = false
    @AppStorage(AppStorageKey.notifyPeriodToday.rawValue) private var notifyPeriodToday: Bool = false
    @AppStorage(AppStorageKey.showSexualActivity.rawValue) private var showSexualActivity: Bool = false
    @AppStorage(AppStorageKey.showCravingsLogging.rawValue) private var showCravingsLogging: Bool = false
    @AppStorage(AppStorageKey.showSymptomsLogging.rawValue) private var showSymptomsLogging: Bool = true
    @AppStorage(AppStorageKey.showLifestyleLogging.rawValue) private var showLifestyleLogging: Bool = false
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Cycle.startDate, order: .reverse) private var cycles: [Cycle]

    @State private var lockAttemptFailed = false
    @State private var calendarFailed = false
    @State private var calendarPending = false
    @State private var healthFailed = false
    @State private var healthPending = false
    @State private var notificationsDenied = false
    @State private var notificationsPending = false
    @State private var isExporting = false
    @State private var exportFileURL: URLWrapper?
    @State private var showEraseConfirm = false
    @State private var isErasing = false
    @State private var editingField: ProfileField?
    @State private var showPrivacyPolicy = false
    @State private var showAsteraPlus = false
    @State private var asteraPlus = AsteraPlusService.shared
    @State private var importPending = false
    @State private var importResult: HealthKitImportService.Result?
    @State private var importFailed = false
    @State private var choosingCalendar = false
    /// Held in state rather than read inline. Resolving it opens an `EKEventStore` and looks the
    /// calendar up by identifier, which is not something to do on every body evaluation.
    @State private var calendarDestinationName = CalendarSyncService.calendarTitle

    private var profile: UserProfile? { profiles.first }
    private var biometry: AppLockService.BiometryKind { AppLockService.availableBiometry }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AsteraSpacing.xl) {
                header
                    .padding(.top, AsteraSpacing.lg)

                aboutYouSection
                loggingSection
                bringHistorySection
                lockSection
                calendarSection
                healthSection
                notificationsSection
                syncSection
                yourDataSection
                asteraPlusSection
                promiseSection

                Spacer(minLength: AsteraSpacing.xl)
            }
            .asteraEditorialMargins()
            .padding(.bottom, AsteraSpacing.xl)
        }
        .asteraScreen()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsLabel(text: "Astera · settings")
            Text("Settle in.")
                .font(.asteraSerif(34, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text("Change anything you'd like. Nothing you've logged is ever deleted unless you ask.")
                .font(.asteraSerifItalic(15))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }

    // MARK: - About you

    private var aboutYouSection: some View {
        section(title: "About you") {
            VStack(alignment: .leading, spacing: 0) {
                editableRow(label: "We call you", value: pronounsValue, field: .pronouns)
                editableRow(label: "Greeting", value: profile?.homeGreeting ?? "Hello.", field: .salutation)
                editableRow(label: "Tracking with", value: relationshipValue, field: .relationship)
                editableRow(label: "Cycles right now", value: profile?.cycleMode.displayName.lowercased() ?? "not sure", field: .cycleMode)
                editableRow(label: "Born", value: profile.map { String($0.birthYear) } ?? "not set", field: .birthYear)
            }
        }
        .sheet(isPresented: $choosingCalendar) {
            CalendarDestinationPicker(
                selected: CalendarSyncService.destinationIdentifier(),
                onChoose: { identifier in
                    choosingCalendar = false
                    moveCalendarDestination(to: identifier)
                },
                onCancel: { choosingCalendar = false }
            )
            .ignoresSafeArea()
        }
        .task { calendarDestinationName = CalendarSyncService.destinationName() }
        .sheet(item: $editingField) { field in
            if let profile {
                ProfileEditSheet(field: field, profile: profile, onDismiss: { editingField = nil })
            }
        }
    }

    private func editableRow(label: String, value: String, field: ProfileField) -> some View {
        Button {
            editingField = field
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.asteraSerifItalic(15))
                    .foregroundStyle(AsteraColor.iron)
                Spacer(minLength: AsteraSpacing.md)
                Text(value)
                    .font(.asteraSerif(17, weight: .regular))
                    .foregroundStyle(AsteraColor.ink)
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AsteraColor.iron.opacity(0.4))
            }
            .padding(.vertical, AsteraSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(profile == nil)
        .accessibilityIdentifier("settings.profile.\(field.rawValue)")
    }

    private var pronounsValue: String {
        guard let profile else { return Pronouns.theyThem.summary }
        if profile.pronouns == .custom, let custom = profile.customPronouns, !custom.isEmpty {
            return custom
        }
        return profile.pronouns.summary
    }

    private var relationshipValue: String {
        (profile?.relationshipStructure ?? .single).summary
    }

    // MARK: - Lock

    // MARK: - Logging preferences

    private var hideSexualForTeen: Bool {
        guard let p = profile else { return false }
        return AgeMode.hideSexualContent(birthYear: p.birthYear)
    }

    private func logToggle(identifier: String, title: String, isOn: Binding<Bool>, body: String) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.asteraSerif(17, weight: .regular))
                    .foregroundStyle(AsteraColor.ink)
                Text(body)
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(AsteraColor.accent)
        .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    private var loggingSection: some View {
        section(title: "What you log") {
            VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
                Text("Pick what to track. Turn off anything that doesn't fit your day. You can change this any time.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                logToggle(
                    identifier: "settings.log.symptoms",
                    title: "Symptoms",
                    isOn: $showSymptomsLogging,
                    body: "Cramps, mood, sleep, headaches, skin, the works. The richest signal you can give Astera."
                )

                logToggle(
                    identifier: "settings.log.lifestyle",
                    title: "Lifestyle",
                    isOn: $showLifestyleLogging,
                    body: "Exercise, alcohol, caffeine, travel, illness, medication, stress. Useful for spotting what might be moving your cycle around."
                )

                logToggle(
                    identifier: "settings.log.cravings",
                    title: "Cravings and appetite",
                    isOn: $showCravingsLogging,
                    body: "Sweet, salty, chocolate, carbs, savory, low appetite. Off by default. Anyone navigating an eating disorder may prefer to keep food out of cycle tracking entirely."
                )

                if !hideSexualForTeen {
                    logToggle(
                        identifier: "settings.log.sexualActivity",
                        title: "Sexual activity",
                        isOn: $showSexualActivity,
                        body: "Adds sex, protected sex, and painful sex. Useful for fertility tracking, intimacy patterns, or pain."
                    )
                }
            }
        }
    }

    // MARK: - Bring history with you (import from Apple Health)

    @ViewBuilder
    private var bringHistorySection: some View {
        if HealthKitService.isAvailable {
            section(title: "Bring history with you") {
                VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                    Text("If you've been using Flo, Clue, Stardust, Apple Health, or anything that writes to Apple Health, Astera can pull your cycle history across so you don't start from scratch.")
                        .font(.asteraSerifItalic(14))
                        .foregroundStyle(AsteraColor.iron)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: runImport) {
                        HStack {
                            Text(importPending ? "Looking…" : "Import from Apple Health")
                                .font(.asteraSerif(17, weight: .medium))
                            Spacer()
                            if !importPending {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundStyle(AsteraColor.vellum)
                        .padding(.vertical, 16)
                        .padding(.horizontal, AsteraSpacing.lg)
                        .background(Capsule().fill(AsteraColor.ink))
                    }
                    .buttonStyle(.plain)
                    .disabled(importPending)
                    .accessibilityIdentifier("settings.health.import")

                    if let result = importResult {
                        importResultView(result)
                    } else if importFailed {
                        Text("Apple Health didn't give us access. Open the Health app, then Sharing → Apps and Services → Astera, and allow menstrual flow.")
                            .font(.asteraSerifItalic(13))
                            .foregroundStyle(AsteraColor.accent)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("settings.health.importDenied")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func importResultView(_ result: HealthKitImportService.Result) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !result.didFindAnything {
                Text("Apple Health doesn't have any menstrual flow yet. If you're on another tracker, ask it to write to Apple Health, then come back.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            } else if result.daysImported == 0 {
                // Not "Astera has every day Apple Health has": days Apple Health records with an
                // unspecified intensity are skipped on the way in, so that would not be true.
                Text("Already up to date. Nothing new to bring across.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            } else {
                Text(welcomeOverText(result))
                    .font(.asteraSerif(15, weight: .regular))
                    .foregroundStyle(AsteraColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
                Text("You can re-run this any time. Astera never overwrites days you've already logged.")
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
    }

    private func welcomeOverText(_ result: HealthKitImportService.Result) -> String {
        let daysLine = "\(result.daysImported) bleed day\(result.daysImported == 1 ? "" : "s") brought in"
        let cyclesLine = result.cyclesAdded > 0 ? " across \(result.cyclesAdded) cycle\(result.cyclesAdded == 1 ? "" : "s")" : ""
        let sourceLine: String
        let cleaned = result.sourceNames.filter { !$0.localizedCaseInsensitiveContains("astera") }
        if cleaned.isEmpty {
            sourceLine = ""
        } else if cleaned.count == 1 {
            sourceLine = " from \(cleaned[0])"
        } else if cleaned.count == 2 {
            sourceLine = " from \(cleaned[0]) and \(cleaned[1])"
        } else {
            sourceLine = " from \(cleaned.dropLast().joined(separator: ", ")), and \(cleaned.last!)"
        }
        return "\(daysLine)\(cyclesLine)\(sourceLine). Welcome over."
    }

    private func runImport() {
        guard let profile else { return }
        importFailed = false
        importPending = true
        importResult = nil
        let mode = profile.cycleMode
        Task { @MainActor in
            do {
                let result = try await HealthKitImportService.runImport(defaultMode: mode, context: modelContext)
                importPending = false
                // An empty result now means Apple Health is genuinely empty. A refusal throws.
                importResult = result
            } catch {
                importPending = false
                importFailed = true
            }
        }
    }

    private var lockSection: some View {
        section(title: "A little extra privacy") {
            VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                Toggle(isOn: lockBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lockToggleTitle)
                            .font(.asteraSerif(17, weight: .regular))
                            .foregroundStyle(AsteraColor.ink)
                        Text(lockToggleSubtitle)
                            .font(.asteraSerifItalic(14))
                            .foregroundStyle(AsteraColor.iron)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(AsteraColor.accent)
                .disabled(biometry == .unavailable)

                if lockAttemptFailed {
                    Text("That didn't go through. You can try again, or skip this for now.")
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var lockBinding: Binding<Bool> {
        Binding(
            get: { requiresAppLock },
            set: { wantsOn in
                if wantsOn {
                    attemptEnableLock()
                } else {
                    requiresAppLock = false
                    lockAttemptFailed = false
                }
            }
        )
    }

    private var lockToggleTitle: String { biometry.lockToggleLabel }

    private var lockToggleSubtitle: String {
        switch biometry {
        case .faceID, .touchID, .opticID:
            return "Astera asks for \(biometry.humanName), or your phone's passcode, every time you open it."
        case .passcodeOnly:
            return "Astera asks for your phone's passcode every time you open it."
        case .unavailable:
            return "Set a passcode on your phone first, then come back."
        }
    }

    private func attemptEnableLock() {
        lockAttemptFailed = false
        Task { @MainActor in
            let ok = await AppLockService.authenticate(
                reason: "Confirm with \(biometry.humanName) to turn on the lock."
            )
            if ok {
                requiresAppLock = true
            } else {
                requiresAppLock = false
                lockAttemptFailed = true
            }
        }
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        section(title: "Show in your Calendar") {
            VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                Toggle(isOn: calendarBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add your periods to a calendar")
                            .font(.asteraSerif(17, weight: .regular))
                            .foregroundStyle(AsteraColor.ink)
                        Text("Adds your next predicted period to a calendar. Astera makes its own by default, separate from your other ones. It updates whenever your pattern changes, and never touches anything else.")
                            .font(.asteraSerifItalic(14))
                            .foregroundStyle(AsteraColor.iron)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(AsteraColor.accent)
                .disabled(calendarPending)
                .accessibilityIdentifier("settings.calendar.toggle")

                // Hidden without full access rather than shown disabled. "Add Events Only" is a
                // reasonable answer to the permission prompt, and it genuinely cannot list your
                // calendars, so there is nothing to choose from and no wrong to put right.
                if showInCalendar && CalendarSyncService.canChooseDestination {
                    Hairline()
                    Button {
                        choosingCalendar = true
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Write to")
                                    .font(.asteraSerif(17, weight: .regular))
                                    .foregroundStyle(AsteraColor.ink)
                                Text("Its own calendar by default. Pick one of yours if you would rather it sat alongside everything else. Astera only ever touches the events it wrote.")
                                    .font(.asteraSerifItalic(14))
                                    .foregroundStyle(AsteraColor.iron)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: AsteraSpacing.md)
                            Text(calendarDestinationName)
                                .font(.asteraSerif(17, weight: .regular))
                                .foregroundStyle(AsteraColor.ink)
                                .multilineTextAlignment(.trailing)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(AsteraColor.iron.opacity(0.4))
                        }
                        .padding(.vertical, AsteraSpacing.sm)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.calendar.destination")
                }

                // Only offered once the calendar is on, because it is meaningless before that,
                // and off by default. History in a calendar is a different disclosure from a
                // forecast: it can be read by anyone the calendar is shared with, and it says
                // when you bled for as long as you have been logging.
                if showInCalendar {
                    Hairline()
                    Toggle(isOn: pastPeriodsBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Include your past periods too")
                                .font(.asteraSerif(17, weight: .regular))
                                .foregroundStyle(AsteraColor.ink)
                            Text("Off by default. Turning it on adds every period you've logged, as all-day events. Useful if you want the whole picture in one place, worth a thought if this calendar is shared with anyone.")
                                .font(.asteraSerifItalic(14))
                                .foregroundStyle(AsteraColor.iron)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(AsteraColor.accent)
                    .accessibilityIdentifier("settings.calendar.includePast")
                }

                if calendarFailed {
                    Text("Calendar access wasn't given. Open the Settings app → Astera → Calendars to allow it.")
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.accent)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("settings.calendar.denied")
                }
            }
        }
    }

    /// Turning this off has to remove the past events already written, not just stop writing new
    /// ones. `syncCurrentPrediction` replaces everything Astera owns on each run, so re-syncing
    /// with the flag off is what takes them back out.
    private var pastPeriodsBinding: Binding<Bool> {
        Binding(
            get: { includePastPeriodsInCalendar },
            set: { wantsOn in
                includePastPeriodsInCalendar = wantsOn
                syncCurrentPrediction()
            }
        )
    }

    /// Moves Astera's events to a different calendar, taking them out of the old one first.
    ///
    /// The name is re-read from the store afterwards rather than assumed, so a calendar that has
    /// gone missing between the picker closing and the write shows the fallback it will actually
    /// use instead of the one you tapped.
    private func moveCalendarDestination(to identifier: String?) {
        Task { @MainActor in
            // Awaited, not fired alongside: the move clears the old calendar and repoints the
            // destination, and a sync that overtook it would write the new events into the
            // calendar we are trying to leave.
            let name = await Task.detached {
                try? CalendarSyncService.moveDestination(to: identifier)
                return CalendarSyncService.destinationName()
            }.value
            calendarDestinationName = name
            syncCurrentPrediction()
        }
    }

    private var calendarBinding: Binding<Bool> {
        Binding(
            get: { showInCalendar },
            set: { wantsOn in
                if wantsOn {
                    enableCalendar()
                } else {
                    disableCalendar()
                }
            }
        )
    }

    private func enableCalendar() {
        calendarFailed = false
        calendarPending = true
        Task { @MainActor in
            let auth = await CalendarSyncService.requestAccess()
            calendarPending = false
            switch auth {
            case .granted:
                showInCalendar = true
                syncCurrentPrediction()
            case .writeOnly:
                showInCalendar = true
                syncCurrentPrediction()
            case .denied, .restricted, .notRequested:
                showInCalendar = false
                calendarFailed = true
            }
        }
    }

    private func disableCalendar() {
        showInCalendar = false
        calendarFailed = false
        Task.detached {
            try? CalendarSyncService.clearEvents()
        }
    }

    @MainActor
    private func syncCurrentPrediction() {
        let prediction = BayesianPredictor.predict(
            lastStart: cycles.first?.startDate,
            observedLengths: cycles.observedLengths,
            cycleMode: profile?.cycleMode ?? .notSure
        )
        let payload = CalendarSyncService.makePayload(
            cycles: Array(cycles),
            prediction: prediction,
            includePastPeriods: includePastPeriodsInCalendar
        )
        Task.detached {
            try? CalendarSyncService.sync(payload)
        }
    }

    // MARK: - Apple Health

    private var healthSection: some View {
        section(title: "In Apple Health") {
            VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                Toggle(isOn: healthBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Write flow to Apple Health")
                            .font(.asteraSerif(17, weight: .regular))
                            .foregroundStyle(AsteraColor.ink)
                        Text(healthSubtitle)
                            .font(.asteraSerifItalic(14))
                            .foregroundStyle(AsteraColor.iron)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(AsteraColor.accent)
                .disabled(healthPending || !HealthKitService.isAvailable)
                .accessibilityIdentifier("settings.health.toggle")

                if healthFailed {
                    Text("Apple Health access wasn't given. Open the Health app → Sharing → Apps and Services → Astera to allow it.")
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.accent)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("settings.health.denied")
                }
            }
        }
    }

    private var healthSubtitle: String {
        if !HealthKitService.isAvailable {
            return "Apple Health isn't available on this device."
        }
        return "What you log here also goes into Apple Health, so it lives alongside your other health data. We don't read anything else."
    }

    private var healthBinding: Binding<Bool> {
        Binding(
            get: { syncToHealth },
            set: { wantsOn in
                if wantsOn {
                    enableHealth()
                } else {
                    syncToHealth = false
                    healthFailed = false
                }
            }
        )
    }

    private func enableHealth() {
        healthFailed = false
        healthPending = true
        Task { @MainActor in
            let ok = await HealthKitService.requestAccess()
            healthPending = false
            if ok {
                syncToHealth = true
                backfillHealthFromExisting()
            } else {
                syncToHealth = false
                healthFailed = true
            }
        }
    }

    @MainActor
    private func backfillHealthFromExisting() {
        // Push every existing FlowEntry (most recent 90 days) into Apple Health so the user's history travels with the toggle.
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let allFlow = (try? modelContext.fetch(FetchDescriptor<FlowEntry>())) ?? []
        let recent = allFlow.filter { $0.day >= cutoff }
        let snapshots: [(intensity: FlowIntensity, day: Date, isCycleStart: Bool)] = recent.map {
            let isCycleStart = $0.cycle.map { Calendar.current.isDate($0.startDate, inSameDayAs: $0.flowEntries?.first(where: { _ in true }).map(\.day) ?? Date()) } ?? false
            return ($0.intensity, $0.day, isCycleStart)
        }
        Task.detached {
            for snap in snapshots {
                try? await HealthKitService.writeFlow(intensity: snap.intensity, on: snap.day, isCycleStart: snap.isCycleStart)
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        section(title: "Quiet reminders") {
            VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                Text("At most a couple a cycle.")
                    .font(.asteraSerif(17))
                    .foregroundStyle(AsteraColor.ink)
                Text("Each one is shown in full before you turn it on. We don't send anything we wouldn't want to read ourselves.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                notificationCategoryRow(
                    category: .periodInThreeDays,
                    binding: notify3DaysBinding,
                    identifier: "settings.notifications.threeDays"
                )
                Hairline()
                notificationCategoryRow(
                    category: .periodToday,
                    binding: notifyTodayBinding,
                    identifier: "settings.notifications.today"
                )

                if notificationsDenied {
                    Text("System notifications are turned off for Astera. Open the Settings app → Astera → Notifications to allow them.")
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.accent)
                        .padding(.top, AsteraSpacing.sm)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("settings.notifications.denied")
                }
            }
        }
    }

    private func notificationCategoryRow(
        category: NotificationCategory,
        binding: Binding<Bool>,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            Toggle(isOn: binding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.humanTitle)
                        .font(.asteraSerif(17, weight: .regular))
                        .foregroundStyle(AsteraColor.ink)
                    Text(category.explainer)
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.iron)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(AsteraColor.accent)
            .disabled(notificationsPending)
            .accessibilityIdentifier(identifier)

            HStack(alignment: .top, spacing: AsteraSpacing.sm) {
                Circle().fill(AsteraColor.accent.opacity(0.4)).frame(width: 6, height: 6)
                Text("\u{201C}\(category.previewBody)\u{201D}")
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .padding(.leading, 2)
        }
        .padding(.vertical, AsteraSpacing.sm)
    }

    private var notify3DaysBinding: Binding<Bool> {
        Binding(
            get: { notifyPeriodInThreeDays },
            set: { wantsOn in
                if wantsOn {
                    enableNotifications { notifyPeriodInThreeDays = true }
                } else {
                    notifyPeriodInThreeDays = false
                    rescheduleNotifications()
                }
            }
        )
    }

    private var notifyTodayBinding: Binding<Bool> {
        Binding(
            get: { notifyPeriodToday },
            set: { wantsOn in
                if wantsOn {
                    enableNotifications { notifyPeriodToday = true }
                } else {
                    notifyPeriodToday = false
                    rescheduleNotifications()
                }
            }
        )
    }

    private func enableNotifications(after grant: @escaping () -> Void) {
        notificationsDenied = false
        notificationsPending = true
        Task { @MainActor in
            let status = await NotificationsService.requestAuthorization()
            notificationsPending = false
            switch status {
            case .authorized, .provisional, .ephemeral:
                grant()
                rescheduleNotifications()
            case .denied, .notDetermined:
                notificationsDenied = true
            @unknown default:
                notificationsDenied = true
            }
        }
    }

    @MainActor
    private func rescheduleNotifications() {
        var enabled: Set<NotificationCategory> = []
        if notifyPeriodInThreeDays { enabled.insert(.periodInThreeDays) }
        if notifyPeriodToday { enabled.insert(.periodToday) }
        let prediction = BayesianPredictor.predict(
            lastStart: cycles.first?.startDate,
            observedLengths: cycles.observedLengths,
            cycleMode: profile?.cycleMode ?? .notSure
        )
        Task.detached {
            await NotificationsService.reschedule(prediction: prediction, enabledCategories: enabled)
        }
    }

    // MARK: - Sync

    private var syncSection: some View {
        section(title: "Between your devices") {
            VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                Text("Your cycles travel with you.")
                    .font(.asteraSerif(17))
                    .foregroundStyle(AsteraColor.ink)
                Text("If you're signed into iCloud on this phone, your data backs up there automatically: into your own iCloud, encrypted by Apple, invisible to us. Sign into the same iCloud on another iPhone or iPad and it shows up there too. If you're not signed in, the app works just the same on this phone alone.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Your data

    private var yourDataSection: some View {
        section(title: "Your data") {
            VStack(spacing: 0) {
                exportRow
                Hairline()
                deleteRow
            }
        }
        .confirmationDialog(
            "Delete everything?",
            isPresented: $showEraseConfirm,
            titleVisibility: .visible
        ) {
            Button("Yes, delete everything", role: .destructive) {
                Task { @MainActor in
                    isErasing = true
                    await EraseService.eraseEverything(context: modelContext)
                    isErasing = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every cycle, symptom, and note you've logged on this device will be gone. Anything we've added to your Calendar will be removed. There's no undo. Your Apple Health data is separate; manage it from the Health app.")
        }
        .sheet(item: $exportFileURL) { wrapper in
            ExportShareView(url: wrapper.url, onDismiss: { exportFileURL = nil })
        }
    }

    private var exportRow: some View {
        Button {
            buildAndShareExport()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Take a copy with you")
                        .font(.asteraSerif(17, weight: .regular))
                        .foregroundStyle(AsteraColor.ink)
                    Spacer()
                    if isExporting {
                        ProgressView().tint(AsteraColor.accent)
                    } else {
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AsteraColor.accent)
                    }
                }
                Text("Saves a clean PDF of every cycle, symptom, and note you've logged. Open it in any reader, print it, or send it to your clinician. It's yours.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AsteraSpacing.md)
        }
        .buttonStyle(.plain)
        .disabled(isExporting)
        .accessibilityIdentifier("settings.data.export")
    }

    private var deleteRow: some View {
        Button {
            showEraseConfirm = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Delete everything")
                        .font(.asteraSerif(17, weight: .regular))
                        .foregroundStyle(AsteraColor.accent)
                    Spacer()
                    if isErasing {
                        ProgressView().tint(AsteraColor.accent)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AsteraColor.accent)
                    }
                }
                Text("Wipes everything on this phone: every cycle, symptom, note, and setting. Anything we added to your Calendar goes too. Once it's done, it's gone. By design, there's no recovery.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AsteraSpacing.md)
        }
        .buttonStyle(.plain)
        .disabled(isErasing)
        .accessibilityIdentifier("settings.data.delete")
    }

    private func buildAndShareExport() {
        isExporting = true
        Task { @MainActor in
            defer { isExporting = false }
            do {
                let export = try ExportService.buildExport(context: modelContext)
                let pdfData = PDFExportService.buildPDF(export)
                let url = try PDFExportService.writeToTempFile(pdfData, exportedAt: export.exportedAt)
                exportFileURL = URLWrapper(url: url)
            } catch {
                // Silent failure for v1; could surface an error toast later.
            }
        }
    }

    // MARK: - Astera+

    private var asteraPlusSection: some View {
        section(title: "Astera+") {
            Button {
                showAsteraPlus = true
            } label: {
                VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(asteraPlus.hasAsteraPlus ? "Astera+ is active." : "Optional support.")
                            .font(.asteraSerif(17, weight: .regular))
                            .foregroundStyle(AsteraColor.ink)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(AsteraColor.iron.opacity(0.4))
                    }
                    Text(asteraPlus.hasAsteraPlus
                         ? "Thank you. All Astera+ extras are unlocked. Manage from the App Store."
                         : "The tracker is free, always. If you'd like to chip in toward keeping it that way, and happen to want a few extras, this is where to do it. Tap to see what you'd get.")
                        .font(.asteraSerifItalic(14))
                        .foregroundStyle(AsteraColor.iron)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.asteraPlus")
        }
        .sheet(isPresented: $showAsteraPlus) {
            AsteraPlusView(onDismiss: { showAsteraPlus = false })
        }
    }

    // MARK: - The promise

    private var promiseSection: some View {
        section(title: "The promise") {
            VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                Text("Astera doesn't collect anything.")
                    .font(.asteraSerif(17))
                    .foregroundStyle(AsteraColor.ink)
                Text("No analytics. No ads. No account to make. No third-party anything. Your data lives on this phone and, if you want, in your own iCloud. We can't read it. If this ever changes you have every right to walk away with all of your data and call us out.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    showPrivacyPolicy = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Read the full promise")
                            .font(.asteraSerifItalic(15))
                            .underline(true, color: AsteraColor.accent.opacity(0.4))
                            .foregroundStyle(AsteraColor.accent)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AsteraColor.accent)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, AsteraSpacing.xs)

                HStack(spacing: 6) {
                    Circle().fill(AsteraColor.accent.opacity(0.4)).frame(width: 6, height: 6)
                    Text("Astera · version \(Self.appVersion)")
                        .font(.asteraCaps(11))
                        .tracking(1.4)
                        .foregroundStyle(AsteraColor.iron)
                }
                .padding(.top, AsteraSpacing.md)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView(onDismiss: { showPrivacyPolicy = false })
        }
    }

    // MARK: - Shared chrome

    /// Reads the shipping version out of the bundle so the footer can never contradict the
    /// build a reviewer is looking at.
    private static var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    private func section<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            Hairline()
            CapsLabel(text: title)
                .padding(.top, AsteraSpacing.sm)
            content()
        }
    }
}

struct URLWrapper: Identifiable {
    let url: URL
    var id: URL { url }
}

struct ExportShareView: View {
    let url: URL
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
            HStack {
                Button("Done", action: onDismiss)
                    .buttonStyle(AsteraGhostButtonStyle())
                    .accessibilityIdentifier("export.done")
                Spacer()
            }
            VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                CapsLabel(text: "Your export · ready")
                Text("Saved.")
                    .font(.asteraSerif(28, weight: .medium))
                    .foregroundStyle(AsteraColor.ink)
                Text("Open the file or share it from here. It's a PDF any reader can open, and you can print it or send it to a clinician.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ShareLink(item: url) {
                HStack {
                    Text("Share or save the file")
                        .font(.asteraSerif(17, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(AsteraColor.vellum)
                .padding(.vertical, 18)
                .padding(.horizontal, AsteraSpacing.lg)
                .background(Capsule().fill(AsteraColor.ink))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .asteraEditorialMargins()
        .padding(.top, AsteraSpacing.md)
        .padding(.bottom, AsteraSpacing.xl)
        .asteraScreen()
    }
}
