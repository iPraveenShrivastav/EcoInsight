import SwiftUI

struct EarthPollutionView: View {
    let carbonFootprint: Double
    
    // Constants for calculations
    private let averageDailyPersonalEmission = 12.0 // kg CO2 per day per person (global average)
    private let globalEmissions2025 = 40.0 // Gigatons CO2 expected in 2025
    private let treesNeededPerKgCO2 = 0.017 // Average number of trees needed to offset 1kg CO2 per year
    private let cigaretteCO2 = 0.014 // kg CO2 per cigarette
    
    private var impactColor: Color {
        let percentage = comparisonPercentage
        if percentage > 150 { return .red }
        if percentage > 100 { return .orange }
        return .green
    }
    
    private var alertIcon: String {
        let percentage = comparisonPercentage
        if percentage > 150 { return "exclamationmark.triangle.fill" }
        if percentage > 100 { return "exclamationmark.circle.fill" }
        return "checkmark.circle.fill"
    }
    
    private var actionItems: [String] {
        let percentage = comparisonPercentage
        if percentage > 150 {
            return [
                "Choose products with eco-friendly packaging",
                "Opt for locally produced items to reduce transport emissions",
                "Buy in bulk to reduce packaging waste",
                "Support brands with strong environmental commitments"
            ]
        } else if percentage > 100 {
            return [
                "Look for products with sustainable packaging",
                "Consider products with lower carbon footprints",
                "Choose reusable over disposable items"
            ]
        } else {
            return [
                "Continue making environmentally conscious choices",
                "Share your sustainable practices with others",
                "Stay informed about reducing carbon emissions"
            ]
        }
    }
    
    private var comparisonPercentage: Double {
        (carbonFootprint / averageDailyPersonalEmission) * 100
    }
    
    private func getComparisonWidth(total: CGFloat) -> CGFloat {
        let percentage = carbonFootprint / averageDailyPersonalEmission
        return min(total, total * CGFloat(percentage))
    }
    
    private var pollutionPercentage: CGFloat {
        let percentage = carbonFootprint / averageDailyPersonalEmission
        return max(0.1, min(1.0, percentage))
    }
    
    private var impactMessage: String {
        let percentage = comparisonPercentage
        if percentage > 150 {
            return "Your CO₂ emissions are \(String(format: "%.1f", percentage))% of the global daily average per person (12kg). This is significantly higher than typical. Immediate action is recommended to reduce your environmental impact."
        } else if percentage > 100 {
            return "Your CO₂ emissions are \(String(format: "%.1f", percentage))% of the global daily average per person. Consider making changes to reduce your carbon footprint."
        } else if percentage > 50 {
            return "You're below the global daily average at \(String(format: "%.1f", percentage))% of typical personal emissions, but there's always room for improvement!"
        } else {
            return "Excellent! Your CO₂ emissions are only \(String(format: "%.1f", percentage))% of the global daily average per person. Keep up the great work!"
        }
    }
    
    private var savedTrees: Int {
        if comparisonPercentage <= 100 {
            let carbonSaved = averageDailyPersonalEmission - carbonFootprint
            return max(1, Int(carbonSaved * treesNeededPerKgCO2))
        }
        return 0
    }
    
    private var carbonSaved: Double {
        if comparisonPercentage <= 100 {
            return averageDailyPersonalEmission - carbonFootprint
        }
        return 0
    }
    
    private var cigaretteEquivalent: String {
        if comparisonPercentage > 100 {
            let extraEmissions = carbonFootprint - averageDailyPersonalEmission
            let cigarettes = Int(extraEmissions / cigaretteCO2)
            return "\(cigarettes)"
        }
        return "0"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Earth Visualization Card
                CardView {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 250, height: 250)
                                .background(.ultraThinMaterial.opacity(0.3)) // UI only - no logic change: Material effect for earth visualization
                            
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 250, height: 250)
                                .mask(
                                    Rectangle()
                                        .frame(height: 250 * pollutionPercentage)
                                        .offset(y: 125 * (2 - pollutionPercentage))
                                )
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: UUID()) // UI only - no logic change: Animation for pollution visualization
                            
                            Image(systemName: "globe.americas.fill")
                                .resizable()
                                .foregroundColor(.green.opacity(0.8))
                                .frame(width: 250, height: 250)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4) // UI only - no logic change: Shadow effect for earth icon
                        }
                        
                        StatisticView(
                            title: "Your Total Contribution",
                            value: String(format: "%.2f", carbonFootprint),
                            unit: "kg CO2",
                            color: impactColor
                        )
                    }
                }
                
                // Global Context Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        CardTitle(title: "Global Context", icon: "globe.americas.fill")
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Projected Global CO₂ Emissions in 2025:")
                                .font(.subheadline)
                            Text("\(globalEmissions2025, specifier: "%.1f") Gigatons")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .fontWeight(.bold)
                            
                            Divider()
                            
                            Text("That's equivalent to:")
                                .font(.subheadline)
                            
                            HStack {
                                Image(systemName: "car.fill")
                                Text("8.7 billion cars driven for one year")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Impact Comparison Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        CardTitle(title: "Your Impact", icon: "chart.line.uptrend.xyaxis.circle.fill")
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Compared to Global Daily Average")
                                .font(.subheadline)
                            
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(impactColor)
                                    .frame(width: getComparisonWidth(total: 300), height: 25)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 300 - getComparisonWidth(total: 300), height: 25)
                            }
                            .cornerRadius(8)
                            
                            HStack {
                                Text("Your Contribution")
                                    .foregroundColor(impactColor)
                                Spacer()
                                Text("Daily Average (12kg CO₂)")
                                    .foregroundColor(.gray)
                            }
                            .font(.caption)
                        }
                    }
                }
                
                // Impact Alert Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        if comparisonPercentage <= 100 {
                            CardTitle(title: "Impact Alert", icon: "leaf.circle.fill", iconColor: .green)
                        } else {
                            CardTitle(title: "Impact Alert", icon: "exclamationmark.shield.fill", iconColor: .orange)
                        }
                        
                        Text(impactMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if comparisonPercentage <= 100 {
                                ImpactInfoRow(
                                    icon: "leaf.fill",
                                    color: .green,
                                    title: "Trees Saved",
                                    value: "\(savedTrees) trees! 🌳",
                                    description: "Removing \(String(format: "%.1f", carbonSaved)) kg of CO₂"
                                )
                            } else {
                                ImpactInfoRow(
                                    icon: "smoke.fill",
                                    color: .orange,
                                    title: "Excess Impact",
                                    value: " \(cigaretteEquivalent) cigarettes! 🚬",
                                    description: "Your emissions equal burning this many cigarettes"
                                )
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recommended Actions:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(actionItems, id: \.self) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(item)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Environmental Impact")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar) // UI only - no logic change: Glass toolbar background
        .background(Color(.systemBackground).ignoresSafeArea())
        .background(.ultraThinMaterial.opacity(0.1)) // UI only - no logic change: Subtle material tint for environmental impact view
    }
}

// Helper Views
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .shadow(radius: 3, x: 0, y: 2)
            .background(.ultraThinMaterial.opacity(0.3)) // UI only - no logic change: Material tint for environmental cards
    }
}

struct CardTitle: View {
    let title: String
    let icon: String
    var iconColor: Color = .black
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.headline)
        }
        .foregroundColor(.primary)
    }
}

struct ImpactInfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(value)
                    .foregroundColor(color)
                    .fontWeight(.medium)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.headline)
                    .foregroundColor(color.opacity(0.8))
            }
        }
    }
}
