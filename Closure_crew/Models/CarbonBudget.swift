import Foundation
import SwiftUI

struct CarbonBudget: Codable, Identifiable {
    let id: UUID
    let period: BudgetPeriod
    let targetAmount: Double // in kg CO2
    let startDate: Date
    let endDate: Date
    var currentAmount: Double
    var isActive: Bool
    
    init(period: BudgetPeriod, targetAmount: Double, startDate: Date = Date()) {
        self.id = UUID()
        self.period = period
        self.targetAmount = targetAmount
        self.startDate = startDate
        self.endDate = period.calculateEndDate(from: startDate)
        self.currentAmount = 0.0
        self.isActive = true
    }
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var remainingAmount: Double {
        max(0, targetAmount - currentAmount)
    }
    
    var isOverBudget: Bool {
        currentAmount > targetAmount
    }
    
    var progressColor: Color {
        switch progress {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        case 0.8..<1.0: return .red
        default: return .red
        }
    }
    
    var statusMessage: String {
        if isOverBudget {
            return "Over budget by \(String(format: "%.1f", currentAmount - targetAmount)) kg CO2"
        } else if progress >= 0.8 {
            return "Approaching budget limit"
        } else {
            return "On track"
        }
    }
}

enum BudgetPeriod: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var icon: String {
        switch self {
        case .daily: return "calendar.day.timeline.left"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
    
    var description: String {
        switch self {
        case .daily: return "Track your daily carbon footprint"
        case .weekly: return "Set weekly carbon budget goals"
        case .monthly: return "Monthly carbon budget planning"
        }
    }
    
    var defaultBudget: Double {
        switch self {
        case .daily: return 12.0 // kg CO2 per day (global average)
        case .weekly: return 84.0 // 7 days * 12 kg
        case .monthly: return 360.0 // 30 days * 12 kg
        }
    }
    
    func calculateEndDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        }
    }
    
    func isDateInPeriod(_ date: Date, startDate: Date) -> Bool {
        let endDate = calculateEndDate(from: startDate)
        return date >= startDate && date < endDate
    }
}

struct BudgetInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: String?
    
    static func generateInsights(for budget: CarbonBudget, recentProducts: [Product]) -> [BudgetInsight] {
        var insights: [BudgetInsight] = []
        
        // Budget status insight
        if budget.isOverBudget {
            insights.append(BudgetInsight(
                title: "Over Budget",
                description: "You've exceeded your \(budget.period.rawValue.lowercased()) carbon budget by \(String(format: "%.1f", budget.currentAmount - budget.targetAmount)) kg CO2",
                icon: "exclamationmark.triangle.fill",
                color: .red,
                action: "Review your choices"
            ))
        } else if budget.progress >= 0.8 {
            insights.append(BudgetInsight(
                title: "Budget Alert",
                description: "You're approaching your \(budget.period.rawValue.lowercased()) limit. \(String(format: "%.1f", budget.remainingAmount)) kg CO2 remaining",
                icon: "exclamationmark.circle.fill",
                color: .orange,
                action: "Choose wisely"
            ))
        } else {
            insights.append(BudgetInsight(
                title: "On Track",
                description: "Great job! You're within your \(budget.period.rawValue.lowercased()) carbon budget",
                icon: "checkmark.circle.fill",
                color: .green,
                action: nil
            ))
        }
        
        // Product recommendations
        if let worstProduct = recentProducts.max(by: { 
            Double($0.carbonFootprint.replacingOccurrences(of: "kg CO2", with: "")) ?? 0 < 
            Double($1.carbonFootprint.replacingOccurrences(of: "kg CO2", with: "")) ?? 0 
        }) {
            let footprint = Double(worstProduct.carbonFootprint.replacingOccurrences(of: "kg CO2", with: "")) ?? 0
            insights.append(BudgetInsight(
                title: "Highest Impact Product",
                description: "\(worstProduct.name) contributed \(String(format: "%.1f", footprint)) kg CO2 to your footprint",
                icon: "arrow.up.circle.fill",
                color: .red,
                action: "Find alternatives"
            ))
        }
        
        return insights
    }
} 