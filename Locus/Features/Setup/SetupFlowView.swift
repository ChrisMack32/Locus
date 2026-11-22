import SwiftUI
import UniformTypeIdentifiers

/// First-run walkthrough: welcome → pairing → LocalDevVPN → map.
/// Skipped when `SetupGate.isComplete` (see `LocusApp`).
struct SetupFlowView: View {
    @EnvironmentObject private var pairing: PairingStore
    @EnvironmentObject private var session: SpoofSession

    var onFinished: () -> Void

    @State private var step: Step
    @State private var appear = false
    @State private var showImporter = false
    @State private var localDevVPNInstalled = LocalDevVPN.isInstalled
    @Environment(\.scenePhase) private var scenePhase

    enum Step: Int, CaseIterable {
        case welcome
        case pairing
        case vpn
    }

    init(initialStep: Step = .welcome, onFinished: @escaping () -> Void) {
        _step = State(initialValue: initialStep)
        self.onFinished = onFinished
    }

    private var supportsOnDevicePairing: Bool {
        if #available(iOS 27.0, *) { return true }
        return false
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                Group {
                    switch step {
                    case .welcome:
                        welcomePage
                    case .pairing:
                        pairingPage
                    case .vpn:
                        vpnPage
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: step)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appear = true }
            localDevVPNInstalled = LocalDevVPN.isInstalled
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                localDevVPNInstalled = LocalDevVPN.isInstalled
            }
        }
        .onChange(of: step) { _, newStep in
            if newStep == .vpn {
                localDevVPNInstalled = LocalDevVPN.isInstalled
            }
        }
        .onChange(of: pairing.hasPairingFile) { _, hasFile in
            if hasFile, step == .welcome || step == .pairing {
                SetupGate.markInProgress()
                withAnimation { step = .vpn }
            }
        }
        .sheet(isPresented: $showImporter) {
            PairingDocumentPicker(
                onPick: { url in
                    showImporter = false
                    do {
                        try pairing.importPairing(from: url)
                        withAnimation { step = .vpn }
                    } catch {
                        session.lastError = error.localizedDescription
                    }
                },
                onCancel: { showImporter = false }
            )
            .ignoresSafeArea()
        }
        .alert("Locus", isPresented: Binding(
            get: { session.lastError != nil },
            set: { if !$0 { session.lastError = nil } }
        )) {
            Button(String(localized: "OK"), role: .cancel) { session.lastError = nil }
        } message: {
            Text(session.lastError ?? "")
        }
    }

    // MARK: - Chrome

    private var background: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Soft map-adjacent atmosphere (no flat fill).
            RadialGradient(
                colors: [
                    LocusTheme.accent.opacity(0.22),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.12, green: 0.18, blue: 0.28).opacity(0.9),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 380
            )
            .ignoresSafeArea()

            // Subtle grid suggestion of a map without competing with copy.
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 44
                    for x in stride(from: 0, through: geo.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, through: geo.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
            }
            .ignoresSafeArea()
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? LocusTheme.accent : Color.white.opacity(0.12))
                    .frame(height: 3)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: String(localized: "Step %lld of %lld"), Int64(step.rawValue + 1), Int64(Step.allCases.count)))
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 20) {
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(LocusTheme.accent)
                    .symbolEffect(.pulse, options: .repeating.speed(0.4), isActive: appear)
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.85)

                VStack(spacing: 10) {
                    Text("Locus")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .tracking(-0.5)

                    Text(String(localized: "Teleport your location.\nNo computer required."))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)
            }
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 14) {
                Text(String(localized: "A short setup — about two minutes."))
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)

                primaryButton(String(localized: "Get started")) {
                    SetupGate.markInProgress()
                    withAnimation { step = .pairing }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .opacity(appear ? 1 : 0)
        }
    }

    // MARK: - Pairing

    private var pairingPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Connect this iPhone"))
                    .font(.title.weight(.bold))
                Text(supportsOnDevicePairing
                     ? String(localized: "Locus needs a one-time pairing so it can set your location. You’ll confirm a short code in Settings.")
                     : String(localized: "Import a pairing file from your computer — Locus uses it to set your location securely on this device."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 16)

            if supportsOnDevicePairing {
                PairOnDeviceView(mode: .embedded) {
                    withAnimation { step = .vpn }
                }
                .environmentObject(pairing)
            } else {
                importPairingCard
                    .padding(.horizontal, 24)
                Spacer()
                VStack(spacing: 12) {
                    primaryButton(String(localized: "Import pairing file")) {
                        showImporter = true
                    }
                    Button {
                        do {
                            try pairing.importPairingFromClipboard()
                            withAnimation { step = .vpn }
                        } catch {
                            session.lastError = error.localizedDescription
                        }
                    } label: {
                        Text(String(localized: "Paste from clipboard"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .locusGlass(.interactive, in: Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private var importPairingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepRow(1, String(localized: "On a Mac, run idevice_pair and create an RPPairing file."))
            stepRow(2, String(localized: "AirDrop / Share into Locus, or copy the plist text."))
            stepRow(3, String(localized: "Tap Import, or Paste from clipboard if the picker doesn’t work (LiveContainer)."))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func stepRow(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 22, height: 22)
                .background(LocusTheme.accent, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - LocalDevVPN

    private var vpnPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(spacing: 22) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(LocusTheme.accent)

                VStack(spacing: 10) {
                    Text(localDevVPNInstalled ? String(localized: "Connect LocalDevVPN") : String(localized: "One more app"))
                        .font(.title.weight(.bold))

                    Text(localDevVPNInstalled
                         ? String(localized: "LocalDevVPN is installed. Open it to turn on the private tunnel Locus needs, then come back here.")
                         : String(localized: "LocalDevVPN creates a private tunnel Locus uses to talk to your phone’s location system. Install it, turn it on, then you’re ready to teleport."))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if localDevVPNInstalled {
                        tipRow(systemImage: "checkmark.circle.fill", title: String(localized: "Installed"), detail: String(localized: "LocalDevVPN is on this iPhone."))
                        tipRow(systemImage: "power.circle.fill", title: String(localized: "Connect"), detail: String(localized: "Tap below to open it and start the tunnel. You’ll bounce back to Locus."))
                    } else {
                        tipRow(systemImage: "arrow.down.app.fill", title: String(localized: "Install"), detail: String(localized: "Get LocalDevVPN from the App Store."))
                        tipRow(systemImage: "power.circle.fill", title: String(localized: "Connect"), detail: String(localized: "Open it and turn the VPN on. Leave the default IP alone."))
                    }
                    tipRow(systemImage: "wifi", title: String(localized: "First teleport on Wi‑Fi"), detail: String(localized: "Start your first teleport while on Wi‑Fi. After that, it can keep working on cellular."))
                }
                .padding(18)
                .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    if localDevVPNInstalled {
                        LocalDevVPN.openInstalled()
                    } else {
                        LocalDevVPN.openAppStore()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: localDevVPNInstalled ? "lock.shield.fill" : "apple.logo")
                        Text(localDevVPNInstalled ? String(localized: "Open LocalDevVPN") : String(localized: "Get LocalDevVPN"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.primary)
                    .locusGlass(.interactive, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)

                primaryButton(String(localized: "I’ve connected it — continue")) {
                    onFinished()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func tipRow(systemImage: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(LocusTheme.accent)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Shared

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(LocusTheme.accent))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gate

enum SetupGate {
    static let defaultsKey = "locus.setupComplete"
    static let inProgressKey = "locus.setupInProgress"

    static var isComplete: Bool {
        UserDefaults.standard.bool(forKey: defaultsKey)
    }

    static var isInProgress: Bool {
        UserDefaults.standard.bool(forKey: inProgressKey)
    }

    static func markInProgress() {
        UserDefaults.standard.set(true, forKey: inProgressKey)
    }

    static func markComplete() {
        UserDefaults.standard.set(true, forKey: defaultsKey)
        UserDefaults.standard.set(false, forKey: inProgressKey)
    }

    /// Already paired *during* this walkthrough → LocalDevVPN page.
    /// Fresh install → welcome. Already-paired upgrades are handled in `LocusApp`.
    static func initialStep(hasPairingFile: Bool) -> SetupFlowView.Step {
        if hasPairingFile, isInProgress { return .vpn }
        return .welcome
    }
}
