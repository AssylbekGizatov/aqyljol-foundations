import UIKit
import DGis
import CoreLocation

final class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: - Deps
    private let viewModel: MapViewModel
    
    // MARK: - Map
    private var mapView: (UIView & IMapView)!
    private var map: Map!
    private var mapControlFactory: (any IMapControlFactory)?
    private var roadEventFactory: (any IRoadEventCardViewFactory)?
    
    private var objectManager: MapObjectManager!
    
    // MARK: - UI helpers
    private lazy var searchService = SearchService { SDK.container }
    private let controlsManager = MapControlsManager()
    private let roadEventUI = RoadEventUIManager()
    var sheetCoordinator: MapFlowCoordinator!
    
    // MARK: - State
    var lastUserLocation: CLLocation?
    
    // MARK: - Map gestures
    private var tapGR: UITapGestureRecognizer!
    private var panGR: UIPanGestureRecognizer!
    private var pinchGR: UIPinchGestureRecognizer!
    
    private var navCoordinator: NavigationCoordinator?
    
    // MARK: - Init
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(viewModel:)") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupMap()
        
        if let container = SDK.container {
            let nav = NavigationCoordinator(container: container, map: map, hostView: view)
            nav.attach()
            nav.onFinishTrip = { [weak self] in
                self?.sheetCoordinator.finishRouting()
            }
            self.navCoordinator = nav
        }
        
        addMyLocationLayer()
        setupMapGestures()
        
        if let factory = mapControlFactory { controlsManager.attachAll(to: view, factory: factory) }
        controlsManager.onCreateRoadEventTapped = { [weak self] in
            guard let self, let rf = self.roadEventFactory else { return }
            self.roadEventUI.presentCreateView(on: self.view, map: self.map, factory: rf)
        }
        
        sheetCoordinator = MapFlowCoordinator(
            host: self,
            map: map,
            controls: controlsManager,
            openChats: { [weak self] in self?.openChatsFullScreen() },
            searchService: searchService
        )
        
        sheetCoordinator.start()
        bindViewModel()
        viewModel.requestWhenInUse()
        viewModel.startUpdating()
    }
    
    // MARK: - Map setup
    private func setupMap() {
        guard let container = SDK.container else { fatalError("2GIS not initialized") }
        var options = MapOptions.default
        options.appearance = .automatic(light: "day", dark: "night")
        do {
            let factory = try container.makeMapFactory(options: options)
            mapView = factory.mapView
            map     = factory.map
            mapControlFactory = factory.mapControlFactory
            roadEventFactory  = try? container.makeRoadEventCardViewFactory(options: .default)
        } catch {
            assertionFailure("Map init error: \(error)")
            return
        }
        
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        self.objectManager = MapObjectManager(map: map)
        renderFakeExcludedAreas()
    }
    
    private func addMyLocationLayer() {
        do {
            let src = try MyLocationMapObjectSource(context: SDK.container.context)
            map.addSource(source: src)
        } catch {
            print("❌ MyLocationMapObjectSource error: \(error.localizedDescription)")
        }
    }
    
    private func moveCamera(to point: GeoPoint, zoom: Float, animate: Bool = true) {
        let pos = CameraPosition( point: point, zoom: Zoom(value: zoom), tilt: Tilt(value: 0), bearing: Bearing(value: 0)
        )
        _ = map.camera.move(
            position: pos,
            time: animate ? 0.3 : 0.0,
            animationType: animate ? .linear : .default
        )
    }
    
    func startNavigation(with route: TrafficRoute, options: RouteBuildOptions) {
        do { try navCoordinator?.start(route: route, options: options) }
        catch { print("❌ Navigation start failed:", error) }
    }
    func startNavigationFreeRoam() {
        do { try navCoordinator?.startFreeRoam() }
        catch { print("❌ Navigation start freemroam failed:", error)}
    }
    
    func stopNavigation()          { navCoordinator?.stop() }
    func enterNavigationUI() {
        tapGR.isEnabled   = false
        panGR.isEnabled   = false
        pinchGR.isEnabled = false
        sheetCoordinator.enterNavigationUI()
    }

    func exitNavigationUI() {
        sheetCoordinator.exitNavigationUI()
        tapGR.isEnabled   = true
        panGR.isEnabled   = true
        pinchGR.isEnabled = true
    }
    
    // MARK: - ViewModel binding
    private func bindViewModel() {
        viewModel.onAuthorizationChanged = { status in
            if status == .denied || status == .restricted { print("⚠️ Location permission denied") }
        }

        viewModel.onStateChanged = { [weak self] state in
            guard let self else { return }
            self.lastUserLocation = state.lastUserLocation
            if [.medium, .high].contains(self.sheetCoordinator.currentDetent) {
                self.sheetCoordinator.setMapPaddingIfNeeded(bottom: self.sheetCoordinator.currentBottomInset)
            }
        }
        
        viewModel.onCameraCommand = { [weak self] cmd in
            guard let self else { return }
            switch cmd {
            case .none: break
            case .moveTo(let coord, let zoom):
                let gp = GeoPoint(latitude: coord.latitude, longitude: coord.longitude)
                self.moveCamera(to: gp, zoom: zoom)
            case .moveToUser(let zoom):
                if let coord = self.lastUserLocation?.coordinate {
                    let gp = GeoPoint(latitude: coord.latitude, longitude: coord.longitude)
                    self.moveCamera(to: gp, zoom: zoom)
                }
            }
        }
    }
    
    // MARK: - Chats
    @objc private func dismissChats() {
        dismiss(animated: false)
    }
    
    private func openChatsFullScreen() {
        let vc = ChatViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @objc private func dismissProfileTab() {
        dismiss(animated: false)
    }
    func openProfile() {
        let vc = ProfileTabViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    private func setupMapGestures() {
        tapGR = UITapGestureRecognizer(target: self, action: #selector(onMapTapped(_:)))
        tapGR.cancelsTouchesInView = false
        tapGR.delegate = self
        mapView.addGestureRecognizer(tapGR)
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(onMapPanned(_:)))
        panGR.cancelsTouchesInView = false
        panGR.delegate = self
        mapView.addGestureRecognizer(panGR)
        
        pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(onMapPinched(_:)))
        pinchGR.cancelsTouchesInView = false
        pinchGR.delegate = self
        mapView.addGestureRecognizer(pinchGR)
    }
    
    @objc private func onMapPanned(_ gr: UIPanGestureRecognizer) {
        if gr.state == .began { sheetCoordinator.setDetent(.low, animated: true) }
    }
    @objc private func onMapPinched(_ gr: UIPinchGestureRecognizer) {
        if gr.state == .began { sheetCoordinator.setDetent(.low, animated: true) }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    
    @objc private func onMapTapped(_ gr: UITapGestureRecognizer) {
        if sheetCoordinator.currentDetent != .low {
            sheetCoordinator.setDetent(.low, animated: true)
            return
        }

        let loc   = gr.location(in: mapView)
        let scale = UIScreen.main.nativeScale
        let sp = ScreenPoint(x: Float(loc.x * scale), y: Float(loc.y * scale))
        sheetCoordinator.handleMapTap(at: sp)
    }
    
    private func renderFakeExcludedAreas() {
        objectManager.removeAll()
        
        let fillRed   = Color(argb: 0x66FF0000)
        let strokeRed = Color(argb: 0xFFFF0000)
        let lineRed   = Color(argb: 0xFFFF3333)

        for area in FAKE_EXCLUDED_AREAS {
            switch area.type {
            case .point:
                let radiusMeters = Double(area.extent.millimeters) / 1000.0
                let center = area.points.first!
                let circleOpt = CircleOptions(
                    position: center,
                    radius: Meter(value: Float(radiusMeters))
                )
                do {
                    let circle = try Circle(options: circleOpt)
                    circle.color = fillRed
                    circle.strokeWidth = LogicalPixel(value: 2)
                    circle.strokeColor = strokeRed
                    objectManager.addObject(item: circle)
                } catch {
                    print("❌ Circle create error:", error)
                }

            case .polyline:
                let plOpt = PolylineOptions(
                    points: area.points,
                    width: LogicalPixel(value: 4),
                    color: lineRed
                )
                do {
                    let polyline = try Polyline(options: plOpt)
                    objectManager.addObject(item: polyline)
                } catch {
                    print("❌ Polyline create error:", error)
                }

            case .polygon:
                let polyOpt = PolygonOptions(
                    contours: [area.points],
                    color: fillRed,
                    strokeWidth: LogicalPixel(value: 2)
                )
                do {
                    let polygon = try Polygon(options: polyOpt)
                    polygon.strokeColor = strokeRed
                    objectManager.addObject(item: polygon)
                } catch {
                    print("❌ Polygon create error:", error)
                }

            @unknown default:
                break
            }
        }
    }
}
