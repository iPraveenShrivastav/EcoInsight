import Foundation
import SwiftUI

struct Product: Identifiable, Codable {
    let id: UUID
    let code: String
    let name: String
    let packaging: String
    let packagingTags: [String]
    let carbonFootprint: String
    let environmentalImpact: EnvironmentalImpact
    
    init(code: String, name: String, packaging: String, packagingTags: [String], carbonFootprint: String) {
        self.id = UUID()
        self.code = code
        self.name = name
        self.packaging = packaging
        self.packagingTags = packagingTags
        self.carbonFootprint = carbonFootprint
        
        // Calculate environmental impact
        let isRecyclable = packagingTags.contains("recyclable")
        let isBiodegradable = packagingTags.contains("biodegradable")
        
        let score = Product.calculateScore(
            isRecyclable: isRecyclable,
            isBiodegradable: isBiodegradable,
            packaging: packaging
        )
        
        self.environmentalImpact = EnvironmentalImpact(
            score: score,
            recyclable: isRecyclable,
            biodegradable: isBiodegradable,
            carbonFootprint: carbonFootprint
        )
    }
    
    private static func calculateScore(isRecyclable: Bool, isBiodegradable: Bool, packaging: String) -> Double {
        var score = 5.0
        if isRecyclable { score += 2.5 }
        if isBiodegradable { score += 2.5 }
        if packaging.lowercased().contains("plastic") { score -= 1.0 }
        if packaging.lowercased().contains("paper") || 
           packaging.lowercased().contains("cardboard") { score += 1.0 }
        if packaging.lowercased().contains("aluminum") { score += 0.5 }
        if packaging.lowercased().contains("glass") { score += 1.5 }
        return min(max(score, 0), 10)
    }
}

struct EnvironmentalImpact: Codable {
    let score: Double
    let recyclable: Bool
    let biodegradable: Bool
    let carbonFootprint: String
    
    var impactLevel: ImpactLevel {
        switch score {
            case 0..<4: return .high
            case 4..<7: return .medium
            default: return .low
        }
    }
    
    enum ImpactLevel {
        case low
        case medium
        case high
        
        var color: Color {
            switch self {
                case .low: return .green
                case .medium: return .orange
                case .high: return .red
            }
        }
        
        var description: String {
            switch self {
                case .low: return "Low Environmental Impact"
                case .medium: return "Medium Environmental Impact"
                case .high: return "High Environmental Impact"
            }
        }
    }
} 