import MapKit
import SwiftUI

/// Map pin with save/remove actions and long-press drag.
struct MapDropPin: View {
    var selected: Bool
    var isDragging: Bool
    var onSelect: () -> Void
    var onFavorite: () -> Void
    var onRemove: () -> Void
    var onDragBegan: () -> Void
    var onDragMoved: (CGPoint) -> Void
    var onDragEnded: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if selected && !isDragging {
                VStack(spacing: 0) {
                    Button(action: onFavorite) {
                        Label(String(localized: "Save Favorite"), systemImage: "star.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    Button(action: onRemove) {
                        Label(String(localized: "Remove Pin"), systemImage: "trash.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LocusTheme.danger)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
                .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 18))
                .contentShape(RoundedRectangle(cornerRadius: 18))
                .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
            }

            Image(systemName: "mappin.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, LocusTheme.accentSecondary)
                .font(.system(size: isDragging ? 44 : 36))
                .shadow(color: .black.opacity(0.35), radius: isDragging ? 8 : 4, y: 2)
                .scaleEffect(isDragging ? 1.12 : 1)
        }
        // Keep the pin tip on the coordinate while the menu sits above.
        .padding(.bottom, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .gesture(dragGesture)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: selected)
        .animation(.easeOut(duration: 0.15), value: isDragging)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(selected ? String(localized: "Selected pin") : String(localized: "Map pin"))
        .accessibilityHint(String(localized: "Tap to save or remove. Touch and hold to drag."))
    }

    private var dragGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                switch value {
                case .first(true):
                    break
                case .second(true, let drag):
                    if let drag {
                        if !isDragging {
                            onDragBegan()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        onDragMoved(drag.location)
                    }
                default:
                    break
                }
            }
            .onEnded { _ in
                onDragEnded()
            }
    }
}
