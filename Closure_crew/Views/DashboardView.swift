import SwiftUI

struct DashboardView: View {
    @ObservedObject var historyViewModel: HistoryViewModel
    @AppStorage("selectedAllergens") private var selectedAllergensString: String = ""
    
    private var selectedAllergens: [String] {
        selectedAllergensString.isEmpty ? [] : selectedAllergensString.split(separator: ",").map { String($0) }
    }
    
    private var allergenStatus: (text: String, color: Color) {
        if selectedAllergens.isEmpty {
            return ("Not set", .red)
        } else if selectedAllergens.count == 1 {
            return ("1 allergen set", .green)
        } else {
            return ("\(selectedAllergens.count) allergens set", .green)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with greeting
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hi Nagar👋")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Here's how your choices are impacting the planet")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                    
                    // Main Stats Card
                    if !historyViewModel.scannedProducts.isEmpty {
                        MainStatsCard(historyViewModel: historyViewModel)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                    
                    // Recent Scans Section
                    if !historyViewModel.scannedProducts.isEmpty {
                        RecentScansSection(historyViewModel: historyViewModel)
                            .padding(.bottom, 30)
                    }
                    
                    // Eco Grade Guide Section
                    EcoGradeGuideSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    
                    // Eco-Friendly Tips Section
                    EcoTipsSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    
                    // Allergens Card
                    NavigationLink(destination: AllergensPreferencesView()) {
                        HStack(spacing: 16) {
                            // Icon section
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            
                            // Content section
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Allergens & Preferences")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Text("Get personalized food warnings")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Text(allergenStatus.text)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(allergenStatus.color)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// MARK: - Main Stats Card
struct MainStatsCard: View {
    let historyViewModel: HistoryViewModel
    
    var totalCarbonFootprint: Double {
        historyViewModel.scannedProducts.compactMap { parseCO2Value($0.geminiCarbonResult ?? $0.carbonFootprint) }.reduce(0, +)
    }
    
    var totalProductsScanned: Int {
        historyViewModel.scannedProducts.count
    }
    
    var progressPercentage: Double {
        min(Double(totalProductsScanned) / 25.0, 1.0) // Target of 25 products for 100%
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(format: "%.1f kg", totalCarbonFootprint))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("Total CO₂ Saved")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(totalProductsScanned) Products Scanned")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
    
    private func parseCO2Value(_ value: String?) -> Double? {
        guard let value = value else { return nil }
        let cleaned = value.replacingOccurrences(of: "kg CO₂e", with: "").replacingOccurrences(of: "kg CO2e", with: "").replacingOccurrences(of: "kg CO2", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
}

// MARK: - Recent Scans Section
struct RecentScansSection: View {
    let historyViewModel: HistoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Recent Scans")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(historyViewModel.scannedProducts.prefix(5).enumerated()), id: \.offset) { index, product in
                        RecentScanCard(product: product)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Recent Scan Card
struct RecentScanCard: View {
    let product: Product
    
    var ecoGradeColor: Color {
        switch product.ecoScoreGrade?.uppercased() {
        case "A": return .green
        case "B": return Color(red: 0.7, green: 0.8, blue: 0.2)
        case "C": return .orange
        case "D": return Color(red: 1.0, green: 0.6, blue: 0.2)
        case "E": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // Product Image Placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(width: 130, height: 90)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                )
            
            VStack(spacing: 6) {
                Text(String(product.name.prefix(20)))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(String(product.packaging.prefix(15)))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Eco Grade Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(ecoGradeColor)
                        .frame(width: 18, height: 18)
                    
                    Text(product.ecoScoreGrade ?? "N/A")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ecoGradeColor)
                }
                .padding(.top, 2)
            }
        }
        .frame(width: 130)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Eco Grade Guide Section
struct EcoGradeGuideSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Eco Grade Guide")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 16) {
                EcoGradeBadge(grade: "A", description: "Excellent", color: .green)
                EcoGradeBadge(grade: "B", description: "Good", color: Color(red: 0.7, green: 0.8, blue: 0.2))
                EcoGradeBadge(grade: "C", description: "Average", color: .orange)
                EcoGradeBadge(grade: "D", description: "Poor", color: Color(red: 1.0, green: 0.6, blue: 0.2))
                EcoGradeBadge(grade: "E", description: "Very Poor", color: .red)
            }
        }
    }
}

// MARK: - Eco Grade Badge
struct EcoGradeBadge: View {
    let grade: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(grade)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(description)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Eco Tips Section
struct EcoTipsSection: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var timer: Timer?
    private let cardWidth: CGFloat = 136 // 120 width + 16 spacing
    
    let tips = [
        ("arrow.3.trianglepath", "Choose Recyclable", Color.green),
        ("slash.circle", "Avoid Plastic", Color.blue),
        ("leaf.arrow.circlepath", "Buy Eco-Friendly", Color.mint),
        ("cart.badge.minus", "Reduce Packaging", Color.orange),
        ("location.fill", "Support Local", Color.purple)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Eco-Friendly Tips")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Auto-scrolling carousel with offset animation
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Triple the tips for infinite scroll effect
                    ForEach(0..<(tips.count * 3), id: \.self) { index in
                        let tipIndex = index % tips.count
                        let tip = tips[tipIndex]
                        
                        EcoTipCard(
                            icon: tip.0,
                            title: tip.1,
                            color: tip.2,
                            isHighlighted: false
                        )
                    }
                }
                .padding(.horizontal, 20)
                .offset(x: scrollOffset)
                .animation(.easeInOut(duration: 1.0), value: scrollOffset)
            }
            .clipped()
        }
        .onAppear {
            startAutoScroll()
        }
        .onDisappear {
            stopAutoScroll()
        }
    }
    
    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                scrollOffset -= cardWidth
                
                // Reset position when scrolled through one complete set
                let maxOffset = cardWidth * CGFloat(tips.count)
                if abs(scrollOffset) >= maxOffset {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                        scrollOffset = 0
                    }
                }
            }
        }
    }
    
    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Eco Tip Card
struct EcoTipCard: View {
    let icon: String
    let title: String
    let color: Color
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with circular background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 120, height: 115)
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}
