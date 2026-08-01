#!/usr/bin/env python3
"""Fail when the same fact is written down twice and the copies disagree.

The App Store paperwork restates things the code already declares: product IDs, prices,
subscription lengths, legal URLs, the shipping version. Those restatements are for a human to
paste into App Store Connect, so they stay as prose rather than being generated. This checks
them instead.

It has caught real drift: review-notes.md claimed £0.50/£5/£30 long after the products moved
to £0.49/£4.99/£14.99, and that file goes verbatim into the App Review Notes field.

Sources of truth:
    AsteraDev/Resources/AsteraPlus.storekit   product IDs, types, prices, durations
    AsteraDev/Services/AsteraPlusService.swift  the Tier enum the app actually queries
    AsteraDev/Resources/AsteraLinks.swift     the legal URLs shipped in the binary
    AsteraDev/Info.plist                      the shipping version

Usage:
    python3 scripts/check_consistency.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

STOREKIT = ROOT / "AsteraDev/Resources/AsteraPlus.storekit"
SERVICE = ROOT / "AsteraDev/Services/AsteraPlusService.swift"
LINKS = ROOT / "AsteraDev/Resources/AsteraLinks.swift"
INFO_PLIST = ROOT / "AsteraDev/Info.plist"

DISCLOSURE_TESTS = ROOT / "AsteraDevUITests/AsteraPlusDisclosureUITests.swift"

IAP_DOC = ROOT / "appstore/iap.md"
LISTING_DOC = ROOT / "appstore/listing.md"
NOTES_DOC = ROOT / "appstore/review-notes.md"
RESUBMISSION_DOC = ROOT / "appstore/resubmission.md"

DURATION_WORDS = {"P1M": "1 Month", "P1Y": "1 Year"}

problems = []


def fail(message):
    problems.append(message)


def rel(path):
    return path.relative_to(ROOT)


def load_products():
    """Returns [(id, display_price, duration_or_None, reference_name)] from the StoreKit config."""
    config = json.loads(STOREKIT.read_text())
    products = [
        (p["productID"], p["displayPrice"], None, p["referenceName"])
        for p in config.get("products", [])
    ]
    for group in config.get("subscriptionGroups", []):
        for s in group.get("subscriptions", []):
            products.append(
                (s["productID"], s["displayPrice"], s.get("recurringSubscriptionPeriod"), s["referenceName"])
            )
    return sorted(products)


def check_tier_ids(products):
    """The Swift enum drives Product.products(for:). A typo here means an empty paywall."""
    declared = set(re.findall(r'case \w+ = "(\d+)"', SERVICE.read_text()))
    configured = {p[0] for p in products}
    if declared != configured:
        fail(
            f"Product IDs disagree: {rel(SERVICE)} has {sorted(declared)}, "
            f"{rel(STOREKIT)} has {sorted(configured)}"
        )


def check_prices_and_ids(products):
    """Every product's ID and price must appear verbatim in the docs that enumerate products."""
    for doc in (IAP_DOC, NOTES_DOC):
        text = doc.read_text()
        for product_id, price, _, name in products:
            if f"`{product_id}`" not in text and f"ID {product_id}" not in text:
                fail(f"{rel(doc)} never states the product ID {product_id} ({name})")
            if price not in text:
                fail(f"{rel(doc)} does not state {name}'s current price of {price}")


def check_durations(products):
    text = IAP_DOC.read_text()
    for product_id, _, duration, name in products:
        if duration is None:
            continue
        words = DURATION_WORDS.get(duration)
        if words and words not in text:
            fail(f"{rel(IAP_DOC)} does not state {name}'s duration of {words} ({duration})")


def check_disclosure_tests(products):
    """Every product on sale needs a 3.1.2(c) disclosure test.

    Not the price: the tests assert the shape of a rendered price rather than a literal, because
    StoreKit's local framework snaps `displayPrice` to its own price points, so the config's
    number and the rendered number are not the same fact. What this guards is coverage: a tier
    without a disclosure test would be silently submittable, and the disclosures are the thing
    v1.0 was rejected over.
    """
    text = DISCLOSURE_TESTS.read_text()
    for product_id, _, _, name in products:
        if f'productID: "{product_id}"' not in text:
            fail(
                f"{rel(DISCLOSURE_TESTS)} has no disclosure test for {name} (product "
                f"{product_id}). Apple requires the title, length, and price of every product."
            )


def check_legal_urls():
    """The URLs in the binary and the URLs in the metadata have to be the same strings."""
    urls = dict(re.findall(r'static let (\w+) = URL\(string: "([^"]+)"\)', LINKS.read_text()))
    if len(urls) != 2:
        fail(f"Expected two legal URLs in {rel(LINKS)}, found {len(urls)}")
        return
    for name, url in urls.items():
        for doc in (LISTING_DOC, NOTES_DOC, RESUBMISSION_DOC):
            if url not in doc.read_text():
                fail(f"{rel(doc)} is missing the {name} URL shipped in the app: {url}")


def check_version():
    # Read the plist with a regex rather than plistlib: this has to run anywhere, and some
    # Homebrew Pythons ship a pyexpat that fails to load.
    match = re.search(
        r"<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>",
        INFO_PLIST.read_text(),
    )
    if not match:
        fail(f"Could not read CFBundleShortVersionString from {rel(INFO_PLIST)}")
        return
    short = match.group(1)
    text = LISTING_DOC.read_text()
    if f"`{short}`" not in text:
        fail(f"{rel(LISTING_DOC)} does not mention the shipping version {short} from Info.plist")


def main():
    products = load_products()
    check_tier_ids(products)
    check_prices_and_ids(products)
    check_durations(products)
    check_disclosure_tests(products)
    check_legal_urls()
    check_version()

    if problems:
        for problem in problems:
            print(f"  {problem}")
        sys.exit(f"\n{len(problems)} inconsistenc{'y' if len(problems) == 1 else 'ies'} found.")

    print(f"Consistent: {len(products)} products, their prices, durations, legal URLs, and version.")


if __name__ == "__main__":
    main()
