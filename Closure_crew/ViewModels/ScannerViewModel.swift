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
    @Published var geminiCarbonResult: String?
    
    let historyViewModel: HistoryViewModel
    let productService = ProductService()
    let nutritionService = NutritionService()
    let geminiService = GeminiService(apiKey: "AIzaSyBFPSpiWUNLvL390wzHI0NUyN7ZDsh5EV0")
    
    init(historyViewModel: HistoryViewModel) {
        self.historyViewModel = historyViewModel
        Task {
            await productService.initialize()
        }
    }
    
    private func onBarcodeScanned(_ upc: String) {
        print("🔍 Scanned UPC: \(upc)")
        isLoading = true
        error = nil
        
        Task {
            do {
                // Try to get product from ProductService first (includes eco grade)
                let product = try await productService.fetchProduct(barcode: upc)
                
                // Create ProductInfo from the product
                var info = ProductInfo(barcode: upc)
                info.nutrition = NutritionFacts(
                    item_name: product.name,
                    nf_calories: 0, // We'll get this from nutrition service
                    nf_total_fat: 0,
                    nf_protein: 0,
                    nf_total_carbohydrate: 0,
                    nf_sugars: 0
                )
                info.ecoScoreGrade = product.ecoScoreGrade
                info.packaging = product.packaging
                info.packagingTags = product.packagingTags
                
                // Get additional data from nutrition and allergens only
                let (nutrition, allergens) = await (
                    fetchNutritionData(for: upc),
                    fetchAllergensData(for: upc)
                )
                
                // Update info with fetched data
                if let nutrition = nutrition {
                    info.nutrition = nutrition.nutrition
                    info.ingredients = nutrition.ingredients
                    info.ecoScoreGrade = nutrition.ecoScoreGrade
                    info.productImageUrl = nutrition.imageUrl
                    info.quantity = nutrition.quantity
                    info.packaging = nutrition.packaging
                    info.packagingTags = nutrition.packagingTags
                }
                if let allergens = allergens {
                    info.allergens = allergens
                }
                // Check if barcode is already in history and reuse Gemini value if present
                let cachedGemini = historyViewModel.scannedProducts.first(where: { $0.code == upc })?.geminiCarbonResult
                let geminiResult: String?
                if let cached = cachedGemini, !cached.isEmpty {
                    print("♻️ Using cached Gemini result for barcode \(upc): \(cached)")
                    geminiResult = cached
                } else {
                    let geminiResultRaw = await geminiService.estimateCarbon(for: info)
                    geminiResult = geminiResultRaw?
                        .components(separatedBy: .whitespaces)
                        .first(where: { Double($0) != nil }) ?? "0"
                }
                self.geminiCarbonResult = geminiResult
                
                // Update the product info
                self.productInfo = info
                self.isLoading = false
                
                // Add to history, always save Gemini result
                let productForHistory = Product(
                    code: product.code,
                    name: product.name,
                    packaging: product.packaging,
                    packagingTags: product.packagingTags,
                    carbonFootprint: product.carbonFootprint,
                    ecoScore: product.ecoScore,
                    ecoScoreGrade: product.ecoScoreGrade,
                    geminiCarbonResult: geminiResult,
                    scannedAt: Date(),
                    imageUrl: info.productImageUrl
                )
                self.historyViewModel.addScan(productForHistory)
                
            } catch {
                print("❌ Error fetching product: \(error)")
                self.error = "Product not found"
                self.isLoading = false
            }
        }
    }
    
    private func fetchNutritionData(for upc: String) async -> (nutrition: NutritionFacts?, ingredients: String?, ecoScoreGrade: String?, imageUrl: String?, quantity: String?, packaging: String?, packagingTags: [String]?)? {
        await withCheckedContinuation { continuation in
            nutritionService.fetchNutrition(for: upc) { nutrition, ingredients, ecoScoreGrade, imageUrl, quantity, packaging, packagingTags in
                continuation.resume(returning: (nutrition, ingredients, ecoScoreGrade, imageUrl, quantity, packaging, packagingTags))
            }
        }
    }
    
    private func fetchAllergensData(for upc: String) async -> [String]? {
        await withCheckedContinuation { continuation in
            // Use a simple API call for allergens
            let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(upc).json")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let product = json["product"] as? [String: Any],
                   let tags = product["allergens_tags"] as? [String] {
                    let clean = tags.compactMap { $0.split(separator: ":").last.map(String.init) }
                    continuation.resume(returning: clean)
                } else {
                    continuation.resume(returning: nil)
                }
            }.resume()
        }
    }
    
    // For testing
    func testScan(barcode: String) {
        self.scannedCode = barcode
    }
}

extension ScannerViewModel {
    func saveCarbonResultToHistory(for productInfo: ProductInfo, value: String) {
        if let index = historyViewModel.scannedProducts.firstIndex(where: { $0.code == productInfo.barcode }) {
            var product = historyViewModel.scannedProducts[index]
            product.geminiCarbonResult = value
            historyViewModel.deleteProduct(product)
            historyViewModel.addScan(product)
        }
        // If not in history, add a new Product (optional, depending on your flow)
    }

    // Add this helper for alternative product selection
    func saveProductToHistory(productInfo: ProductInfo, carbonResult: CarbonFootprintResult?, carbonString: String?, replacingBarcode: String?) {
        // Remove the previous product if needed
        if let replacingBarcode = replacingBarcode,
           let index = historyViewModel.scannedProducts.firstIndex(where: { $0.code == replacingBarcode }) {
            let oldProduct = historyViewModel.scannedProducts[index]
            historyViewModel.deleteProduct(oldProduct)
        }
        let geminiValue: String? = {
            if let carbonResult = carbonResult {
                return String(format: "%.2f kg CO₂e", carbonResult.totalKgCO2e)
            } else if let carbonString = carbonString {
                return carbonString
            } else {
                return nil
            }
        }()
        let product = Product(
            code: productInfo.barcode,
            name: productInfo.nutrition?.item_name ?? "",
            packaging: productInfo.packaging ?? "",
            packagingTags: productInfo.packagingTags ?? [],
            carbonFootprint: "", // Only using Gemini for now
            ecoScore: nil,
            ecoScoreGrade: productInfo.ecoScoreGrade,
            geminiCarbonResult: geminiValue,
            scannedAt: Date(),
            imageUrl: productInfo.productImageUrl
        )
        historyViewModel.addScan(product)
    }
}
