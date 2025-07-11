import Foundation

struct ProductInfo: Identifiable, Hashable, Equatable {
    let id = UUID()
    let barcode: String
    var nutrition: NutritionFacts?
    var carbon: CarbonResponse?
    var allergens: [String]?
    var ingredients: String?
    var ecoScoreGrade: String?
    var productImageUrl: String?
    var quantity: String?
    var packaging: String?
    var packagingTags: [String]?

    static func == (lhs: ProductInfo, rhs: ProductInfo) -> Bool {
        lhs.id == rhs.id && lhs.barcode == rhs.barcode
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(barcode)
    }
}

struct NutritionFacts: Decodable {
    let item_name: String
    let nf_calories: Double
    let nf_total_fat: Double
    let nf_protein: Double
    let nf_total_carbohydrate: Double
    let nf_sugars: Double
}

struct CarbonResponse: Decodable {
    let co2e: Double
    let co2e_breakdown: [Breakdown]
}

struct Breakdown: Decodable {
    let scope: String   // e.g. "production", "transport"
    let co2e: Double    // kg CO2e
}
