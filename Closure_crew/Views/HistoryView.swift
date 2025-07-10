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

    var body: some View {
        NavigationView {
            Group {
                if viewModel.scannedProducts.isEmpty {
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
                } else {
                    List {
                        ForEach(viewModel.scannedProducts) { product in
                            ProductHistoryRow(
                                product: product,
                                selectedEcoGrade: $selectedEcoGrade,
                                showingEcoGradeInfo: $showingEcoGradeInfo
                            )
                        }
                        .onDelete(perform: viewModel.deleteProduct)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .toolbar {
                        EditButton()
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !viewModel.scannedProducts.isEmpty {
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Text("Clear All")
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

    // Helper to get the correct carbon emission (Gemini or API)
    func getCarbonEmission(for product: Product) -> String? {
        // If you have a way to access the Gemini result for this product, return it here.
        // For now, just return product.carbonFootprint.
        // You can enhance this to use a cache or lookup if needed.
        return product.carbonFootprint
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(viewModel: HistoryViewModel())
    }
} 


