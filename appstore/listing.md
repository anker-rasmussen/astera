# Astera — App Store Connect listing

Everything to paste into App Store Connect → My Apps → Astera. Character counts include spaces.

---

## App Information (set once, persists across versions)

**Name** (30 char limit, 22 used)
```
Astera: Period tracker
```

**Subtitle** (30 char limit, 25 used)
```
Honest cycle predictions.
```

**Primary Category**
```
Health & Fitness
```

**Secondary Category** _(optional, broadens discovery without changing review scrutiny)_
```
Lifestyle
```

**Privacy Policy URL**
```
https://anker-rasmussen.github.io/astera/privacy/
```

**Support URL**
```
https://github.com/anker-rasmussen/astera/issues
```

**Marketing URL** _(optional, recommend the landing page)_
```
https://anker-rasmussen.github.io/astera/
```

**Copyright**
```
© 2026 Anker Rasmussen
```

**License Agreement (App Information → License Agreement)**
```
Leave at Apple's Standard License Agreement. Do not upload a custom EULA.
```

_Deliberate. We link Apple's standard Terms of Use from the App Description instead, which is the path Apple's own rejection notice offers. Filling in a custom EULA here while also linking the standard one is a contradiction reviewers bounce. If a future version needs bespoke terms, change both at once._

---

## Version 1.0 (per-release metadata)

### Promotional Text (170 char limit, 132 used. Editable any time without re-submission.)

```
The tracker you'd build for your sister. Honest predictions, opt-in everything, your data never leaves your phone unless you ask.
```

### Description (4000 char limit, ~2,800 used)

```
A quieter way to know your body.

Astera is a period and cycle tracker built for people who are tired of being treated like a data point. The full tracker is free. There are no ads. There are no third-party SDKs. Your cycles, symptoms, and notes live on your phone and, if you want, in your own iCloud. The person who built Astera cannot read your data, because there is no server to read it from.

HONEST PREDICTIONS

Astera shows you a window, not a single date pretending to be certain. Every prediction comes with a confidence range, and a "why this prediction" view that shows the math. If your cycles are irregular, the window stays wider on purpose. That's honest, not a bug.

BRING YOUR HISTORY WITH YOU

If you've been using Flo, Clue, Stardust, or Apple's built-in Cycle Tracking, Astera can pull your menstrual history straight from Apple Health. One tap. Years of data, restored. You don't start from scratch.

FOR WHERE YOU ACTUALLY ARE

Regular cycles. Irregular cycles. PCOS. IUDs and hormonal birth control. Perimenopause. Surgical menopause. Pregnancy. After pregnancy loss. Trying to conceive. Postpartum. Tracking on testosterone. Not sure yet.

Each is a first-class state with its own home tab, its own prediction behaviour, and its own copy. Switch any time. Your history stays exactly where it is.

CARE FOR THE HARD SCREENS

The post-loss home tab says "We're here." Not "Day 14." Periods come back when they come back. Cycle changes on testosterone are real and varied. Astera was built with care for the screens other apps treat as edge cases. None of those needs to be turned into a countdown.

LOG WHAT MATTERS, SKIP THE REST

Per-symptom severity. Cravings tracking and lifestyle tracking, both off by default and easy to turn on if you'd like them. Sexual activity logging, off by default and hidden entirely for users under 16. The log sheet adapts to what you've chosen.

EXPORT, NOT LOCK-IN

Take a copy with you whenever you'd like: a clean PDF you can print, save, or hand to a clinician. Delete everything any time. Your data is yours.

INCLUSIVE BY DESIGN

Pronouns, salutation, and the greeting at the top of the home tab are all configurable. There's no assumption baked into the app about who you are. The greeting can even be your own words.

PRIVACY, BY ARCHITECTURE

Your data lives on this phone. If you're signed into iCloud, an encrypted copy syncs to your own Apple devices, where your photos and notes already live. With Advanced Data Protection on, not even Apple can read it. There is no Astera-operated server. There is no Astera account.

ASTERA+

The full tracker is free, always. Astera+ exists for people who'd like to support the project and happen to want a few extras (themes, widgets, detailed insights, custom symptoms, and the Apple Watch app on the way). Tip-jar pricing: under 50p a month, under £5 a year, or £15 once for lifetime. Never pushed. There's no paywall on anything you actually need.

Astera+ Monthly is an auto-renewing subscription of one month at £0.49. Astera+ Yearly is an auto-renewing subscription of one year at £4.99. Payment is charged to your Apple ID at confirmation of purchase, and each renews automatically at the same price unless auto-renew is turned off at least 24 hours before the current period ends. Manage or cancel in the App Store app, under your Apple ID, in Subscriptions. Astera+ Lifetime is a one-time purchase of £15.00 and does not renew.

Privacy policy: https://anker-rasmussen.github.io/astera/privacy/
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

Astera makes no medical claims. Predictions are estimates, not advice. If something about your cycle worries you, please talk to a clinician.

Built and maintained by one engineer in the UK.
```

> The two URLs above are required by Guideline 3.1.2(c) and must stay in the Description. The same two links appear inside the app on the Astera+ screen, sourced from `AsteraDev/Resources/AsteraLinks.swift`. If either URL changes, change it in both places.

### Keywords (100 char limit, 95 used. Comma-separated, no spaces.)

```
cycle,menstrual,ovulation,fertility,PCOS,endo,perimenopause,menopause,pregnancy,postpartum,TTC
```

_Don't repeat "period," "tracker," "privacy," or "Astera." Apple already indexes those from your name, subtitle, and description._

### What's New in This Version (4000 char limit, used here for v1.0)

```
Welcome to Astera. The first version.
```

---

## Screenshots (drag in order, 6.9″ slot accepts 1284×2778)

Located at `appstore/screenshots/` in the repo. Recommended carousel order:

1. `01-home.png` — daily hero: cycle ring, prediction, log button
2. `02-why-prediction.png` — confidence ranges, math shown
3. `08-promise.png` — "Astera doesn't collect anything"
4. `03-settings-top.png` — inclusive profile + opt-in logging
5. `04-bring-history.png` — import from Apple Health
6. `05-history.png` — calendar of cycles
7. `06-log-sheet.png` — clean log UI
8. `07-log-sheet-scrolled.png` — severity, cravings, lifestyle depth

---

## App Privacy questionnaire (App Privacy → Get Started)

**Q: Do you or your third-party partners collect data from this app?**
```
No
```

That's the entire answer. Astera does not collect any data. iCloud Private Database and HealthKit storage do not count as developer-side collection — the data lives in the user's own iCloud and Apple Health, never in any system the developer can read. The nutrition label will render "Data Not Collected" across every category.

If App Store Connect prompts follow-ups, the answer is "No" to every category (Contact Info, Health & Fitness, Financial Info, Location, Identifiers, Usage Data, Diagnostics, etc.).

---

## Age Rating questionnaire

| Category | Answer |
|---|---|
| Medical / Treatment Information | **Infrequent / Mild** _(predictions framed as estimates, not advice)_ |
| Sexual Content or Nudity | **None** _(sex-related logging chips are hidden for under-16 users, hidden by default for 16+, and contain no graphic content even when enabled)_ |
| Cartoon / Fantasy Violence | None |
| Realistic Violence | None |
| Profanity / Crude Humor | None |
| Alcohol / Tobacco / Drug Use | None |
| Mature / Suggestive Themes | None |
| Horror / Fear Themes | None |
| Gambling | None |
| Contests | None |
| Unrestricted Web Access | None |
| Made for Kids | No |

**Expected outcome: 12+**

---

## Pricing & Availability

- **Price**: Free
- **Availability**: All territories (recommend launching everywhere; the app has no regional dependencies)

---

## Export Compliance

Pre-declared via `ITSAppUsesNonExemptEncryption=false` in `AsteraDev/Info.plist`. App Store Connect won't ask the encryption questionnaire at submission. If it does, answer **No, doesn't use encryption** (we use Apple's standard frameworks; the exemption applies).

---

## Build management (before each upload)

- `CFBundleShortVersionString` stays at `1.0` for the first public version
- Increment `CFBundleVersion` (build number) on every upload to App Store Connect (`1`, `2`, `3`, ...)
- Xcode Cloud handles archive + upload to TestFlight automatically. Once your build is on TestFlight you can attach it to the v1.0 record in App Store Connect.

---

## CloudKit production schema (do this before submission)

Before the first public submission, deploy the development schema to production in CloudKit Dashboard:

1. Open [icloud.developer.apple.com](https://icloud.developer.apple.com)
2. Pick the `iCloud.com.anker.astera` container
3. Schema → Development → **Deploy Schema to Production**

If you skip this, CloudKit sync silently fails in production builds. The single easiest pre-launch thing to forget.
