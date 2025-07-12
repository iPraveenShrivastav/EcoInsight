import SwiftUI

struct DashboardView: View {
    @ObservedObject var historyViewModel: HistoryViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Stats Overview Card
                    if !historyViewModel.scannedProducts.isEmpty {
                        QuickStatsCard(historyViewModel: historyViewModel)
                    }
                    
                    // Environmental Impact Summary Card
                    if !historyViewModel.scannedProducts.isEmpty {
                        EnvironmentalImpactCard(historyViewModel: historyViewModel)
                    }
                    
                    // Achievement & Progress Card
                    if !historyViewModel.scannedProducts.isEmpty {
                        AchievementCard(historyViewModel: historyViewModel)
                    }
                    
                    // Allergens Card
                    NavigationLink(destination: AllergensPreferencesView()) {
                        DashboardCard(
                            title: "Allergens",
                            subtitle: "Set your allergens and dietary restrictions",
                            systemImage: "exclamationmark.triangle.fill",
                            color: .green
                        ) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Tap to manage your allergens and filter preferences.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Manage your allergens")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                                .padding(.top, 5)
                            }
                        }
                    }
                    
                    // How App Works Card
                    DashboardCard(
                        title: "How EcoScan Works",
                        subtitle: "Scan products to track environmental impact",
                        systemImage: "questionmark.circle.fill",
                        color: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(text: "Scan product barcodes", icon: "barcode.viewfinder")
                            InfoRow(text: "View packaging details", icon: "shippingbox.fill")
                            InfoRow(text: "Track carbon footprint", icon: "leaf.fill")
                            InfoRow(text: "Make eco-friendly choices", icon: "heart.fill")
                        }
                    }
                    
                    // Smart Recommendations Card
                    SmartRecommendationsCard(historyViewModel: historyViewModel)
                    
                    // Eco Grade Legend Card
                    DashboardCard(
                        title: "Eco Grade Guide",
                        subtitle: "Understanding environmental impact",
                        systemImage: "leaf.fill",
                        color: .green
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            EcoGradeLegendRow(grade: "A", description: "Excellent environmental impact")
                            EcoGradeLegendRow(grade: "B", description: "Good environmental impact")
                            EcoGradeLegendRow(grade: "C", description: "Average environmental impact")
                            EcoGradeLegendRow(grade: "D", description: "Poor environmental impact")
                            EcoGradeLegendRow(grade: "E", description: "Very poor environmental impact")
                        }
                    }
                    
                    // Tips Card
                    DashboardCard(
                        title: "Eco-Friendly Tips",
                        subtitle: "Small changes, big impact",
                        systemImage: "lightbulb.fill",
                        color: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(text: "Choose recyclable packaging", icon: "arrow.3.trianglepath")
                            InfoRow(text: "Avoid single-use plastics", icon: "xmark.circle")
                            InfoRow(text: "Opt for biodegradable materials", icon: "leaf")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("EcoScan")
        }
    }
}

// MARK: - Quick Stats Card
struct QuickStatsCard: View {
    let historyViewModel: HistoryViewModel
    
    var averageEcoGrade: String {
        let grades = historyViewModel.scannedProducts.compactMap { $0.ecoScoreGrade }
        guard !grades.isEmpty else { return "N/A" }
        
        let gradeValues = grades.map { grade -> Int in
            switch grade {
            case "A": return 5
            case "B": return 4
            case "C": return 3
            case "D": return 2
            case "E": return 1
            default: return 3
            }
        }
        
        let average = Double(gradeValues.reduce(0, +)) / Double(gradeValues.count)
        switch average {
        case 4.5...: return "A"
        case 3.5..<4.5: return "B"
        case 2.5..<3.5: return "C"
        case 1.5..<2.5: return "D"
        default: return "E"
        }
    }
    
    var totalCarbonFootprint: Double {
        historyViewModel.scannedProducts.compactMap { parseCO2Value($0.geminiCarbonResult ?? $0.carbonFootprint) }.reduce(0, +)
    }
    
    var body: some View {
        DashboardCard(
            title: "Your Eco Journey",
            subtitle: "Quick overview of your impact",
            systemImage: "chart.bar.fill",
            color: .blue
        ) {
            VStack(spacing: 15) {
                HStack(spacing: 20) {
                    StatItem(
                        title: "Products",
                        value: "\(historyViewModel.scannedProducts.count)",
                        icon: "barcode.viewfinder",
                        color: .blue
                    )
                    
                    StatItem(
                        title: "Avg Grade",
                        value: averageEcoGrade,
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    StatItem(
                        title: "CO₂ Total",
                        value: String(format: "%.1f", totalCarbonFootprint),
                        icon: "cloud.fill",
                        color: .orange
                    )
                }
                
                if historyViewModel.scannedProducts.count > 1 {
                    HStack {
                        Text("📈 You're making progress!")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func parseCO2Value(_ value: String?) -> Double? {
        guard let value = value else { return nil }
        let cleaned = value.replacingOccurrences(of: "kg CO₂e", with: "").replacingOccurrences(of: "kg CO2e", with: "").replacingOccurrences(of: "kg CO2", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
}

// MARK: - Environmental Impact Card
struct EnvironmentalImpactCard: View {
    let historyViewModel: HistoryViewModel
    
    var totalCarbonFootprint: Double {
        historyViewModel.scannedProducts.compactMap { parseCO2Value($0.geminiCarbonResult ?? $0.carbonFootprint) }.reduce(0, +)
    }
    
    var treesEquivalent: Int {
        // 1 tree absorbs about 22kg CO2 per year
        return max(1, Int(totalCarbonFootprint / 22.0))
    }
    
    var plasticBottlesEquivalent: Int {
        // 1 plastic bottle = ~0.1kg CO2
        return max(1, Int(totalCarbonFootprint / 0.1))
    }
    
    var body: some View {
        DashboardCard(
            title: "Environmental Impact",
            subtitle: "Your contribution to the planet",
            systemImage: "globe.americas.fill",
            color: .green
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    ImpactItem(
                        icon: "tree.fill",
                        value: "\(treesEquivalent)",
                        label: "Trees needed",
                        color: .green
                    )
                    
                    ImpactItem(
                        icon: "drop.fill",
                        value: "\(plasticBottlesEquivalent)",
                        label: "Plastic bottles",
                        color: .blue
                    )
                }
                
                HStack {
                    Text("🌱 Every scan helps track your environmental footprint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
    
    private func parseCO2Value(_ value: String?) -> Double? {
        guard let value = value else { return nil }
        let cleaned = value.replacingOccurrences(of: "kg CO₂e", with: "").replacingOccurrences(of: "kg CO2e", with: "").replacingOccurrences(of: "kg CO2", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let historyViewModel: HistoryViewModel
    
    var scanStreak: Int {
        // Simple streak calculation - can be enhanced
        return min(historyViewModel.scannedProducts.count, 7)
    }
    
    var achievementLevel: String {
        let count = historyViewModel.scannedProducts.count
        switch count {
        case 0: return "Beginner"
        case 1...5: return "Eco Explorer"
        case 6...15: return "Green Guardian"
        case 16...30: return "Sustainability Champion"
        default: return "Environmental Hero"
        }
    }
    
    var body: some View {
        DashboardCard(
            title: "Achievements",
            subtitle: "Your eco-friendly milestones",
            systemImage: "trophy.fill",
            color: .orange
        ) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(achievementLevel)
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("\(historyViewModel.scannedProducts.count) products scanned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("🔥 \(scanStreak) day streak")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                    Text("Next: \(nextMilestone) products")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var nextMilestone: Int {
        let count = historyViewModel.scannedProducts.count
        switch count {
        case 0...5: return 10
        case 6...15: return 20
        case 16...30: return 50
        default: return count + 10
        }
    }
}

// MARK: - Smart Recommendations Card
struct SmartRecommendationsCard: View {
    let historyViewModel: HistoryViewModel
    
    var personalizedTip: String {
        let count = historyViewModel.scannedProducts.count
        if count == 0 {
            return "Start by scanning your next grocery item!"
        } else if count < 5 {
            return "Try scanning different product categories for better insights"
        } else {
            return "Great progress! Consider scanning household items next"
        }
    }
    
    var body: some View {
        DashboardCard(
            title: "Smart Recommendations",
            subtitle: "Personalized eco-tips for you",
            systemImage: "brain.head.profile",
            color: .purple
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(personalizedTip)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                if historyViewModel.scannedProducts.count > 0 {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Scan regularly to track your environmental progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ImpactItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let content: Content
    
    init(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(color)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            content
                .padding(.top, 5)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct InfoRow: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            Text(text)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

struct EcoGradeLegendRow: View {
    let grade: String
    let description: String
    
    var ecoGradeInfo: EcoGradeInfo {
        EcoGradeInfo(grade: grade)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(grade)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(ecoGradeInfo.color)
                .clipShape(Circle())
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
} 
