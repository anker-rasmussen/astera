import SwiftUI

struct RootView: View {
    @AppStorage(AppStorageKey.hasCompletedOnboarding.rawValue) private var hasCompletedOnboarding: Bool = false
    @AppStorage(AppStorageKey.requiresAppLock.rawValue) private var requiresAppLock: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var isLocked: Bool = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }

            if hasCompletedOnboarding && requiresAppLock && isLocked {
                LockedView { isLocked = false }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.2), value: isLocked)
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.environment["ASTERA_FORCE_HOME"] == "1" {
                seedDemoIfNeeded()
                hasCompletedOnboarding = true
            }
            #endif
            if requiresAppLock { isLocked = true }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                if requiresAppLock { isLocked = true }
            case .active:
                break
            @unknown default:
                break
            }
        }
        .onChange(of: requiresAppLock) { _, nowOn in
            if !nowOn { isLocked = false }
        }
    }

    #if DEBUG
    private func seedDemoIfNeeded() {
        let seedMode: CycleMode = {
            switch ProcessInfo.processInfo.environment["ASTERA_SEED_MODE"] {
            case "pregnant": return .pregnant
            case "postLoss": return .postLoss
            case "postpartum": return .postpartum
            case "pcos": return .pcos
            case "perimenopause": return .perimenopause
            default: return .regular
            }
        }()
        let profile = UserProfile(
            pronouns: .theyThem,
            salutation: .girl, // demo: warm "Hey, girlie 🌸" greeting
            relationshipStructure: .single,
            cycleMode: seedMode,
            birthYear: 1995
        )
        modelContext.insert(profile)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Seed three cycles roughly 28 days apart, with a bleed FlowEntry on each start.
        for daysAgo in [70, 42, 14] {
            guard let startDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let cycle = Cycle(startDate: startDate, modeAtStart: .regular)
            modelContext.insert(cycle)

            // Three bleed days starting from startDate, intensity tapering.
            let intensities: [FlowIntensity] = [.medium, .medium, .light]
            for (i, intensity) in intensities.enumerated() {
                guard let day = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
                let flow = FlowEntry(day: day, intensity: intensity, source: .manual)
                flow.cycle = cycle
                modelContext.insert(flow)
            }
        }
        try? modelContext.save()
    }
    #endif
}

struct MainTabView: View {
    @State private var selection: Int = {
        switch ProcessInfo.processInfo.environment["ASTERA_INITIAL_TAB"] {
        case "history": return 1
        case "settings": return 2
        default: return 0
        }
    }()

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Today", systemImage: "leaf") }
                .tag(0)

            HistoryView()
                .tabItem { Label("History", systemImage: "book.closed") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "ellipsis.circle") }
                .tag(2)
        }
        .tint(AsteraColor.accent)
    }
}
