import Foundation

public struct Place: Codable, Equatable {
    var name: String
    var type: String
    var latitude: Double
    var longitude: Double
    var distance_km: Double
    var rating: Double
    var description: String
}
