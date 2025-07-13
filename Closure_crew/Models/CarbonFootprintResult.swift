import Foundation

struct CarbonFootprintResult: Codable {
    let totalKgCO2e: Double
    let breakdown: Breakdown
    let ecoFriendlyLabel: String

    struct Breakdown: Codable {
        let productionPercent: Double
        let packagingPercent: Double
        let transportPercent: Double
    }
} 