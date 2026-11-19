import Foundation
import DGis

final class RoadEventViewModel {
    private let manager: RoadEventManager

    init(container: Container) throws {
        self.manager = try RoadEventManager(context: container.context)
    }
    
    func createAccident(at point: GeoPoint,
                        lanes: LaneOptionSet,
                        description: String = "") {
        _ = manager.createAccident(location: point, lanes: lanes, description: description)
            .sink(
                receiveValue: { _ in  },
                failure: { error in
                    print("❌ createAccident error: \(error)")
                }
            )
    }
    
    func createCamera(at point: GeoPoint, description: String = "") {
        _ = manager.createCamera(location: point, description: description)
            .sink(
                receiveValue: { _ in  },
                failure: { error in
                    print("❌ createCamera error: \(error)")
                }
            )
    }
    
    func createRoadRestriction(at point: GeoPoint, description: String = "") {
        _ = manager.createRoadRestriction(location: point, description: description)
            .sink(
                receiveValue: { _ in },
                failure: { error in
                    print("❌ createRoadRestriction error: \(error)")
                }
            )
    }
    
    func createComment(at point: GeoPoint, description: String) {
        _ = manager.createComment(location: point, description: description)
            .sink(
                receiveValue: { _ in },
                failure: { error in
                    print("❌ createComment error: \(error)")
                }
            )
    }
    
    func createRoadWorks(at point: GeoPoint, lanes: LaneOptionSet, description: String) {
        _ = manager.createRoadWorks(location: point, lanes: lanes, description: description)
            .sink(
                receiveValue: { _ in },
                failure: { error in
                    print("❌ createRoadWorks error: \(error)")
                }
            )
    }

    func createOther(at point: GeoPoint, lanes: LaneOptionSet, description: String) {
        _ = manager.createOther(location: point, lanes: lanes, description: description)
            .sink(
                receiveValue: { _ in },
                failure: { error in
                    print("❌ createOther error: \(error)")
                }
            )
    }
}
