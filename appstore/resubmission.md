# Resubmission after the v1.0 rejection

Two rejections came back together. They resolve through **different mechanisms**, and the order below matters because the screen recording has to show the new build.

| Guideline | What Apple wants | Resolves via |
|---|---|---|
| 2.1(b) Performance | The three Astera+ IAPs submitted for review with the app | A **new binary** plus the IAPs attached to the version |
| 3.1.2(c) Subscriptions | Subscription terms and both legal links, in the app and in the metadata | Metadata edits plus a **screen recording reply** |

---

## What's already done in the repo

- `AsteraDev/Resources/AsteraLinks.swift` holds the two legal URLs. Both verified live.
- `AsteraPlusView.swift` gained a "The small print" block: the terms, plus tappable Privacy policy and Terms of Use (EULA) links that open in Safari.
- `asteraTierDescription` in `AsteraPlusService.swift` now states length, price, and renewal for each product. Renewal wording is switched per product ID, so the non-consumable lifetime tier says it never renews.
- `appstore/listing.md` Description now carries both URLs and the subscription terms paragraph.
- `appstore/review-notes.md` section 7 records the disclosures for the Notes field, which the rejection asks for explicitly.
- Settings footer reads the real version from the bundle instead of the old hardcoded "version 0.1 · early days".

## Order of operations

### 1. In App Store Connect: get the three IAPs to Ready to Submit

This is the whole of 2.1(b). Product IDs and copy are in `appstore/iap.md`.

For **each** of 000, 001, 002:

- [ ] Localization filled in (display name and description)
- [ ] Price set
- [ ] **App Review screenshot uploaded.** This is the item the rejection names. Without it the product cannot reach Ready to Submit. Capture the Astera+ screen from the running app, or use `appstore/screenshots/`.
- [ ] Review notes pasted
- [ ] Status shows **Ready to Submit**

### 2. Attach the IAPs to the version

- [ ] On the **version page** (not the product pages), in the In-App Purchases and Subscriptions section, **select all three products** for submission with this build.

Products can sit at Ready to Submit indefinitely without being part of the submission. This step is the usual cause of a 2.1(b) rejection and is almost certainly what happened here.

### 3. Metadata edits

- [ ] Description replaced with the version in `appstore/listing.md`, including the two URLs
- [ ] Privacy Policy URL is `https://anker-rasmussen.github.io/astera/privacy/`
- [ ] **License Agreement left at Apple's Standard License Agreement.** Do not upload a custom EULA. We link Apple's standard terms from the Description instead, and doing both is a contradiction reviewers bounce.
- [ ] App Review Information → Notes updated from `appstore/review-notes.md`

### 4. Build and upload

- [ ] Bump `CFBundleVersion` in `AsteraDev/Info.plist` (1 → 2). `CFBundleShortVersionString` stays `1.0`.
- [ ] Archive and upload, attach the build to the version

### 5. Record the screen recording

Do this on the uploaded build, not on a simulator running older code. Apple asks for a recording that confirms the disclosures. One continuous take, no cuts:

1. Open the app, go to Settings
2. Scroll to Astera+ and tap in
3. Show the three products with their titles, lengths, and prices on screen
4. Scroll to "The small print" and pause long enough to read the renewal terms
5. Tap **Privacy policy**, let Safari load the page, come back
6. Tap **Terms of Use (EULA)**, let Safari load Apple's terms, come back

### 6. Reply to App Review

Attach the recording and reply in the Resolution Center. Draft:

```
Thank you for the review.

Regarding 2.1(b): all three In-App Purchase products (Astera+ Monthly, 000; Astera+ Yearly, 001; Astera+ Lifetime, 002) are now submitted for review with this build, each with an App Review screenshot.

Regarding 3.1.2(c): the attached screen recording shows the Astera+ screen (Settings, then Astera+), which displays the title, length, and price of each product, states the auto-renewal terms for the monthly and yearly subscriptions, and carries functional links to both the privacy policy and the Terms of Use. Astera uses Apple's standard Terms of Use (EULA); the link is now in the App Description, and the License Agreement field is left at Apple's standard agreement. The same information is in the Notes field of the App Review Information section.

Privacy policy: https://anker-rasmussen.github.io/astera/privacy/
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

---

## Notes for next time

- The two legal URLs live in `AsteraDev/Resources/AsteraLinks.swift` and in `appstore/listing.md`. Changing one without the other is the way this comes back.
- The privacy policy exists in three places, all at **v1.1**: `PRIVACY.md`, `docs/privacy/index.html` (the live page), and `AsteraDev/Resources/PrivacyPolicy.swift` (what ships in the app). A reviewer can compare the in-app text against the linked URL, so they have to agree. If the text changes, bump the version in all three and confirm the live page has redeployed **before** recording anything.
- CloudKit production schema deploy is still a pre-launch step. See `appstore/listing.md`.
