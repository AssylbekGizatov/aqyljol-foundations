import UIKit
import DGis

final class ZoomControlsManager {
    private var zoomControl: ZoomControl?

    func attach(
        to hostView: UIView,
        controlsFactory: any DGis.IMapControlFactory,
        bottomRight: CGPoint = CGPoint(x: 16, y: 16)
    ) {
        detach()
        let control: ZoomControl = controlsFactory.makeZoomControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(control)
        
        let guide = hostView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            control.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -bottomRight.x),
            control.centerYAnchor.constraint(equalTo: guide.centerYAnchor)
        ])
        
        zoomControl = control
    }

    func setHidden(_ hidden: Bool) { zoomControl?.isHidden = hidden }

    func detach() {
        zoomControl?.removeFromSuperview()
        zoomControl = nil
    }
}
