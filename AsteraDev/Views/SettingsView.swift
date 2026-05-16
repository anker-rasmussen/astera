import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKey.requiresAppLock.rawValue) private var requiresAppLock: Bool = false
    @AppStorage(AppStorageKey.showInCalendar.rawValue) private var showInCalendar: Bool = false
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
    }

    private var pronounsValue: String {
        guard let profile else { return "they / them" }
        if profile.pronouns == .custom, let custom = profile.customPronouns, !custom.isEmpty {
            return custom
        }
        switch profile.pronouns {
        case .sheHer: return "she / her"
        case .heHim: return "he / him"
        case .theyThem: return "they / them"
        case .custom: return "your own words"
        }
    }

    private var salutationValue: String {
        profile?.homeGreeting ?? "Hello."
    }

    private var relationshipValue: String {
        switch profile?.relationshipStructure ?? .single {
        case .single: return "solo"
        case .partneredTracking: return "a partner who tracks too"
        case .partneredNotTracking: return "a partner who doesn't"
        case .polyamorous: return "polyamorous"
        }
    }

    // MARK: - Lock

    // MARK: - Logging preferences

    private var hideSexualForTeen: Bool {
        guard let p = profile else { return false }
        return AgeMode.hideSexualContent(birthYear: p.birthYear)
    }

    private func logToggle(title: String, isOn: Binding<Bool>, body: String) -> some View {
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
                    title: "Symptoms",
                    isOn: $showSymptomsLogging,
                    body: "Cramps, mood, sleep, headaches, skin, the works. The richest signal you can give Astera."
                )

                logToggle(
                    title: "Lifestyle",
                    isOn: $showLifestyleLogging,
                    body: "Exercise, alcohol, caffeine, travel, illness, medication, stress. Useful for spotting what might be moving your cycle around."
                )

                logToggle(
                    title: "Cravings and appetite",
                    isOn: $showCravingsLogging,
                    body: "Sweet, salty, chocolate, carbs, savory, low appetite. Off by default. Anyone navigating an eating disorder may prefer to keep food out of cycle tracking entirely."
                )

                if !hideSexualForTeen {
                    logToggle(
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

                    if let result = importResult {
                        importResultView(result)
                    } else if importFailed {
                        Text("Apple Health didn't give us access. Open the Health app, then Sharing → Apps and Services → Astera, and allow menstrual flow.")
                            .font(.asteraSerifItalic(13))
                            .foregroundStyle(AsteraColor.accent)
                            .fixedSize(horizontal: false, vertical: true)
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
                Text("Already up to date. Astera has every day Apple Health has.")
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
                importResult = result
                if !result.didFindAnything && result.samplesFound == 0 {
                    // Could be either no access or genuinely no data; we can't tell the difference
                    // without an explicit auth check, so prefer the gentler "nothing here yet" message
                    // unless the user re-taps and it still fails.
                }
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

    private var lockToggleTitle: String {
        switch biometry {
        case .faceID: return "Lock with Face ID"
        case .touchID: return "Lock with Touch ID"
        case .opticID: return "Lock with Optic ID"
        case .passcodeOnly: return "Lock with your passcode"
        case .unavailable: return "Lock (not available on this phone)"
        }
    }

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
                        Text("Add predicted periods to a calendar")
                            .font(.asteraSerif(17, weight: .regular))
                            .foregroundStyle(AsteraColor.ink)
                        Text("Astera makes one dedicated calendar, separate from your other ones, and adds your next predicted period to it. It updates whenever your pattern changes, and never touches anything else.")
                            .font(.asteraSerifItalic(14))
                            .foregroundStyle(AsteraColor.iron)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(AsteraColor.accent)
                .disabled(calendarPending)

                if calendarFailed {
                    Text("Calendar access wasn't given. Open the Settings app → Astera → Calendars to allow it.")
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
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
        let payload = CalendarSyncService.makePayload(cycles: Array(cycles), prediction: prediction)
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

                if healthFailed {
                    Text("Apple Health access wasn't given. Open the Health app → Sharing → Apps and Services → Astera to allow it.")
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.accent)
                        .fixedSize(horizontal: false, vertical: true)
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

                notificationCategoryRow(category: .periodInThreeDays, binding: notify3DaysBinding)
                Hairline()
                notificationCategoryRow(category: .periodToday, binding: notifyTodayBinding)

                if notificationsDenied {
                    Text("System notifications are turned off for Astera. Open the Settings app → Astera → Notifications to allow them.")
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.accent)
                        .padding(.top, AsteraSpacing.sm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func notificationCategoryRow(category: NotificationCategory, binding: Binding<Bool>) -> some View {
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
                Text("Saves a readable copy of every cycle, symptom and note you've logged. Open it in another app or send it to a doctor. It's yours.")
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
                Text("Removes everything on this phone: cycles, symptoms, notes, settings. Any predicted dates we added to your Calendar go too. Once it's done it's gone, by design.")
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
    }

    private func buildAndShareExport() {
        isExporting = true
        Task { @MainActor in
            defer { isExporting = false }
            do {
                let export = try ExportService.buildExport(context: modelContext)
                let url = try ExportService.writeToTempFile(export)
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
                    Text("Astera · version 0.1 · early days")
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
                Spacer()
            }
            VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                CapsLabel(text: "Your export · ready")
                Text("Saved.")
                    .font(.asteraSerif(28, weight: .medium))
                    .foregroundStyle(AsteraColor.ink)
                Text("Open the file or share it from here. It's a plain-text JSON that any text editor can read.")
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
