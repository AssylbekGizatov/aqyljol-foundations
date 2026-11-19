import DGis
import UIKit

protocol MapTapInteractorOutput: AnyObject {
    func showInfo(for object: DirectoryObject)
    func highlight(_ object: DirectoryObject, primarySource: DgisSource?, primaryId: DgisObjectId?)
}

final class MapTapInteractor {
    private let map: Map
    private var lastAppliedBottomPadding: UInt32 = 0
    private let search: SearchService
    private weak var output: MapTapInteractorOutput?
    private var getRenderedObjectsCancellable: DGis.Cancellable?
    private var getDirectoryObjectCancellable: DGis.Cancellable?
    
    var currentBottomPadding: CGFloat { CGFloat(lastAppliedBottomPadding) }

    init(map: Map, searchService: SearchService, output: MapTapInteractorOutput) {
        self.map = map
        self.search = searchService
        self.output = output
    }

    func handleTap(at sp: ScreenPoint) {
        guard let searchManager = search.ensureOnlineManager() else {
            print("🟥 MapTapInteractor: searchManager == nil"); return
        }
        let r = ScreenDistance(value: 3.0)
        getRenderedObjectsCancellable?.cancel()
        getRenderedObjectsCancellable = map.getRenderedObjects(centerPoint: sp, radius: r).sink(
            receiveValue: { [weak self] infos in
                guard let self else { return }
                let pairs = infos.compactMap { info -> (DgisSource, DgisMapObject)? in
                    guard let src = info.item.source as? DgisSource,
                          let mo  = info.item.item   as? DgisMapObject else { return nil }
                    return (src, mo)
                }
                guard !pairs.isEmpty else {
                    self.reverseGeocodeFallback()
                    return
                }
                let candidate = pairs.prefix(1).first { pair in
                    let ud = (pair.1.userData as? String ?? "").lowercased()
                    return !(ud.contains("bus") || ud.contains("stop") || ud.contains("транспорт") || ud.contains("останов"))
                } ?? pairs.first!

                let (src, mo) = candidate
                let fut = searchManager.searchByDirectoryObjectId(objectId: mo.id)
                self.getDirectoryObjectCancellable = fut.sinkOnMainThread(
                    receiveValue: { [weak self] directoryObject in
                        guard let self, let obj = directoryObject else { return }
                        self.output?.showInfo(for: obj)
                        self.output?.highlight(obj, primarySource: src, primaryId: obj.id)
                    },
                    failure: { error in print("🟥 searchByDirectoryObjectId error:", error) }
                )
            },
            failure: { error in print("🟥 getRenderedObjects error:", error) }
        )
    }

    private func reverseGeocodeFallback() {
        guard let searchManager = search.ensureOnlineManager() else { return }
        let gp = map.camera.position.point
        let q = SearchQueryBuilder
            .fromGeoPoint(geoPoint: gp)
            .setRadius(radius: Meter(value: 30))
            .setSortingType(sortingType: .byDistance)
            .setPageSize(pageSize: 1)
            .build()

        getDirectoryObjectCancellable = searchManager.search(query: q).sinkOnMainThread(
            receiveValue: { [weak self] res in
                guard let self, let obj = res.firstPage?.items.first else { return }
                self.output?.showInfo(for: obj)
                self.output?.highlight(obj, primarySource: nil, primaryId: obj.id)
            },
            failure: { error in print("🟥 reverse geocode error:", error) }
        )
    }
}
