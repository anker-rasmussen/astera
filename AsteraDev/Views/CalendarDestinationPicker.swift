import SwiftUI
import EventKit
import EventKitUI

/// Lets you choose which calendar Astera writes to.
///
/// This is Apple's `EKCalendarChooser`, not a list of our own. Writing one would mean rebuilding
/// the account grouping, the colour dots, the writability rules and the delegate accounts that
/// hide calendars you cannot add to, and getting all of it subtly wrong. The system control
/// already knows which calendars accept events and shows them grouped by the account they live
/// in, which is the part that matters here: it makes visible whether a calendar is on the phone,
/// in iCloud, or in a work account, before anything is written to it.
///
/// It is UIKit, and it insists on a `UINavigationController` of its own rather than a SwiftUI
/// `NavigationStack`; its Done and Cancel buttons live in that navigation bar and do not appear
/// without it.
struct CalendarDestinationPicker: UIViewControllerRepresentable {

    /// The chosen calendar's identifier, or nil for Astera's own calendar.
    let selected: String?
    /// Called with the choice. Nil means Astera's own calendar.
    let onChoose: (String?) -> Void
    /// Called instead when the sheet is dismissed without choosing, which has to be distinct:
    /// a cancel means leave the destination alone, not move it back to Astera's own calendar.
    let onCancel: () -> Void

    private let store = EKEventStore()

    func makeUIViewController(context: Context) -> UINavigationController {
        let chooser = EKCalendarChooser(
            selectionStyle: .single,
            displayStyle: .writableCalendarsOnly,
            entityType: .event,
            eventStore: store
        )
        if let selected, let calendar = store.calendar(withIdentifier: selected) {
            chooser.selectedCalendars = [calendar]
        }
        chooser.showsDoneButton = true
        chooser.showsCancelButton = true
        chooser.delegate = context.coordinator
        chooser.title = "Write to"
        return UINavigationController(rootViewController: chooser)
    }

    func updateUIViewController(_ controller: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onChoose: onChoose, onCancel: onCancel)
    }

    final class Coordinator: NSObject, EKCalendarChooserDelegate, UINavigationControllerDelegate {
        private let onChoose: (String?) -> Void
        private let onCancel: () -> Void

        init(onChoose: @escaping (String?) -> Void, onCancel: @escaping () -> Void) {
            self.onChoose = onChoose
            self.onCancel = onCancel
        }

        func calendarChooserDidFinish(_ chooser: EKCalendarChooser) {
            // Single selection still hands back a set. An empty one means Done with nothing
            // picked, which is a request for the default rather than for no calendar at all.
            onChoose(chooser.selectedCalendars.first?.calendarIdentifier)
        }

        func calendarChooserDidCancel(_ chooser: EKCalendarChooser) {
            onCancel()
        }
    }
}
