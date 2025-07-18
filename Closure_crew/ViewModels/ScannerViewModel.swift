import Foundation
import UIKit
import Vision
import ImageIO
import CoreImage

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
                print("📱 ScannerViewModel: About to add product to history - \(productForHistory.name)")
                self.historyViewModel.addScan(productForHistory)
                print("📱 ScannerViewModel: Product added to history successfully")
                
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
                   let product = json["product"] as? [String: Any] {
                    
                    var allergens: [String] = []
                    
                    // Try multiple allergen fields from OpenFoodFacts
                    if let tags = product["allergens_tags"] as? [String] {
                        let clean = tags.compactMap { $0.split(separator: ":").last.map(String.init) }
                        allergens.append(contentsOf: clean)
                    }
                    
                    if let hierarchy = product["allergens_hierarchy"] as? [String] {
                        let clean = hierarchy.compactMap { $0.split(separator: ":").last.map(String.init) }
                        allergens.append(contentsOf: clean)
                    }
                    
                    if let text = product["allergens"] as? String {
                        // Parse allergens from text format
                        let allergenList = text.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        allergens.append(contentsOf: allergenList)
                    }
                    
                    // Also check for allergen traces
                    if let traces = product["traces_tags"] as? [String] {
                        let clean = traces.compactMap { $0.split(separator: ":").last.map(String.init) }
                        allergens.append(contentsOf: clean)
                    }
                    
                    // Remove duplicates and empty strings, and normalize
                    let uniqueAllergens = Array(Set(allergens))
                        .filter { !$0.isEmpty }
                        .map { allergen in
                            // Normalize common allergen names
                            let lower = allergen.lowercased()
                            switch lower {
                            case "en:peanuts", "peanuts", "peanut":
                                return "Peanut"
                            case "en:milk", "milk":
                                return "Milk"
                            case "en:soy", "soy", "soybeans":
                                return "Soy"
                            case "en:wheat", "wheat":
                                return "Wheat"
                            case "en:fish", "fish":
                                return "Fish"
                            case "en:gluten", "gluten":
                                return "Gluten"
                            case "en:eggs", "eggs", "egg":
                                return "Eggs"
                            case "en:nuts", "nuts", "tree nuts":
                                return "Nuts"
                            default:
                                return allergen.capitalized
                            }
                        }
                    
                    print("🔍 Found allergens for \(upc): \(uniqueAllergens)")
                    continuation.resume(returning: uniqueAllergens.isEmpty ? nil : uniqueAllergens)
                } else {
                    print("🔍 No product data found for \(upc)")
                    continuation.resume(returning: nil)
                }
            }.resume()
        }
    }
    
    // For testing
    func testScan(barcode: String) {
        self.scannedCode = barcode
    }
    
    // MARK: - Scan barcode from UIImage (for Scan from Photo)
    func scanBarcode(from image: UIImage) {
        guard let cgImage = image.normalizedCGImage(maxDimension: 1024) else {
            self.error = "Image is not valid for barcode detection."
            return
        }
        isLoading = true
        error = nil

        // Always use .up orientation for Vision
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = "Barcode detection failed: \(error.localizedDescription)"
                    self?.isLoading = false
                    return
                }
                guard let results = request.results as? [VNBarcodeObservation],
                      let payload = results.first?.payloadStringValue else {
                    self?.error = "No barcode found in image."
                    self?.isLoading = false
                    return
                }
                self?.scannedCode = payload
            }
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.error = "Failed to perform barcode detection: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
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

// Helper to convert UIImage.Orientation to CGImagePropertyOrientation
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// Extension to robustly convert UIImage to CGImage
extension UIImage {
    func toCGImage(maxDimension: CGFloat = 1024) -> CGImage? {
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
        if let cgImage = imageToUse.cgImage {
            return cgImage
        }
        if let ciImage = imageToUse.ciImage {
            let context = CIContext()
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        UIGraphicsBeginImageContextWithOptions(imageToUse.size, false, imageToUse.scale)
        defer { UIGraphicsEndImageContext() }
        imageToUse.draw(at: .zero)
        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        return drawnImage?.cgImage
    }
}
