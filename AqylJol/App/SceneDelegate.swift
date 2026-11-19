import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }
        let win = UIWindow(windowScene: ws)
        
        if Auth.auth().currentUser != nil {
            win.rootViewController = MapViewController(viewModel: MapViewModel())
        } else {
            win.rootViewController = AuthRootViewController()
        }
        
        ThemeManager.shared.apply(to: win)
        win.makeKeyAndVisible()
        window = win
    }
}
