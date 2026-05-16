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
            return "All of your cycle reminders are quiet now. Your history is safe, exactly as you left it. Take all the time you need. There's no clock."
        case .postpartum:
            return "Your period might take a few weeks to come back, or many months, especially if you're nursing. Whenever it returns, we'll be here."
        case .surgicalMenopause:
            return "We've turned cycle predictions off. Everything else is still here for you, for logging symptoms, keeping notes, tracking how you're doing."
        case .trackingOnT:
            return "Bleeds on T have their own rhythm, and we're not going to forecast something this unpredictable. Logging, history, and notes are all still yours."
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
        case .postpartum: return "Bodies take their time after birth."
        case .surgicalMenopause: return "The app still has plenty for you."
        case .trackingOnT: return "Cycle changes on T are their own thing."
        default: return "No predictions for now."
        }
    }

    private var careCopyBody: String {
        switch mode {
        case .postLoss:
            return "Loss isn't something you're supposed to be over in a number of weeks. There is no timeline you're supposed to be on. Astera stays quiet about cycles for as long as you need. If you want to write something down today, for yourself or because a clinician asked, the log is right below."
        case .postpartum:
            return "Periods come back when they come back. Sometimes it's a few weeks, sometimes many months, sometimes longer than that if you're nursing. All of that is normal. Whenever yours returns, log a flow day and tracking will quietly pick up again. There's no \"late\" here."
        case .surgicalMenopause:
            return "Astera was built around cycles, but it has plenty to offer when there isn't one. Log hot flashes, sleep, mood, anything HRT-related. Keep notes for clinician visits. Your full history stays exactly where it is. Nothing here will pretend a bleed is about to arrive."
        case .trackingOnT:
            return "Cycle changes on T are real and varied. Bleeds might stop entirely, get lighter, or take a long while to settle. Astera isn't going to forecast something this unpredictable. But logging is still here whenever you want it, for yourself or for your provider."
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
            Text("Switching modes doesn't delete anything. It only changes how the home tab behaves.")
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
