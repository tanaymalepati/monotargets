import Foundation

// MARK: - Custom Transaction Category

struct CustomCategory: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var icon: String   // SF Symbol name
    var isIncome: Bool // true = income category, false = expense

    init(id: UUID = UUID(), name: String, icon: String, isIncome: Bool) {
        self.id       = id
        self.name     = name
        self.icon     = icon
        self.isIncome = isIncome
    }
}

// MARK: - Suggested SF Symbols for custom categories

extension CustomCategory {
    /// A curated set of ~30 SF Symbols suitable for transaction categories
    static let suggestedIcons: [String] = [
        "star.fill",
        "heart.fill",
        "house.fill",
        "car.fill",
        "bicycle",
        "bus.fill",
        "tram.fill",
        "airplane",
        "gift.fill",
        "cart.fill",
        "bag.fill",
        "creditcard.fill",
        "fork.knife",
        "cup.and.saucer.fill",
        "pills.fill",
        "dumbbell.fill",
        "sportscourt.fill",
        "book.fill",
        "music.note",
        "film.fill",
        "gamecontroller.fill",
        "paintpalette.fill",
        "camera.fill",
        "phone.fill",
        "wifi",
        "bolt.fill",
        "drop.fill",
        "leaf.fill",
        "pawprint.fill",
        "wrench.and.screwdriver.fill",
        "hammer.fill",
        "scissors",
        "graduationcap.fill",
        "stethoscope",
        "dollarsign.circle.fill"
    ]
}
