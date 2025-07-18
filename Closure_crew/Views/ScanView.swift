import SwiftUI
import AVFoundation
import PhotosUI
import UIKit

// Set your Gemini API key here
let GEMINI_API_KEY = "AIzaSyChk26SFhMAhZIUVMnYNPwXdoREpT1iUg0"

struct ScanView: View {
    @StateObject private var scannerViewModel: ScannerViewModel
    @State private var showingScanner = false
    @State private var selectedProduct: ProductInfo? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    
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
                    .ignoresSafeArea()
                
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
            .onChange(of: selectedPhoto) { newItem in
                if let newItem = newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data),
                           let cgImage = uiImage.normalizedCGImage(maxDimension: 1024) {
                            let normalizedImage = UIImage(cgImage: cgImage)
                            selectedUIImage = normalizedImage
                            scannerViewModel.scanBarcode(from: normalizedImage)
                        } else {
                            scannerViewModel.error = "Could not load a valid image for barcode detection."
                        }
                    }
                }
            }
            .navigationTitle("Scan")
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
                ProductDetailView(
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
            
            VStack(spacing: 14) {
                Button(action: { showingScanner = true }) {
                    Text("Try Again (Scan Product)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(14)
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    Text("Scan from Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Error: \(error)")
    }
    
    private var scanLandingView: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "barcode.viewfinder")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .padding(.bottom, 8)
            Text("Ready to scan a product?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            VStack(spacing: 18) {
                Button(action: { showingScanner = true }) {
                    HStack {
                        Image(systemName: "viewfinder")
                        Text("Scan Product")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(18)
                }
                .glassEffect()
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Scan from Photo")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(18)
                }
                .glassEffect()
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
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

// MARK: - Glass Effect Modifier
import SwiftUI

struct GlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .blur(radius: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassEffect() -> some View {
        self.modifier(GlassEffect())
    }
}

extension UIImage {
    /// Returns a new UIImage with .up orientation and a valid cgImage, or nil if conversion fails.
    func normalizedCGImage(maxDimension: CGFloat = 1024) -> CGImage? {
        // Downscale if needed
        var imageToUse = self
        let maxSide = max(size.width, size.height)
        if maxSide > maxDimension {
            let scale = maxDimension / maxSide
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            self.draw(in: CGRect(origin: .zero, size: newSize))
            if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                imageToUse = resized
            }
            UIGraphicsEndImageContext()
        }
        // Normalize orientation to .up
        if imageToUse.imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(imageToUse.size, false, imageToUse.scale)
            imageToUse.draw(in: CGRect(origin: .zero, size: imageToUse.size))
            let normalized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let normalized = normalized {
                imageToUse = normalized
            }
        }
        // Ensure cgImage exists
        if let cgImage = imageToUse.cgImage {
            return cgImage
        }
        // Try CIImage conversion
        if let ciImage = imageToUse.ciImage {
            let context = CIContext()
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        return nil
    }
}
