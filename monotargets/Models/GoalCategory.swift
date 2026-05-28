import SwiftUI

// MARK: - Goal Category

enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case electronics  = "electronics"
    case automotive   = "automotive"
    case clothing     = "clothing"
    case travel       = "travel"
    case housing      = "housing"
    case education    = "education"
    case health       = "health"
    case entertainment = "entertainment"
    case sports       = "sports"
    case gaming       = "gaming"
    case foodDrink    = "foodDrink"
    case other        = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .electronics:   return "Electronics"
        case .automotive:    return "Automotive"
        case .clothing:      return "Clothing"
        case .travel:        return "Travel"
        case .housing:       return "Housing"
        case .education:     return "Education"
        case .health:        return "Health"
        case .entertainment: return "Entertainment"
        case .sports:        return "Sports"
        case .gaming:        return "Gaming"
        case .foodDrink:     return "Food & Drink"
        case .other:         return "Other"
        }
    }

    var icon: String {
        switch self {
        case .electronics:   return "laptopcomputer"
        case .automotive:    return "car.fill"
        case .clothing:      return "tshirt.fill"
        case .travel:        return "airplane"
        case .housing:       return "house.fill"
        case .education:     return "graduationcap.fill"
        case .health:        return "heart.fill"
        case .entertainment: return "tv.fill"
        case .sports:        return "sportscourt.fill"
        case .gaming:        return "gamecontroller.fill"
        case .foodDrink:     return "fork.knife"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .electronics:   return Color(red: 0.40, green: 0.65, blue: 1.00)
        case .automotive:    return Color(red: 0.85, green: 0.55, blue: 0.20)
        case .clothing:      return Color(red: 0.85, green: 0.42, blue: 0.70)
        case .travel:        return Color(red: 0.30, green: 0.82, blue: 0.70)
        case .housing:       return Color(red: 0.55, green: 0.75, blue: 0.35)
        case .education:     return Color(red: 0.95, green: 0.80, blue: 0.25)
        case .health:        return Color(red: 0.95, green: 0.35, blue: 0.40)
        case .entertainment: return Color(red: 0.70, green: 0.45, blue: 0.95)
        case .sports:        return Color(red: 0.30, green: 0.75, blue: 0.55)
        case .gaming:        return Color(red: 0.60, green: 0.40, blue: 0.95)
        case .foodDrink:     return Color(red: 0.95, green: 0.60, blue: 0.30)
        case .other:         return Color(red: 0.55, green: 0.55, blue: 0.65)
        }
    }
}
