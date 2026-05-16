# Astera+ — In-App Purchase configuration

For App Store Connect → Monetization → In-App Purchases.

Three products. Two are Auto-Renewable Subscriptions (in a single subscription group called **Astera+**); the third is a Non-Consumable.

> **Configure all three products before submitting the app for review.** App Store Connect lets you submit the app and the IAPs together in the same review.

---

## Subscription Group

Create the group first (Monetization → Subscriptions → Create).

| Field | Value |
|---|---|
| **Reference Name** _(private)_ | `Astera+` |
| **Display Name** _(visible to users in their App Store subscriptions list)_ | `Astera+` |

Both monthly and yearly products live inside this group. Users moving between them counts as an upgrade/downgrade, not two separate subscriptions.

---

## Product 1 — Astera+ Monthly

| Field | Value |
|---|---|
| **Type** | Auto-Renewable Subscription |
| **Reference Name** _(private)_ | `Astera+ Monthly` |
| **Product ID** | `000` |
| **Subscription Group** | Astera+ |
| **Subscription Duration** | 1 Month |
| **Price** | $0.49 USD / £0.49 GBP / €0.49 EUR (region-customised, granular pricing) |

**Localization: English (UK)**

| Field | Value |
|---|---|
| **Display Name** _(30 char limit)_ | `Astera+ Monthly` |
| **Description** _(45 char min, 4000 max)_ | `Monthly support for Astera. Cancel any time from your App Store subscriptions. Includes themes, widgets, detailed cycle insights, custom symptoms and flow types, and the Apple Watch app as it ships.` |

**Review Information**
- **Screenshot**: Use `appstore/screenshots/06-log-sheet.png` or capture the Astera+ tab from inside the app.
- **Review Notes**:
```
Astera+ is an optional support tier. The free version of Astera includes all core tracking functionality. This subscription unlocks cosmetic and convenience features (themes, widgets, insights, custom symptoms, Apple Watch). Users access this via Settings → Astera+. It is never gated behind a paywall on core flows.
```

---

## Product 2 — Astera+ Yearly

| Field | Value |
|---|---|
| **Type** | Auto-Renewable Subscription |
| **Reference Name** _(private)_ | `Astera+ Yearly` |
| **Product ID** | `001` |
| **Subscription Group** | Astera+ |
| **Subscription Duration** | 1 Year |
| **Price** | $4.99 USD / £4.99 GBP / €4.99 EUR (region-customised) |

**Localization: English (UK)**

| Field | Value |
|---|---|
| **Display Name** | `Astera+ Yearly` |
| **Description** | `Yearly support for Astera. A small discount on the monthly price. Includes themes, widgets, detailed cycle insights, custom symptoms and flow types, and the Apple Watch app as it ships. Cancel any time.` |

**Review Information**: same screenshot + notes as Monthly.

---

## Product 3 — Astera+ Lifetime

| Field | Value |
|---|---|
| **Type** | Non-Consumable |
| **Reference Name** _(private)_ | `Astera+ Lifetime` |
| **Product ID** | `002` |
| **Price** | $15.00 USD / £15.00 GBP / €15.00 EUR (region-customised, round-number tip-jar pricing) |

**Localization: English (UK)**

| Field | Value |
|---|---|
| **Display Name** | `Astera+ Lifetime` |
| **Description** | `One-time support. Astera+ stays on for as long as the app exists, with no renewals. Includes themes, widgets, detailed cycle insights, custom symptoms and flow types, and the Apple Watch app as it ships.` |

**Review Information**: same screenshot + notes as Monthly.

---

## Cross-product notes

- **Promotional images**: Not required for v1, but Apple now supports "Promoted In-App Purchases" that appear in the App Store listing. Optional.
- **Introductory offers**: Not used in v1. Could add a free week trial later as a marketing experiment, but Astera's brand promise is "the tracker is free either way," and adding a trial muddies that.
- **Family Sharing**: Recommend **enabling** for all three products (toggle in each product's settings). Lets a household share Astera+ via Family Sharing, matches the "for your sister" brand voice.
- **Sandbox testing**: After you save the products in App Store Connect, they become available to TestFlight sandbox testers within ~30 minutes. The Restore button in-app will then have something to restore.
