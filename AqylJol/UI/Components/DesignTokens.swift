import UIKit

enum DesignTokens {
    // Neon blues
    static let neon = UIColor(displayP3Red: 0.22, green: 0.76, blue: 1.0, alpha: 1.0)
    static let neon2 = UIColor(displayP3Red: 0.12, green: 0.48, blue: 1.0, alpha: 1.0)
    static let neon3 = UIColor(displayP3Red: 0.06, green: 0.28, blue: 0.8, alpha: 1.0)
    // Surfaces
    static let glass = UIColor.white.withAlphaComponent(0.08)
    static let stroke = UIColor.white.withAlphaComponent(0.18)
    static let labelDim = UIColor.white.withAlphaComponent(0.8)
    static let labelFaint = UIColor.white.withAlphaComponent(0.6)
    
    // Metrics
    static let cornerXL: CGFloat = 20
    static let cornerPill: CGFloat = 14
    static let dockInset: CGFloat = 12

    // Shadows
    static let auraShadow: (color: UIColor, radius: CGFloat, opacity: Float, y: CGFloat) =
        (UIColor.systemBlue.withAlphaComponent(0.7), 16, 0.45, 3)

    static let softShadow: (color: UIColor, radius: CGFloat, opacity: Float, y: CGFloat) =
        (UIColor.black.withAlphaComponent(0.6), 28, 0.35, 10)

    // Haptics
    static func hapticTap() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
