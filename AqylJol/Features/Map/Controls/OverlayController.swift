import UIKit
import DGis

protocol OverlayActions: AnyObject {
    func showSearchTab()
    func openChats()
    func openProfile()
    func presentRouteAction(for currentInfo: DirectoryObject?)
    func addToFavorites(_ obj: DirectoryObject)
    func share(_ obj: DirectoryObject, from host: UIViewController)
    func finishRouting()
}

final class OverlayController {
    private let overlay: TabBarOverlayView
    private weak var host: UIViewController?
    private weak var actions: OverlayActions?
    private let currentInfoProvider: () -> DirectoryObject?

    init(overlay: TabBarOverlayView,
         host: UIViewController,
         actions: OverlayActions,
         currentInfoProvider: @escaping () -> DirectoryObject?) {
        self.overlay = overlay
        self.host = host
        self.actions = actions
        self.currentInfoProvider = currentInfoProvider
        wire()
    }

    private func wire() {
        overlay.onSelect = { [weak self] item in
            guard let self else { return }
            switch item {
            case .search: self.actions?.showSearchTab()
            case .chats:  self.actions?.openChats()
            case .profile: self.actions?.openProfile()
            case .route:  self.actions?.presentRouteAction(for: self.currentInfoProvider())
            case .favorite:
                if let obj = self.currentInfoProvider() { self.actions?.addToFavorites(obj) }
            case .share:
                if let obj = self.currentInfoProvider(), let host = self.host {
                    self.actions?.share(obj, from: host)
                }
            }
        }
    }

    func setMode(_ mode: TabBarOverlayView.Mode) { overlay.mode = mode }
    func setSelected(_ item: TabBarOverlayView.Item) { overlay.setSelected(item) }
}
