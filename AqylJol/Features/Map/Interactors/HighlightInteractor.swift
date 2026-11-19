import UIKit
import DGis

final class HighlightInteractor {
    private let map: Map
    private weak var hostView: UIView?

    private var lastHighlightSource: DgisSource?
    private var lastHighlightedIds: [DgisObjectId] = []

    init(map: Map, hostView: UIView?) {
        self.map = map
        self.hostView = hostView
    }

    func applyHighlight(for obj: DirectoryObject, primarySource: DgisSource? = nil, primaryId: DgisObjectId? = nil) {
        clearHighlights()

        var ids: [DgisObjectId] = []
        if let primaryId { ids.append(primaryId) }
        obj.entrances.forEach { ids.append($0.id) }
        
        if let mp = obj.markerPosition {
            let gp = GeoPoint(latitude: mp.latitude.value, longitude: mp.longitude.value)
            let targetZoom = max(map.camera.position.zoom.value, 16)
            _ = map.camera.move(
                position: CameraPosition(point: gp, zoom: Zoom(value: targetZoom), tilt: .init(value: 0), bearing: .init(value: 0)),
                time: 0.3,
                animationType: .linear
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            func apply(on source: DgisSource) {
                source.setHighlighted(directoryObjectIds: ids, highlighted: true)
                self.lastHighlightSource = source
                self.lastHighlightedIds  = ids
            }

            if let src = primarySource { apply(on: src); return }
            
            let center = CGPoint(x: self.hostView?.bounds.midX ?? 0, y: self.hostView?.bounds.midY ?? 0)
            let sp = ScreenPoint(x: Float(center.x * UIScreen.main.nativeScale), y: Float(center.y * UIScreen.main.nativeScale))
            let r  = ScreenDistance(value: 5.0)
            _ = self.map.getRenderedObjects(centerPoint: sp, radius: r).sink(
                receiveValue: { infos in
                    if let src = infos.compactMap({ $0.item.source as? DgisSource }).first {
                        DispatchQueue.main.async { apply(on: src) }
                    }
                },
                failure: { _ in }
            )
        }
    }

    func clearHighlights() {
        if let src = lastHighlightSource, !lastHighlightedIds.isEmpty {
            src.setHighlighted(directoryObjectIds: lastHighlightedIds, highlighted: false)
        }
        lastHighlightedIds.removeAll()
        lastHighlightSource = nil
    }
}
