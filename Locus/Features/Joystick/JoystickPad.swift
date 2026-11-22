import SwiftUI

struct JoystickPad: View {
    var onChange: (CGVector) -> Void

    @State private var dragOffset: CGSize = .zero
    private let radius: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .frame(width: radius * 2 + 28, height: radius * 2 + 28)
                .locusGlass(.clear, in: Circle())

            Circle()
                .stroke(LocusTheme.accent.opacity(0.4), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(LocusTheme.accent)
                .frame(width: 44, height: 44)
                .shadow(color: LocusTheme.accent.opacity(0.45), radius: 8)
                .offset(dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let limited = clamp(value.translation, radius: radius)
                            dragOffset = limited
                            onChange(CGVector(dx: limited.width / radius, dy: limited.height / radius))
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                            onChange(.zero)
                        }
                )
        }
        .accessibilityLabel(String(localized: "Movement joystick"))
    }

    private func clamp(_ translation: CGSize, radius: CGFloat) -> CGSize {
        let length = sqrt(translation.width * translation.width + translation.height * translation.height)
        guard length > radius else { return translation }
        let scale = radius / length
        return CGSize(width: translation.width * scale, height: translation.height * scale)
    }
}
