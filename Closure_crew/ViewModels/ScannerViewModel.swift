import Foundation

@MainActor
class ScannerViewModel: ObservableObject {
    @Published var scannedCode: String? {
        didSet {
            if let code = scannedCode {
                fetchProductInfo(for: code)
            }
        }
    }
    @Published var scannedProduct: Product?
    @Published var isLoading = false
    @Published var error: String?
    
    private let productService: ProductService
    private let historyViewModel: HistoryViewModel
    
    init(historyViewModel: HistoryViewModel) {
        self.historyViewModel = historyViewModel
        self.productService = ProductService()
        Task {
            await productService.initialize()
        }
    }
    
    func fetchProductInfo(for barcode: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                let product = try await productService.fetchProduct(barcode: barcode)
                self.scannedProduct = product
                self.historyViewModel.addScan(product)
            } catch {
                self.error = "Product not found in database.\nOnly supported products can be scanned."
            }
            self.isLoading = false
        }
    }
    
    // Add this method for testing
    func testScan(barcode: String) {
        self.scannedCode = barcode
    }
} 
