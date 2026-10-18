import SwiftUI

/// Full-screen easter egg: a swarm of locusts (the bugs) scurries across the void.
/// Spelling optional. Humor mandatory.
struct LocusEasterEggView: View {
    @Environment(\.dismiss) private var dismiss

    private let swarm: [Critter] = [
        .init(band: 0.10, size: 36, speed: 0.14, reverse: false, bob: 10),
        .init(band: 0.18, size: 28, speed: 0.22, reverse: true, bob: 14),
        .init(band: 0.26, size: 44, speed: 0.11, reverse: false, bob: 8),
        .init(band: 0.34, size: 32, speed: 0.19, reverse: true, bob: 16),
        .init(band: 0.42, size: 40, speed: 0.16, reverse: false, bob: 12),
        .init(band: 0.50, size: 24, speed: 0.27, reverse: true, bob: 18),
        .init(band: 0.58, size: 48, speed: 0.09, reverse: false, bob: 7),
        .init(band: 0.66, size: 30, speed: 0.20, reverse: true, bob: 13),
        .init(band: 0.74, size: 38, speed: 0.15, reverse: false, bob: 11),
        .init(band: 0.82, size: 26, speed: 0.24, reverse: true, bob: 15),
        .init(band: 0.90, size: 34, speed: 0.17, reverse: false, bob: 9),
        .init(band: 0.14, size: 22, speed: 0.30, reverse: true, bob: 20),
        .init(band: 0.62, size: 52, speed: 0.08, reverse: false, bob: 6),
        .init(band: 0.38, size: 20, speed: 0.28, reverse: false, bob: 17),
        .init(band: 0.78, size: 42, speed: 0.13, reverse: true, bob: 10),
        .init(band: 0.22, size: 18, speed: 0.32, reverse: false, bob: 22),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.09, blue: 0.08),
                        Color.black,
                        Color(red: 0.08, green: 0.06, blue: 0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    ZStack {
                        ForEach(Array(swarm.enumerated()), id: \.offset) { index, critter in
                            critterView(critter, index: index, time: t, size: geo.size)
                        }
                    }
                }
                .allowsHitTesting(false)

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .locusGlass(.interactive, in: Circle())
                        .padding(.trailing, 16)
                        .padding(.top, 12)
                    }
                    Spacer()

                    Text(String(localized: "close enough"))
                        .font(.caption.italic())
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.bottom, 28)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }

    private func critterView(_ critter: Critter, index: Int, time: TimeInterval, size: CGSize) -> some View {
        let travel = size.width + 160
        let phase = (time * critter.speed + Double(index) * 0.07).truncatingRemainder(dividingBy: 1)
        let progress = critter.reverse ? (1 - phase) : phase
        let x = -80 + CGFloat(progress) * travel
        let bob = sin(time * (2.5 + Double(index) * 0.17) + Double(index)) * critter.bob
        let y = size.height * critter.band + bob
        let wobble = sin(time * (4 + Double(index) * 0.3)) * 10

        return Text("🦗")
            .font(.system(size: critter.size))
            .rotationEffect(.degrees(wobble))
            .scaleEffect(x: critter.reverse ? -1 : 1, y: 1)
            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
            .position(x: x, y: y)
            .accessibilityHidden(true)
    }

    private struct Critter {
        var band: CGFloat
        var size: CGFloat
        var speed: Double
        var reverse: Bool
        var bob: Double
    }
}
