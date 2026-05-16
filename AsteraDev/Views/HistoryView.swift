import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Cycle.startDate, order: .reverse) private var cycles: [Cycle]
    @Query(sort: \FlowEntry.day, order: .reverse) private var flowEntries: [FlowEntry]

    @State private var currentMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var pickedDay: DayPick?

    private var calendar: Calendar { Calendar.current }
    private var profile: UserProfile? { profiles.first }
    private var latestCycle: Cycle? { cycles.first }

    private var bleedDays: Set<Date> {
        Set(flowEntries
            .filter { $0.intensity.rawValue >= FlowIntensity.light.rawValue }
            .map { calendar.startOfDay(for: $0.day) })
    }

    private var predictedDays: Set<Date> {
        let prediction = BayesianPredictor.predict(
            lastStart: latestCycle?.startDate,
            observedLengths: cycles.observedLengths,
            cycleMode: profile?.cycleMode ?? .notSure
        )
        var result: Set<Date> = []
        var day = calendar.startOfDay(for: prediction.lowerBound)
        let end = calendar.startOfDay(for: prediction.upperBound)
        while day <= end {
            result.insert(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    private func mark(for date: Date) -> DayMark {
        let day = calendar.startOfDay(for: date)
        let isToday = calendar.isDateInToday(day)
        let isBleed = bleedDays.contains(day)
        let isPredicted = predictedDays.contains(day)

        if isBleed && isToday { return .bleedAndToday }
        if isPredicted && isToday { return .predictedAndToday }
        if isBleed { return .bleed }
        if isPredicted { return .predicted }
        if isToday { return .today }
        return .none
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AsteraSpacing.xl) {
                header
                    .padding(.top, AsteraSpacing.lg)

                Hairline()

                CalendarMonthView(
                    month: currentMonth,
                    markFor: mark,
                    onTapDay: { date in pickedDay = DayPick(date: date) },
                    onPrev: { stepMonth(-1) },
                    onNext: { stepMonth(1) }
                )

                Hairline()

                pastCyclesSection

                Spacer(minLength: AsteraSpacing.xl)
            }
            .asteraEditorialMargins()
            .padding(.bottom, AsteraSpacing.xl)
        }
        .asteraScreen()
        .sheet(item: $pickedDay) { picked in
            LogSheet(
                date: picked.date,
                onCancel: { pickedDay = nil },
                onSaved: { _ in pickedDay = nil }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsLabel(text: "Astera · history")
            Text("Your cycles")
                .font(.asteraSerif(34, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text("Tap any day to log it. Past days, today, future days, all editable. If a day is already logged, the sheet opens with what you wrote.")
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }

    @ViewBuilder
    private var pastCyclesSection: some View {
        if cycles.isEmpty {
            VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                CapsLabel(text: "Past cycles")
                Text("Nothing yet.")
                    .font(.asteraSerif(20))
                    .foregroundStyle(AsteraColor.ink)
                Text("Cycles you've started will appear here. Tap any day above to log a period start.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        } else {
            VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                CapsLabel(text: "Past cycles")
                VStack(spacing: 0) {
                    ForEach(Array(cyclesWithLengths.enumerated()), id: \.element.cycle.id) { _, item in
                        cycleRow(cycle: item.cycle, length: item.length)
                        Hairline()
                    }
                }
            }
        }
    }

    private struct CycleEntry {
        let cycle: Cycle
        let length: Int?
    }

    private var cyclesWithLengths: [CycleEntry] {
        let sortedAsc = cycles.sorted { $0.startDate < $1.startDate }
        var byId: [UUID: Int] = [:]
        for (i, c) in sortedAsc.enumerated() where i > 0 {
            let prev = sortedAsc[i - 1]
            let days = calendar.dateComponents([.day], from: prev.startDate, to: c.startDate).day ?? 0
            if days >= 14 && days <= 80 { byId[c.id] = days }
        }
        return cycles.map { CycleEntry(cycle: $0, length: byId[$0.id]) }
    }

    private func cycleRow(cycle: Cycle, length: Int?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(cycle.startDate.formatted(.dateTime.day(.defaultDigits).month(.wide).year(.defaultDigits)))
                    .font(.asteraSerif(20, weight: .regular))
                    .foregroundStyle(AsteraColor.ink)
                Text(subtitle(for: cycle))
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
            }
            Spacer()
            if let length {
                Text("\(length) days")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
            }
        }
        .padding(.vertical, AsteraSpacing.md)
    }

    private func subtitle(for cycle: Cycle) -> String {
        if calendar.isDate(cycle.startDate, equalTo: latestCycle?.startDate ?? .distantPast, toGranularity: .day) {
            return "current cycle · \(cycle.modeAtStart.displayName.lowercased())"
        }
        return cycle.modeAtStart.displayName.lowercased()
    }

    private func stepMonth(_ delta: Int) {
        if let new = calendar.date(byAdding: .month, value: delta, to: currentMonth) {
            currentMonth = new
        }
    }
}

private struct DayPick: Identifiable {
    let date: Date
    var id: Date { date }
}
