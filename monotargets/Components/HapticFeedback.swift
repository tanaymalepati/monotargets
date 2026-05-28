import UIKit

enum Haptic {
    // Calling prepare() right before impactOccurred() warms up the haptic engine
    // so the vibration fires immediately and reliably on-device.
    static func light() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }
    static func medium() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }
    static func heavy() {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        g.impactOccurred()
    }
    static func soft() {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.prepare()
        g.impactOccurred()
    }
    static func rigid() {
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.prepare()
        g.impactOccurred()
    }
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }
    static func error() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.error)
    }
    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }
    static func select() {
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }
}
