import Foundation

/// Plain-English privacy policy, < 600 words. Spec §6 + §14.
/// Versioned so we can show "Last updated" and detect changes.
struct PrivacyPolicy {
    static let version = "1.0"
    static let lastUpdated = "May 2026"

    static let body: String = """
    Astera collects nothing.

    There is no analytics service in this app. There is no advertising. There are no third-party SDKs of any kind: not Facebook's, not Mixpanel's, not Amplitude's, not Google's, not Segment's. The developer who built Astera cannot read your data, because the developer has no server to read it from.

    Where your data lives

    Everything you log in Astera (your cycles, your symptoms, your notes, your settings) is stored on this phone. If you are signed into iCloud, Astera also keeps an encrypted copy in your own iCloud, so it syncs to your other Apple devices. Apple's iCloud encryption protects it in transit and at rest. If you turn on Advanced Data Protection in your Apple ID settings, not even Apple can read it. The Astera developer cannot, in any configuration, read your iCloud data.

    The same is true of Apple Health: if you turn on the Apple Health toggle, Astera writes the flow you log into the Health app, where it joins the rest of your health data under Apple's encryption. Astera doesn't see what's in the Health app beyond what you've shared with it.

    The same is true of your Calendar: if you turn on the Calendar toggle, Astera writes predicted period dates to a dedicated "Astera" calendar that lives on your device. It never touches any other calendar.

    What we don't do

    We don't sell anything to anyone. We don't share with anyone. We don't have ad partners. We don't have "marketing partners". We don't keep aggregated statistics. We don't measure your engagement. We don't A/B test your retention. If Astera ever does any of those things, it has broken its promise and you have every right to leave.

    Your rights

    You can export every piece of data you've logged at any time. Settings → Your data → Take a copy with you. It's a plain JSON file you can open in any text editor or send to your doctor.

    You can delete every piece of data you've logged at any time. Settings → Your data → Delete everything. It wipes the local copy on this phone and the encrypted iCloud copy. There's no recovery. That's by design.

    You can change everything you told us during setup. Settings → About you. Pronouns, cycle state, birth year, anything.

    The legal small print

    Under GDPR, CCPA, UK GDPR and similar laws: your "right to access" is the Export button. Your "right to erasure" is the Delete button. Your "right to data portability" is the JSON format itself, which is documented and stable. Your "right to rectification" is the in-app editing. Astera satisfies these rights by architecture, not by policy. The developer never holds your health data, so there is nothing to hand over and nothing to forget.

    Apple acts as the technical processor for iCloud and HealthKit sync. Their privacy posture (under Advanced Data Protection in particular) is the strongest in the industry for this data class. You can read Apple's own commitments at apple.com/legal/privacy.

    Astera makes no medical claims. Predictions are estimates, not advice. If something about your cycle worries you, please talk to a clinician.

    Reach us

    Astera is built and maintained by one engineer. If you have a question this doesn't answer, the project repo on GitHub is the place to file an issue.

    This policy is hash-committed to the public Astera repository. Any future changes will be visible in its history.
    """
}
