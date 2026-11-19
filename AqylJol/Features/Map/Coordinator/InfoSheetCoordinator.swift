import UIKit
import DGis

final class InfoSheetCoordinator {

    // MARK: Deps
    private weak var host: UIViewController?
    private let overlay: TabBarOverlayView
    private let padding: MapPaddingInteractor
    private let highlight: HighlightInteractor
    
    private let setBaseSheetVisible: (_ visible: Bool, _ animated: Bool) -> Void
    private let onWillDismiss: () -> Void
    private let onObjectShown: (DirectoryObject) -> Void
    private let dockLocateTo: (NSLayoutYAxisAnchor) -> Void
    private let dockLocateBackToPrimary: () -> Void
    
    // MARK: UI
    private var overlaySheet: BottomSheetViewController?
    private var overlayVisibility: VisibilityInteractor?
    private let controls: MapControlsManager

    // MARK: Init
    init(host: UIViewController,
         overlay: TabBarOverlayView,
         padding: MapPaddingInteractor,
         highlight: HighlightInteractor,
         controls: MapControlsManager,
         setBaseSheetVisible: @escaping (_ visible: Bool, _ animated: Bool) -> Void,
         onWillDismiss: @escaping () -> Void,
         onObjectShown: @escaping (DirectoryObject) -> Void,
         dockLocateTo: @escaping (NSLayoutYAxisAnchor) -> Void,
         dockLocateBackToPrimary: @escaping () -> Void) {
        self.host = host
        self.overlay = overlay
        self.padding = padding
        self.highlight = highlight
        self.controls = controls
        self.setBaseSheetVisible = setBaseSheetVisible
        self.onWillDismiss = onWillDismiss
        self.onObjectShown = onObjectShown
        self.dockLocateTo = dockLocateTo
        self.dockLocateBackToPrimary = dockLocateBackToPrimary
    }

    // MARK: Public
    var isPresenting: Bool { overlaySheet != nil }

    func present(for directoryObject: DirectoryObject) {
        guard overlaySheet == nil, let host else { return }

        let s = BottomSheetViewController()
        s.lowHeight   = 250
        s.mediumRatio = 0.75
        s.highRatio   = 0.92
        
        let vm = InfoViewModel()
        let content = InfoViewController(viewModel: vm)
        content.onClose = { [weak self] in
            self?.dismiss(animated: true, initiatedByUserPan: false)
            self?.highlight.clearHighlights()
        }

        s.setContent(content)
        s.present(over: host)
        s.setDetent(.low, animated: true)
        content.setCompactMode(true)
        
        overlayVisibility = VisibilityInteractor(hostView: host.view, sheet: s, controls: controls)
        overlayVisibility?.apply(sheetInset: s.currentBottomInset)
        dockLocateTo(s.dockingTopAnchor)
        
        vm.configure(with: directoryObject)
        
        overlay.mode = .info
        host.view.bringSubviewToFront(overlay)
        overlay.isHidden = false
        
        onObjectShown(directoryObject)
        
        highlight.applyHighlight(for: directoryObject, primarySource: nil, primaryId: nil)
        
        s.onBottomInsetChanged = { [weak self] inset in
            guard let self else { return }
            self.padding.setBottomPaddingIfNeeded(inset)
            self.overlayVisibility?.apply(sheetInset: inset)
        }
        s.onDetentChanged = { [weak self] detent in
            guard let self else { return }
            content.setCompactMode(detent == .low)
        }
        
        setBaseSheetVisible(false, false)
        overlaySheet = s
    }

    func presentOrReplace(for directoryObject: DirectoryObject) {
        if overlaySheet != nil {
            dismiss(animated: false, initiatedByUserPan: false, makeBaseVisible: false) { [weak self] in
                self?.present(for: directoryObject)
            }
        } else {
            present(for: directoryObject)
        }
    }

    func dismiss(animated: Bool,
                 initiatedByUserPan: Bool,
                 makeBaseVisible: Bool = true,
                 completion: (() -> Void)? = nil) {
        guard let s = overlaySheet else { return }

        let teardown: () -> Void = { [weak self] in
            guard let self else { return }
            self.onWillDismiss()
            s.willMove(toParent: nil)
            s.view.removeFromSuperview()
            s.removeFromParent()
            self.overlaySheet = nil
            self.overlayVisibility = nil
            self.highlight.clearHighlights()
            self.overlay.mode = .primary
            if makeBaseVisible {
                self.setBaseSheetVisible(true, true)
                self.dockLocateBackToPrimary()
            } else {
                self.overlay.isHidden = false
            }
            completion?()
        }
        
        if animated && initiatedByUserPan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: teardown)
            return
        }
        if animated {
            s.setDetent(.low, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26, execute: teardown)
        } else {
            teardown()
        }
    }
}
