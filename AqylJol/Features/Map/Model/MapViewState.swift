import CoreLocation

public struct MapViewState {
    public var didCenterOnUser: Bool
    public var lastUserLocation: CLLocation?
    public var authorizationStatus: CLAuthorizationStatus

    public init(
        didCenterOnUser: Bool = false,
        lastUserLocation: CLLocation? = nil,
        authorizationStatus: CLAuthorizationStatus = .notDetermined
    ) {
        self.didCenterOnUser = didCenterOnUser
        self.lastUserLocation = lastUserLocation
        self.authorizationStatus = authorizationStatus
    }
}
