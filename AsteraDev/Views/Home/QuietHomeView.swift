import SwiftUI
import SwiftData

/// Used for modes where forecasting a bleed makes no sense or could be unkind:
/// after pregnancy loss, postpartum, surgical menopause or hysterectomy, and tracking on testosterone.
/// Suppresses predictions; foregrounds care, history, and a quiet log button.
struct QuietHomeView: View {
    let profile: UserProfile?
    let latestCycle: Cycle?
    let onShowLog: () -> Void
    let onSwitchMode: () -> Void

    private var mode: CycleMode { profile?.cycleMode ?? .notSure }

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AsteraSpacing.xl) {
                header
                    .padding(.top, AsteraSpacing.lg)
                Hairline()
                careNote
                Hairline()
                quietLoggingNote
                Hairline()
                switchModeRow
                Spacer(minLength: AsteraSpacing.xl)
            }
            .asteraEditorialMargins()
            .padding(.bottom, AsteraSpacing.xl)
        }
        .asteraScreen()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsLabel(text: Date().formatted(.dateTime.weekday(.wide).day(.defaultDigits).month(.wide)))
            Text("We're here.")
                .font(.asteraSerif(34, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text(subtitleForMode)
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }

    private var subtitleForMode: String {
        switch mode {
        case .postLoss:
            return "All cycle reminders are quiet. Your history stays, exactly as it was. Take whatever time you need."
        case .postpartum:
            return "Periods can take many months to come back. That's normal. We'll wait quietly until you log a real cycle."
        case .surgicalMenopause:
            return "Cycle predictions are off. The rest of the app stays available for logging symptoms, notes, and how you're feeling."
        case .trackingOnT:
            return "We won't forecast bleeds while you're on T. Logging, history, and notes are all yours."
        default:
            return "Predictions are paused for now."
        }
    }

    private var careNote: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: careHeader)
            Text(careCopyTitle)
                .font(.asteraSerif(22, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text(careCopyBody)
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var careHeader: String {
        switch mode {
        case .postLoss: return "After loss"
        case .postpartum: return "Postpartum"
        case .surgicalMenopause: return "After surgical menopause"
        case .trackingOnT: return "On testosterone"
        default: return ""
        }
    }

    private var careCopyTitle: String {
        switch mode {
        case .postLoss: return "There's no schedule for this."
        case .postpartum: return "Bodies take their time."
        case .surgicalMenopause: return "Different shape, same care."
        case .trackingOnT: return "Your body, your pace."
        default: return "No predictions for now."
        }
    }

    private var careCopyBody: String {
        switch mode {
        case .postLoss:
            return "Loss isn't a thing you're supposed to recover from in a number of weeks. Astera will be quiet about cycles until you tell us you're ready to track again. If you want to log a symptom or a note today, for yourself or because a clinician asked, the log is below."
        case .postpartum:
            return "Periods returning after birth can take anywhere from a few weeks to many months, especially if you're nursing. There's no \"late\" here. When you log a flow day, we'll quietly start tracking again."
        case .surgicalMenopause:
            return "Astera was built around cycles, but it's still useful when there isn't one. Log symptoms (hot flashes, sleep, mood, anything HRT-related), keep notes for clinician visits, and your full history stays put. Nothing here will pretend a bleed is about to arrive."
        case .trackingOnT:
            return "Cycle changes on T are varied. Some bleeds stop, some get lighter, some take a while to settle. Astera won't forecast what's not predictable. Logging stays available so you can keep notes for yourself or your provider."
        default:
            return ""
        }
    }

    private var quietLoggingNote: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "If you'd like to")
            Button(action: onShowLog) {
                HStack {
                    Text("Log something today")
                        .font(.asteraSerif(17, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(AsteraColor.vellum)
                .padding(.vertical, 16)
                .padding(.horizontal, AsteraSpacing.lg)
                .background(Capsule().fill(AsteraColor.ink))
            }
            .buttonStyle(.plain)
            Text("No obligation. The log is here when you want it.")
                .font(.asteraSerifItalic(13))
                .foregroundStyle(AsteraColor.iron)
                .padding(.top, AsteraSpacing.xs)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var switchModeRow: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "When you're ready")
            Button(action: onSwitchMode) {
                HStack {
                    Text(switchActionLabel)
                        .font(.asteraSerifItalic(15))
                        .underline(true, color: AsteraColor.accent.opacity(0.4))
                        .foregroundStyle(AsteraColor.accent)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AsteraColor.accent)
                }
            }
            .buttonStyle(.plain)
            Text("This won't delete anything. It only changes how the home tab behaves.")
                .font(.asteraSerifItalic(13))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var switchActionLabel: String {
        switch mode {
        case .postLoss: return "Return to cycle tracking"
        case .postpartum: return "Switch to a different mode"
        case .surgicalMenopause, .trackingOnT: return "Pick a different mode"
        default: return "Switch to a different mode"
        }
    }
}
