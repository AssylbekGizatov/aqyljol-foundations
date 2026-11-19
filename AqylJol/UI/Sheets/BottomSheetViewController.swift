import UIKit

private final class PassthroughView: UIView {
    weak var tappableArea: UIView?
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let area = tappableArea else { return false }
        let p = convert(point, to: area)
        return area.point(inside: p, with: event)
    }
}

final class BottomSheetViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: Detents
    enum Detent: Equatable { case low, medium, high }
    
    // MARK: Tunables
    var lowHeight: CGFloat = 120
    var mediumRatio: CGFloat = 0.5
    var highRatio: CGFloat = 0.96
    var cornerRadius: CGFloat = 16
    var grabberHeight: CGFloat = 4
    
    // MARK: Events
    var onDetentChanged: ((Detent) -> Void)?
    var onBottomInsetChanged: ((CGFloat) -> Void)?
    
    // MARK: Views / Layout
    private let dimView = UIView()
    private let container = UIView()
    private let grabber = UIView()
    private var topConstraint: NSLayoutConstraint!
    private var pan: UIPanGestureRecognizer!
    
    var dockingTopAnchor: NSLayoutYAxisAnchor { container.topAnchor }
    
    private(set) var currentDetent: Detent = .low {
        didSet { if oldValue != currentDetent { onDetentChanged?(currentDetent) } }
    }
    
    var currentBottomInset: CGFloat { max(0, -topConstraint.constant) }
    
    // MARK: View life cycle
    override func loadView() {
        let v = PassthroughView()
        v.isOpaque = false
        v.backgroundColor = .clear
        view = v
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: Public API
    func setContent(_ vc: UIViewController) {
        if let old = children.first {
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
        }
        addChild(vc)
        container.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor, constant: grabberHeight + 3),
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 3)
        ])
        vc.didMove(toParent: self)
    }
    
    func present(over parent: UIViewController) {
        parent.addChild(self)
        parent.view.addSubview(view)
        didMove(toParent: parent)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: parent.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor)
        ])
        
        parent.view.layoutIfNeeded()
        view.layoutIfNeeded()
        layoutFor(detent: .low, animated: false)
        
        dimView.alpha = 0
    }
    
    func setDetent(_ detent: Detent, animated: Bool) {
        layoutFor(detent: detent, animated: animated)
    }
    
    // MARK: Setup
    private func setupViews() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        dimView.isUserInteractionEnabled = false
        view.addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = cornerRadius
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 10
        container.layer.shadowOffset = .init(width: 0, height: -2)
        
        view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        topConstraint = container.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -lowHeight)
        NSLayoutConstraint.activate([
            topConstraint,
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        grabber.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.3)
        grabber.layer.cornerRadius = grabberHeight/2
        container.addSubview(grabber)
        grabber.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 40),
            grabber.heightAnchor.constraint(equalToConstant: grabberHeight)
        ])
        
        pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.delegate = self
        container.addGestureRecognizer(pan)
        
        (view as? PassthroughView)?.tappableArea = container
    }
    
    // MARK: Pan handling
    @objc private func onPan(_ g: UIPanGestureRecognizer) {
        let dy = g.translation(in: view).y
        switch g.state {
        case .changed:
            let highH = view.bounds.height * highRatio
            let next = topConstraint.constant + dy
            topConstraint.constant = max(min(next, 0), -highH)
            g.setTranslation(.zero, in: view)
            view.layoutIfNeeded()
            notifyBottomInset()
        case .ended, .cancelled, .failed:
            settleToNearestDetent(with: g.velocity(in: view).y)
        default: break
        }
    }
    
    private func settleToNearestDetent(with velocityY: CGFloat) {
        let height = -topConstraint.constant
        let lowH  = lowHeight
        let medH  = view.bounds.height * mediumRatio
        let highH = view.bounds.height * highRatio
        
        let targets: [(Detent, CGFloat)] = [(.low, lowH), (.medium, medH), (.high, highH)]
        let nearest = targets.min { abs($0.1 - height) < abs($1.1 - height) }?.0 ?? .low
        
        let detent: Detent
        if velocityY < -800 { detent = .high }
        else if velocityY > 800 { detent = .low }
        else { detent = nearest }
        
        layoutFor(detent: detent, animated: true)
    }
    
    // MARK: Layout to detent
    private func layoutFor(detent: Detent, animated: Bool) {
        let desiredHeight: CGFloat
        switch detent {
        case .low:    desiredHeight = lowHeight
        case .medium: desiredHeight = view.bounds.height * mediumRatio
        case .high:   desiredHeight = view.bounds.height * highRatio
        }
        
        currentDetent = detent
        topConstraint.constant = -desiredHeight
        
        let animations = {
            self.view.layoutIfNeeded()
            self.notifyBottomInset()
        }
        animated ? UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: animations, completion: nil)
                 : animations()
    }
    
    private func notifyBottomInset() {
        onBottomInsetChanged?(currentBottomInset)
    }
    
    // MARK: Gesture delegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
