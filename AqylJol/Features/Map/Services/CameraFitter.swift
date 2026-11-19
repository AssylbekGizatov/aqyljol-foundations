import UIKit
import DGis
import CoreLocation

enum CameraFitter {
    // MARK: Public API
    
    static func fitRouteAB(
        map: Map,
        hostView: UIView?,
        padding: MapPaddingInteractor,
        a: GeoPoint,
        b: GeoPoint
    ) {
        let sideAirPt: CGFloat = 24
        let topAirPt:  CGFloat = 24
        let botAirPt:  CGFloat = 24
        
        let viewSizePt = hostView?.bounds.size ?? UIScreen.main.bounds.size
        let visibleWpt = max(1, viewSizePt.width  - sideAirPt * 2)
        let visibleHpt = max(1, viewSizePt.height - topAirPt - botAirPt - padding.currentBottomPadding)
        let scale = UIScreen.main.scale
        
        let midLat = (a.latitude.value + b.latitude.value) * 0.5
        let midLon = midLongitude(a.longitude.value, b.longitude.value)
        let center = GeoPoint(latitude: midLat, longitude: midLon)
        
        let margin: Double = 1.25
        let dist = distanceMeters(a, b) * margin
        var z = zoomForDistance(dist) + 1.0
        z = min(z, 16.0)

        let pos = CameraPosition(
            point: center,
            zoom: Zoom(value: z),
            tilt: Tilt(value: 0),
            bearing: Bearing(value: 0)
        )
        _ = map.camera.move(position: pos, time: 0.25, animationType: .linear)
    }
    
    static func moveToUser(map: Map, coord: CLLocationCoordinate2D, zoom: Float = 16) {
        let gp = GeoPoint(latitude: coord.latitude, longitude: coord.longitude)
        let pos = CameraPosition(
            point: gp,
            zoom: Zoom(value: zoom),
            tilt: Tilt(value: 0),
            bearing: Bearing(value: 0)
        )
        _ = map.camera.move(position: pos, time: 0.3, animationType: .linear)
    }

    // MARK: Helpers
    private static func distanceMeters(_ a: GeoPoint, _ b: GeoPoint) -> Double {
        let R = 6_371_000.0
        let φ1 = a.latitude.value  * .pi/180
        let φ2 = b.latitude.value  * .pi/180
        let dφ = (b.latitude.value  - a.latitude.value)  * .pi/180
        let dλ = (b.longitude.value - a.longitude.value) * .pi/180
        let h = sin(dφ/2)*sin(dφ/2) + cos(φ1)*cos(φ2)*sin(dλ/2)*sin(dλ/2)
        return 2 * R * atan2(sqrt(h), sqrt(1 - h))
    }

    private static func zoomForDistance(_ d: Double) -> Float {
        switch d {
        case ..<300:        return 16.0
        case ..<700:        return 15.0
        case ..<1_500:      return 14.0
        case ..<3_000:      return 13.0
        case ..<7_000:      return 12.0
        case ..<15_000:     return 11.0
        case ..<30_000:     return 10.0
        case ..<60_000:     return 9.0
        case ..<120_000:    return 8.0
        case ..<250_000:    return 7.0
        case ..<500_000:    return 6.0
        case ..<1_000_000:  return 5.0
        case ..<2_000_000:  return 4.0
        default:            return 3.5
        }
    }

    private static func normDeltaLon(_ d: Double) -> Double {
        var x = d
        while x >  180 { x -= 360 }
        while x < -180 { x += 360 }
        return x
    }

    private static func midLongitude(_ lon1: Double, _ lon2: Double) -> Double {
        let d = normDeltaLon(lon2 - lon1)
        var lon = lon1 + d * 0.5
        if lon > 180 { lon -= 360 }
        if lon < -180 { lon += 360 }
        return lon
    }
}
