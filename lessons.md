# Lessons learned while building Astera

Append as we go. Each lesson: a one-line title, then context + correct pattern + the source if it conflicted with prior assumption.

---

## SwiftData + CloudKit: model rules

CloudKit Private DB sync via SwiftData has structural constraints. Violating them causes a runtime crash at `ModelContainer` init with messages like *"CloudKit integration requires that all attributes be optional or have a default value"*.

- Every persisted property must be **optional** OR have a **default value**. Non-optional, non-defaulted properties break sync init.
- **No `@Attribute(.unique)`**. CloudKit has no uniqueness constraints; SwiftData refuses to create the container.
- **All `@Relationship` properties must be optional** (e.g., `var entries: [FlowEntry]? = []`). Cascade rules still work.
- Enum-typed properties: serialize via `rawValue: String` (or make the enum `Codable`). Don't store the enum directly unless it has a `RawRepresentable` backing SwiftData can serialize.
- The `@Model` macro generates an init; for CloudKit, prefer providing default values inline so the auto-generated init compiles cleanly.

Source: Apple's "Syncing model data across a person's devices" documentation + WWDC23 "Model your schema with SwiftData".

## Xcode 26 / Swift 6 default

Xcode 26.2 ships with Swift 6.2. Defaulting to `SWIFT_VERSION = 5.0` (Swift 5 language mode) for early dev to avoid strict-concurrency churn while learning SwiftData/CloudKit. Flip to 6.0 once the basics are stable.

## iCloud entitlement requires paid Apple Developer Program

The `com.apple.developer.icloud-services` entitlement cannot be claimed on a free Apple ID. If you add it before enrolment is active, codesign fails with *"Provisioning profile doesn't include the com.apple.developer.icloud-services entitlement"*.

Strategy: ship local-only SwiftData first (no entitlement). Once enrolled, add the entitlement file, set `cloudKitDatabase: .private(...)` in `ModelConfiguration`, regenerate project, rebuild.

**Resolved 2026-05-16**: Anker's enrolment came through; entitlements file lives at `AsteraDev/AsteraDev.entitlements`, project.yml has `CODE_SIGN_ENTITLEMENTS` pointing at it, and `PersistenceController.makeContainer()` now uses `cloudKitDatabase: .private("iCloud.com.anker.asteradev")`. App boots clean on simulator without iCloud signed in — SwiftData transparently falls back to local-only behaviour when no iCloud account is present.

## SwiftData + CloudKit simulator caveats

- Simulator can sign into iCloud via Settings, but CloudKit sync on the simulator has historically been flaky. **Test sync on real hardware** before trusting it.
- The CloudKit container (`iCloud.com.anker.asteradev`) is auto-created in CloudKit Dashboard on first write from a signed-in device. For App Store / TestFlight builds the **schema must be explicitly deployed to production** in CloudKit Dashboard ("Deploy Schema Changes"). Dev environment is fine without this.
- Background Modes must include `remote-notification` (set via `INFOPLIST_KEY_UIBackgroundModes: "remote-notification"`) for `CKSubscription` push wake. Without it the app only syncs on foreground.

## Swift Testing: don't combine `@MainActor` with SwiftData test bodies that need ModelContext

Marking a Swift Testing `@Test` (or its containing `@Suite` struct) `@MainActor` caused tests using a SwiftData `ModelContext` to silently fail discovery — the runner spawned a process per test, each one crashed during launch (IOSurfaceClientSetSurfaceNotify), and the suite reported "passed" with 0 tests executed. The CloudKit "no iCloud account" log noise looked like the cause but was incidental.

Fix: **drop `@MainActor` from both the service code under test and the test method**. Use `ModelContext(container)` (a free background context) instead of `container.mainContext`. SwiftData contexts work fine off the main actor as long as you stay on one context at a time. UI views still need `@MainActor` (they get it implicitly from being SwiftUI Views).

Caveat: `container.mainContext` is `@MainActor`-isolated. Don't try to access it from a non-MainActor test. Either spin up a fresh context with `ModelContext(container)` (what we do in `LogServiceTests.freshContext()`) or keep the whole test on MainActor.

## simctl can't send taps; use `SIMCTL_CHILD_` env vars to seed dev state

`xcrun simctl ui` only handles appearance/accessibility, not taps. For automation use XCUITest or idb. For one-off verification, set `SIMCTL_CHILD_<NAME>=value` before `xcrun simctl launch` to pass env vars into the child process — useful for `#if DEBUG` flags like `ASTERA_FORCE_HOME=1` that bypass onboarding and seed demo data.

## Reference reading for the Bayesian predictor

When implementing the spec §4 prediction model, these are the relevant prior works:

- **Urteaga et al., 2021** — *"A Generative Modeling Approach to Calibrated Predictions: A Use Case on Menstrual Cycle Length Prediction"* (Proc. MLR). [Paper](https://proceedings.mlr.press/v149/urteaga21a/urteaga21a.pdf) · [Code](https://github.com/iurteaga/menstrual_cycle_analysis). Bayesian generative model that handles self-tracking artifacts (skipped logs, retroactive entries). The most relevant published reference for what we want.
- **Symul & Holmes, 2021** — *"Labeling Self-Tracked Menstrual Health Records With Hidden Semi-Markov Models"* (IEEE J. Biomed. Health Inf.). [Symul research page](https://lasy.github.io/research/). HSMM for labelling cycle phases (follicular / ovulatory / luteal / etc.). Heavier than we need for Phase 1; reach for it later if we want phase-aware predictions.
- **Bortot et al., 2012** — *Flexible Bayesian Human Fecundity Models* (Bayesian Analysis). [PDF](https://projecteuclid.org/journals/bayesian-analysis/volume-7/issue-4/Flexible-Bayesian-Human-Fecundity-Models/10.1214/12-BA726.pdf). Foundational; useful for TTC-mode priors.

**Existing open-source period trackers** that we can sanity-check against (none are Bayesian):
- [Drip (Bloody Health)](https://github.com/jfr3000/drip) — sympto-thermal (Sensiplan rules)
- [Mensinator](https://github.com/EmmaTellblom/Mensinator) — average period + average luteal phase
- [Menstrudel](https://github.com/J-shw/Menstrudel) — Flutter, average-based

Strategy: implement Beta-Binomial in pure Swift ourselves (math is textbook, repos are Python/R and academically licensed). Test against synthetic cycle histories before plugging into the UI.

## Bayesian predictor v1 — Normal-Normal conjugate, design rationale

Landed 2026-05-16. Files:
- `AsteraDev/Prediction/CyclePopulationPriors.swift` — per-mode `CycleLengthPrior` (mean, mean stddev, observation stddev, prior strength)
- `AsteraDev/Prediction/BayesianPredictor.swift` — the math + the public `predict(lastStart:observedLengths:cycleMode:)` API

**Why Normal-Normal, not Beta-Binomial:** spec §4 said *either* Beta-Binomial *or* Gamma. Cycle lengths are positive-real-valued and roughly normal-distributed in literature (Bortot 2012, Symul 2021), so Normal with known observation variance + conjugate Normal prior on the mean is the simplest model that hits the spec's MAE targets. ~150 lines. Beta-Binomial would need to discretise the support and is awkward; Gamma is fine but adds digamma-function machinery. We can swap up if needed.

**Predictive distribution:**
- prior: μ ~ Normal(μ₀, τ₀²), σ² known per mode
- posterior: μ | data ~ Normal(μₙ, τₙ²) with precision-weighted update
- predictive: L_new | data ~ Normal(μₙ, τₙ² + σ²)
- displayed band: centre ± round(1.5 · √(τₙ² + σ²)), clamped to [1, 14] days

**Per-mode priors** (informed by Symul 2021 + clinical norms):
- regular:   μ=28, τ=2, σ=2  → tight band, hits <2 day MAE target with ≥3 logs
- irregular: μ=30, τ=5, σ=6  → wider band, correct
- PCOS:      μ=35, τ=8, σ=9  → longest mean, very wide band
- IUD:       μ=28, τ=4, σ=5
- perimenopause: μ=30, τ=6, σ=8
- TTC:       μ=28, τ=2.5, σ=3 (slightly tighter — TTC users tend to track meticulously)

**Cycle-length extraction:** `[Cycle].observedLengths` filters consecutive-startDate gaps to [14, 80] days so a misclicked log doesn't poison the model.

**Confidence label mapping:**
- 0 observations → `.populationPrior` ("Just a first guess · based on typical cycles")
- 1–2 → `.low`
- 3–5 → `.medium`
- ≥6 → `.high`

These were validated by tests at `AsteraDevTests/BayesianPredictorTests.swift` covering: population prior offsets, mode-dependent band widths, posterior pull toward observations, single-observation shrinkage, variability widening.

**Followups when we want to push further:** exponential time-decay weighting (recent cycles count more); HSMM phase labelling (Symul); explicit ovulation prediction for TTC; missingness-aware model (Urteaga 2021) for users who skip logs.

## SwiftUI design language for Astera

Locked aesthetic: **Considered Almanac**. See `[[design-language-astera]]` memory for the full guide. Highlights worth keeping at the codebase root for searchability:
- Headlines: `.system(size: X, weight: .medium, design: .serif)` (New York via iOS).
- Body: SF Pro Text (default `.body`). Never apply `.fontDesign(.rounded)` globally — only on big numerics.
- No drop shadows on cards. Hairline rules (`Hairline` view, ink at 14% opacity) and tonal contrast define elevation.
- Roman-numeral chapter headers replace pill progress dots in onboarding.
- Aster mark (`AsteraMark` view, 8-petal Canvas drawing) is the brand ornament.
