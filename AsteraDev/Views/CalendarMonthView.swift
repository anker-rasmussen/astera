import SwiftUI

enum DayMark: Equatable {
    case none
    case bleed
    case predicted
    case today
    case bleedAndToday
    case predictedAndToday
}

struct CalendarMonthView: View {
    let month: Date
    let markFor: (Date) -> DayMark
    let onTapDay: (Date) -> Void
    let onPrev: () -> Void
    let onNext: () -> Void

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: AsteraSpacing.md) {
            header
            weekdayRow
            daysGrid
            legend
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AsteraColor.iron)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()
            Text(monthLabel)
                .font(.asteraSerif(22, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AsteraColor.iron)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
    }

    private var monthLabel: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(orderedWeekdays, id: \.self) { day in
                Text(day)
                    .font(.asteraCaps(10))
                    .tracking(1.4)
                    .foregroundStyle(AsteraColor.iron)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var orderedWeekdays: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let firstWeekday = calendar.firstWeekday // 1=Sunday
        let rotated = Array(symbols[(firstWeekday - 1)...]) + Array(symbols[..<(firstWeekday - 1)])
        return rotated
    }

    private var daysGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(daysToDisplay, id: \.self) { date in
                if let date {
                    DayCell(
                        date: date,
                        mark: markFor(date),
                        isInDisplayedMonth: calendar.isDate(date, equalTo: month, toGranularity: .month),
                        onTap: { onTapDay(date) }
                    )
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: AsteraSpacing.md) {
            legendRow(mark: .bleed, label: "bleed day")
            legendRow(mark: .predicted, label: "expected")
            Spacer()
        }
        .padding(.top, AsteraSpacing.sm)
    }

    private func legendRow(mark: DayMark, label: String) -> some View {
        HStack(spacing: 6) {
            ZStack {
                background(for: mark)
                    .frame(width: 18, height: 18)
            }
            Text(label)
                .font(.asteraSerifItalic(12))
                .foregroundStyle(AsteraColor.iron)
        }
    }

    @ViewBuilder
    private func background(for mark: DayMark) -> some View {
        switch mark {
        case .bleed, .bleedAndToday:
            Circle().fill(AsteraColor.accent)
        case .predicted, .predictedAndToday:
            Circle().strokeBorder(AsteraColor.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
        default:
            EmptyView()
        }
    }

    private var daysToDisplay: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let range = calendar.range(of: .day, in: .month, for: monthStart)
        else { return [] }

        // Compute leading blanks based on firstWeekday alignment.
        let firstWeekday = calendar.firstWeekday
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart) // 1=Sunday
        var leading = weekdayOfFirst - firstWeekday
        if leading < 0 { leading += 7 }

        var dates: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                dates.append(d)
            }
        }
        // Pad to full week rows.
        while dates.count % 7 != 0 {
            dates.append(nil)
        }
        return dates
    }
}

private struct DayCell: View {
    let date: Date
    let mark: DayMark
    let isInDisplayedMonth: Bool
    let onTap: () -> Void

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                background
                Text("\(calendar.component(.day, from: date))")
                    .font(.asteraNumeric(15, weight: .medium))
                    .foregroundStyle(textColor)
                    .opacity(isInDisplayedMonth ? 1 : 0.3)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var background: some View {
        ZStack {
            switch mark {
            case .bleed, .bleedAndToday:
                Circle()
                    .fill(AsteraColor.accent)
                    .frame(width: 34, height: 34)
            case .predicted, .predictedAndToday:
                Circle()
                    .strokeBorder(AsteraColor.accent.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: 34, height: 34)
            case .today:
                Circle()
                    .fill(AsteraColor.ink.opacity(0.06))
                    .frame(width: 34, height: 34)
            case .none:
                EmptyView()
            }
            if mark == .today || mark == .bleedAndToday || mark == .predictedAndToday {
                Circle()
                    .strokeBorder(AsteraColor.ink, lineWidth: 1)
                    .frame(width: 34, height: 34)
            }
        }
    }

    private var textColor: Color {
        switch mark {
        case .bleed, .bleedAndToday:
            return AsteraColor.vellum
        default:
            return AsteraColor.ink
        }
    }

    private var accessibilityLabel: String {
        let base = date.formatted(.dateTime.day().month(.wide))
        switch mark {
        case .bleed, .bleedAndToday: return "\(base), bleed day"
        case .predicted, .predictedAndToday: return "\(base), expected period day"
        case .today: return "\(base), today"
        case .none: return base
        }
    }
}
