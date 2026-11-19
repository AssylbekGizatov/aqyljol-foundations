import UIKit
import DGis

final class MapControlsManager {

    // MARK: Public controls (read-only)
    private(set) var zoomControl: ZoomControl?
    private(set) var trafficControl: TrafficControl?
    private(set) var createRoadEventControl: CreateRoadEventControl?
    private(set) var compassControl: CompassControl?
    private(set) var currentLocationControl: CurrentLocationControl?
    private(set) var profileControl: UIView?
    
    var currentZoomView: UIView? { zoomControl }

    // MARK: Callbacks
    var onCreateRoadEventTapped: (() -> Void)?
    var onProfileTapped: (() -> Void)?

    // MARK: Private layout state
    private weak var hostView: UIView?
    private var lastFactory: (any IMapControlFactory)?
    private var isSuspendedForNavigation = false
    private var currentLocationBottomConstraint: NSLayoutConstraint?
    private var isDockedToSheetTop = false

    // MARK: Attach / Detach
    func attachAll(to hostView: UIView, factory: any IMapControlFactory) {
        detachAll()
        self.hostView = hostView
        self.lastFactory = factory

        let guide = hostView.safeAreaLayoutGuide
        let side: CGFloat = -16
        let spacing: CGFloat = 12
        
        let traffic = factory.makeTrafficControl()
        traffic.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(traffic)
        NSLayoutConstraint.activate([
            traffic.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            traffic.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: side)
        ])
        self.trafficControl = traffic
        
        let road = factory.makeCreateRoadEventControl()
        road.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(road)
        NSLayoutConstraint.activate([
            road.topAnchor.constraint(equalTo: traffic.bottomAnchor, constant: spacing),
            road.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: side)
        ])
        road.addTarget(self, action: #selector(didTapRoadEvent), for: .touchUpInside)
        self.createRoadEventControl = road
        
        let zoom = factory.makeZoomControl()
        zoom.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(zoom)
        NSLayoutConstraint.activate([
            zoom.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            zoom.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: side)
        ])
        self.zoomControl = zoom
        
        let locate = factory.makeCurrentLocationControl()
        locate.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(locate)
        let bottom = locate.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: side)
        NSLayoutConstraint.activate([
            locate.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: side),
            bottom
        ])
        self.currentLocationControl = locate
        self.currentLocationBottomConstraint = bottom
        self.isDockedToSheetTop = false
        
        let compass = factory.makeCompassControl()
        compass.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(compass)
        NSLayoutConstraint.activate([
            compass.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: side),
            compass.bottomAnchor.constraint(equalTo: locate.topAnchor, constant: -spacing)
        ])
        self.compassControl = compass
    }
    
    func suspendForNavigation() {
        guard !isSuspendedForNavigation else { return }
        [zoomControl, trafficControl, createRoadEventControl, compassControl, currentLocationControl, profileControl]
            .forEach { $0?.removeFromSuperview() }
        zoomControl = nil
        trafficControl = nil
        createRoadEventControl = nil
        compassControl = nil
        currentLocationControl = nil
        profileControl = nil
        currentLocationBottomConstraint = nil
        isDockedToSheetTop = false
        isSuspendedForNavigation = true
    }
    
    func resumeAfterNavigation() {
        guard isSuspendedForNavigation, let host = hostView, let factory = lastFactory else { return }
        isSuspendedForNavigation = false
        attachAll(to: host, factory: factory)    }
    
    func detachAll() {
        [zoomControl, trafficControl, createRoadEventControl, compassControl, currentLocationControl, profileControl]
            .forEach { $0?.removeFromSuperview() }
        zoomControl = nil
        trafficControl = nil
        createRoadEventControl = nil
        compassControl = nil
        currentLocationControl = nil
        profileControl = nil
        currentLocationBottomConstraint = nil
        isDockedToSheetTop = false
        hostView = nil
    }

    // MARK: Actions
    @objc private func didTapRoadEvent() {
        onCreateRoadEventTapped?()
    }

    // MARK: Visibility
    func setZoomHidden(_ hidden: Bool) { zoomControl?.isHidden = hidden }
    func setTopButtonsHidden(_ hidden: Bool) {
        trafficControl?.isHidden = hidden
        createRoadEventControl?.isHidden = hidden
    }
    func setCompassHidden(_ hidden: Bool) { compassControl?.isHidden = hidden }
    func setCurrentLocationHidden(_ hidden: Bool) { currentLocationControl?.isHidden = hidden }
    func setProfileHidden(_ hidden: Bool) { profileControl?.isHidden = hidden }
    
    // MARK: Positioning
    func updateForSheet(inset: CGFloat) {
        guard !isDockedToSheetTop else { return }
        let paddingAboveTop: CGFloat = 2
        currentLocationBottomConstraint?.constant = -(inset + paddingAboveTop)
    }
    
    func dockCurrentLocation(toSheetTop topAnchor: NSLayoutYAxisAnchor) {
        guard let locate = currentLocationControl else { return }
        currentLocationBottomConstraint?.isActive = false
        let c = locate.bottomAnchor.constraint(equalTo: topAnchor, constant: -8)
        c.isActive = true
        currentLocationBottomConstraint = c
        isDockedToSheetTop = true
    }
    
    func undockCurrentLocationToSafeArea() {
        guard let locate = currentLocationControl, let host = hostView else { return }
        currentLocationBottomConstraint?.isActive = false
        let c = locate.bottomAnchor.constraint(equalTo: host.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        c.isActive = true
        currentLocationBottomConstraint = c
        isDockedToSheetTop = false
    }
    
    func setHidden(_ hidden: Bool) {
        let apply = {
            [self.zoomControl, self.trafficControl, self.createRoadEventControl,
             self.compassControl, self.currentLocationControl, self.profileControl]
                .forEach { v in
                    v?.isHidden = hidden
                    v?.alpha = hidden ? 0.0 : 1.0
                    v?.isUserInteractionEnabled = !hidden
                }
        }
        if Thread.isMainThread {
            UIView.performWithoutAnimation(apply)
        } else {
            DispatchQueue.main.async { UIView.performWithoutAnimation(apply) }
        }
    }
}
