# Astera. App Store Connect listing

Paste these into App Store Connect → My Apps → Astera. Character counts include spaces.

---

## App Information (set once)

**Name** (30 char limit, 6 used)
```
Astera
```

**Subtitle** (30 char limit, 28 used)
```
Period tracker. Yours alone.
```

**Category, primary**
Health & Fitness

**Category, secondary**
Medical _(optional, do not pick if it triggers extra App Review scrutiny you don't want; "Lifestyle" is the safe fallback.)_

**Privacy Policy URL**
```
https://github.com/<your-github-username>/astera/blob/main/PRIVACY.md
```
_(Or set up GitHub Pages on the repo and use `https://<username>.github.io/astera/privacy` for a prettier URL. Apple accepts the raw GitHub URL; either works.)_

**Support URL**
```
https://github.com/<your-github-username>/astera/issues
```

**Marketing URL** _(optional, leave blank for v1)_

**Copyright**
```
© 2026 Anker Rasmussen
```

---

## Version Information (per release)

**Version**
```
1.0
```

**Promotional Text** (170 char limit, 145 used. Can change without resubmitting.)
```
A privacy-first period tracker that doesn't sell your data. Free forever, no ads. Built for regular cycles, PCOS, endo, perimenopause, and on T.
```

**Description** (4000 char limit, ~2,200 used)
```
A quieter way to know your body.

Astera is a period and cycle tracker built for people who are tired of being treated like a data point. The full tracker is free, forever. There are no ads. There are no third-party SDKs in this app. Your cycles, symptoms, and notes live on your phone and, if you want, in your own iCloud. The person who built Astera cannot read your data, because there is no server to read it from.

HONEST PREDICTIONS

Astera shows you a window, not a single date pretending to be certain. Every prediction comes with a confidence range, and a "why this prediction" view that shows the math. If your cycles are irregular, the window stays wider on purpose. That is honest, not a flaw.

FOR WHERE YOU ACTUALLY ARE

Regular cycles. Irregular cycles. PCOS. Endometriosis. IUDs. Hormonal birth control. Perimenopause. Surgical menopause. Pregnancy. After pregnancy loss. Trying to conceive. Postpartum. Tracking on testosterone. Not sure yet.

Each of these is a first-class state with its own home tab, its own prediction behaviour, and its own copy. Switch between them any time. Your history stays exactly where it is, no matter how many times you switch.

CARE FOR THE HARD SCREENS

The post-loss home tab says "We're here." Not "Day 14." Periods come back when they come back. Cycle changes on testosterone are real and varied. Astera was built with care for the screens that other apps treat as edge cases. None of those needs to be turned into a countdown.

FREE, FOREVER

The full tracker is free. No paywall on education. No paywall on prediction. No paywall on the cohorts. No paywall on anything you actually need to track your cycle. Astera+ exists for people who want to support development and happen to want a few niche extras (clinical PDF export, hormone medication tracking, BBT charting, Apple Watch). The free tracker is the product. Astera+ is the tip jar.

PRIVACY, BY ARCHITECTURE

Your data lives on this phone. If you are signed into iCloud, an encrypted copy syncs to your other Apple devices via Apple's iCloud, the same place your photos and notes live. The developer has no server, no analytics, no third-party SDK. With Advanced Data Protection on, not even Apple can read your data. You can export everything any time. You can delete everything any time.

This is the tracker you would build for someone you love.
```

**Keywords** (100 char limit, 96 used. Comma-separated, no spaces.)
```
cycle,menstrual,ovulation,fertility,PCOS,endo,perimenopause,menopause,pregnancy,postpartum,TTC
```

_Don't include "period", "tracker", "privacy" or "Astera" in keywords. Those are already indexed from your name, subtitle, and description._

---

## App Privacy nutrition label (Privacy section in App Store Connect)

**Do you or your third-party partners collect data from this app?**
```
No
```

That is the entire answer. Astera does not collect any data. CloudKit Private Database and HealthKit do not count as developer-side collection because the data lives in the user's own iCloud and Apple Health, never in any system the developer can read. The nutrition label will display "Data Not Collected."

If App Store Connect asks follow-up questions: the answer is "No" to every category.

---

## Age rating

When you fill out the age rating questionnaire, the relevant flags are:

- Medical/Treatment Information: **Infrequent/Mild** (predictions are framed as estimates, not advice).
- Sexual Content or Nudity: **None** (no images; sex-related logging chips are off by default for under-18 users via teen mode).
- All other categories: **None**.

Expected outcome: **12+** rating.

---

## Pricing & Availability

- Price: **Free**
- Availability: All territories (or pick the subset you want to launch in first; UK and US is a reasonable starting set).
- In-App Purchases: none for v1.0. Astera+ launches in v1.1 per the spec.

---

## Export Compliance

Already declared via `ITSAppUsesNonExemptEncryption=false` in Info.plist. App Store Connect will not ask the encryption questionnaire on submission.

---

## Build

- Increment `CFBundleVersion` to `2` (or any value higher than what is already uploaded) before each new upload to App Store Connect. `CFBundleShortVersionString` stays at `1.0` for the first public version.
- Archive: Xcode → Product → Archive.
- Upload: Xcode Organizer → Distribute App → App Store Connect.

---

## CloudKit production schema

Before the first public submission, deploy the development schema to production in CloudKit Dashboard:

1. Open [icloud.developer.apple.com](https://icloud.developer.apple.com)
2. Pick the `iCloud.com.anker.astera` container.
3. Schema → Development → "Deploy Schema to Production".

If you skip this, CloudKit sync silently fails in production builds. Easiest thing in the world to forget.
