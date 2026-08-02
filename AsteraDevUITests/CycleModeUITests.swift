import XCTest

/// Cold-launch cover for every cycle mode (App Store Guideline 2.1, completeness).
///
/// Astera swaps the whole home tab per mode, including screens written for hard moments
/// (after loss, postpartum, surgical menopause). A crash or an empty screen in one of those is
/// both a rejection and the worst possible user experience, and modes are exactly the kind of
/// thing that gets added without anyone revisiting all fourteen.
///
/// **Why this is split into shards.** XCUITest distributes work across parallel simulator clones
/// per test *class*, not per test method. As a single class the fourteen-mode sweep was one
/// worker's serial job and pinned the whole run at about seven minutes no matter how many workers
/// were available. Four classes covering four groups of modes spread across four clones instead.
/// The groups are clinical rather than arbitrary so a failure reads as something meaningful.
class CycleModeUITestCase: AsteraUITestCase {

    /// Overridden per shard. The base class covers nothing and skips.
    class var modes: [Mode] { [] }

    /// One launch per mode, checking the three tabs and the absence of placeholder copy together.
    /// Combining them halves the launches, and launching is nearly all of the cost.
    func testModesRenderEveryTabWithoutPlaceholders() throws {
        try XCTSkipIf(Self.modes.isEmpty, "Base class covers no modes")

        for mode in Self.modes {
            XCTContext.runActivity(named: "mode: \(mode.rawValue)") { _ in
                launchApp(mode: mode)
                app.tabBars.buttons["Today"]
                    .requireExistence("the Today tab in \(mode.rawValue) mode")

                for tab in ["Today", "History", "Settings"] {
                    app.tabBars.buttons[tab].tap()
                    XCTAssertEqual(
                        app.state, .runningForeground,
                        "App left the foreground on \(tab) in \(mode.rawValue) mode"
                    )
                    assertNoPlaceholders(app, tab: tab, mode: mode)
                }

                app.terminate()
            }
        }
    }

    /// The same modes with an empty database, which is what a reviewer sees on first launch.
    /// A mode that renders fine with three seeded cycles can still divide by zero with none.
    func testModesRenderWithNoDataAtAll() throws {
        try XCTSkipIf(Self.modes.isEmpty, "Base class covers no modes")

        for mode in Self.modes {
            XCTContext.runActivity(named: "mode: \(mode.rawValue), no cycles") { _ in
                launchApp(mode: mode, cycles: 0)
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
    private func assertNoPlaceholders(_ app: XCUIApplication, tab: String, mode: Mode) {
        let visible = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        for placeholder in ["Lorem", "TODO", "FIXME", "Placeholder"] {
            XCTAssertFalse(
                visible.contains(placeholder),
                "Found placeholder text \"\(placeholder)\" on \(tab) in \(mode.rawValue) mode"
            )
        }
    }
}

// MARK: - Shards

/// Modes where a cycle is expected to come and go.
final class CyclingModeUITests: CycleModeUITestCase {
    override class var modes: [Mode] { [.regular, .irregular, .pcos, .endometriosis] }
}

/// Modes shaped by contraception, or by not having decided yet.
final class ContraceptionModeUITests: CycleModeUITestCase {
    override class var modes: [Mode] { [.iud, .hormonalBC, .ttc, .notSure] }
}

/// Modes where cycles are changing or ending.
final class TransitionModeUITests: CycleModeUITestCase {
    override class var modes: [Mode] { [.perimenopause, .surgicalMenopause, .trackingOnT] }
}

/// The screens written for hard moments. Most important of the four, least likely to be opened
/// by hand during development.
final class PregnancyModeUITests: CycleModeUITestCase {
    override class var modes: [Mode] { [.pregnant, .postLoss, .postpartum] }
}

/// Sharding is only safe if the shards still add up. Cheap, launches nothing.
final class CycleModeShardingUITests: XCTestCase {

    private static let shards: [[AsteraUITestCase.Mode]] = [
        CyclingModeUITests.modes,
        ContraceptionModeUITests.modes,
        TransitionModeUITests.modes,
        PregnancyModeUITests.modes,
    ]

    func testEveryModeBelongsToExactlyOneShard() {
        let sharded = Self.shards.flatMap { $0 }
        let all = Set(AsteraUITestCase.Mode.allCases)

        XCTAssertEqual(
            Set(sharded), all,
            "Modes missing from every shard: \(all.subtracting(sharded).map(\.rawValue).sorted())"
        )
        XCTAssertEqual(
            sharded.count, all.count,
            "A mode appears in more than one shard, wasting a worker on duplicate coverage"
        )
    }
}
