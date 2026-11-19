import DGis
import UIKit

final class MapPaddingInteractor {
    private let map: Map
    private var lastAppliedBottomPadding: UInt32 = 0
    var currentBottomPadding: CGFloat { CGFloat(lastAppliedBottomPadding) }

    init(map: Map) { self.map = map }

    func setBottomPaddingIfNeeded(_ bottom: CGFloat) {
        let clamped = UInt32(max(0, min(bottom.rounded(), CGFloat(UInt32.max))))
        guard clamped != lastAppliedBottomPadding else { return }
        var pad = map.camera.padding
        pad.bottom = clamped
        map.camera.padding = pad
        lastAppliedBottomPadding = clamped
    }
    
    func resetBottomPaddingIfNeeded() {
        guard lastAppliedBottomPadding != 0 else { return }
        var pad = map.camera.padding
        pad.bottom = 0
        map.camera.padding = pad
        lastAppliedBottomPadding = 0
    }
}
