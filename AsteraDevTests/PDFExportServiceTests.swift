import Foundation
import Testing
import PDFKit
@testable import Astera

@Suite("PDFExportService rendering")
struct PDFExportServiceTests {
    private func sampleExport(cycleCount: Int = 3, symptomCount: Int = 2) -> ExportService.Export {
        let profile = ExportService.ProfileSnapshot(
            pronouns: "sheHer",
            customPronouns: nil,
            salutation: "girl",
            customSalutation: nil,
            relationshipStructure: "single",
            cycleMode: "regular",
            birthYear: 1995
        )
        let cycles = (0..<cycleCount).map { i in
            let start = Calendar.current.date(byAdding: .day, value: -28 * i, to: Date())!
            return ExportService.CycleSnapshot(
                id: UUID(),
                startDate: start,
                endDate: nil,
                notes: i == 0 ? "Quite painful this round." : nil,
                modeAtStart: "regular",
                flowEntries: [
                    ExportService.FlowSnapshot(day: start, intensity: "medium", source: "manual"),
                    ExportService.FlowSnapshot(day: Calendar.current.date(byAdding: .day, value: 1, to: start)!, intensity: "light", source: "manual")
                ],
                symptomEntries: (0..<symptomCount).map { _ in
                    ExportService.SymptomSnapshot(day: start, category: "cramps", severity: 2, notes: nil)
                }
            )
        }
        return ExportService.Export(
            schemaVersion: ExportService.schemaVersion,
            exportedAt: Date(),
            profile: profile,
            cycles: cycles
        )
    }

    @Test("PDF builds non-empty data")
    func buildsNonEmpty() async {
        let data = PDFExportService.buildPDF(sampleExport())
        #expect(data.count > 1000) // a real PDF for a few cycles will be > 1 KB
    }

    @Test("Generated PDF parses with PDFKit")
    func validPDF() async {
        let data = PDFExportService.buildPDF(sampleExport())
        let doc = PDFDocument(data: data)
        #expect(doc != nil)
        #expect((doc?.pageCount ?? 0) >= 1)
    }

    @Test("PDF paginates when there's a lot of data")
    func paginates() async {
        // 30 cycles, each with 20 symptoms = lots of content.
        let big = sampleExport(cycleCount: 30, symptomCount: 20)
        let data = PDFExportService.buildPDF(big)
        let doc = PDFDocument(data: data)
        #expect((doc?.pageCount ?? 0) >= 2)
    }

    @Test("Empty export still produces a valid PDF")
    func emptyExport() async {
        let empty = ExportService.Export(
            schemaVersion: ExportService.schemaVersion,
            exportedAt: Date(),
            profile: nil,
            cycles: []
        )
        let data = PDFExportService.buildPDF(empty)
        let doc = PDFDocument(data: data)
        #expect(doc != nil)
        #expect((doc?.pageCount ?? 0) >= 1)
    }
}
