import SwiftUI

struct ProductHistoryRow: View {
    let product: Product
    @Binding var selectedEcoGrade: String
    @Binding var showingEcoGradeInfo: Bool

    var cleanPackaging: String {
        product.packaging.replacingOccurrences(of: "en:", with: "").capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Product Name
            Text(product.name)
                .font(.headline)

            // Packaging
            HStack(spacing: 8) {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.gray)
                Text(cleanPackaging)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Eco Score
            HStack(spacing: 8) {
                Image(systemName: product.environmentalImpact.ecoGradeInfo.icon)
                    .foregroundColor(product.environmentalImpact.ecoGradeInfo.color)
                    .onTapGesture {
                        if let ecoGrade = product.ecoScoreGrade {
                            selectedEcoGrade = ecoGrade
                            showingEcoGradeInfo = true
                        }
                    }
                Text("Eco Score: ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(product.environmentalImpact.ecoGradeInfo.displayGrade)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(product.environmentalImpact.ecoGradeInfo.color)
            }

            // Carbon Emission
            HStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                    .foregroundColor(.gray)
                Text(product.geminiCarbonResult ?? product.carbonFootprint)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Recyclable status
            HStack(spacing: 8) {
                Image(systemName: product.environmentalImpact.recyclable ? "arrow.3.trianglepath" : "trash")
                    .foregroundColor(product.environmentalImpact.recyclable ? .green : .red)
                Text(product.environmentalImpact.recyclable ? "Recyclable" : "Not Recyclable")
                    .font(.subheadline)
                    .foregroundColor(product.environmentalImpact.recyclable ? .green : .red)
            }
        }
        .padding(.vertical, 8)
    }
}

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @State private var showingClearConfirmation = false
    @State private var showingEcoGradeInfo = false
    @State private var selectedEcoGrade: String = ""
    @State private var showingEnvironmentalImpact = false

    var totalCO2Saved: Double {
        // Example: sum of all negative carbon values (if any), else 0
        viewModel.scannedProducts.compactMap { parseCO2Value($0.geminiCarbonResult ?? $0.carbonFootprint) }.reduce(0, +)
    }
    
    var totalCarbonFootprint: Double {
        // Calculate total carbon footprint from all scanned products
        viewModel.scannedProducts.compactMap { parseCO2Value($0.geminiCarbonResult ?? $0.carbonFootprint) }.reduce(0, +)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    if viewModel.scannedProducts.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Products Scanned Yet")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Start scanning products to track their environmental impact")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        Spacer()
                    } else {
                        VStack(spacing: 20) {
                            // Your Impact Card (fixed)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your Impact")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Total CO₂e")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(totalCO2Saved == 0 ? "0 kg" : String(format: "%.2f kg", totalCO2Saved))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                Button(action: { showingEnvironmentalImpact = true }) {
                                    HStack {
                                        Image(systemName: "leaf.circle.fill")
                                        Text("Environmental Impact")
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.green.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.green, lineWidth: 1.5)
                                    )
                                    .cornerRadius(25)
                                    .shadow(color: Color.green.opacity(0.15), radius: 4, x: 0, y: 2)
                                }
                                .foregroundColor(.green)
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(15)
                            .shadow(radius: 3, x: 0, y: 2)
                            .padding(.horizontal)

                            // Recent Scans Header
                            HStack {
                                Text("Recent Scans")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)

                            // Only this section scrolls
                            ScrollView {
                                VStack(spacing: 14) {
                                    ForEach(viewModel.scannedProducts) { product in
                                        HStack(spacing: 16) {
                                            if let imageUrl = product.imageUrl, let url = URL(string: imageUrl) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } placeholder: {
                                                    Color(.systemGray5)
                                                }
                                                .frame(width: 48, height: 48)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            } else {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.green.opacity(0.12))
                                                        .frame(width: 48, height: 48)
                                                    Image(systemName: "cart.fill")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 28, height: 28)
                                                        .foregroundColor(.green)
                                                }
                                            }
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(product.name)
                                                    .font(.headline)
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                Text(scanTimeString(for: product.scannedAt))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                Text(co2String(for: product))
                                                    .font(.headline)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(16)
                                        .shadow(radius: 3, x: 0, y: 2)
                                        .frame(minHeight: 80) // Ensures all cards have the same minimum height
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                            }
                            .scrollIndicators(.hidden)
                        }
                        .padding(.top, 12)
                        .background(Color(.systemBackground).ignoresSafeArea())
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("History & Impact")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.scannedProducts.isEmpty {
                        Button("Clear All") { showingClearConfirmation = true }
                    }
                }
            }
            .alert("Clear History", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel.clearHistory()
                }
            } message: {
                Text("Are you sure you want to clear all scan history?")
            }
            .sheet(isPresented: $showingEcoGradeInfo) {
                EcoGradeInfoSheet(grade: selectedEcoGrade)
            }
            .sheet(isPresented: $showingEnvironmentalImpact) {
                NavigationView {
                    EarthPollutionView(carbonFootprint: totalCarbonFootprint)
                        .navigationTitle("Environmental Impact")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingEnvironmentalImpact = false
                                }
                            }
                        }
                }
            }
        }
    }

    func parseCO2Value(_ value: String?) -> Double? {
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

    func co2String(for product: Product) -> String {
        let value = parseCO2Value(product.geminiCarbonResult ?? product.carbonFootprint) ?? 0
        if value == 0 {
            return "0 kg CO₂e"
        } else {
            return String(format: "%.2f kg CO₂e", value)
        }
    }

    func scanTimeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
}



struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(viewModel: HistoryViewModel())
    }
} 


