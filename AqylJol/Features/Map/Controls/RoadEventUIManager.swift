import UIKit
import DGis

final class RoadEventUIManager {
    private weak var hostView: UIView?
    private var createView: (UIView & ICreateRoadEventView)?
    private var cardView: (UIView & IRoadEventCardView)?

    private var roadEventFactory: (any IRoadEventCardViewFactory)?
    private var map: Map?

    init() {}

    func presentCreateView(on hostView: UIView,
                           map: Map,
                           factory: any IRoadEventCardViewFactory) {
        self.hostView = hostView
        self.map = map
        self.roadEventFactory = factory

        if createView == nil {
            let v = factory.makeCreateRoadEventView(map: map) as (UIView & ICreateRoadEventView)
            v.translatesAutoresizingMaskIntoConstraints = false
            self.createView = v
        }
        guard let v = createView, v.superview == nil else { return }

        hostView.addSubview(v)
        let guide = hostView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
        
        wireButtons(in: v)
        
        v.alpha = 0
        UIView.animate(withDuration: 0.2) { v.alpha = 1 }
    }

    private func wireButtons(in root: UIView) {
        func attach(to button: UIButton?) {
            guard let btn = button else { return }
            // Уберём старые таргеты, чтобы не дублировать
            btn.removeTarget(self, action: #selector(_onCancelTapped), for: .touchUpInside)
            btn.addTarget(self, action: #selector(_onCancelTapped), for: .touchUpInside)
        }

        // Ищем локализованные заголовки
        let cancelTitles = ["Отмена", "Cancel"]
        // рекурсивный поиск UIButton с нужным заголовком
        func findButton(in view: UIView, withTitles titles: [String]) -> UIButton? {
            if let b = view as? UIButton, let t = b.title(for: .normal), titles.contains(t) {
                return b
            }
            for sub in view.subviews {
                if let found = findButton(in: sub, withTitles: titles) { return found }
            }
            return nil
        }

        attach(to: findButton(in: root, withTitles: cancelTitles))
    }

    @objc private func _onCancelTapped() {
        dismissCreateView()
    }
    
    func dismissCreateView() {
        guard let v = createView else { return }
        UIView.animate(withDuration: 0.2, animations: { v.alpha = 0 }) { _ in
            v.removeFromSuperview()
        }
    }
    
    func presentCard(for event: RoadEvent) {
        guard let hostView = hostView,
              let factory = roadEventFactory else { return }
        
        cardView?.removeFromSuperview()
        let card = factory.makeRoadEventCardView(event) as (UIView & IRoadEventCardView)
        card.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(card)

        let guide = hostView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
        
        card.closeButtonCallback = { [weak self] in
            self?.cardView?.removeFromSuperview()
            self?.cardView = nil
        }
        self.cardView = card
    }

    func detach() {
        createView?.removeFromSuperview(); createView = nil
        cardView?.removeFromSuperview();   cardView = nil
        hostView = nil; map = nil; roadEventFactory = nil
    }
}
