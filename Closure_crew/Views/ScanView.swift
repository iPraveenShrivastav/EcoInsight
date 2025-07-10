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
            VStack(spacing: 20) {
                if scannerViewModel.isLoading {
                    ProgressView("Loading product information...")
                        .accessibilityLabel("Loading product information")
                } else if let error = scannerViewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        // Display the scanned barcode when product is not found
                        if let code = scannerViewModel.scannedCode {
                            Text("Scanned Barcode: \(code)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                } else if let productInfo = scannerViewModel.productInfo {
                    ProductDetailView(productInfo: productInfo, scannerViewModel: scannerViewModel)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 100))
                            .foregroundColor(.green)
                        
                        Text("Scan Product Barcode")
                            .font(.title2.weight(.medium))
                        
                        Text("Supports EAN-8, EAN-13, and UPC-E barcodes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Ready to scan product barcode")
                }
                
                Button(action: {
                    showingScanner = true
                }) {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .accessibilityHint("Double tap to open barcode scanner")
            }
            .padding()
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView(scannedCode: $scannerViewModel.scannedCode)
            }
            .navigationTitle("Scan")
        }
    }
}

// Add a scanning overlay view
struct ScannerOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.5)
                    .mask(
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(width: geometry.size.width * 0.7,
                                         height: geometry.size.width * 0.3)
                                    .blendMode(.destinationOut)
                            )
                    )
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: geometry.size.width * 0.7,
                          height: geometry.size.width * 0.3)
                
                VStack {
                    Spacer()
                    Text("Align barcode within frame")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
