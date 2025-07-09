import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @State private var showingClearConfirmation = false
    
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
                            ProductRow(product: product)
                        }
                        .onDelete(perform: viewModel.deleteProduct)
                    }
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
        }
    }
}

struct ProductRow: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.secondary)
                Text(product.packaging)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(product.environmentalImpact.impactLevel.color)
                Text("Impact Score: \(String(format: "%.1f", product.environmentalImpact.score))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundColor(.secondary)
                Text(product.carbonFootprint)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Show packaging tags
            HStack {
                ForEach(product.packagingTags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // Show recyclable and biodegradable status
            HStack {
                if product.environmentalImpact.recyclable {
                    Label("Recyclable", systemImage: "arrow.3.trianglepath")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                if product.environmentalImpact.biodegradable {
                    Label("Biodegradable", systemImage: "leaf")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(viewModel: HistoryViewModel())
    }
} 
