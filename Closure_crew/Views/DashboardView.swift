import SwiftUI

struct DashboardView: View {
    @ObservedObject var historyViewModel: HistoryViewModel
    @AppStorage("selectedAllergens") private var selectedAllergensString: String = ""
    @State private var refreshTrigger = false
    
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with greeting
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hi Pro 👋")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Here's how your choices are impacting the planet")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            // Removed refresh button
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
                    RecentScansSection(historyViewModel: historyViewModel)
                        .padding(.bottom, 30)
                        .id(refreshTrigger)
                        .onAppear {
                            print("📱 DashboardView: RecentScansSection appeared with \(historyViewModel.scannedProducts.count) products")
                        }
                        .onChange(of: historyViewModel.scannedProducts.count) { count in
                            print("📱 DashboardView: Products count changed to \(count)")
                        }
                    
                    // Allergens Section Header
                    HStack {
                        Text("Set Your Allergens")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    // Allergens Card (moved from bottom)
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
                                    Text("Allergens")
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
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(radius: 3, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    
                    // Eco-Friendly Tips Section
                    EcoTipsSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .onAppear {
                print("📱 DashboardView: Main view appeared with \(historyViewModel.scannedProducts.count) products")
                // Force refresh when view appears
                refreshTrigger.toggle()
            }
            .onChange(of: historyViewModel.scannedProducts.count) { count in
                print("📱 DashboardView: Main view - Products count changed to \(count)")
                // Force refresh when products change
                refreshTrigger.toggle()
            }
            .onReceive(historyViewModel.$scannedProducts) { products in
                print("📱 DashboardView: Received products update - \(products.count) products")
            }
            .refreshable {
                print("📱 DashboardView: Pull to refresh triggered")
                // Force reload from storage
                historyViewModel.loadHistory()
            }
            .background(Color(.systemBackground))
        }
    }
}

// Add this helper at file scope (outside any struct)
func co2String(for product: Product) -> String {
    let value = parseCO2Value(product.geminiCarbonResult ?? product.carbonFootprint) ?? 0
    if value == 0 {
        return "0"
    } else {
        return String(format: "%.2f", value)
    }
}

func parseCO2Value(_ value: String?) -> Double? {
    guard let value = value, !value.isEmpty else { return nil }
    var cleaned = value
        .replacingOccurrences(of: "kg CO₂e", with: "")
        .replacingOccurrences(of: "kg CO2e", with: "")
        .replacingOccurrences(of: "kg CO₂", with: "")
        .replacingOccurrences(of: "kg CO2", with: "")
        .replacingOccurrences(of: "kg", with: "")
        .replacingOccurrences(of: "CO₂e", with: "")
        .replacingOccurrences(of: "CO2e", with: "")
        .replacingOccurrences(of: "CO₂", with: "")
        .replacingOccurrences(of: "CO2", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    cleaned = cleaned.replacingOccurrences(of: "(", with: "")
    cleaned = cleaned.replacingOccurrences(of: ")", with: "")
    cleaned = cleaned.replacingOccurrences(of: "[", with: "")
    cleaned = cleaned.replacingOccurrences(of: "]", with: "")
    if let doubleValue = Double(cleaned) {
        return doubleValue
    }
    let numbers = cleaned.components(separatedBy: CharacterSet.decimalDigits.inverted)
        .compactMap { Double($0) }
    return numbers.first
}

// MARK: - Main Stats Card
struct MainStatsCard: View {
    @ObservedObject var historyViewModel: HistoryViewModel
    
    var totalCarbonFootprint: Double {
        let products = historyViewModel.scannedProducts
        let total = products.compactMap { product -> Double? in
            let carbonValue = product.geminiCarbonResult ?? product.carbonFootprint
            let parsedValue = parseCO2Value(carbonValue)
            
            // Debug: Print the values to console
            print("Product: \(product.name)")
            print("  Carbon Value: '\(carbonValue)'")
            print("  Parsed Value: \(parsedValue ?? 0)")
            
            return parsedValue
        }.reduce(0, +)
        
        print("Total Carbon Footprint: \(total)")
        return total
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
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(radius: 3, x: 0, y: 2)
        )
    }
    
    private func parseCO2Value(_ value: String?) -> Double? {
        guard let value = value, !value.isEmpty else { return nil }
        
        // Remove common units and clean the string
        var cleaned = value
            .replacingOccurrences(of: "kg CO₂e", with: "")
            .replacingOccurrences(of: "kg CO2e", with: "")
            .replacingOccurrences(of: "kg CO₂", with: "")
            .replacingOccurrences(of: "kg CO2", with: "")
            .replacingOccurrences(of: "kg", with: "")
            .replacingOccurrences(of: "CO₂e", with: "")
            .replacingOccurrences(of: "CO2e", with: "")
            .replacingOccurrences(of: "CO₂", with: "")
            .replacingOccurrences(of: "CO2", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle cases where the value might be wrapped in parentheses or brackets
        cleaned = cleaned.replacingOccurrences(of: "(", with: "")
        cleaned = cleaned.replacingOccurrences(of: ")", with: "")
        cleaned = cleaned.replacingOccurrences(of: "[", with: "")
        cleaned = cleaned.replacingOccurrences(of: "]", with: "")
        
        // Try to parse the cleaned value
        if let doubleValue = Double(cleaned) {
            return doubleValue
        }
        
        // If direct parsing fails, try to extract numbers
        let numbers = cleaned.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Double($0) }
        
        return numbers.first
    }
}

// MARK: - Recent Scans Section
struct RecentScansSection: View {
    @ObservedObject var historyViewModel: HistoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent Scans")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if historyViewModel.scannedProducts.isEmpty {
                EmptyRecentScansView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(historyViewModel.scannedProducts.prefix(3).enumerated()), id: \.element.id) { index, product in
                            RecentScanCard(product: product)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            print("RecentScansSection appeared with \(historyViewModel.scannedProducts.count) products")
        }
        .onChange(of: historyViewModel.scannedProducts.count) { count in
            print("RecentScansSection: Products count changed to \(count)")
        }
    }
}

// MARK: - Empty Recent Scans View
struct EmptyRecentScansView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.green)
                }
                // Title
                Text("No Scans Yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                // Subtitle
                Text("Scan a product to discover its eco impact and allergen info!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Empty Scan Card
struct EmptyScanCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
                    .frame(width: 100, height: 100)
    
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(color)
            }
            .padding(.top, 16)
            
            // Text Content
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .frame(height: 36)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .frame(width: 140, height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .opacity(0.6)
        .background(Color(.systemBackground))
    }
}

// MARK: - Recent Scan Card
struct RecentScanCard: View {
    let product: Product
    
    var carbonEmission: String {
        return product.geminiCarbonResult ?? product.carbonFootprint
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 100)
                
                if let imageUrl = product.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 16)
            
            // Product Details
            VStack(spacing: 8) {
                // Product Name
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 36)
                
                // Carbon Emission
                Text("\(co2String(for: product)) kg CO₂e")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .frame(width: 140, height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .background(Color(.systemBackground))
    }
}

// MARK: - Eco Tips Section
struct EcoTipsSection: View {
    @State private var currentIndex: Int = 0
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
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                        EcoTipCard(
                            icon: tip.0,
                            title: tip.1,
                            color: tip.2
                        )
                    }
                }
                .padding(.horizontal, 20)
                .offset(x: -CGFloat(currentIndex) * cardWidth)
                .animation(.easeInOut(duration: 1.0), value: currentIndex)
            }
            .frame(height: 160)
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
        stopAutoScroll()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                if currentIndex < tips.count - 1 {
                    currentIndex += 1
                } else {
                    // Pause on last card, then reset to first after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        currentIndex = 0
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
            .frame(height: 50)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 40)
        }
        .frame(width: 120, height: 120)
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .background(Color(.systemBackground))
    }
}
