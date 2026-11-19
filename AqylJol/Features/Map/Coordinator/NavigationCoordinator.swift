import UIKit
import DGis

final class NavigationCoordinator {
    // MARK: - Deps
    private let container: Container
    private let map: Map
    private weak var hostView: UIView?

    // MARK: - Navigation
    private(set) var navigationManager: NavigationManager?
    private var navigationView: (UIView & INavigationView)?
    private var stateCancellable: DGis.Cancellable?

    // MARK: - Location source
    private var myLocationSource: MyLocationMapObjectSource?
    
    var onFinishTrip: (() -> Void)?

    init(container: Container, map: Map, hostView: UIView) {
        self.container = container
        self.map = map
        self.hostView = hostView
    }
    
    func attach() {
        guard navigationManager == nil, let hostView else { return }

        guard let ctx = try? container.context else {
            print("❌ DGis.Context unavailable"); return
        }
        
        guard let navManager = try? NavigationManager(platformContext: ctx) else {
            print("❌ NavigationManager init failed"); return
        }
        self.navigationManager = navManager
        
        navManager.mapManager.addMap(map: map)
        
        if myLocationSource == nil, let src = try? MyLocationMapObjectSource(context: ctx) {
            map.addSource(source: src)
            self.myLocationSource = src
        }

        // Navigation UI (composite)
        guard let navFactory = try? container.makeNavigationViewFactory() else {
            print("❌ makeNavigationViewFactory failed"); return
        }
        let navView = navFactory.makeNavigationView(map: map, navigationManager: navManager)
        navView.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(navView)
        NSLayoutConstraint.activate([
            navView.leftAnchor.constraint(equalTo: hostView.leftAnchor),
            navView.rightAnchor.constraint(equalTo: hostView.rightAnchor),
            navView.topAnchor.constraint(equalTo: hostView.topAnchor),
            navView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])
        self.navigationView = navView
        
        navView.finishButtonCallback = { [weak self] in
            guard let self else { return }
            self.navigationManager?.stop()
            self.onFinishTrip?()
        }
        
        stateCancellable = navManager.uiModel.stateChannel.sink(
            receiveValue: { [weak self] state in
                guard let self else { return }
                if case .finished = state {
                    DispatchQueue.main.async {
                        self.navigationManager?.stop()
                        self.onFinishTrip?()
                    }
                }
            }
        )
    }

    // MARK: - Modes
    func startFreeRoam() throws {
        try navigationManager?.start()
    }
    
    // MARK: - Starts real navigation
    func start(route: TrafficRoute, options: RouteBuildOptions) throws {
        guard let nav = navigationManager else { return }
        try nav.start(routeBuildOptions: options, trafficRoute: route)
    }
    
    // MARK: - Simulation (m/s)
    func startSimulation(route: TrafficRoute,
                         options: RouteBuildOptions,
                         speedMetersPerSec: Double? = nil) throws {
        guard let nav = navigationManager else { return }

        if let v = speedMetersPerSec {
            nav.simulationSettings.speedMode = .speed(SimulationConstantSpeed(speed: max(0, v)))
        }
        try nav.startSimulation(routeBuildOptions: options, trafficRoute: route)
    }
    
    // MARK: - Simulation (km/h)
    func startSimulation(route: TrafficRoute,
                         options: RouteBuildOptions,
                         speedKmPerHour: Double) throws {
        try startSimulation(route: route, options: options, speedMetersPerSec: max(0, speedKmPerHour / 3.6))
    }

    func stop() {
        navigationManager?.stop()
        stateCancellable?.cancel()
        stateCancellable = nil
    }
}
