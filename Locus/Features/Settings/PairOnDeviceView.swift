import SwiftUI

struct PairOnDeviceView: View {
    enum Mode {
        /// Settings sheet — Close toolbar, dismiss on Done.
        case sheet
        /// First-run setup — no toolbar; calls `onFinished` after success.
        case embedded
    }

    @EnvironmentObject private var pairing: PairingStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var host = PairOnDeviceService()

    var mode: Mode = .sheet
    var onFinished: (() -> Void)?

    var body: some View {
        Group {
            if mode == .sheet {
                NavigationStack {
                    scrollContent
                        .background(Color.black.ignoresSafeArea())
                        .navigationTitle(String(localized: "Pair on this iPhone"))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(String(localized: "Close")) {
                                    host.resetToIdle()
                                    dismiss()
                                }
                            }
                        }
                }
            } else {
                scrollContent
            }
        }
        .onChange(of: host.phase) { _, phase in
            if case .succeeded = phase {
                pairing.refresh()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, host.isBusy {
                _ = host.pin
            }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if mode == .sheet {
                    header
                } else {
                    embeddedIntro
                }

                steps

                statusCard

                if mode == .sheet {
                    tipCard
                }

                actions
            }
            .padding(mode == .embedded ? 16 : 20)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "No computer needed"))
                .font(.title2.weight(.bold))
            Text(String(localized: "Locus advertises a pairable host. iOS connects from Developer Mode, then Locus shows a 6-digit code for you to type."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var embeddedIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Follow these steps"))
                .font(.headline)
            Text(String(localized: "Keep Locus open. You’ll leave briefly for Settings, then come back with a code."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 12) {
            step(1, String(localized: "Tap Start pairing and allow Local Network + Location when asked."))
            step(2, String(localized: "Allow notifications — the code can appear as a banner over Settings."))
            step(3, String(localized: "Open Settings › Privacy & Security › Developer Mode › Pair with Locus → Pair."))
            step(4, String(localized: "Enter your unlock passcode first. On the next prompt, type Locus’s 6-digit code."))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 22, height: 22)
                .background(LocusTheme.accent, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(String(localized: "If the code isn’t here yet"), systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LocusTheme.accentSecondary)
            Text(String(localized: "Keep the app listening while you confirm in Developer Mode. Don’t force-quit. If “Pair with Locus” vanishes, stop/start pairing and reopen Developer Mode."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LocusTheme.accentSecondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var statusCard: some View {
        VStack(spacing: 14) {
            switch host.phase {
            case .idle:
                Label(String(localized: "Ready when you are"), systemImage: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(.secondary)
            case .advertising:
                ProgressView()
                Text(String(localized: "Waiting for Settings…"))
                    .font(.headline)
                Text(String(localized: "In Developer Mode tap Pair with Locus → Pair."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .deviceConnected:
                ProgressView()
                Text(String(localized: "iPhone connected"))
                    .font(.headline)
                Text(String(localized: "Generating your 6-digit code…"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .awaitingPIN(let pin):
                Text(String(localized: "Enter this code in Settings"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(pin)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .tracking(10)
                    .monospacedDigit()
                    .foregroundStyle(LocusTheme.accent)
                    .textSelection(.enabled)
                Text(String(localized: "Second prompt only — after your unlock passcode."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .succeeded:
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(LocusTheme.statusGood)
                Text(String(localized: "Paired"))
                    .font(.title3.weight(.bold))
                Text(mode == .embedded
                     ? String(localized: "Next we’ll set up LocalDevVPN.")
                     : String(localized: "RPPairing file saved. Connect LocalDevVPN, then teleport."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .failed(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(LocusTheme.statusWarn)
                Text(String(localized: "Pairing failed"))
                    .font(.title3.weight(.bold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var actions: some View {
        switch host.phase {
        case .idle, .failed:
            Button {
                host.acknowledgeFailure()
                host.start(pairingStore: pairing)
            } label: {
                Text(host.phase == .idle ? String(localized: "Start pairing") : String(localized: "Try again"))
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(LocusTheme.accent))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        case .succeeded:
            Button {
                if let onFinished {
                    onFinished()
                } else {
                    dismiss()
                }
            } label: {
                Text(mode == .embedded ? String(localized: "Continue") : String(localized: "Done"))
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(LocusTheme.accent))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        case .advertising, .deviceConnected, .awaitingPIN:
            Text({
                switch host.phase {
                case .awaitingPIN: return String(localized: "Type the code above into the second Settings prompt.")
                case .deviceConnected: return String(localized: "Connected — code coming next.")
                default: return String(localized: "Waiting for iOS to connect… don’t force-quit Locus.")
                }
            }())
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }
}
