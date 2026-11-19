import UIKit
import DGis
import Firebase

enum SDK {
    static var container: Container!

    static func initializeDGis() {
        guard container == nil else { return }
        let key = KeySource.fromAsset(KeyFromAsset(path: "dgissdk.key"))
        let log = LogOptions(systemLevel: .info)
        container = Container(keySource: key, logOptions: log)
        print("✅ 2GIS SDK initialized")
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SDK.initializeDGis()
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
