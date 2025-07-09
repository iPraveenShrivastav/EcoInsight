import Foundation

@MainActor
class ScannerViewModel: ObservableObject {
    @Published var scannedCode: String? {
        didSet {
            if let code = scannedCode {
                onBarcodeScanned(code)
            }
        }
    }
    @Published var productInfo: ProductInfo?
    @Published var isLoading = false
    @Published var error: String?
    
    private let historyViewModel: HistoryViewModel
    private let nutritionService = NutritionService()
    private let carbonService = CarbonService()
    private let openFoodService = OpenFoodFactsService()
    
    init(historyViewModel: HistoryViewModel) {
        self.historyViewModel = historyViewModel
    }
    
    private func onBarcodeScanned(_ upc: String) {
        print("🔍 Scanned UPC: \(upc)")
        isLoading = true
        error = nil
        
        var info = ProductInfo(barcode: upc)
        let group = DispatchGroup()
        
        group.enter()
        nutritionService.fetchNutrition(for: upc) { [weak self] nutrition in
            info.nutrition = nutrition
            group.leave()
        }
        
        group.enter()
        carbonService.fetchCarbon(for: upc) { [weak self] carbon in
            info.carbon = carbon
            group.leave()
        }
        
        group.enter()
        openFoodService.fetchAllergens(for: upc) { [weak self] allergens in
            info.allergens = allergens
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.productInfo = info
            self.isLoading = false
            
            // Check if we got any data
            if info.nutrition == nil && info.carbon == nil && info.allergens == nil {
                self.error = "No product information found"
            }
        }
    }
    
    // For testing
    func testScan(barcode: String) {
        self.scannedCode = barcode
    }
}
