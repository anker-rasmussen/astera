import SwiftUI

/// The one place a birth year gets entered, used by onboarding and by the profile editor.
///
/// A `Picker` over `AgeMode.validBirthYears` rather than a text field, which is what makes the
/// range a property of the input instead of a rule enforced after the fact. The previous field
/// took any four digits, filtered them in an `onChange`, parsed them on save, and still let
/// `3000` through to the age gates. None of that code has an equivalent here: there is no
/// invalid state to filter, parse or reject.
///
/// It is the system wheel, not a drawn one. Years are a bounded ordered list, which is precisely
/// what the wheel is for, and it brings its own accessibility, momentum and localisation.
struct BirthYearField: View {
    @Binding var year: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            Picker("Birth year", selection: $year) {
                // Newest first: far more people are picking a year near this end than 1906, and
                // the wheel opens on the selection either way.
                ForEach(AgeMode.validBirthYears.reversed(), id: \.self) { year in
                    Text(verbatim: String(year))
                        .font(.asteraNumeric(22, weight: .medium))
                        .foregroundStyle(AsteraColor.ink)
                        .tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxHeight: 150)
            .accessibilityIdentifier("birthYear.picker")

            Text(ageLine)
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .accessibilityIdentifier("birthYear.age")

            if let gate = AgeMode.gentleGateMessage(birthYear: year) {
                Text(gate)
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AsteraSpacing.xs)
            }
        }
    }

    /// Says the age rather than showing a bare number in brackets, because the number the picker
    /// shows is a year and the number beside it is not, and "(35)" next to "1990" does not say
    /// which is which.
    private var ageLine: String {
        let age = AgeMode.age(forBirthYear: year)
        // The top of the wheel is this year, so zero is reachable by scrolling and is also where
        // a clamped nonsense year lands. "Turning 0 this year" is not a sentence anyone writes.
        return age == 0 ? "Born this year." : "Turning \(age) this year."
    }
}
