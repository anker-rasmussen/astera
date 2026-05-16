# Astera — App Review notes

Paste into App Store Connect → Version 1.0 → App Review Information → Notes.

---

```
Astera is a privacy-first period and cycle tracker. A few things worth flagging up front to make review faster:

1. PRIVACY ARCHITECTURE
Astera stores all user data on-device and, optionally, in the user's own iCloud (CloudKit Private Database) and Apple Health (HealthKit). There is no Astera-operated backend. The developer cannot read user data. No third-party SDKs are used: no analytics, no advertising, no attribution, no crash reporting beyond Apple's own MetricKit. The privacy nutrition label is "Data Not Collected" and that is accurate.

2. NO SIGN-IN
Astera does not require an account. iCloud sign-in is implicit via the device. There is no test account to provide because there is no account system. The app is fully functional on a device with no iCloud configured (local-only mode).

3. HEALTHKIT USAGE
Astera reads and writes only `menstrualFlow`. The read is used to import the user's history from other tracking apps (Flo, Clue, Stardust, Apple Cycle Tracking) so users don't lose data when switching to Astera. The write is so logs in Astera are mirrored back to Apple Health if the user opts in. The usage strings in Info.plist describe both. Both are opt-in via toggles in Settings.

4. EVENTKIT USAGE
When the user opts in, Astera creates a dedicated "Astera" calendar and writes predicted period dates to it. It never reads or modifies any other calendar.

5. FACE ID / TOUCH ID
Used for an optional app-level lock. The lock is off by default. The usage string in Info.plist explains the purpose.

6. IN-APP PURCHASES
Three optional Astera+ products: monthly (£0.50), yearly (£5), lifetime (£30). The full tracker (logging, prediction, history, calendar sync, HealthKit, export, delete, FaceID lock) is free without any purchase. Astera+ is purely a support tier that unlocks cosmetic and convenience features. There is no paywall on core functionality.

7. NO MEDICAL CLAIMS
Predictions are surfaced as estimates with confidence ranges. Language uses "may," "expected," "common." Never diagnostic terms. The privacy policy explicitly states Astera makes no medical claims.

8. AGE GATING
Users entering a birth year that puts them under 18 see fertility/TTC content hidden. Users under 16 cannot see sexual-activity logging chips or the corresponding settings toggle. Both gates apply regardless of any toggle state, and toggles are auto-cleared if a birth year change drops them below a gate.

9. PUBLIC PRIVACY POLICY
The privacy policy is hash-committed to a public GitHub repository so every revision is visible in git history:
https://anker-rasmussen.github.io/astera/privacy/
Source: https://github.com/anker-rasmussen/astera/blob/main/AsteraDev/Resources/PrivacyPolicy.swift

If anything here needs clarification, please reach me via the support URL or by email at anker@rasmussen.engineering.
```

---

**Demo account section**

Sign-in required: **No**. The app does not have an account system.

**Contact Information**

| Field | Value |
|---|---|
| First Name | Anker |
| Last Name | Rasmussen |
| Phone | _(your phone)_ |
| Email | anker@rasmussen.engineering |
