import Foundation
import UIKit

/// Renders the Astera export as a human-readable PDF a woman or her clinician can actually read.
/// JSON exports were useful for round-trip / data portability, but the average user (and most doctors)
/// can't make sense of a JSON file. This is the user-facing format.
enum PDFExportService {
    private static let pageSize = CGSize(width: 612, height: 792) // US Letter at 72 dpi
    private static let margin: CGFloat = 56

    private struct PageCursor {
        var y: CGFloat
        var pageNumber: Int = 1
    }

    /// Build a PDF as Data from a pre-built Export.
    static func buildPDF(_ export: ExportService.Export) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { ctx in
            ctx.beginPage()
            var cursor = PageCursor(y: margin)

            drawCover(export, cursor: &cursor, ctx: ctx)
            drawProfile(export.profile, cursor: &cursor, ctx: ctx)
            drawCycleSummary(export.cycles, cursor: &cursor, ctx: ctx)
            for cycle in export.cycles.reversed() {
                drawCycleDetail(cycle, cursor: &cursor, ctx: ctx)
            }
            drawFooter(cursor: &cursor, ctx: ctx)
        }
    }

    /// Save a PDF to a tempfile suitable for sharing.
    static func writeToTempFile(_ data: Data, exportedAt: Date) throws -> URL {
        let fileName = "Astera history \(dateOnly(exportedAt)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: [.atomic])
        return url
    }

    // MARK: - Sections

    private static func drawCover(_ export: ExportService.Export, cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        drawCaps("ASTERA · CYCLE HISTORY", cursor: &cursor)
        cursor.y += 6
        drawTitle("Your cycles, written out.", cursor: &cursor)
        cursor.y += 4
        drawItalic(
            "Generated \(longDate(export.exportedAt)). A readable copy of everything you've logged. For your records or your clinician.",
            cursor: &cursor
        )
        cursor.y += 12
        drawHairline(cursor: &cursor)
    }

    private static func drawProfile(_ profile: ExportService.ProfileSnapshot?, cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        ensureSpace(120, cursor: &cursor, ctx: ctx)
        drawSectionHeader("About you", cursor: &cursor)
        guard let profile else {
            drawBody("No profile saved.", cursor: &cursor)
            cursor.y += 12
            drawHairline(cursor: &cursor)
            return
        }
        let pronouns = displayPronouns(profile.pronouns, custom: profile.customPronouns)
        let mode = profile.cycleMode.replacingOccurrences(of: "_", with: " ")
        let relationship = profile.relationshipStructure.replacingOccurrences(of: "_", with: " ")
        let age = Calendar.current.component(.year, from: Date()) - profile.birthYear
        drawKeyValue("Pronouns", pronouns, cursor: &cursor)
        drawKeyValue("Cycle mode", mode, cursor: &cursor)
        drawKeyValue("Relationship", relationship, cursor: &cursor)
        drawKeyValue("Age", "\(age) (born \(profile.birthYear))", cursor: &cursor)
        cursor.y += 12
        drawHairline(cursor: &cursor)
    }

    private static func drawCycleSummary(_ cycles: [ExportService.CycleSnapshot], cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        ensureSpace(160, cursor: &cursor, ctx: ctx)
        drawSectionHeader("Summary", cursor: &cursor)

        if cycles.isEmpty {
            drawBody("No cycles logged yet.", cursor: &cursor)
            cursor.y += 12
            drawHairline(cursor: &cursor)
            return
        }

        let lengths: [Int] = cycles.compactMap { cycle in
            guard let next = cycles.first(where: { $0.startDate > cycle.startDate }) else { return nil }
            return Calendar.current.dateComponents([.day], from: cycle.startDate, to: next.startDate).day
        }
        let avgText: String = {
            guard !lengths.isEmpty else { return "Not enough data yet." }
            let mean = Double(lengths.reduce(0, +)) / Double(lengths.count)
            let minL = lengths.min()!
            let maxL = lengths.max()!
            return String(format: "Average %.1f days, range %d to %d", mean, minL, maxL)
        }()
        drawKeyValue("Cycles logged", "\(cycles.count)", cursor: &cursor)
        drawKeyValue("Completed cycles", "\(lengths.count)", cursor: &cursor)
        drawKeyValue("Cycle length", avgText, cursor: &cursor)
        if let first = cycles.first?.startDate, let last = cycles.last?.startDate {
            let range = "\(shortDate(first)) to \(shortDate(last))"
            drawKeyValue("Date range", range, cursor: &cursor)
        }
        cursor.y += 12
        drawHairline(cursor: &cursor)
    }

    private static func drawCycleDetail(_ cycle: ExportService.CycleSnapshot, cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        ensureSpace(120, cursor: &cursor, ctx: ctx)
        drawSectionHeader("Cycle starting \(longDate(cycle.startDate))", cursor: &cursor)
        let modeLabel = cycle.modeAtStart.replacingOccurrences(of: "_", with: " ")
        drawKeyValue("Mode at start", modeLabel, cursor: &cursor)

        // Flow days
        if !cycle.flowEntries.isEmpty {
            cursor.y += 4
            drawCaps("BLEED DAYS", cursor: &cursor)
            for flow in cycle.flowEntries {
                ensureSpace(20, cursor: &cursor, ctx: ctx)
                drawKeyValue(shortDate(flow.day), "\(flow.intensity) (\(flow.source))", cursor: &cursor, indent: 12)
            }
        }

        // Symptom days grouped by date
        if !cycle.symptomEntries.isEmpty {
            cursor.y += 8
            drawCaps("SYMPTOMS AND NOTES", cursor: &cursor)
            let byDay: [Date: [ExportService.SymptomSnapshot]] = Dictionary(grouping: cycle.symptomEntries) { Calendar.current.startOfDay(for: $0.day) }
            for day in byDay.keys.sorted() {
                let entries = byDay[day] ?? []
                let nonNotes = entries.filter { $0.category != "other" }
                let notes = entries.filter { $0.category == "other" }.compactMap { $0.notes }
                if !nonNotes.isEmpty {
                    let listing = nonNotes.map { entry -> String in
                        let label = entry.category.replacingOccurrences(of: "_", with: " ")
                        let sev = severityWord(entry.severity)
                        return sev.isEmpty ? label : "\(label) (\(sev))"
                    }.joined(separator: ", ")
                    ensureSpace(20, cursor: &cursor, ctx: ctx)
                    drawKeyValue(shortDate(day), listing, cursor: &cursor, indent: 12)
                }
                for note in notes {
                    ensureSpace(20, cursor: &cursor, ctx: ctx)
                    drawWrappedBody("\(shortDate(day)): “\(note)”", indent: 12, cursor: &cursor, ctx: ctx)
                }
            }
        }

        // Cycle-level notes
        if let cycleNote = cycle.notes, !cycleNote.isEmpty {
            cursor.y += 8
            drawCaps("CYCLE NOTE", cursor: &cursor)
            drawWrappedBody(cycleNote, indent: 12, cursor: &cursor, ctx: ctx)
        }

        cursor.y += 14
        drawHairline(cursor: &cursor)
    }

    private static func drawFooter(cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        cursor.y += 12
        drawItalic(
            "Generated by Astera. No third-party storage. Data lives on your phone and in your iCloud. Predictions are estimates, not medical advice.",
            cursor: &cursor
        )
    }

    // MARK: - Drawing primitives

    private static func ensureSpace(_ needed: CGFloat, cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        if cursor.y + needed > pageSize.height - margin {
            ctx.beginPage()
            cursor.pageNumber += 1
            cursor.y = margin
        }
    }

    private static func drawTitle(_ text: String, cursor: inout PageCursor) {
        let font = UIFont.systemFont(ofSize: 30, weight: .medium, width: .standard).serif() ?? UIFont(name: "TimesNewRomanPS-MediumMT", size: 30) ?? UIFont.systemFont(ofSize: 30, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.18, green: 0.10, blue: 0.13, alpha: 1)
        ]
        let height = text.size(withAttributes: attrs).height
        let rect = CGRect(x: margin, y: cursor.y, width: pageSize.width - margin * 2, height: height + 4)
        text.draw(in: rect, withAttributes: attrs)
        cursor.y += height + 4
    }

    private static func drawSectionHeader(_ text: String, cursor: inout PageCursor) {
        let font = UIFont.systemFont(ofSize: 18, weight: .medium).serif() ?? UIFont.systemFont(ofSize: 18, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.18, green: 0.10, blue: 0.13, alpha: 1)
        ]
        let height = text.size(withAttributes: attrs).height
        let rect = CGRect(x: margin, y: cursor.y, width: pageSize.width - margin * 2, height: height + 4)
        text.draw(in: rect, withAttributes: attrs)
        cursor.y += height + 8
    }

    private static func drawCaps(_ text: String, cursor: inout PageCursor) {
        let font = UIFont.systemFont(ofSize: 9, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(white: 0.4, alpha: 1),
            .kern: 1.4
        ]
        let height = text.size(withAttributes: attrs).height
        let rect = CGRect(x: margin, y: cursor.y, width: pageSize.width - margin * 2, height: height + 2)
        text.draw(in: rect, withAttributes: attrs)
        cursor.y += height + 4
    }

    private static func drawBody(_ text: String, cursor: inout PageCursor) {
        let font = UIFont.systemFont(ofSize: 12).serif() ?? UIFont.systemFont(ofSize: 12)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.18, green: 0.10, blue: 0.13, alpha: 1)
        ]
        let height = text.size(withAttributes: attrs).height
        let rect = CGRect(x: margin, y: cursor.y, width: pageSize.width - margin * 2, height: height + 4)
        text.draw(in: rect, withAttributes: attrs)
        cursor.y += height + 4
    }

    private static func drawItalic(_ text: String, cursor: inout PageCursor) {
        let font = UIFont.italicSystemFont(ofSize: 12).serif() ?? UIFont.italicSystemFont(ofSize: 12)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(white: 0.3, alpha: 1),
            .paragraphStyle: style
        ]
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: pageSize.width - margin * 2, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: attrs,
            context: nil
        )
        let rect = CGRect(x: margin, y: cursor.y, width: pageSize.width - margin * 2, height: bounds.height + 4)
        text.draw(in: rect, withAttributes: attrs)
        cursor.y += bounds.height + 6
    }

    private static func drawWrappedBody(_ text: String, indent: CGFloat = 0, cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        let font = UIFont.systemFont(ofSize: 11).serif() ?? UIFont.systemFont(ofSize: 11)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.18, green: 0.10, blue: 0.13, alpha: 1),
            .paragraphStyle: style
        ]
        let available = pageSize.width - margin * 2 - indent
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: available, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: attrs,
            context: nil
        )
        ensureSpace(bounds.height + 4, cursor: &cursor, ctx: ctx)
        let rect = CGRect(x: margin + indent, y: cursor.y, width: available, height: bounds.height + 4)
        text.draw(in: rect, withAttributes: attrs)
        cursor.y += bounds.height + 4
    }

    private static func drawKeyValue(_ key: String, _ value: String, cursor: inout PageCursor, indent: CGFloat = 0) {
        let keyFont = UIFont.italicSystemFont(ofSize: 11).serif() ?? UIFont.italicSystemFont(ofSize: 11)
        let valueFont = UIFont.systemFont(ofSize: 11).serif() ?? UIFont.systemFont(ofSize: 11)
        let iron = UIColor(white: 0.35, alpha: 1)
        let ink = UIColor(red: 0.18, green: 0.10, blue: 0.13, alpha: 1)

        let keyAttrs: [NSAttributedString.Key: Any] = [.font: keyFont, .foregroundColor: iron]
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: ink]

        let keyWidth: CGFloat = 130
        let valueWidth = pageSize.width - margin * 2 - indent - keyWidth - 12
        let height = max(
            key.size(withAttributes: keyAttrs).height,
            (value as NSString).boundingRect(
                with: CGSize(width: valueWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: valueAttrs,
                context: nil
            ).height
        )

        let keyRect = CGRect(x: margin + indent, y: cursor.y, width: keyWidth, height: height + 4)
        let valueRect = CGRect(x: margin + indent + keyWidth + 12, y: cursor.y, width: valueWidth, height: height + 4)
        key.draw(in: keyRect, withAttributes: keyAttrs)
        value.draw(in: valueRect, withAttributes: valueAttrs)
        cursor.y += height + 4
    }

    private static func drawHairline(cursor: inout PageCursor) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: cursor.y))
        path.addLine(to: CGPoint(x: pageSize.width - margin, y: cursor.y))
        UIColor(white: 0.15, alpha: 0.18).setStroke()
        path.lineWidth = 0.5
        path.stroke()
        cursor.y += 14
    }

    // MARK: - Formatting helpers

    // `Date.FormatStyle` rather than a `DateFormatter` per call, which is what the rest of the
    // app already uses. Two things came with the old version: a formatter allocated on every
    // line of a document that draws one per flow day, and a hardcoded `d MMMM yyyy` that puts the
    // day first whatever the reader's region says. A clinical printout is the last place to be
    // opinionated about that, and the style honours the device's locale for free.

    private static func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year())
    }

    private static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    /// The filename stamp, so this one stays `2026-08-02` everywhere rather than following the
    /// locale: it sorts, and it is the same string on every device.
    private static func dateOnly(_ date: Date) -> String {
        date.formatted(.iso8601.year().month().day().dateSeparator(.dash))
    }

    private static func severityWord(_ raw: Int) -> String {
        switch raw {
        case 1: return "mild"
        case 2: return "moderate"
        case 3: return "severe"
        default: return ""
        }
    }

    private static func displayPronouns(_ raw: String, custom: String?) -> String {
        if let custom, !custom.isEmpty { return custom }
        switch raw {
        case "sheHer": return "she / her"
        case "heHim": return "he / him"
        case "theyThem": return "they / them"
        default: return raw
        }
    }
}

private extension UIFont {
    /// Returns a serif version of this font's design, falling back to system if unavailable.
    func serif() -> UIFont? {
        let descriptor = fontDescriptor.withDesign(.serif)
        guard let d = descriptor else { return nil }
        return UIFont(descriptor: d, size: pointSize)
    }
}
