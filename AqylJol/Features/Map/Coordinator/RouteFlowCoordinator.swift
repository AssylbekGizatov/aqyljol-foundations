import UIKit
import DGis
import CoreLocation

final class RouteFlowCoordinator {
    // MARK: - Deps
    private weak var host: UIViewController?
    private let map: Map
    private let overlay: TabBarOverlayView
    private let padding: MapPaddingInteractor
    private let searchCoordinator: SearchSheetCoordinator
    private let userLocationProvider: () -> CLLocation?
    private let controls: MapControlsManager
    private let primaryTopAnchor: NSLayoutYAxisAnchor
    
    private let setBaseSheetVisible: (_ visible: Bool, _ animated: Bool) -> Void
    private let clearHighlights: () -> Void
    private let onStartGuidance: (_ route: TrafficRoute, _ options: RouteBuildOptions) -> Void
    private let prepareNavigationUI: () -> Void
    private let restoreUIAfterBuildFail: () -> Void
    
    // MARK: - UI
    private var overlaySheet: BottomSheetViewController?
    private var isOverlayClosing = false
    var isActionSheetPresented: Bool { overlaySheet != nil }
    private var overlayVisibility: VisibilityInteractor?

    // MARK: - Services & State
    private var routeService: RouteService?
    private(set) var state = RoutingState()
    
    private var selectedMode: RouteActionSheetViewController.Mode = .car
    private var previewBounds: RouteBounds?
    private var previewActive = false
    private var previewWork: DispatchWorkItem?
    private var previewSeq: Int = 0

    // MARK: - Init
    init(host: UIViewController,
         map: Map,
         overlay: TabBarOverlayView,
         padding: MapPaddingInteractor,
         searchCoordinator: SearchSheetCoordinator,
         userLocationProvider: @escaping () -> CLLocation?,
         controls: MapControlsManager,
         primaryTopAnchor: NSLayoutYAxisAnchor,
         clearHighlights: @escaping () -> Void,
         onStartGuidance: @escaping (_ route: TrafficRoute, _ options: RouteBuildOptions) -> Void,
         setBaseSheetVisible: @escaping (_ visible: Bool, _ animated: Bool) -> Void,
         prepareNavigationUI: @escaping () -> Void,
         restoreUIAfterBuildFail: @escaping () -> Void = {}) {
        self.host = host
        self.map = map
        self.overlay = overlay
        self.padding = padding
        self.searchCoordinator = searchCoordinator
        self.userLocationProvider = userLocationProvider
        self.controls = controls
        self.primaryTopAnchor = primaryTopAnchor
        self.clearHighlights = clearHighlights
        self.setBaseSheetVisible = setBaseSheetVisible
        self.onStartGuidance = onStartGuidance
        self.prepareNavigationUI = prepareNavigationUI
        self.restoreUIAfterBuildFail = restoreUIAfterBuildFail
    }

    // MARK: - Public API
    func presentRouteActionSheet(_ obj: DirectoryObject? = nil) {
        let show: () -> Void = { [weak self] in
            guard let self, let host = self.host else { return }
            
            self.state = .init()
            self.state.finishObject = obj
            
            let s = BottomSheetViewController()
            s.lowHeight   = 120
            s.mediumRatio = 0.35
            s.highRatio   = 0.60

            let content = RouteActionSheetViewController()
            content.initialFrom = MapStrings.myLocation
            content.initialTo   = (self.state.finishObject?.title ?? obj?.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            content.onModeChanged = { [weak self] mode in
                self?.selectedMode = mode
                self?.requestPreview(.modeChanged)
            }
            content.onClose = { [weak self] in
                self?.dismissOverlaySheet(animated: true, initiatedByUserPan: false)
            }
            content.onStartTap = { [weak self, weak s, weak content] in
                guard let self, let s, let content else { return }
                self.presentRoutingSearch(
                    over: s,
                    prefill: content.currentFromText,
                    applySelected: { [weak self, weak content] obj in
                        self?.state.startObject = obj
                        content?.setFrom(object: obj)
                        self?.requestPreview(.pointsChanged)
                    },
                    backTo: content
                )
            }

            content.onFinishTap = { [weak self, weak s, weak content] in
                guard let self, let s, let content else { return }
                self.presentRoutingSearch(
                    over: s,
                    prefill: content.currentToText,
                    applySelected: { [weak self, weak content] obj in
                        self?.state.finishObject = obj
                        content?.setTo(object: obj)
                        self?.requestPreview(.pointsChanged)
                    },
                    backTo: content
                )
            }
            
            content.onReverseTap = { [weak self] in
                guard let self else { return }
                self.state.reverse()
                content.swapTextFields()
                self.requestPreview(.reversed, delay: 0)
            }
            
            content.onBuild = { [weak self] fromText, toText, _ in
                guard let self else { return }
                
                self.prepareNavigationUI()
                guard let service = self.ensureRouteService() else { return }

                let startObj  = self.state.startObject
                let finishObj = self.state.finishObject
                let fromStr = (fromText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let fromIsMyLocation = fromStr.isEmpty || fromStr.localizedCaseInsensitiveContains(MapStrings.myLocation)

                service.buildRoute(
                    startObject: startObj,
                    finishObject: finishObj,
                    fromText: (fromIsMyLocation && startObj == nil) ? "" : (fromText ?? ""),
                    toText: toText ?? "",
                    mode: self.routeMode(from: self.selectedMode)
                ) { [weak self] route in
                    guard let self else { return }
                    guard let route else {
                        self.restoreUIAfterBuildFail()
                        return
                    }
                    
                    guard let finish = self.finishGeoPoint(from: finishObj, toText: toText) else { return }
                    let options = RouteBuildOptions(
                        finishPoint: RouteSearchPoint(coordinates: finish),
                        routeSearchOptions: self.makeNavRouteSearchOptions()
                    )
                    
                    self.onStartGuidance(route, options)
                    
                    DispatchQueue.main.async {
                        self.dismissOverlaySheet(
                            animated: true,
                            initiatedByUserPan: false,
                            makeBaseVisible: false,
                            clearRoute: false,
                            resetOverlayModeToPrimary: false
                        ) { [weak self] in
                            guard let self else { return }
                            self.clearHighlights()
                            self.routeService?.clearRoute()
                        }
                    }
                }
            }
            
            s.setContent(content)
            s.present(over: host)
            s.setDetent(.medium, animated: true)
            self.padding.setBottomPaddingIfNeeded(s.currentBottomInset)
            self.overlayVisibility = VisibilityInteractor(hostView: host.view, sheet: s, controls: self.controls)
            self.overlayVisibility?.apply(sheetInset: s.currentBottomInset)
            self.controls.dockCurrentLocation(toSheetTop: s.dockingTopAnchor)
            requestPreview(.presented)
            self.setBaseSheetVisible(false, false)
            self.overlay.isHidden = true

            s.onBottomInsetChanged = { [weak self] inset in self?.padding.setBottomPaddingIfNeeded(inset)
                self?.overlayVisibility?.apply(sheetInset: inset)
                if let b = self?.previewBounds, self?.previewActive == true, let self = self {
                    CameraFitter.fitRouteAB(
                        map: self.map,
                        hostView: self.host?.view,
                        padding: self.padding,
                        a: b.southWest,
                        b: b.northEast
                    )
                }
            }
            s.onDetentChanged = { [weak self] detent in
                guard let self else { return }
                if detent == .low { self.dismissOverlaySheet(animated: true, initiatedByUserPan: true) }
            }
            self.overlaySheet = s
        }

        if overlaySheet != nil {
            routeService?.clearRoute()
            dismissOverlaySheet(animated: false, initiatedByUserPan: false, makeBaseVisible: false) { show() }
        } else {
            show()
        }
    }

    // MARK: - Internal helpers
    private func presentRoutingSearch(
        over sheet: BottomSheetViewController,
        prefill: String,
        applySelected: @escaping (DirectoryObject) -> Void,
        backTo actionVC: RouteActionSheetViewController
    ) {
        searchCoordinator.presentRoutingSearch(
            over: sheet,
            prefill: prefill,
            applySelected: applySelected,
            backTo: actionVC
        )
    }

    private func ensureRouteService() -> RouteService? {
        if routeService == nil {
            guard let container = SDK.container else {
                print("🟥 SDK not initialized"); return nil
            }
            guard let context = try? container.context else {
                print("🟥 Failed to get DGis context"); return nil
            }
            routeService = RouteService(
                map: self.map,
                context: context,
                userLocationProvider: { [weak self] in self?.userLocationProvider() }
            )
        }
        return routeService
    }

    // MARK: - Overlay sheet lifecycle
    func dismissOverlaySheet(
        animated: Bool,
        initiatedByUserPan: Bool,
        makeBaseVisible: Bool = true,
        clearRoute: Bool = true,
        resetOverlayModeToPrimary: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard let s = overlaySheet, !isOverlayClosing else { return }
        isOverlayClosing = true
        
        let teardown: () -> Void = { [weak self] in
            guard let self else { return }
            if clearRoute { self.routeService?.clearRoute() }
            self.previewWork?.cancel()
            self.previewActive = false
            self.previewBounds = nil
            if clearRoute { self.routeService?.clearRoute() }
            s.willMove(toParent: nil)
            s.view.removeFromSuperview()
            s.removeFromParent()
            self.overlaySheet = nil
            self.isOverlayClosing = false
            self.overlayVisibility = nil
            if resetOverlayModeToPrimary {
                self.overlay.mode = .primary
            }
            if makeBaseVisible {
                self.setBaseSheetVisible(true, animated)
                self.controls.dockCurrentLocation(toSheetTop: self.primaryTopAnchor)
            } else {
                
            }
            self.clearHighlights()
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
    
    func requestPreview(_ reason: PreviewTrigger, delay: TimeInterval = 0.6) {
        previewWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.performPreview(reason) }
        previewWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    private func performPreview(_ reason: PreviewTrigger) {
        guard let service = ensureRouteService() else { return }
        
        let s = state.startObject
        let f = state.finishObject
        
        let fromText = MapStrings.myLocation
        var toText   = (f?.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if toText.isEmpty, s != nil {
            toText = MapStrings.myLocation
        }
        
        guard f != nil || !toText.isEmpty else { return }

        let mySeq = { previewSeq &+= 1; return previewSeq }()
        previewActive = true

        service.buildRoutePreview(
            startObject: s,
            finishObject: f,
            fromText: fromText,
            toText: toText,
            mode: routeMode(from: selectedMode)
        ) { [weak self] ok, bounds in
            guard let self else { return }
            guard mySeq == self.previewSeq else { return }
            self.previewActive = ok
            self.previewBounds = bounds
            if ok, let b = bounds {
                DispatchQueue.main.async {
                    CameraFitter.fitRouteAB(
                        map: self.map,
                        hostView: self.host?.view,
                        padding: self.padding,
                        a: b.southWest,
                        b: b.northEast
                    )
                }
            }
        }
    }

    private func routeMode(from uiMode: RouteActionSheetViewController.Mode) -> RouteService.Mode {
        switch uiMode {
        case .car:        return .car
        case .truck:      return .truck
        case .pedestrian: return .pedestrian
        }
    }
    
    private func makeNavRouteSearchOptions() -> RouteSearchOptions {
        let car = CarRouteSearchOptions(
            avoidTollRoads: false,
            avoidUnpavedRoads: false,
            avoidFerries: false,
            avoidLockedRoads: true,
            routeSearchType: .jam,
            excludedAreas: []
        )
        switch selectedMode {
        case .car:
            return .car(car)
        case .truck:
            return .truck(
                TruckRouteSearchOptions(
                    car: car,
                    truckLength: 0, truckHeight: 0, truckWidth: 0,
                    actualMass: 0, maxPermittedMass: 0,
                    axleLoad: 0, dangerousCargo: false, explosiveCargo: false,
                    passIds: Set<TruckPassZonePassId>(),
                    fallbackOnCar: true
                )
            )
        case .pedestrian:
            return .pedestrian(
                PedestrianRouteSearchOptions(
                    avoidStairways: false,
                    avoidUnderpassesAndOverpasses: false,
                    useIndoor: true,
                    excludedAreas: []
                )
            )
        }
    }
    
    private func finishGeoPoint(from finishObject: DirectoryObject?, toText: String?) -> GeoPoint? {
        if let mp = finishObject?.markerPosition {
            return GeoPoint(latitude: mp.latitude.value, longitude: mp.longitude.value)
        }
        let trimmed = (toText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.localizedCaseInsensitiveContains(MapStrings.myLocation),
           let loc = userLocationProvider()?.coordinate {
            return GeoPoint(latitude: loc.latitude, longitude: loc.longitude)
        }
        return nil
    }
}
