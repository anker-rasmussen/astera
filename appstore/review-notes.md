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
Three optional Astera+ products, all reachable from Settings → Astera+:
- Astera+ Monthly (product ID 000), auto-renewable subscription, 1 month, £0.49
- Astera+ Yearly (product ID 001), auto-renewable subscription, 1 year, £4.99
- Astera+ Lifetime (product ID 002), non-consumable, one-time, £14.99
All three are submitted with this version. The full tracker (logging, prediction, history, calendar sync, HealthKit, export, delete, Face ID lock) is free without any purchase. Astera+ is purely a support tier that unlocks cosmetic and convenience features. There is no paywall on core functionality.

7. SUBSCRIPTION DISCLOSURES (Guideline 3.1.2(c))
The Astera+ screen (Settings → Astera+) displays, without scrolling past the offer: the title of each product, its length, and its price. Below the offer, under "The small print", it states that the monthly and yearly products renew automatically at the same price unless auto-renew is turned off at least 24 hours before the period ends, that payment is charged to the Apple ID at confirmation, and where to manage or cancel. It also states that Astera+ Lifetime is a one-time purchase that never renews.
The same screen carries two functional links, both of which open in Safari:
- Privacy policy: https://anker-rasmussen.github.io/astera/privacy/
- Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Astera uses Apple's standard Terms of Use (EULA), not a custom one. The same link is in the App Description, and the License Agreement field is left at Apple's standard agreement.

8. NO MEDICAL CLAIMS
Predictions are surfaced as estimates with confidence ranges. Language uses "may," "expected," "common." Never diagnostic terms. The privacy policy explicitly states Astera makes no medical claims.

9. AGE GATING
Users entering a birth year that puts them under 18 see fertility/TTC content hidden. Users under 16 cannot see sexual-activity logging chips or the corresponding settings toggle. Both gates apply regardless of any toggle state, and toggles are auto-cleared if a birth year change drops them below a gate.

10. PUBLIC PRIVACY POLICY
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
