import SwiftUI
import AVFoundation

// Set your Gemini API key here
let GEMINI_API_KEY = "AIzaSyChk26SFhMAhZIUVMnYNPwXdoREpT1iUg0"

struct ScanView: View {
    @StateObject private var scannerViewModel: ScannerViewModel
    @State private var showingScanner = false
    @State private var selectedProduct: ProductInfo? = nil
    
    // Hardcoded alternatives for Häagen‑Dazs Vanilla Ice Cream
    private let haagenDazsAlternatives = [
        AlternativeProduct(
            name: "Oatly Vanilla Frozen Dessert",
            brandOrType: "Plant-based dessert · Frozen foods",
            imageUrl: "https://world.openfoodfacts.org/images/products/17988807/front_en.8.full.jpg",
            description: "Gluten-free, Dairy-free, Egg-free",
            nutrition: nil,
            allergens: [],
            barcode: "17988807"
        ),
        AlternativeProduct(
            name: "Alpro Vanilla Dessert",
            brandOrType: "Plant-based dessert",
            imageUrl: "https://world.openfoodfacts.org/images/products/541/118/811/0521/front_en.10.full.jpg",
            description: "Contains soy; Dairy-free, Egg-free",
            nutrition: nil,
            allergens: ["soy"],
            barcode: "5411188110521"
        ),
        AlternativeProduct(
            name: "Vanilla Bean Dessert – Nora's",
            brandOrType: "Cashew & coconut cream base",
            imageUrl: "https://world.openfoodfacts.org/images/products/062/784/381/4238/front_en.8.full.jpg",
            description: "Dairy-free, Egg-free",
            nutrition: nil,
            allergens: ["cashew"],
            barcode: "0627843814238"
        )
    ]
    
    init(historyViewModel: HistoryViewModel) {
        _scannerViewModel = StateObject(wrappedValue: ScannerViewModel(historyViewModel: historyViewModel))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    if scannerViewModel.isLoading {
                        loadingView
                    } else if let error = scannerViewModel.error {
                        errorView(error)
                    } else {
                        scanLandingView
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView(scannedCode: $scannerViewModel.scannedCode)
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar) // UI only - no logic change: Enhanced toolbar background
            .background(.regularMaterial.opacity(0.95)) // UI only - no logic change: Material background for navigation
            .onChange(of: scannerViewModel.productInfo) { newProduct in
                if let info = newProduct {
                    selectedProduct = info
                }
            }
            .navigationDestination(item: $selectedProduct) { product in
                let normalizedBarcode = product.barcode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let validBarcodes = ["055000205528", "0055000205528"]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                let showAlternatives = validBarcodes.contains(normalizedBarcode)
                return ProductDetailView(
                    productInfo: product,
                    scannerViewModel: scannerViewModel,
                    onBack: {
                        selectedProduct = nil
                        scannerViewModel.productInfo = nil
                    },
                    alternatives: showAlternatives ? haagenDazsAlternatives : nil
                )
                .onAppear {
                    print("Scanned barcode: \(product.barcode)")
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading product information...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Loading product information")
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 56))
                .foregroundColor(.orange)
            
            Text(error)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            if let code = scannerViewModel.scannedCode {
                Text("Scanned Barcode: \(code)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            Button(action: { showingScanner = true }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent) // UI only - no logic change: Enhanced button style for retry
            .background(Color.green)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Error: \(error)")
    }
    
    private var scanLandingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // UI only - no logic change: Enhanced icon and text presentation
            VStack(spacing: 24) {
                Image(systemName: "barcode.viewfinder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)
                    .symbolEffect(.pulse.byLayer, options: .repeat(.continuous)) // UI only - no logic change: Enhanced icon animation
                
                VStack(spacing: 8) {
                    Text("Ready to scan a product?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Discover eco-impact and allergen info instantly")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: { showingScanner = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.headline)
                    Text("Scan Product")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.bordered) // UI only - no logic change: Enhanced button style
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.green.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// Add a scanning overlay view
struct ScannerOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay
                Color(.label).opacity(0.5)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .frame(
                                        width: geometry.size.width * 0.85,
                                        height: geometry.size.width * 0.85
                                    )
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Scanning frame
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.green.opacity(0.8), lineWidth: 2)
                    .frame(
                        width: geometry.size.width * 0.85,
                        height: geometry.size.width * 0.85
                    )
                
                // Corner markers
                ZStack {
                    // Top left
                    Path { path in
                        path.move(to: CGPoint(x: -40, y: 4))
                        path.addLine(to: CGPoint(x: 4, y: 4))
                        path.addLine(to: CGPoint(x: 4, y: 44))
                    }
                    .stroke(Color.green, lineWidth: 4)
                    
                    // Top right
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width * 0.85 + 40, y: 4))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.85 - 4, y: 4))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.85 - 4, y: 44))
                    }
                    .stroke(Color.green, lineWidth: 4)
                    
                    // Bottom left
                    Path { path in
                        path.move(to: CGPoint(x: 4, y: geometry.size.width * 0.85 - 44))
                        path.addLine(to: CGPoint(x: 4, y: geometry.size.width * 0.85 - 4))
                        path.addLine(to: CGPoint(x: 44, y: geometry.size.width * 0.85 - 4))
                    }
                    .stroke(Color.green, lineWidth: 4)
                    
                    // Bottom right
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width * 0.85 - 4, y: geometry.size.width * 0.85 - 44))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.85 - 4, y: geometry.size.width * 0.85 - 4))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.85 - 44, y: geometry.size.width * 0.85 - 4))
                    }
                    .stroke(Color.green, lineWidth: 4)
                }
            }
        }
    }
}
