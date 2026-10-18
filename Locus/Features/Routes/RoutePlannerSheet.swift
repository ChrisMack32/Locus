import CoreLocation
import SwiftUI

struct RoutePlannerSheet: View {
    @Binding var start: CLLocationCoordinate2D?
    @Binding var end: CLLocationCoordinate2D?
    @Binding var isRouting: Bool
    var onBuild: () -> Void
    var onPlay: () -> Void
    var onImportGPX: () -> Void
    var onExportGPX: () -> Void
    var onUseDrawn: () -> Void

    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "Road route")) {
                    Button(String(localized: "Use current pin / spoof as start")) {
                        start = session.simulated ?? session.pin
                    }
                    Button(String(localized: "Use current pin as end")) {
                        end = session.pin
                    }
                    LabeledContent(String(localized: "Start")) {
                        Text(coordText(start)).font(.caption.monospaced())
                    }
                    LabeledContent(String(localized: "End")) {
                        Text(coordText(end)).font(.caption.monospaced())
                    }
                    Button {
                        onBuild()
                    } label: {
                        if isRouting {
                            ProgressView()
                        } else {
                            Label(String(localized: "Build walk/drive route on roads"), systemImage: "road.lanes")
                        }
                    }
                    .disabled(isRouting)
                }

                Section(String(localized: "Play / draw / GPX")) {
                    Button {
                        onUseDrawn()
                    } label: {
                        Label(String(localized: "Use drawn path from map"), systemImage: "pencil.tip")
                    }
                    Button(action: onPlay) {
                        Label(String(localized: "Follow route"), systemImage: "play.fill")
                    }
                    Button(action: onImportGPX) {
                        Label(String(localized: "Import GPX"), systemImage: "square.and.arrow.down")
                    }
                    Button(action: onExportGPX) {
                        Label(String(localized: "Export GPX"), systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    Text(String(localized: "Routes follow Apple Maps roads/footpaths for the selected travel mode. Speed gets light random variation so motion looks less robotic."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "Routes"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
        }
    }

    private func coordText(_ c: CLLocationCoordinate2D?) -> String {
        guard let c else { return "—" }
        return String(format: "%.5f, %.5f", c.latitude, c.longitude)
    }
}
