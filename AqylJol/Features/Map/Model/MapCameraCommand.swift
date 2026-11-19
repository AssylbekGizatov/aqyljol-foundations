import CoreLocation

public enum MapCameraCommand {
    case none
    case moveTo(coordinate: CLLocationCoordinate2D, zoom: Float)
    case moveToUser(zoom: Float)
}
