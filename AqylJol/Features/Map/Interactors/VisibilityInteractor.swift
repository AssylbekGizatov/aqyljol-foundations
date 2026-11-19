import UIKit

final class VisibilityInteractor {
    private weak var hostView: UIView?
    private let sheet: BottomSheetViewController
    private let controls: MapControlsManager

    private var isLocateHidden = false
    private var isRoadHidden = false
    private var isTrafficHidden = false
    private var isProfileHidden = false
    private var isLockedByNavigation = false

    init(hostView: UIView?, sheet: BottomSheetViewController, controls: MapControlsManager) {
        self.hostView = hostView
        self.sheet = sheet
        self.controls = controls
    }

    func apply(sheetInset: CGFloat) {
        guard let view = hostView else { return }
        guard !isLockedByNavigation else { return }
        let sheetTopY = view.bounds.height - sheetInset
        let lowH = sheet.lowHeight

        func frame(_ v: UIView?) -> CGRect? {
            guard let v = v else { return nil }
            return v.convert(v.bounds, to: view)
        }
        func sheetNear(_ v: UIView?, pad: CGFloat) -> Bool {
            guard let f = frame(v) else { return false }
            return sheetTopY <= f.maxY + pad
        }
        func rectsNear(_ a: UIView?, _ b: UIView?, pad: CGFloat) -> Bool {
            guard let fa = frame(a), let fb = frame(b) else { return false }
            return fa.insetBy(dx: -pad, dy: -pad).intersects(fb.insetBy(dx: -pad, dy: -pad))
        }

        let hidePad: CGFloat = 8
        let showPad: CGFloat = 18
        
        let sheetNearRoad_hide = sheetNear(controls.createRoadEventControl, pad: hidePad)
        let sheetNearRoad_show = sheetNear(controls.createRoadEventControl, pad: showPad)

        let locNearRoad_hide = rectsNear(controls.currentLocationControl,
                                         controls.createRoadEventControl,
                                         pad: hidePad)
        let locNearRoad_show = rectsNear(controls.currentLocationControl,
                                         controls.createRoadEventControl,
                                         pad: showPad)

        let needHideLocate = sheetNearRoad_hide || locNearRoad_hide
        let canShowLocate  = !(sheetNearRoad_show || locNearRoad_show)

        if !isLocateHidden, needHideLocate {
            isLocateHidden = true
            controls.setCurrentLocationHidden(true)
        } else if isLocateHidden, canShowLocate {
            isLocateHidden = false
            controls.setCurrentLocationHidden(false)
        }
        
        let zoomVisible = sheetInset <= (lowH + 8)
        controls.setZoomHidden(!zoomVisible)
        
        let needHideRoad = sheetNear(controls.createRoadEventControl, pad: hidePad)
        let canShowRoad  = !sheetNear(controls.createRoadEventControl, pad: showPad)
        if !isRoadHidden, needHideRoad {
            isRoadHidden = true
            controls.createRoadEventControl?.isHidden = true
        } else if isRoadHidden, canShowRoad {
            isRoadHidden = false
            controls.createRoadEventControl?.isHidden = false
        }
        
        let needHideTraffic = sheetNear(controls.trafficControl, pad: hidePad)
        let canShowTraffic  = !sheetNear(controls.trafficControl, pad: showPad)
        if !isTrafficHidden, needHideTraffic {
            isTrafficHidden = true
            controls.trafficControl?.isHidden = true
        } else if isTrafficHidden, canShowTraffic {
            isTrafficHidden = false
            controls.trafficControl?.isHidden = false
        }
        
        let needHideProfile = sheetNear(controls.profileControl, pad: hidePad)
        let canShowProfile  = !sheetNear(controls.profileControl, pad: showPad)
        if !isProfileHidden, needHideProfile {
            isProfileHidden = true
            controls.setProfileHidden(true)
        } else if isProfileHidden, canShowProfile {
            isProfileHidden = false
            controls.setProfileHidden(false)
        }
    }
    
    func setNavigationLock(_ locked: Bool) {
        isLockedByNavigation = locked
        if locked {
            controls.setHidden(true)
        }
    }
}
