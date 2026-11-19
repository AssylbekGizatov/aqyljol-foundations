import UIKit
import DGis

final class SearchSheetCoordinator {

    // MARK: - Deps
    private weak var host: UIViewController?
    private let searchService: SearchService
    private let padding: MapPaddingInteractor
    
    private let setBaseSheetVisible: (_ visible: Bool, _ animated: Bool) -> Void
    
    private let presentInfo: (DirectoryObject) -> Void
    private var voiceCoordinator: VoiceSheetCoordinator?

    // MARK: - UI
    private var overlaySheet: BottomSheetViewController?
    private var isClosing = false

    // MARK: - Init
    init(host: UIViewController,
         searchService: SearchService,
         padding: MapPaddingInteractor,
         setBaseSheetVisible: @escaping (_ visible: Bool, _ animated: Bool) -> Void,
         presentInfo: @escaping (DirectoryObject) -> Void) {
        self.host = host
        self.searchService = searchService
        self.padding = padding
        self.setBaseSheetVisible = setBaseSheetVisible
        self.presentInfo = presentInfo
    }

    // MARK: - Public API
    func presentSearchSheetHigh() {
        presentSearchSheetHigh(initialQuery: nil)
    }
    
    func presentSearchSheetHigh(initialQuery: String?) {
        guard overlaySheet == nil, let host else { return }

        let s = BottomSheetViewController()
        s.highRatio   = 0.92
        s.mediumRatio = s.highRatio
        s.lowHeight   = 120

        let content = SearchPanelViewController()
        content.searchManager = searchService.ensureOnlineManager()
        content.initialQuery = initialQuery
        
        content.onRequestExpandToHigh = { [weak s] in
            s?.setDetent(.high, animated: true)
        }
        
        if let host = self.host {
            self.voiceCoordinator = VoiceSheetCoordinator(host: host)
            content.onRequestVoiceCapture = { [weak self] completion in
                self?.voiceCoordinator?.presentVoiceCapture { text in
                    completion(text)
                }
            }
        }
        
        content.onSelectObject = { [weak self] obj in
            guard let self else { return }
            self.dismissOverlaySheet(
                animated: true,
                initiatedByUserPan: false,
                makeBaseVisible: false
            ) { [weak self] in
                self?.presentInfo(obj)
            }
        }
        
        content.onCancel = { [weak self] in
            self?.dismissOverlaySheet(
                animated: true,
                initiatedByUserPan: false,
                makeBaseVisible: true
            )
        }

        s.setContent(content)
        s.present(over: host)
        s.setDetent(.high, animated: true)

        s.onBottomInsetChanged = { [weak self] inset in
            self?.padding.setBottomPaddingIfNeeded(inset)
        }
        s.onDetentChanged = { [weak self] detent in
            guard let self else { return }
            if detent != .high {
                self.dismissOverlaySheet(animated: true, initiatedByUserPan: true, makeBaseVisible: true)
            }
        }

        overlaySheet = s
        
        setBaseSheetVisible(false, false)
    }
    
    func presentRoutingSearch(
        over sheet: BottomSheetViewController,
        prefill: String,
        applySelected: @escaping (DirectoryObject) -> Void,
        backTo actionVC: RouteActionSheetViewController
    ) {
        guard let host else { return }

        let searchVC = SearchPanelViewController()
        searchVC.searchManager = searchService.ensureOnlineManager()
        searchVC.initialQuery = prefill
        
        searchVC.onRequestExpandToHigh = { [weak sheet] in
            sheet?.setDetent(.high, animated: true)
        }
        
        let voice = VoiceSheetCoordinator(host: host)
        searchVC.onRequestVoiceCapture = { [weak host, weak voice] completion in
            host?.view.endEditing(true)
            voice?.presentVoiceCapture { text in completion(text) }
        }

        searchVC.onSelectObject = { [weak self, weak sheet] obj in
            guard let self, let sheet else { return }
            applySelected(obj)
            sheet.setContent(actionVC)
            sheet.setDetent(.medium, animated: true)
            self.padding.setBottomPaddingIfNeeded(sheet.currentBottomInset)
        }

        searchVC.onCancel = { [weak self, weak sheet] in
            guard let self, let sheet else { return }
            sheet.setContent(actionVC)
            sheet.setDetent(.medium, animated: true)
            self.padding.setBottomPaddingIfNeeded(sheet.currentBottomInset)
        }

        sheet.setContent(searchVC)
        sheet.setDetent(.high, animated: true)
    }

    // MARK: - Closing
    private func dismissOverlaySheet(
        animated: Bool,
        initiatedByUserPan: Bool,
        makeBaseVisible: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard let s = overlaySheet, !isClosing else { return }
        isClosing = true

        let cleanup: () -> Void = { [weak self] in
            guard let self else { return }
            s.willMove(toParent: nil)
            s.view.removeFromSuperview()
            s.removeFromParent()
            self.overlaySheet = nil
            self.isClosing = false
            self.voiceCoordinator = nil
            if makeBaseVisible {
                self.setBaseSheetVisible(true, true)
            }
            completion?()
        }

        if animated && initiatedByUserPan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: cleanup)
            return
        }
        if animated {
            s.setDetent(.low, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26, execute: cleanup)
        } else {
            cleanup()
        }
    }
}
