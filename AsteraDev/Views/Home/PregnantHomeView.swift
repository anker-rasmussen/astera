import SwiftUI
import SwiftData

struct PregnantHomeView: View {
    let profile: UserProfile?
    let latestCycle: Cycle?
    let onSwitchMode: () -> Void

    private var calendar: Calendar { Calendar.current }
    private var today: Date { calendar.startOfDay(for: Date()) }

    /// Conservative: weeks since the latest cycle start. LMP convention, the way clinicians count.
    /// If no cycle is logged, show a setup prompt instead.
    private var weeksSinceLMP: Int? {
        guard let lmp = latestCycle?.startDate else { return nil }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lmp), to: today).day ?? 0
        return max(0, days / 7)
    }

    private var dayWithinWeek: Int {
        guard let lmp = latestCycle?.startDate else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lmp), to: today).day ?? 0
        return days % 7
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AsteraSpacing.xl) {
                header
                    .padding(.top, AsteraSpacing.lg)
                Hairline()

                if let weeks = weeksSinceLMP {
                    weeksCard(weeks: weeks)
                    Hairline()
                    trimesterCard(weeks: weeks)
                    Hairline()
                    upcomingMilestone(weeks: weeks)
                } else {
                    setupPrompt
                }

                Hairline()
                quietSection
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
            Text("Hello.")
                .font(.asteraSerif(34, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text("Pregnancy weeks now, instead of cycle days. Your full cycle history stays right where it is.")
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }

    private func weeksCard(weeks: Int) -> some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Pregnancy")
            HStack(alignment: .firstTextBaseline, spacing: AsteraSpacing.sm) {
                Text("Week")
                    .font(.asteraSerifItalic(22))
                    .foregroundStyle(AsteraColor.iron)
                Text("\(weeks)")
                    .font(.asteraNumeric(64, weight: .medium))
                    .foregroundStyle(AsteraColor.ink)
                    .contentTransition(.numericText())
                if dayWithinWeek > 0 {
                    Text("+ \(dayWithinWeek)d")
                        .font(.asteraSerifItalic(18))
                        .foregroundStyle(AsteraColor.iron)
                }
            }
            Text("Counted from your last logged period. This is the standard clinical week (LMP convention).")
                .font(.asteraSerifItalic(13))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private func trimesterCard(weeks: Int) -> some View {
        let trimester: String = {
            switch weeks {
            case ..<13: return "First trimester"
            case 13..<27: return "Second trimester"
            case 27...: return "Third trimester"
            default: return ""
            }
        }()

        return VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Where you are")
            Text(trimester)
                .font(.asteraSerif(22, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text(trimesterCopy(weeks: weeks))
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private func trimesterCopy(weeks: Int) -> String {
        switch weeks {
        case ..<5: return "Very early days. Tests may not be conclusive yet."
        case 5..<9: return "First trimester. Symptoms vary widely. What you feel is your own normal."
        case 9..<13: return "Late first trimester. Many people start to feel more like themselves again toward the end."
        case 13..<20: return "Early second trimester. Often called the 'easier stretch', though that's not everyone's experience."
        case 20..<27: return "Mid pregnancy. You may start to feel movement somewhere in here."
        case 27..<37: return "Third trimester. Things are getting close. Pack a bag whenever feels right."
        case 37...: return "Full term territory. Anything from now on is on time."
        default: return ""
        }
    }

    private func upcomingMilestone(weeks: Int) -> some View {
        let dueDate: Date? = latestCycle.flatMap { calendar.date(byAdding: .day, value: 280, to: $0.startDate) }
        return VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Estimated due date")
            if let due = dueDate {
                Text(due.formatted(.dateTime.day(.defaultDigits).month(.wide).year(.defaultDigits)))
                    .font(.asteraNumeric(28, weight: .medium))
                    .foregroundStyle(AsteraColor.ink)
                let weeksLeft = max(0, 40 - weeks)
                Text("About \(weeksLeft) week\(weeksLeft == 1 ? "" : "s") to go. This is a 40-week-from-LMP estimate; your clinician's date will be more accurate.")
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var setupPrompt: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Pregnancy")
            Text("We'd need your last period date.")
                .font(.asteraSerif(22))
                .foregroundStyle(AsteraColor.ink)
            Text("Without it we can't count weeks. Open History and tap the day your last period started.")
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }

    private var quietSection: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Not pregnant anymore?")
            Button {
                onSwitchMode()
            } label: {
                HStack {
                    Text("Switch back to cycle tracking")
                        .font(.asteraSerifItalic(15))
                        .underline(true, color: AsteraColor.accent.opacity(0.4))
                        .foregroundStyle(AsteraColor.accent)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AsteraColor.accent)
                }
            }
            .buttonStyle(.plain)
            Text("Your full history stays. We never delete a pregnancy entry unless you ask.")
                .font(.asteraSerifItalic(13))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(.vertical, AsteraSpacing.lg)
    }
}
