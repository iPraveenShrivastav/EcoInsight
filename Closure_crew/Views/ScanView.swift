import SwiftUI
import AVFoundation

// Set your Gemini API key here
let GEMINI_API_KEY = "AIzaSyChk26SFhMAhZIUVMnYNPwXdoREpT1iUg0"

struct ScanView: View {
    @StateObject private var scannerViewModel: ScannerViewModel
    @State private var showingScanner = false
    
    init(historyViewModel: HistoryViewModel) {
        _scannerViewModel = StateObject(wrappedValue: ScannerViewModel(historyViewModel: historyViewModel))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    if scannerViewModel.isLoading {
                        loadingView
                    } else if let error = scannerViewModel.error {
                        errorView(error)
                    } else if let productInfo = scannerViewModel.productInfo {
                        ProductDetailView(productInfo: productInfo, scannerViewModel: scannerViewModel)
                    } else {
                        scannerReadyView
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView(scannedCode: $scannerViewModel.scannedCode)
            }
            .navigationTitle("Scan")
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
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.top, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
    
    private var scannerReadyView: some View {
        VStack(spacing: 0) {
            // Camera preview area
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: UIScreen.main.bounds.width * 0.85,
                           height: UIScreen.main.bounds.width * 0.85)
                    .background(Color.black.opacity(0.02))
                
                // Scan frame corners
                ZStack {
                    // Top left corner
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 40))
                        path.addLine(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 40, y: 0))
                    }
                    .stroke(Color.green, lineWidth: 4)
                    
                    // Other corners...
                }
                .frame(width: UIScreen.main.bounds.width * 0.85,
                       height: UIScreen.main.bounds.width * 0.85)
            }
            .frame(height: UIScreen.main.bounds.height * 0.6)
            
            Spacer(minLength: 0)
            
            // Bottom controls
            VStack(spacing: 24) {
                Text("Scan Product Barcode")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text("Position barcode within the frame")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 40) {
                    Button(action: {}) {
                        Image(systemName: "flashlight.off.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                            .frame(width: 56, height: 56)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { showingScanner = true }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                            .frame(width: 56, height: 56)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 24)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
            .background(
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.bottom)
            )
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 24)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ready to scan product barcode")
    }
}

// Add a scanning overlay view
struct ScannerOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay
                Color.black.opacity(0.5)
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
