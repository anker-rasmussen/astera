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

### 0. Confirm the three prices App Store Connect actually holds

Do this first, because the Description and the review notes both state prices in GBP and a mismatch there is a fresh 3.1.2 rejection rather than a fix.

`scripts/check_consistency.py` only proves the repo agrees with `AsteraPlus.storekit`, and that file is a **local mock for the simulator**. It has no connection to App Store Connect and its storefront is set to USA. A green check says the paperwork is self-consistent, not that Apple holds these numbers.

The simulator is not a second opinion either. StoreKit's local test framework snaps `displayPrice` to a price point it recognises, so the number the app renders is not necessarily the number in the config. The lifetime tier was briefly set to a round `15.00` and rendered as `$14.99` regardless. That is why it is 14.99 now, and it is also why the screen recording in step 5 must not be made on a simulator.

In App Store Connect, Monetization → In-App Purchases, open each product and read the GBP row of the price table:

- [ ] 000 Astera+ Monthly is **£0.49**
- [ ] 001 Astera+ Yearly is **£4.99**
- [ ] 002 Astera+ Lifetime is **£14.99**

If any of the three disagree, either change the price in App Store Connect or change the number in the repo. App Store Connect is the authority. The repo restates these prices in three places, all of which `check_consistency.py` guards:

- `appstore/listing.md` (Description, and the subscription terms paragraph)
- `appstore/review-notes.md`
- `AsteraDev/Resources/AsteraPlus.storekit`

### 1. In App Store Connect: get the three IAPs to Ready to Submit

This is the whole of 2.1(b). Product IDs and copy are in `appstore/iap.md`.

For **each** of 000, 001, 002:

- [ ] Localization filled in (display name and description)
- [ ] Price set
- [ ] **App Review screenshot uploaded.** This is the item the rejection names. Without it the product cannot reach Ready to Submit. Upload `appstore/iap-review-screenshot.png` for all three; the field takes one image per product and the same one is correct for each.
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

- [x] `CFBundleVersion` in `AsteraDev/Info.plist` is now `2`. `CFBundleShortVersionString` stays `1.0`. Bump it again for every further upload, even a rejected one: App Store Connect refuses a build number it has already seen.
- [ ] Archive and upload, attach the build to the version

### 5. Record the screen recording

**Record on a real device running the TestFlight build, never on a simulator.** Two reasons, and the second is easy to miss: a simulator may be running older code, and its StoreKit prices come from the local mock in dollars, snapped to whatever price point the test framework recognises. Neither is what a reviewer sees. A recording submitted to answer a pricing-disclosure rejection is the last place to show a price that is not the real one.

Apple asks for a recording that confirms the disclosures. One continuous take, no cuts:

1. Open the app, go to Settings
2. Scroll to Astera+ and tap in
3. Show the three products with their titles, lengths, and prices on screen
4. Scroll to "The small print" and pause long enough to read the renewal terms
5. Tap **Privacy policy**, let Safari load the page, come back
6. Tap **Terms of Use (EULA)**, let Safari load Apple's terms, come back

### 6. Reply to App Review

Attach the recording and reply in the Resolution Center.

`appstore/iap-small-print.png` can go alongside it as a still: it holds the whole renewal paragraph and both legal links in one frame, which the recording only shows in passing. It is a simulator capture and does not replace the recording, which has to come off a real device running this build.

Draft:

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
- The privacy policy exists in three places, all at **v1.2**: `PRIVACY.md`, `docs/privacy/index.html` (the live page), and `AsteraDev/Resources/PrivacyPolicy.swift` (what ships in the app). A reviewer can compare the in-app text against the linked URL, so they have to agree. If the text changes, bump the version in all three and confirm the live page has redeployed **before** recording anything.
- CloudKit production schema deploy is still a pre-launch step. See `appstore/listing.md`.
