import XCTest

/// Cold-launch cover for every cycle mode (App Store Guideline 2.1, completeness).
///
/// Astera swaps the whole home tab per mode, including screens written for hard moments
/// (after loss, postpartum, surgical menopause). A crash or an empty screen in one of those is
/// both a rejection and the worst possible user experience, and modes are exactly the kind of
/// thing that gets added without anyone revisiting all fourteen.
final class CycleModeUITests: AsteraUITestCase {

    /// Walks all three tabs in every mode. Fails naming the mode, so a failure is actionable.
    func testEveryModeRendersAllThreeTabs() {
        for mode in Mode.allCases {
            XCTContext.runActivity(named: "mode: \(mode.rawValue)") { _ in
                let app = launchApp(mode: mode)

                app.tabBars.buttons["Today"]
                    .requireExistence("the Today tab in \(mode.rawValue) mode")

                for tab in ["Today", "History", "Settings"] {
                    app.tabBars.buttons[tab].tap()
                    XCTAssertEqual(
                        app.state, .runningForeground,
                        "App left the foreground on \(tab) in \(mode.rawValue) mode"
                    )
                }

                app.terminate()
            }
        }
    }

    /// The same sweep with an empty database, which is what a reviewer sees on first launch.
    /// A mode that renders fine with three seeded cycles can still divide by zero with none.
    func testEveryModeRendersWithNoDataAtAll() {
        for mode in Mode.allCases {
            XCTContext.runActivity(named: "mode: \(mode.rawValue), no cycles") { _ in
                let app = launchApp(mode: mode, cycles: 0)

                app.tabBars.buttons["Today"]
                    .requireExistence("the Today tab in \(mode.rawValue) mode with no data")
                XCTAssertEqual(
                    app.state, .runningForeground,
                    "App left the foreground in \(mode.rawValue) mode with no data"
                )

                app.terminate()
            }
        }
    }

    /// Nothing user-facing should be a stand-in. Catches the "TODO" that ships.
    func testNoPlaceholderTextIsVisibleInAnyMode() {
        let placeholders = ["Lorem", "TODO", "FIXME", "Placeholder", "xxx"]
        for mode in Mode.allCases {
            XCTContext.runActivity(named: "mode: \(mode.rawValue)") { _ in
                let app = launchApp(mode: mode)
                app.tabBars.buttons["Today"].requireExistence("the Today tab")

                let visible = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
                for placeholder in placeholders {
                    XCTAssertFalse(
                        visible.contains(placeholder),
                        "Found placeholder text \"\(placeholder)\" on home in \(mode.rawValue) mode"
                    )
                }

                app.terminate()
            }
        }
    }
}
