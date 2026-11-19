import UIKit

final class VoiceSheetCoordinator {
    private weak var host: UIViewController?

    init(host: UIViewController) {
        self.host = host
    }
    
    func presentVoiceCapture(completion: @escaping (String) -> Void) {
        guard let host else { return }
        let sheet = BottomSheetViewController()
        sheet.lowHeight   = 80
        sheet.mediumRatio = 0.25
        sheet.highRatio   = 0.60

        let vc = VoiceListeningViewController()
        vc.onFinish = { [weak sheet] text in
            sheet?.setDetent(.low, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                guard let s = sheet else { return }
                s.willMove(toParent: nil)
                s.view.removeFromSuperview()
                s.removeFromParent()
                completion(text)
            }
        }

        sheet.setContent(vc)
        sheet.present(over: host)
        sheet.setDetent(.medium, animated: true)
    }
}
