import SwiftUI

struct DashboardView: View {
    @ObservedObject var historyViewModel: HistoryViewModel
    @State private var showingEarthView = false
    @State private var showAllergensPreferences = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Allergens & Preferences Card/Button
                    Button(action: { showAllergensPreferences = true }) {
                        DashboardCard(
                            title: "Allergens & Preferences",
                            subtitle: "Set your allergens and sustainability preferences",
                            systemImage: "exclamationmark.triangle.fill",
                            color: .green
                        ) {
                            Text("Tap to manage your allergens and filter preferences.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                    
                    // Pollution Contribution Card
                    NavigationLink(destination: EarthPollutionView(carbonFootprint: totalCarbonFootprint)) {
                        DashboardCard(
                            title: "Your Contribution",
                            subtitle: "Based on scanned products",
                            systemImage: "chart.bar.xaxis.ascending",
                            color: .green
                        ) {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Total Carbon Footprint:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(String(format: "%.1f", totalCarbonFootprint)) kg CO2")
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Products Scanned:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(historyViewModel.scannedProducts.count)")
                                        .foregroundColor(.secondary)
                                }
                                
                                // Add tap indicator
                                HStack {
                                    Spacer()
                                    Label("Tap to see Earth Impact", systemImage: "arrow.right.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.top, 5)
                                }
                            }
                        }
                    }
                    
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
            .sheet(isPresented: $showAllergensPreferences) {
                AllergensPreferencesView()
            }
        }
    }
    
    private var totalCarbonFootprint: Double {
        historyViewModel.scannedProducts.reduce(0.0) { total, product in
            let footprint = Double(product.carbonFootprint.replacingOccurrences(of: "kg CO2", with: "")) ?? 0.0
            return total + footprint
        }
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
