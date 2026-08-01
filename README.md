# Astera

A privacy-first period and cycle tracker for iOS.

The full tracker is free, forever. No ads, no third-party SDKs, no analytics. Your cycles, symptoms, and notes live on your phone and, if you want, in your own iCloud. The person who built Astera cannot read your data, because there is no server to read it from.

## Why this exists

The dominant period trackers have collectively trained around 300 million people to expect a category-defining product, then progressively degraded it. Flo shared menstrual data with Meta. Clue stacked paywalls onto features that used to be free. Stardust ships predictions that are off by weeks for irregular cycles, and has shipped sexualized notification copy.

There is room in this category for a tracker that is built for the user instead of around the user. This is that.

## What's in it

- Honest predictions, with confidence ranges instead of single dates.
- A "why this prediction" view that shows the math underneath.
- First-class support for: regular cycles, irregular cycles, PCOS, endometriosis, IUDs, hormonal birth control, perimenopause, surgical menopause, pregnancy, after pregnancy loss, trying to conceive, postpartum, and tracking on testosterone. Each is its own home tab, with its own prediction behaviour and its own copy. Switching states never deletes history.
- An optional app lock (Face ID, Touch ID, or passcode) for shared phones and unsafe situations.
- One-tap export of everything you've logged, in a documented JSON format.
- One-tap delete of everything, with no recovery, by design.
- HealthKit read and write for menstrual flow.
- A dedicated "Astera" calendar that holds your predicted period dates and never touches your other calendars.

## What's not in it

- A login or account system. The app is fully usable on a device with no iCloud configured.
- Any third-party SDK. None. Not Facebook's, not Mixpanel's, not Amplitude's, not Google's, not Segment's.
- An Astera-operated backend. There isn't one.
- Analytics, telemetry, attribution, or crash reporters beyond Apple's own MetricKit.
- Engagement metrics, retention A/B tests, push spam, dark patterns, "rate the app" prompts inside the first 30 days.

## The privacy promise

The full policy is at [PRIVACY.md](./PRIVACY.md), committed to this public repo so every change is visible in git history.

The short version: nothing leaves your phone unless you ask it to. Your cycle data lives in CloudKit Private Database (your own iCloud silo) and Apple Health. With Advanced Data Protection enabled, not even Apple can read it. The developer of this app cannot read your data, by construction, because the architecture leaves nowhere for the developer to read from.

This isn't a marketing claim. It's the only configuration in which it can be true, and Astera is built in that configuration.

## Status

Astera is built by a single engineer in evenings and weekends. It launches on TestFlight first, then a public App Store release once it has been through real use with real testers.

If you want to be on the TestFlight beta, file a GitHub issue and I'll send you an invite.

## Building from source

iOS 17 or later. Swift 5.10. SwiftUI. SwiftData. No third-party dependencies.

To run locally:

1. Open `AsteraDev.xcodeproj` in Xcode 26 or later.
2. Update `DEVELOPMENT_TEAM` in `project.yml` if you have your own Apple Developer account.
3. Run on a real device for HealthKit, StoreKit, and CloudKit work. The simulator is fine for everything else.

The product spec is at [specs/astera.md](./specs/astera.md). It is the source of truth for principles and behaviour, ahead of any code. If something in the code conflicts with the spec, the spec wins.

## Contributing

This is a solo project for now, so pull requests are not being accepted. Issues are welcome: bug reports, accessibility regressions, copy that lands wrong, prediction errors against your own cycle data, anything that helps Astera be the tracker it claims to be.

## License

[Mozilla Public License 2.0](./LICENSE).

MPL-2.0 is file-level copyleft. You can use Astera's code in your own project, including a closed-source one, but any modifications you make to MPL-licensed files have to be shared back under MPL. In practice: anyone is welcome to learn from the code, port pieces of it, or fork it, as long as improvements to those pieces stay open. Nobody gets to clone the whole tracker, close the source, and ship it as a competitor.

## Contact

Anker Rasmussen. File a GitHub issue, or reach me at anker.rasmussen09@gmail.com.

Astera is the tracker I would build for someone I love. That is the entire product principle. Everything else descends from it.
