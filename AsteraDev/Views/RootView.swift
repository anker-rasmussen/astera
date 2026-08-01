import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage(AppStorageKey.hasCompletedOnboarding.rawValue) private var hasCompletedOnboarding: Bool = false
    @AppStorage(AppStorageKey.requiresAppLock.rawValue) private var requiresAppLock: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]

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
            if DebugSeed.isEnabled {
                // Re-seed on every launch, not just an empty store: the previous test's data
                // survives in the same install, and inheriting it makes assertions meaningless.
                DebugSeed.apply(in: modelContext)
                hasCompletedOnboarding = true
            }
            #endif
            if requiresAppLock { isLocked = true }
            // Safety net: if the user's saved birth year now puts them below an age gate
            // (because they edited it, or the year ticked over to their birthday), force
            // the corresponding toggles off so nothing they consented to at a higher age
            // silently survives.
            if let profile = profiles.first {
                AgeMode.reconcileAgeGatedSettings(birthYear: profile.birthYear)
            }
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
