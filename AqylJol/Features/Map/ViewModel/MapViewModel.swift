import Foundation
import CoreLocation

public final class MapViewModel: NSObject {

    // MARK: Outputs
    public var onAuthorizationChanged: ((CLAuthorizationStatus) -> Void)?
    public var onStateChanged: ((MapViewState) -> Void)? {
        didSet { DispatchQueue.main.async { [state] in self.onStateChanged?(state) } }
    }
    public var onCameraCommand: ((MapCameraCommand) -> Void)?

    // MARK: State (MVVM Model)
    private(set) var state = MapViewState()

    // MARK: Location
    private let manager = CLLocationManager()

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .automotiveNavigation
    }

    // MARK: Inputs
    public func requestWhenInUse() { manager.requestWhenInUseAuthorization() }

    public func startUpdating() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        manager.startUpdatingLocation()
    }

    public func stopUpdating() { manager.stopUpdatingLocation() }

    public func requestPreciseIfReduced(purposeKey: String) {
        if manager.accuracyAuthorization == .reducedAccuracy {
            manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey)
        }
    }
    
    public func resetDidCenterOnUser() {
        mutate { $0.didCenterOnUser = false }
    }

    // MARK: Private helpers
    private func mutate(_ block: (inout MapViewState) -> Void) {
        block(&state)
        DispatchQueue.main.async { [state] in self.onStateChanged?(state) }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapViewModel: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async { self.onAuthorizationChanged?(status) }
        mutate { $0.authorizationStatus = status }

        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startUpdating()
        } else {
            stopUpdating()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last, last.horizontalAccuracy >= 0 else { return }
        
        let shouldAutoCenter: Bool = (state.didCenterOnUser == false)
        mutate {
            $0.lastUserLocation = last
            if shouldAutoCenter { $0.didCenterOnUser = true }
        }
        
        if shouldAutoCenter {
            DispatchQueue.main.async {
                self.onCameraCommand?(.moveTo(coordinate: last.coordinate, zoom: 16))
            }
        }
    }
}
