import DGis

public struct RoutingState {
    public var startObject: DirectoryObject?
    public var finishObject: DirectoryObject?

    public init(startObject: DirectoryObject? = nil, finishObject: DirectoryObject? = nil) {
        self.startObject = startObject
        self.finishObject = finishObject
    }
    
    public mutating func reverse() {
        let tmp = startObject
        startObject = finishObject
        finishObject = tmp
    }
}
