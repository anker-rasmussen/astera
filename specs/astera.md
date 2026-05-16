# Astera: Period & Cycle Tracker

A privacy-first, biologically-honest, inclusively-framed iOS period and cycle tracking app. **Everything a person needs to track their cycle is free, forever, with no ads, no third-party data sharing, and no upgrade pressure.** Astera is built by a single engineer who is tired of watching the incumbents in this category exploit a captive audience.

The product brief that follows leads with the customer experience because that is the order of priority. Monetization is a paragraph near the end. If the CX-first commitment ever conflicts with the monetization model, the monetization model loses.

> **Astera's promise to the user.** Astera is not a startup, is not raising money, and is not trying to monetize menstrual data. It cannot, by construction: cycle data lives in the user's *own* iCloud via CloudKit Private Database and HealthKit, end-to-end encrypted within Apple's infrastructure. The developer cannot read it. There is no analytics service. There is no third-party SDK. GDPR compliance is automatic because nothing is collected. If Astera ever ships a feature that contradicts any of the above, it has betrayed its premise and you have every right to call it out in public and leave, with all of your data, via the one-tap export.

---

## 1. Why Astera exists

The dominant period trackers (Flo, Clue, Stardust) have collectively trained roughly 300 million people to expect a category-defining UX, then progressively degraded it:

- Flo locked features that were free for a decade behind a $10–25/mo subscription (78 reviews in our research dataset name this directly), shared menstrual data with Meta, and uses a 20-minute personal-health questionnaire as a paywall on-ramp.
- Clue followed Flo's paywall trajectory and added popup pressure on every open.
- Stardust positions as "privacy-first" but ships predictions that are off by weeks for irregular cycles, has shipped sexualized notification copy, and crashes on launch after recent updates.

The research repo this spec lives in clustered all three apps; the loudest single theme across 65,540 reviews is Flo's paywall-creep, at 78 matched reviews, larger than any other complaint cluster in the dataset. The single-largest *technical* complaint about the existing privacy-first alternative is prediction accuracy. Both gaps are addressable by a competent solo engineer.

**Astera is the tracker you'd build for someone you love.** That sentence is the entire internal product principle. (It used to read "for your sister," which captures the warmth but misses anyone without one. The principle is the warmth, not the relationship.) Every other principle in this spec descends from it.

---

## 2. Customer-experience principles

In strict priority order. When two principles conflict, the higher one wins.

1. **Honest.** Predictions are surfaced with confidence ranges, never as single dates that imply false certainty. Education content cites sources. What Astera shows you is what's actually happening: no hidden charges, no surprise screens, no quiet changes to what's about to load on the next tap.
2. **Local-first and private by construction.** The app works fully offline. Local storage is the source of truth; CloudKit sync is an opportunistic, end-to-end-encrypted mirror within the user's own iCloud. There is no Astera-operated backend that holds health data. There are no third-party SDKs. GDPR compliance is a side-effect of the architecture (§5), not a workstream.
3. **Inclusive at the foundation.** Pronouns, salutation, and relationship structure are configured at first launch, with neutral defaults; every option is opt-in. "Girl" and "woman" never appear in copy a user did not choose. The full range of bodies and situations (regular cycles, irregular cycles, PCOS, endometriosis, IUDs, hormonal birth control, perimenopause, surgical menopause, pregnancy, loss, TTC, postpartum, tracking on testosterone) are real states with their own home tab, not edge cases bolted onto a "default" cycle.
4. **Fast.** First useful prediction within 60 seconds of opening the app for the first time. Home tab renders in <300ms on cold launch on a 3-year-old iPhone. No spinner over a network request, ever, on the home tab; local-first storage makes this trivial.
5. **Quiet.** One notification per cycle event, by default. No upsells in push, no flirtatious copy, no surveys after every interaction. The app earns the right to interrupt; it doesn't assume it.
6. **Reversible. Your history belongs to you.** Every cycle-state change, every preference change, every data import is reversible. Astera will never ask a user to delete a miscarriage record, will never silently archive an old pregnancy, will never wipe two years of cycles on a software update. If the worst happens and a migration corrupts data, we'd rather show a recovery banner than pretend it didn't.
7. **Calm to leave.** One-tap export to a portable format. One-tap delete-everything. If a user wants to leave Astera, Astera helps them. No countdown, no win-back screen, no dark pattern.

---

## 3. The day-to-day user experience

A literal walkthrough of the happy path. This is what the MVP must deliver.

### First launch (≤ 60 seconds to first prediction)

1. Single welcome screen: one sentence on what Astera does, one sentence on the privacy stance, one button. No commitment screens, no manifesto.
2. Pronoun + salutation + relationship-structure configuration. Each screen has a "skip" option and a sensible default. No "create an account" gate; iCloud sign-in is implicit.
3. **"Where are you right now?"** A single warm question, not a clinical "cycle state" picker. Options appear one per line, each with a one-sentence description in the user's voice rather than a medical label. The list:
   - *Regular cycles*: usually within a few days of the same length.
   - *Irregular cycles*: length varies a lot, with no clear pattern.
   - *PCOS*: we'll skip ovulation prompts unless you ask.
   - *Endometriosis*: wider bands, pain logging up front, no false certainty.
   - *I have an IUD*: we'll quietly accept lighter or absent bleeds.
   - *On hormonal birth control*: pill, patch, ring, implant, injection. Withdrawal bleeds and absent bleeds are both normal.
   - *Perimenopause*: variable cycles are expected, not a tracking failure.
   - *After surgical menopause or hysterectomy*: we'll switch off cycle predictions and keep the rest of the app working for you.
   - *Pregnant*: we'll switch to a week-by-week view; your cycle history stays.
   - *After pregnancy loss*: we'll keep your history, exactly, and quiet reminders until you tell us you're ready.
   - *Trying to conceive*: fertility window with confidence bands; no countdown, no comparison.
   - *Postpartum*: bodies take their time; we'll wait quietly.
   - *Tracking on testosterone*: cycle changes on T are real; we'll log without forecasting bleeds.
   - *Not sure yet*: that's completely fine. You can change this any time without losing anything.

   "Where are you right now?" replaces the older slash-separated framing because that older framing read as triage rather than welcome. Whichever state the user picks is reversible from Settings; switching states never destroys history.
4. Three data points: last period start date, typical cycle length (or "I don't know"), birth year. Each is skippable. The birth-year screen says, in one inline line: *"We use this only on this device; younger and older users see slightly different framings. It never leaves your phone."*
5. **A lock for the app?** Optional Face ID / Touch ID / passcode gate, with a clear "no lock for now" default. Phrased as a quiet question, not a security upsell.
6. First reading. Even with a single data point, show a prediction with explicit low-confidence framing. **No paywall, no upsell, no questionnaire.**
7. **A single optional "why we built it this way" screen.** One swipe past the first reading, a skippable screen names the stakes plainly (in user-facing language, not legalese): why the privacy posture matters, what subpoena posture means for menstrual data in 2026, why everything lives in the user's own iCloud. Not paranoid; not preachy. Just honest. Anyone who taps "skip" never sees it again.

### Daily use

The home tab shows:
- Today's cycle day and phase (e.g., "Day 14, likely ovulating, ±2 days").
- Next predicted event with confidence range (e.g., "Period expected May 20–24, ~70% confidence").
- A single tap-to-log control for today's flow, symptoms, or notes. No carousel, no "suggested for you", no full-screen prompt.

Tapping into history shows a calendar view. Long-press any day to log retroactively. Edits are non-destructive; the log keeps an audit trail accessible from settings if the user wants it.

### Notifications

By default the user gets at most three notifications per cycle: period-likely-in-a-few-days, period-likely-today, and ovulation-window-open (only for users who turn on fertility tracking). Each category can be muted individually. The full literal copy is previewable in settings before turning the category on.

---

## 4. The prediction model

This is the load-bearing technical differentiator. Incumbents collapse a cycle to a single average length and break on anything irregular. Astera maintains per-user, per-phase distributions and updates them Bayesianly.

### Model shape

- Four phase-length random variables per user: follicular, ovulatory, luteal, menstrual.
- Each modeled as a Beta-Binomial or Gamma distribution with a population prior; user observations update the posterior.
- A separate "regularity" parameter estimates the variance of the user's cycle length, which drives the *width* of the confidence band on predictions. A regular user with 10 logged cycles gets a ±1-day band; a PCOS user with the same number of cycles gets a ±7-day band, *and that's correct*.
- Mode-specific models: PCOS users skip ovulation-window estimation. IUD users skip "period likely today" alerts when historical bleeds are absent. Perimenopause users get a "this cycle may be anovulatory" framing. Pregnant users see no cycle predictions, only a week-by-week pregnancy tracker. Surgical-menopause and tracking-on-T users see no period predictions at all; the home tab supports logging and history without forecasting bleeds that may never arrive.

### Implementation

- Pure Swift, on-device, no ML framework needed. A few hundred lines.
- For users with <3 logged cycles, fall back to population priors with explicit `low confidence` UI.
- The prediction surface exposes a **"why this prediction"** sheet showing the underlying observations and uncertainty. Honest products show their work.

### Target accuracy

- Median absolute error of period-start prediction:
  - Regular cycles, ≥3 logged: **< 2 days**
  - Irregular / PCOS / endometriosis, ≥3 logged: **< 4 days**
  - First cycle (population prior only): **< 5 days**, with a band labeled `estimated`

---

## 5. Architecture

iOS 17+ only. Swift 5.10+. SwiftUI. No own backend, no third-party SDKs, no analytics services.

### Local-first paradigm

The app is fully usable offline. Local persistence is the source of truth; CloudKit Private Database sync is an opportunistic mirror for the user's other Apple devices. A user can disable iCloud entirely and Astera still works: predictions, history, logging, notifications, everything. This is the inverse of most consumer apps, which break without network.

This pattern matters for three reasons: (1) it makes the privacy story honest, because if the network is optional, the data path is short; (2) cold-launch and write latency are both bounded by local SQLite, not by any server's p99; (3) it aligns with how cycle tracking is actually used: quick log entries on the subway, on planes, in places without reliable signal.

### Stack

| Concern | Choice | Notes |
|---|---|---|
| Local persistence | **SwiftData** | `@Model` types backed by SQLite under the hood. ModelConfiguration with CloudKit sync enabled. |
| Cross-device sync | **CloudKit Private Database** | Per-user iCloud silo. Astera (the developer) cannot read users' private DBs. Inherits Advanced Data Protection if the user enables it. |
| Health data | **HealthKit** | Read+write `menstrualFlow`, `intermenstrualBleeding`, `ovulationTestResult`, `cervicalMucusQuality`, `sexualActivity`, `basalBodyTemperature`. HealthKit auto-syncs E2EE via iCloud. |
| Keys & secrets | **iCloud Keychain** (`kSecAttrSynchronizable`) | For any app-level keys or sensitive preferences. Synced E2EE across user's devices. |
| Identity | **Sign in with Apple** | Implicit via iCloud account presence; no email collected. App is fully functional with no iCloud account (local-only mode). |
| Payments | **StoreKit 2** | For Astera+ premium. Receipt verification against Apple's server on every cold launch. |
| Crash reporting | **MetricKit** | Apple-native. No third-party crash reporter, no Sentry, no Crashlytics. |
| Analytics | **None.** | First-party event counters in `UserDefaults` for *local* product debugging only. Nothing leaves the device. |

### Why no own backend

Because every byte that doesn't exist in a server can't be subpoenaed, leaked, or sold. CloudKit Private Database puts each user's data in their *own* iCloud silo; Astera-the-developer can read public records (e.g., shared educational content) and aggregate counts via CloudKit's metrics dashboard, but cannot read any user's cycle data. With Advanced Data Protection on, Apple themselves cannot either. The legal exposure surface is reduced to nearly zero.

### Data model (sketch)

```swift
@Model
final class Cycle {
    var id: UUID
    var startDate: Date
    var endDate: Date?           // nil = ongoing
    var flowEntries: [FlowEntry]
    var symptomEntries: [SymptomEntry]
    var notes: String?
    var modeAtStart: CycleMode   // regular, pcos, iud, perimenopause, etc.
    var createdAt: Date
    var modifiedAt: Date
}

@Model
final class FlowEntry { /* day, intensity, source: manual | healthkit */ }

@Model
final class SymptomEntry { /* day, category, severity, notes */ }

@Model
final class PredictionSnapshot {
    var generatedAt: Date
    var phaseLengthPosteriors: Data   // serialized Beta params
    var nextPeriodCenter: Date
    var nextPeriodLowerBound: Date
    var nextPeriodUpperBound: Date
    var confidence: Double            // 0-1
}

@Model
final class UserProfile {
    var pronouns: Pronouns
    var salutation: Salutation
    var relationshipStructure: RelationshipStructure
    var cycleMode: CycleMode
    var birthYear: Int
    var notificationPreferences: NotificationPreferences
}
```

All `@Model` types are synced to CloudKit Private DB by SwiftData automatically given the right `ModelConfiguration`. Migration plan uses SwiftData's `SchemaMigrationPlan`.

### Advanced Data Protection (ADP)

Astera surfaces a one-line notice in onboarding: *"For the strongest privacy, enable Advanced Data Protection in your Apple ID settings. Astera works either way; ADP means even Apple cannot read your data."* A `Settings → Privacy` screen shows the current ADP status (via `NSUbiquitousKeyValueStore` availability check + documentation pointer) and explains what it changes. Not required. Strongly encouraged.

### What's explicitly not in the architecture

- No own server, ever.
- No third-party SDKs of any kind: no Facebook SDK, no AppsFlyer, no Branch, no Mixpanel, no Amplitude, no Adjust, no Firebase.
- No web app.
- No Android app. (Possibly revisited Phase 3+, with its own E2EE story. Not promised.)
- No telemetry that leaves the device.

---

## 6. Privacy & key management

The full privacy story in one screen:

1. **Cycle data lives in CloudKit Private Database**, the user's own iCloud. Astera-the-developer cannot read it.
2. **HealthKit data lives in Apple Health**, the same story. E2EE in iCloud sync.
3. **The user's encryption keys live in iCloud Keychain**, E2EE across the user's Apple devices. Apple cannot read iCloud Keychain entries either.
4. **No Astera-operated server exists.** There is no database we run, no API we host, no auth service we operate.
5. **Phone replacement** is silent: sign into iCloud on the new phone, Astera reads CloudKit Private DB and HealthKit, data is there.
6. **If you lose access to your Apple ID**: if a user loses their entire Apple ecosystem with no iCloud backup, we cannot recover their cycle history; there is no copy on our side. Onboarding states this in one calm sentence: *"This is the floor of the privacy promise: your data lives with you. The one-tap export gives you a copy you control whenever you want it."* The app surfaces an export nudge on the 30-day anniversary as a gentle reminder.

### App-level lock (Face ID / Touch ID / passcode)

A separate-from-device lock is a first-class privacy feature, not a Phase-2 add-on. It exists because:

- Cycle data is sensitive even on a phone the user otherwise shares (family device, partner with the passcode, work device).
- Users in coercive or unsafe situations need the option without having to ask.
- The architecture promise above is meaningful only if the *local* surface area is also respected.

The lock is offered during onboarding (skippable, off by default), toggleable any time from Settings, and uses LocalAuthentication with biometry first and passcode fallback. No "remember me," no "skip lock for X minutes": every cold launch and every return from background checks. When biometry is unavailable, the toggle copy explains plainly ("Set a passcode on your phone first, then come back").

### Privacy policy

Plain English, <600 words, hash-committed to a public GitHub repo so changes are auditable. The privacy nutrition label in App Store Connect: **"Data Not Collected."** Period.

### Subpoena posture

Astera holds no user data. A subpoena to Astera produces nothing because there is nothing to produce. A subpoena to Apple is subject to Apple's legal posture, which (especially with ADP) is the strongest in the industry for this data class. This is not a marketing claim; it is the *only* configuration where it can be true, and Astera is built in that configuration.

---

## 7. Cycle states (first-class)

Each state has its own home-tab presentation, its own prediction behavior, and its own notification copy. Switching states is reversible and never destroys history. Each row below describes the *behavior*; the user-facing language is set in §3 and §9.

| State | Notable behavior |
|---|---|
| Regular cycles | Standard prediction with tight confidence bands once cycles are logged. |
| Irregular cycles | Wider confidence bands. Never "you're late." Instead: "Your period is taking longer than usual; this is common." |
| PCOS | No ovulation prediction unless the user explicitly opts in. No pregnancy-test prompts. |
| Endometriosis | Wider bands by default. Pain logging surfaces front-of-card on the home tab. Cycle-pattern view emphasizes severity history (useful for clinician visits). |
| IUD | Acknowledges absent or light bleeds without flagging them as missed. If the user wants fertility tracking, prediction shifts to BBT and mucus signals. |
| Hormonal birth control | Distinguishes withdrawal bleeds from spontaneous cycles. Absent bleeds are treated as expected, not as a sign something is wrong. No "you might be pregnant" alerts. |
| Perimenopause | "This cycle may be anovulatory" framing. Cycle-length variance treated as expected, not as a tracking failure. |
| Surgical menopause or hysterectomy | No period predictions at all. The home tab supports logging symptoms, notes, and HRT-related side effects without forecasting bleeds. History stays. |
| Pregnant | Replaces cycle prediction UI with a week-by-week tracker. Preserves cycle history. Offers a return-to-tracking flow on user action. |
| After pregnancy loss | All cycle reminders go quiet for 30 days when the user switches here. They can turn them back on whenever they're ready; there is no countdown, no nudge. The pregnancy-loss record is preserved in history; **Astera never asks the user to delete it.** |
| TTC | Fertility window with confidence bands. Ovulation-test scan via camera (Astera+ feature). TTC mode never counts down, never blames, never compares the user to averages. It just shows the window. |
| Postpartum | Your period may not return for months while you're nursing or recovering. That's normal, and Astera will not ask "where is it?" Lochia tracking supported in early postpartum. |
| Tracking on testosterone | No bleed forecasting. Symptom and mood logging supported. The home tab acknowledges that cycle changes on T are real, varied, and not a problem. |

---

## 8. Onboarding: what we will *not* do

The inverse list, from the research:

- ❌ No 20-minute health questionnaire. Onboarding takes <60 seconds.
- ❌ No paywall before the user sees any value. Astera has no paywall at all on the core tracker (see §10).
- ❌ No promise-to-use-the-app commitment screen. (Flo did this and it is a dark pattern; we won't.)
- ❌ No "what's your goal" multi-page funnel. The cycle-state picker is the only goal selector.
- ❌ No email collection. Sign in with Apple or local-only.
- ❌ No "rate the app" prompt for at least 30 days of use, and only after a successfully completed cycle prediction.

---

## 9. Inclusive UX

Configured once at setup, applied everywhere.

- **Pronouns:** she/her, he/him, they/them, custom. App copy interpolates `{they} {are} on day {n} of {their} cycle`.
- **Salutation:** default is "you" or no salutation. Opt-in to "girl", "woman", "person", or custom.
- **Relationship structure:** single, partnered (cycle-tracking), partnered (not-tracking), polyamorous. Affects only the Partner Sync feature (Phase 2). Same-sex pairings are first-class.
- **TTC framing:** opt-in. Even within TTC, language is neutral ("you've logged 3 fertility-window days this cycle"), not "you and your husband."
- **Teen mode:** auto-enabled for ages 9 to 17 based on birth year. Hides fertility/TTC content, hides any sexual-health content, hides any third-party promo (there is none anyway). The lower bound is 9 because menarche can happen earlier than people remember and a 9-year-old who has started their period has a real need *now*. Anyone under 9 sees a supportive callout ("Astera is built for ages 9 and up. If that's not you yet, a trusted adult can help with the early years"), shown as a gentle line rather than a hard block.
- **App-lock copy:** the lock screen says "Locked" rather than "Authenticate" or "Verify your identity." Friction is unavoidable; coldness is not.
- **QA matrix:** every release tests at minimum: she/her+woman+single, they/them+person+polyamorous, he/him+person+partnered. Anything that breaks on these doesn't ship.

---

## 10. Astera+ (premium): *only after the free experience is great*

This section comes last by design. The free tier is the product. Astera+ exists for users who want to support continued development *and* happen to want some optional tools.

### Free, forever

Cycle tracking. Symptom logging. All cycle states. Prediction with confidence ranges. "Why this prediction" view. Education content. Notifications with previews. Export everything. HealthKit integration. iCloud sync. Calendar view. History. Audit trail. Cycle-state switching. Pronoun, salutation, and relationship configuration. Teen mode. App-level lock. Privacy policy. Delete-everything. All of it. Forever.

### Astera+: optional support tier

| Feature | Why it's premium, not free |
|---|---|
| App icons and themes | Cosmetic. Doesn't gate any utility. |
| Custom notification sounds | Same. |
| TTC fertility window with BBT integration and camera-based ovulation-test scan | Genuinely niche: only TTC users need it. Users who do need it tend to *want* a better tool and are happy to pay. |
| Clinical PDF export (full cycle chart formatted for a doctor's visit) | Niche use case, real value for the cohort that needs it. |
| Hormone-medication tracking with dose, time, and refill reminders | Same: niche but high-value to the cohort. |
| Partner sync (Phase 2) | Real engineering cost (CloudKit Shared DB, invite flow, conflict resolution). Premium covers the maintenance. |

**A "basic" period tracker user never hits a paywall.** They use Astera for a decade and never see an upsell screen. Astera+ surfaces only on:
- The settings tab, one row labeled "Astera+" with a clear, non-manipulative description.
- The TTC-mode entry point, with a single line: "The fertility window is free. Astera+ adds BBT charting and ovulation-test scanning if you want them."

Pricing: **$3/month, $20/year, or $60 lifetime.** Lifetime is honest here because the product is genuinely complete; there is no ongoing content cost. Pause subscription up to 6 months.

**Astera+ is free if cost is a barrier.** Anyone (students, low income, in transition between jobs, in any situation where $20 is real money) can request a free Astera+ unlock from a single line in Settings. No documents. No verification. The button reads: *"If cost is in the way, tap here."* That's it. The trust cost of someone gaming it is lower than the dignity cost of asking everyone to prove they need help.

### The promise

If Astera ever ships a feature that makes the *free* experience worse to push users toward premium, it has betrayed its founding principle. The maintainer (Anker) commits to this in a one-line statement on the GitHub repo. Anything that violates it is a P0 bug.

---

## 11. Anti-patterns: do not ship these

1. ❌ Single-point predictions that ignore variance.
2. ❌ Notifications that frame bleeding, cramps, or PMS in flirtatious or sexual language.
3. ❌ "You might be pregnant" alerts for users with IUDs, on hormonal birth control, or who report no unprotected sex.
4. ❌ Any third-party SDK that sends cycle data off-device. None. Ever.
5. ❌ Pregnancy-after-loss requiring users to delete prior pregnancies.
6. ❌ Gendered language not opted into by the user.
7. ❌ Subscription gates on basic education.
8. ❌ Witchcraft, astrology, or moon-phase theming that obscures medical clarity. (Stardust's mistake; it is the reason Stardust failed.)
9. ❌ Customer support that auto-routes through a chatbot.
10. ❌ Full-screen upsells on the home tab.
11. ❌ Rate-the-app prompts within the first 30 days.
12. ❌ Notification badges that can't be disabled while keeping period reminders on.
13. ❌ Account loss on app update. SwiftData migrations must be regression-tested every release.
14. ❌ "Hardship verification" that asks users to prove they're poor. The free-if-it's-in-the-way tier in §10 requires no proof; it is a trust-by-default feature.

---

## 12. Phased roadmap (solo build, web to iOS)

Honest timelines for one engineer who is a strong web engineer but new to Apple platforms. Swift and SwiftUI themselves are easy if you're already a strong engineer; the *Apple framework surface* (HealthKit, CloudKit, StoreKit 2, SwiftData, MetricKit, App Review process) is wide enough to consume real time. Plan for it.

### Phase 0: iOS ramp (~4 weeks evenings/weekends)

Do not try to learn iOS *while* building Astera. You'll re-architect twice and ship nothing. Carve out a phase.

Pragmatic path:
- **Week 1.** Apple's "Develop in Swift Tutorials" (`developer.apple.com/tutorials/develop-in-swift`): Swift basics + Xcode fluency. Brisk pace; you already know how to program.
- **Week 2.** Paul Hudson's *100 Days of SwiftUI*. Skim, but actually do the SwiftData chapters and the persistence chapters in full.
- **Week 3.** Build a deliberately throwaway app (a "log my coffee" app) using **SwiftData with CloudKit sync enabled, HealthKit read+write for one type, Sign in with Apple, StoreKit 2 with a single non-consumable IAP, MetricKit crash hookup**. Ship it to TestFlight to one device. Don't put it in the App Store. The goal is to hit every framework Astera needs at least once in a low-stakes context.
- **Week 4.** Read Apple's sample apps for SwiftData+CloudKit (the "SyncingPlantData" sample is the canonical one). Read Apple's HIG sections on privacy, notifications, and onboarding. Read the App Review Guidelines (especially §5.1, Privacy).

By end of Phase 0 you can read SwiftUI code without translation and know what you don't know.

### Phase 1: Astera MVP (~14 weeks evenings/weekends)

Week 1–2. SwiftData schema. Get the CloudKit Private DB sync working end-to-end with a stub UI. Verify on two devices. This is the single highest-risk piece and you want it solved before you build features on top of it.
Week 3–4. First-launch onboarding (pronoun, salutation, relationship, cycle-mode pickers, app-lock prompt). Home tab shell.
Week 5–6. Logging flow + calendar view. Cycle records create, edit, history. HealthKit read+write integrated.
Week 7–8. **Prediction model v1.** Beta-distribution phase-length posteriors with population priors. "Why this prediction" sheet. This is the load-bearing engineering work; it will take longer than you expect. Budget the slack here.
Week 9. All cycle states wired up (UI variants + prediction-mode switching). Teen mode. App-level lock.
Week 10. Notifications with previews. Notification settings UI.
Week 11. Privacy policy. One-tap export (JSON + PDF). One-tap delete-everything. Audit trail screen.
Week 12. Education content for each cycle state. Empty states. Error states. Offline behavior verification.
Week 13. Polish pass. App icon. Screenshots for App Store Connect. Privacy nutrition label (which will read: **Data Not Collected**).
Week 14. TestFlight beta with ~20 testers from the people Astera is built for. App Review submission.

**MVP launches with no Astera+.** No premium tier at all on day one. Ship the free product, gather feedback for 4–8 weeks, then introduce Astera+ in v1.1.

### Phase 2 (~+6 weeks)

- Astera+ tier launches: app icons, themes, custom sounds, clinical PDF export.
- Hormone-medication tracking.
- Advanced TTC: BBT charting, ovulation-test scan (Vision framework).
- Free-if-cost-is-a-barrier tier wired up via a simple StoreKit promo-code flow.

### Phase 3 (~+8 weeks)

- Partner sync (CloudKit Shared DB + invite flow). The invite is one-way revocable from either side.
- iPad-optimized layout (do not ship until typing, navigation, and rotation are first-class; see how Notion failed).
- Apple Watch app: log flow + see today's prediction. Nothing else.

### Phase 4 (only after Phase 3 is solid)

- Localizations: en-GB, es, fr, de.
- Perimenopause-specific deep-dive content.
- Pregnancy mode (full week-by-week, separate sub-product feel).

---

## 13. Success metrics

The single load-bearing metric: **median absolute error of period-start prediction on the user's last 3 cycles**. Targets in §4.

Secondary, in priority order:

- Time to first prediction from first app open: **< 60 seconds**.
- Crash-free session rate: **> 99.9%**.
- Cold-launch to home-tab-rendered: **< 300ms** on iPhone 12 or newer.
- Free-tier retention at 90 days: **> 50%** (Flo's is rumored ~30%; we should beat it because we don't drive users out with paywall fatigue).
- App Store rating after 90 days: **≥ 4.7**.
- Astera+ conversion (after Phase 2): **3 to 6%**, not higher; if it's higher than that the free tier probably isn't generous enough.
- Zero data-sharing incidents. This is binary, brand-protection.

Anti-metrics (deliberately not optimized):
- DAU / MAU (cycle tracking is a once-a-cycle activity, not a daily habit).
- Session length (we want this *low*; log and leave).
- Engagement (in the modern PM sense). We don't want to maximize taps.

---

## 14. Regulatory & ethical notes (read this section)

- **No medical claims.** Astera surfaces predictions and observations. In-app language: "may indicate", "expected", "common", never "you have" or "you are." Positive example of the tone: *"You're on day 14. Your body is likely preparing to ovulate."* Not: *"Ovulation event predicted with 72% confidence."*
- **Reproductive privacy is a US legal risk.** In states where reproductive choices are criminalized, period data has been subpoenaed. The architecture in §5 is not a marketing choice; it is the legal safety floor. Do not weaken it.
- **The user-facing "why we built it this way" screen (§3, step 7)** names this in plain language for users who want to know. It does not assume every user is at risk; it does not euphemize the risk for those who are.
- **GDPR / UK GDPR / CCPA: satisfied by design**, not by policy.
  - *Right to access (GDPR Art. 15)*: in-app **Export Everything** produces a JSON + PDF ZIP instantly. No support ticket required.
  - *Right to erasure (Art. 17)*: in-app **Delete Everything** purges local storage and the user's CloudKit Private DB within seconds. HealthKit data is the user's own and managed in Apple Health; Astera does not own it.
  - *Right to data portability (Art. 20)*: the export is in an open JSON schema, documented and version-pinned in the public repo.
  - *Right to rectification (Art. 16)*: every cycle, symptom, and profile entry is editable in-app at any time.
  - *Privacy by design (Art. 25)*: the architecture in §5 is privacy-*by-design*, not privacy-by-policy. The developer does not hold user health data and cannot, by construction, leak it.
  - *Lawful basis for processing*: there is no developer-side processing of health data. The only processing happens on the user's device, under the user's control. Apple acts as the technical processor for sync; the legal frame is Apple's iCloud Data Processing Agreement.
  - *No data sale, no advertising, no third-party sharing*. Ever. The privacy policy states this in plain English in under 600 words and is hash-committed to the public repo so changes are auditable.
- **Apple App Review**: the privacy nutrition label and the absence of third-party SDKs should make this clean. Flag in App Review notes: "This app stores all user data in the user's own iCloud (CloudKit Private Database and HealthKit). The developer cannot read user data."
- **No data sale.** Ever. This is non-negotiable. If Astera is ever acquired, the acquisition contract must preserve this guarantee in writing or the deal does not close.

---

## 15. What this spec is not

This is the product brief, not an engineering ticket list. The hard sub-problem is the prediction model in §4; budget time accordingly. Everything else is iOS-engineering-grade-known.

If something here conflicts with the principles in §2, the principles win. Astera is the tracker you'd build for someone you love; act accordingly.

---

## Appendix A: Build notes for a web engineer

You're coming from web. Some things will surprise you.

- **There is no `package.json` equivalent that "just works."** Swift Package Manager is integrated into Xcode and is fine, but the package ecosystem is small. You will use far fewer third-party libraries than on web, partly because the standard library is richer, partly because there are no third-party SDKs allowed in this app anyway. Treat this as a feature, not a limitation.
- **The build system is Xcode, not a CLI by default.** You *can* drive builds from the command line (`xcodebuild`) but accept early that Xcode is the IDE and learn its layout. Especially: the Scheme editor, Provisioning Profiles, Signing & Capabilities, and the Console (Cmd-Shift-C).
- **iCloud / CloudKit setup is configured in App Store Connect + Capabilities, not in code.** You enable the iCloud capability, choose CloudKit, configure containers, and your SwiftData ModelConfiguration picks it up. The dev-vs-production CloudKit environment split will bite you if you don't read about it before getting deep.
- **HealthKit requires explicit Info.plist entries** for every data type you read or write, with user-facing usage strings. App Review rejects HealthKit apps with vague usage strings. Write them warmly and clearly: "So Astera can help you anticipate your next period and notice patterns over time."
- **SwiftData is new (iOS 17+).** It's good, but the Stack Overflow / Apple Forums corpus is thin. When you hit edge cases (especially around CloudKit conflict resolution and migration), Apple's WWDC sessions are usually the best source. The 2023 and 2024 WWDC SwiftData sessions are required watching.
- **Background fetch / notifications are restrictive.** iOS will not let you run arbitrary background work on a schedule. For Astera this is fine: prediction is fast, runs at app foreground, and notifications are scheduled via `UNUserNotificationCenter` at known cycle events. Don't fight the platform here.
- **App Review is a real process.** Submission can take 1–7 days. Reviewers will check that HealthKit usage matches what's described, that your privacy policy is reachable, that you don't ship dark patterns. For Astera the privacy stance is your friend; it's easy to defend.
- **TestFlight is excellent.** Use it heavily from week 9 onwards. Add 5 to 10 early testers from the people Astera is built for. Their feedback on the *inclusive UX* matters more than any technical detail.
- **StoreKit 2** is much cleaner than StoreKit 1. Ignore most StoreKit 1 tutorials online; they're noise. Apple's "Meet StoreKit 2" session is the right starting point.
- **You cannot reliably test IAP in the simulator**; use a real device with a Sandbox Apple ID. This trips up everyone once.
- **You will write less code than on a web product of comparable scope.** SwiftUI + SwiftData + CloudKit eliminates most of the data-layer plumbing you're used to. Embrace this. The engineering wins are in the prediction model and the inclusive-UX matrix, not in framework wrangling.

### What to NOT do, learned from the research

- Do not pull in a single third-party analytics, attribution, or crash SDK. The privacy story is your moat. The first SDK you add is the day Astera stops being different from Flo.
- Do not architect for "scale" before Phase 1 ships. CloudKit Private DB is the scale solution. There is no service to scale.
- Do not gold-plate the prediction model in Phase 1. Ship the Beta-distribution version, see real user data, iterate. The biggest improvement to prediction accuracy will come from *real cycle data* you can study (privately, on-device, in TestFlight), not from a fancier model up front.
- Do not over-design the partner sync (Phase 2). CloudKit Shared DB is finicky; the simplest possible invite flow is the right one.
