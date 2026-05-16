# Astera. App Review notes

Paste this into App Store Connect → Submit for Review → App Review Information → Notes.

---

```
Astera is a privacy-first period and cycle tracker. A few things worth flagging up front to make review faster:

1. PRIVACY ARCHITECTURE
Astera stores all user data in the user's own iCloud (CloudKit Private Database) and Apple Health (HealthKit). There is no Astera-operated backend. The developer cannot read user data. No third-party SDKs are used: no analytics, no advertising, no attribution, no crash reporters beyond Apple's own MetricKit. Privacy nutrition label is "Data Not Collected" and that is accurate.

2. NO SIGN-IN
Astera does not require an account. iCloud sign-in is implicit via the device. There is no test account to provide because there is no account system. The app is fully functional on a device with no iCloud configured (local-only mode).

3. HEALTHKIT USAGE
Astera reads and writes only `menstrualFlow`. The usage strings in Info.plist describe this plainly. The feature is opt-in via a toggle in Settings.

4. CALENDAR USAGE
When the user opts in, Astera creates a dedicated "Astera" calendar and writes predicted period dates to it. It never reads or modifies any other calendar.

5. FACE ID / TOUCH ID
Used for an optional app-level lock. The lock is off by default. Usage string in Info.plist explains the purpose.

6. NO IN-APP PURCHASE IN V1
Astera+ (the optional support tier) is not in this build. The full free tracker is the v1 product. IAP will be introduced in a future version.

7. NO MEDICAL CLAIMS
Predictions are surfaced as estimates with confidence ranges. Language throughout the app uses "may", "expected", "common", never diagnostic terms.

8. PUBLIC PRIVACY POLICY
The privacy policy is committed to a public GitHub repository so changes are visible in git history: https://github.com/<your-github-username>/astera/blob/main/PRIVACY.md

If anything here needs clarification, reach the developer via the support URL or by email at anker.rasmussen09@gmail.com.
```

---

**Demo account section in App Review Information:**

Tick "Sign-in required: No". The app does not require an account.

**Contact Information:**

- First Name: Anker
- Last Name: Rasmussen
- Phone: <your phone>
- Email: anker.rasmussen09@gmail.com
