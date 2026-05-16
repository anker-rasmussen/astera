import SwiftUI
import StoreKit

struct AsteraPlusView: View {
    let onDismiss: () -> Void

    @State private var service = AsteraPlusService.shared
    @State private var purchasing: String?
    @State private var thankYou = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Done", action: onDismiss)
                    .buttonStyle(AsteraGhostButtonStyle())
                Spacer()
                EmptyView()
            }
            .asteraEditorialMargins()
            .padding(.top, AsteraSpacing.md)

            Hairline().asteraEditorialMargins().padding(.top, AsteraSpacing.sm)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AsteraSpacing.xl) {
                    headline
                    Hairline()
                    if service.hasAsteraPlus {
                        activeStateBlock
                    } else {
                        offerBlock
                    }
                    Hairline()
                    extrasBlock
                    Hairline()
                    promiseBlock
                }
                .asteraEditorialMargins()
                .padding(.top, AsteraSpacing.lg)
                .padding(.bottom, AsteraSpacing.xxl)
            }
        }
        .asteraScreen()
        .task { await service.refresh() }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Astera+ · optional support")
            Text(service.hasAsteraPlus ? "Thank you." : "If you'd like to chip in.")
                .font(.asteraSerif(34, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text("The tracker is free forever, and not because we've found a way to extract value from you. This is for people who want to keep Astera made and happen to want a few extras in return.")
                .font(.asteraSerifItalic(15))
                .foregroundStyle(AsteraColor.iron)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var offerBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "Pick what fits")
            if service.products.isEmpty && service.isLoading {
                HStack {
                    ProgressView().tint(AsteraColor.accent)
                    Text("Loading…")
                        .font(.asteraSerifItalic(15))
                        .foregroundStyle(AsteraColor.iron)
                }
            } else if service.products.isEmpty {
                Text(service.lastError ?? "Couldn't load support options right now. The free tracker keeps working either way.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    Hairline()
                    ForEach(service.products, id: \.id) { product in
                        tierRow(product: product)
                        Hairline()
                    }
                }
            }

            restoreControl
                .padding(.top, AsteraSpacing.sm)
        }
    }

    @ViewBuilder
    private var restoreControl: some View {
        switch service.restoreOutcome {
        case .restoring:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(AsteraColor.accent)
                Text("Checking with Apple…")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
            }
        case .restoredWithPurchases:
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back. Astera+ restored on this device.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.ink)
                Button("Done") { service.acknowledgeRestoreOutcome() }
                    .buttonStyle(AsteraLinkButtonStyle())
            }
        case .nothingToRestore:
            VStack(alignment: .leading, spacing: 4) {
                Text("Nothing to restore. No Astera+ purchases were found on the Apple ID you're signed into.")
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                Button("Try again") {
                    Task { await service.restore() }
                }
                .buttonStyle(AsteraLinkButtonStyle())
            }
        case .failed(let message):
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                Button("Try again") {
                    Task { await service.restore() }
                }
                .buttonStyle(AsteraLinkButtonStyle())
            }
        case .idle:
            Button("Restore a previous purchase") {
                Task { await service.restore() }
            }
            .buttonStyle(AsteraLinkButtonStyle())
        }
    }

    private func tierRow(product: Product) -> some View {
        Button {
            Task { await purchase(product) }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.asteraTierTitle.lowercased())
                        .font(.asteraSerif(20, weight: .medium))
                        .foregroundStyle(AsteraColor.ink)
                    Text(product.asteraTierDescription)
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.iron)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                Spacer()
                if purchasing == product.id {
                    ProgressView().tint(AsteraColor.accent)
                } else {
                    Text(product.displayPrice)
                        .font(.asteraNumeric(20, weight: .medium))
                        .foregroundStyle(AsteraColor.accent)
                }
            }
            .padding(.vertical, AsteraSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(purchasing != nil)
    }

    private var activeStateBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Astera+ is active")
            Text("You're chipping in. We appreciate it more than you know.")
                .font(.asteraSerif(20, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text("All Astera+ extras are unlocked. If you ever want to manage or cancel your subscription, it's in the App Store app → your Apple ID → Subscriptions.")
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var extrasBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.md) {
            CapsLabel(text: "What you'd get")
            VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                extraRow(title: "Themes and app icons", body: "Cosmetic, never gates utility.")
                extraRow(title: "Home and lock screen widgets", body: "Your cycle day and what's expected, at a glance.")
                extraRow(title: "Detailed cycle insights", body: "Patterns, trends, monthly and yearly summaries of your own data.")
                extraRow(title: "Custom symptoms and flow types", body: "Log what matters to you, beyond the defaults.")
                extraRow(title: "Apple Watch app", body: "Log from your wrist. Cycle day on your watch face.")
                extraRow(title: "Custom notification sounds", body: "Pick one that doesn't feel like an iPhone telling you something.")
                extraRow(title: "Advanced TTC tools", body: "BBT charting and ovulation-test scan, when you need them.")
                extraRow(title: "Clinical PDF export", body: "A printable cycle chart for a doctor's visit.")
                extraRow(title: "Hormone-medication tracking", body: "Dose, time, refill reminders.")
                extraRow(title: "Partner sync", body: "Coming after the basics.")
            }
        }
    }

    private func extraRow(title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: AsteraSpacing.sm) {
            Text("·")
                .font(.asteraSerif(18, weight: .medium))
                .foregroundStyle(AsteraColor.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.asteraSerif(15, weight: .medium))
                    .foregroundStyle(AsteraColor.ink)
                Text(body)
                    .font(.asteraSerifItalic(13))
                    .foregroundStyle(AsteraColor.iron)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var promiseBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "What you wouldn't get")
            Text("Pressure.")
                .font(.asteraSerif(20, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text("Astera will never show you another reminder about this. We'll never make the free tracker worse to nudge you here. If we ever do, we've broken the promise and you can walk away with all of your data.")
                .font(.asteraSerifItalic(14))
                .foregroundStyle(AsteraColor.iron)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func purchase(_ product: Product) async {
        purchasing = product.id
        let succeeded = await service.purchase(product)
        purchasing = nil
        if succeeded {
            thankYou = true
        }
    }
}
