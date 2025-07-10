import Foundation
import SwiftUI

struct Product: Identifiable, Codable {
    let id: UUID
    let code: String
    let name: String
    let packaging: String
    let packagingTags: [String]
    let carbonFootprint: String
    let ecoScore: String?
    let ecoScoreGrade: String?
    let environmentalImpact: EnvironmentalImpact
    var geminiCarbonResult: String?
    
    init(code: String, name: String, packaging: String, packagingTags: [String], carbonFootprint: String, ecoScore: String? = nil, ecoScoreGrade: String? = nil, geminiCarbonResult: String? = nil) {
        self.id = UUID()
        self.code = code
        self.name = name
        self.packaging = packaging
        self.packagingTags = packagingTags
        self.carbonFootprint = carbonFootprint
        self.ecoScore = ecoScore
        self.ecoScoreGrade = ecoScoreGrade
        self.geminiCarbonResult = geminiCarbonResult
        
        // Calculate environmental impact
        let isRecyclable = packagingTags.contains("recyclable")
        let isBiodegradable = packagingTags.contains("biodegradable")
        
        let score = Product.calculateScore(
            isRecyclable: isRecyclable,
            isBiodegradable: isBiodegradable,
            packaging: packaging,
            ecoScoreGrade: ecoScoreGrade
        )
        
        self.environmentalImpact = EnvironmentalImpact(
            score: score,
            recyclable: isRecyclable,
            biodegradable: isBiodegradable,
            carbonFootprint: carbonFootprint,
            ecoScoreGrade: ecoScoreGrade
        )
    }
    
    private static func calculateScore(isRecyclable: Bool, isBiodegradable: Bool, packaging: String, ecoScoreGrade: String?) -> Double {
        var score = 5.0
        
        // Factor in eco grade if available
        if let ecoGrade = ecoScoreGrade?.lowercased() {
            switch ecoGrade {
            case "a": score += 3.0
            case "b": score += 2.0
            case "c": score += 1.0
            case "d": score -= 1.0
            case "e": score -= 2.0
            default: break
            }
        }
        
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
    let ecoScoreGrade: String?
    
    var impactLevel: ImpactLevel {
        switch score {
            case 0..<4: return .high
            case 4..<7: return .medium
            default: return .low
        }
    }
    
    var ecoGradeInfo: EcoGradeInfo {
        EcoGradeInfo(grade: ecoScoreGrade)
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

struct EcoGradeInfo {
    let grade: String?
    
    init(grade: String?) {
        self.grade = grade?.uppercased()
    }
    
    var displayGrade: String {
        guard let grade = grade else { return "N/A" }
        return grade
    }
    
    var color: Color {
        guard let grade = grade else { return .gray }
        switch grade {
        case "A": return .green
        case "B": return .mint
        case "C": return .yellow
        case "D": return .orange
        case "E": return .red
        default: return .gray
        }
    }
    
    var description: String {
        guard let grade = grade else { return "No eco score available" }
        switch grade {
        case "A": return "Excellent environmental impact"
        case "B": return "Good environmental impact"
        case "C": return "Average environmental impact"
        case "D": return "Poor environmental impact"
        case "E": return "Very poor environmental impact"
        default: return "Unknown eco score"
        }
    }
    
    var icon: String {
        guard let grade = grade else { return "questionmark.circle" }
        switch grade {
        case "A": return "leaf.fill"
        case "B": return "leaf"
        case "C": return "leaf"
        case "D": return "exclamationmark.triangle"
        case "E": return "exclamationmark.triangle.fill"
        default: return "questionmark.circle"
        }
    }
} 