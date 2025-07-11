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
    @State private var showShareSheet = false

    var totalCO2Saved: Double {
        // Example: sum of all negative carbon values (if any), else 0
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
                                        .foregroundColor(.black)
                                    Text("Total CO₂e Saved")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(totalCO2Saved == 0 ? "0 kg" : String(format: "%.2f kg", totalCO2Saved))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                }
                                Spacer()
                                Button(action: { showShareSheet = true }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share Impact")
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                                }
                                .sheet(isPresented: $showShareSheet) {
                                    ActivityView(activityItems: ["I've saved \(String(format: "%.2f", totalCO2Saved)) kg using EcoScan!"])
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .padding(.horizontal)

                            // Recent Scans Header
                            HStack {
                                Text("Recent Scans")
                                    .font(.headline)
                                    .foregroundColor(.black)
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
                                                    .foregroundColor(.black)
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
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.bottom, 16)
                            }
                        }
                        .padding(.top, 12)
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
        }
    }

    func parseCO2Value(_ value: String?) -> Double? {
        guard let value = value else { return nil }
        let cleaned = value.replacingOccurrences(of: "kg CO₂e", with: "").replacingOccurrences(of: "kg CO2e", with: "").replacingOccurrences(of: "kg CO2", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
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

// Share Sheet Helper
import UIKit
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(viewModel: HistoryViewModel())
    }
} 


