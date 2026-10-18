import CoreLocation
import Foundation

/// Explicit output conversion. Stored pins, routes and favorites retain their input coordinates.
enum CoordinateTransform {
    enum Mode: String, CaseIterable, Identifiable {
        case none, wgsToGCJ, wgsToBD, gcjToWGS

        var id: String { rawValue }
        var title: String {
            switch self {
            case .none: return String(localized: "Off (original coordinates)")
            case .wgsToGCJ: return "WGS-84 → GCJ-02"
            case .wgsToBD: return "WGS-84 → BD-09"
            case .gcjToWGS: return "GCJ-02 → WGS-84"
            }
        }
    }

    static let defaultsKey = "locus.coordinateConversion"
    static var selectedMode: Mode {
        Mode(rawValue: UserDefaults.standard.string(forKey: defaultsKey) ?? "") ?? .none
    }

    static func convert(_ coordinate: CLLocationCoordinate2D, mode: Mode) -> CLLocationCoordinate2D {
        // Approximate coverage rectangle, not a national boundary. Selection is manual.
        guard CLLocationCoordinate2DIsValid(coordinate), mode != .none,
              (72.004...137.8347).contains(coordinate.longitude),
              (0.8293...55.8271).contains(coordinate.latitude) else { return coordinate }
        switch mode {
        case .none: return coordinate
        case .wgsToGCJ: return gcj(coordinate)
        case .wgsToBD:
            let shifted = gcj(coordinate)
            let x = shifted.longitude
            let y = shifted.latitude
            let factor = Double.pi * 3000 / 180
            let radius = hypot(x, y) + 0.00002 * sin(y * factor)
            let angle = atan2(y, x) + 0.000003 * cos(x * factor)
            return CLLocationCoordinate2D(latitude: radius * sin(angle) + 0.006,
                                          longitude: radius * cos(angle) + 0.0065)
        case .gcjToWGS:
            var estimate = coordinate
            for _ in 0..<10 {
                let shifted = gcj(estimate)
                let latitudeError = shifted.latitude - coordinate.latitude
                let longitudeError = shifted.longitude - coordinate.longitude
                estimate.latitude -= latitudeError
                estimate.longitude -= longitudeError
                if max(abs(latitudeError), abs(longitudeError)) < 1e-9 { break }
            }
            return estimate
        }
    }

    private static func gcj(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let x = coordinate.longitude - 105
        let y = coordinate.latitude - 35
        let pi = Double.pi
        let common = (20 * sin(6 * x * pi) + 20 * sin(2 * x * pi)) * 2 / 3
        var latitude = -100 + 2 * x + 3 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        latitude += common
        latitude += (20 * sin(y * pi) + 40 * sin(y / 3 * pi)) * 2 / 3
        latitude += (160 * sin(y / 12 * pi) + 320 * sin(y * pi / 30)) * 2 / 3
        var longitude = 300 + x + 2 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        longitude += common
        longitude += (20 * sin(x * pi) + 40 * sin(x / 3 * pi)) * 2 / 3
        longitude += (150 * sin(x / 12 * pi) + 300 * sin(x / 30 * pi)) * 2 / 3
        let radians = coordinate.latitude / 180 * pi
        let eccentricity = 0.00669342162296594323
        let magic = 1 - eccentricity * pow(sin(radians), 2)
        let root = sqrt(magic)
        let axis = 6378245.0
        latitude = latitude * 180 / ((axis * (1 - eccentricity)) / (magic * root) * pi)
        longitude = longitude * 180 / (axis / root * cos(radians) * pi)
        return CLLocationCoordinate2D(latitude: coordinate.latitude + latitude,
                                      longitude: coordinate.longitude + longitude)
    }
}
