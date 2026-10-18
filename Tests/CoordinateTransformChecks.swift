import CoreLocation
import Foundation

@main
struct CoordinateTransformChecks {
    static func main() {
        let beijing = CLLocationCoordinate2D(latitude: 39.908823, longitude: 116.397470)
        let gcj = CoordinateTransform.convert(beijing, mode: .wgsToGCJ)
        assert(abs(gcj.latitude - 39.910226498) < 0.000001)
        assert(abs(gcj.longitude - 116.403713582) < 0.000001)
        let original = CoordinateTransform.convert(gcj, mode: .gcjToWGS)
        assert(abs(original.latitude - beijing.latitude) < 0.0000001)
        assert(abs(original.longitude - beijing.longitude) < 0.0000001)
        let bd = CoordinateTransform.convert(beijing, mode: .wgsToBD)
        assert(abs(bd.latitude - 39.916565819) < 0.000002)
        assert(abs(bd.longitude - 116.410086454) < 0.000002)
        for mode in CoordinateTransform.Mode.allCases {
            let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
            let unchanged = CoordinateTransform.convert(london, mode: mode)
            assert(unchanged.latitude == london.latitude && unchanged.longitude == london.longitude)
        }
        let unchanged = CoordinateTransform.convert(beijing, mode: .none)
        assert(unchanged.latitude == beijing.latitude && unchanged.longitude == beijing.longitude)
        for point in [beijing, CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
                      CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579)] {
            let shifted = CoordinateTransform.convert(point, mode: .wgsToGCJ)
            let restored = CoordinateTransform.convert(shifted, mode: .gcjToWGS)
            assert(abs(restored.latitude - point.latitude) < 0.0000001)
            assert(abs(restored.longitude - point.longitude) < 0.0000001)
            // Resends always start from the unchanged logical coordinate.
            let resent = CoordinateTransform.convert(point, mode: .wgsToGCJ)
            assert(shifted.latitude == resent.latitude && shifted.longitude == resent.longitude)
        }
        print("Coordinate transform checks passed")
    }
}
