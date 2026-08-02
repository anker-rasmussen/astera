import Testing
import Foundation
@testable import Astera

/// The birth year range, which exists so the input cannot express an invalid year.
@Suite("Birth year bounds")
struct BirthYearBoundsTests {

    private var thisYear: Int { Calendar.current.component(.year, from: Date()) }

    @Test("The range ends at this year, so nobody can be born in the future")
    func rangeStopsAtThisYear() {
        #expect(AgeMode.validBirthYears.upperBound == thisYear)
        #expect(!AgeMode.validBirthYears.contains(thisYear + 1))
    }

    @Test("The range reaches back far enough to cover anyone alive")
    func rangeCoversTheOldest() {
        #expect(AgeMode.validBirthYears.contains(thisYear - 100))
        #expect(AgeMode.validBirthYears.lowerBound == thisYear - AgeMode.maxPlausibleAge)
    }

    /// The case that mattered: the old text field accepted any four digits, and a year in the
    /// future reads as a negative age, which every gate treats as a small child. An adult who
    /// fat-fingered 3000 would have found sexual and fertility content silently gone.
    @Test("A year in the future clamps back to this year")
    func futureYearsClamp() {
        #expect(AgeMode.clampBirthYear(3000) == thisYear)
        #expect(AgeMode.age(forBirthYear: AgeMode.clampBirthYear(3000)) == 0)
    }

    @Test("An implausibly old year clamps to the bottom of the range")
    func ancientYearsClamp() {
        #expect(AgeMode.clampBirthYear(1000) == thisYear - AgeMode.maxPlausibleAge)
    }

    @Test("A year already in range is left alone")
    func ordinaryYearsAreUntouched() {
        #expect(AgeMode.clampBirthYear(1990) == 1990)
    }
}

/// Where Astera writes its calendar events.
@Suite("Calendar destination")
struct CalendarDestinationTests {

    private func freshDefaults(_ name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("No stored value means Astera's own calendar")
    func unsetMeansOwnCalendar() {
        let defaults = freshDefaults("astera.destination.unset")
        #expect(CalendarSyncService.destinationIdentifier(in: defaults) == nil)
    }

    /// `@AppStorage` has no optional, so clearing the choice writes an empty string rather than
    /// removing the key. Reading that back as "" would send every sync to a calendar whose
    /// identifier is the empty string, which is no calendar at all.
    @Test("An empty stored value also means Astera's own calendar")
    func emptyStringMeansOwnCalendar() {
        let defaults = freshDefaults("astera.destination.empty")
        CalendarSyncService.setDestinationIdentifier(nil, in: defaults)
        #expect(CalendarSyncService.destinationIdentifier(in: defaults) == nil)
    }

    @Test("A chosen calendar round trips")
    func chosenIdentifierRoundTrips() {
        let defaults = freshDefaults("astera.destination.chosen")
        CalendarSyncService.setDestinationIdentifier("ABC-123", in: defaults)
        #expect(CalendarSyncService.destinationIdentifier(in: defaults) == "ABC-123")
    }

    @Test("Choosing and then clearing goes back to Astera's own calendar")
    func clearingReturnsToOwnCalendar() {
        let defaults = freshDefaults("astera.destination.cleared")
        CalendarSyncService.setDestinationIdentifier("ABC-123", in: defaults)
        CalendarSyncService.setDestinationIdentifier(nil, in: defaults)
        #expect(CalendarSyncService.destinationIdentifier(in: defaults) == nil)
    }
}
