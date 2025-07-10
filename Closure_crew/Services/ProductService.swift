import Foundation

enum ProductError: Error {
    case fileNotFound
    case invalidData
    case productNotFound
}

// Add this structure to match JSON format
struct ProductDatabase: Codable {
    let products: [String: OpenFoodFactsResponse]
}

actor ProductService {
    private var localProducts: [String: OpenFoodFactsResponse]?
    
    init() {}
    
    func initialize() async {
        await loadLocalProducts()
    }
    
    private func loadLocalProducts() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            self.localProducts = createInitialProducts()
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("indian_products.json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let database = try decoder.decode(ProductDatabase.self, from: data)
            self.localProducts = database.products
        } catch {
            self.localProducts = createInitialProducts()
            let database = ProductDatabase(products: self.localProducts ?? [:])
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(database)
                try data.write(to: fileURL)
            } catch {
                return
            }
        }
    }
    
    func fetchProduct(barcode: String) async throws -> Product {
        // First try to get from local database
        if let products = localProducts,
           let response = products[barcode] {
            return createProductFromResponse(response)
        }
        
        // If not found locally, try to fetch from OpenFoodFacts API
        return try await fetchFromOpenFoodFacts(barcode: barcode)
    }
    
    private func fetchFromOpenFoodFacts(barcode: String) async throws -> Product {
        let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let json = json,
              let productData = json["product"] as? [String: Any] else {
            throw ProductError.productNotFound
        }
        
        // Create response object
        let response = OpenFoodFactsResponse(
            code: barcode,
            product: OpenFoodFactsProductDetails(
                productName: productData["product_name"] as? String,
                packaging: productData["packaging"] as? String,
                packagingTags: productData["packaging_tags"] as? [String],
                carbonFootprint: productData["carbon_footprint_100g"] as? String,
                ecoScore: productData["ecoscore_score"] as? String,
                ecoScoreGrade: productData["ecoscore_grade"] as? String
            ),
            status: json["status"] as? Int
        )
        
        // Save to local database
        var updatedProducts = localProducts ?? [:]
        updatedProducts[barcode] = response
        localProducts = updatedProducts
        saveLocalProducts()
        
        return createProductFromResponse(response)
    }
    
    private func createProductFromResponse(_ response: OpenFoodFactsResponse) -> Product {
        return Product(
            code: response.code,
            name: response.product.productName ?? "Unknown Product",
            packaging: response.product.packaging ?? "Unknown Packaging",
            packagingTags: response.product.packagingTags ?? [],
            carbonFootprint: response.product.carbonFootprint ?? "Not Available",
            ecoScore: response.product.ecoScore,
            ecoScoreGrade: response.product.ecoScoreGrade
        )
    }
    
    private func createInitialProducts() -> [String: OpenFoodFactsResponse] {
        var products: [String: OpenFoodFactsResponse] = [:]
        let initialProducts = [
            Product(
                code: "0685450116442",
                name: "Parle-G Original Glucose Biscuits",
                packaging: "Plastic wrapper",
                packagingTags: ["plastic", "wrapper"],
                carbonFootprint: "1.2kg CO2",
                ecoScoreGrade: "C"
            ),
            Product(
                code: "8901063142125",
                name: "Maggi 2-Minute Noodles",
                packaging: "Plastic wrapper with cardboard box",
                packagingTags: ["plastic", "cardboard", "recyclable"],
                carbonFootprint: "2.1kg CO2",
                ecoScoreGrade: "D"
            ),
            Product(
                code: "8901052089844",
                name: "Britannia Marie Gold",
                packaging: "Plastic wrapper",
                packagingTags: ["plastic", "wrapper"],
                carbonFootprint: "1.4kg CO2",
                ecoScoreGrade: "C"
            ),
            Product(
                code: "0194253408079",
                name: "iPhone-14",
                packaging: "Paper Box",
                packagingTags: ["paper", "recyclable"],
                carbonFootprint: "1.2kg CO2",
                ecoScoreGrade: "B"
            )
        ]
        
        for product in initialProducts {
            products[product.code] = OpenFoodFactsResponse(
                code: product.code,
                product: OpenFoodFactsProductDetails(
                    productName: product.name,
                    packaging: product.packaging,
                    packagingTags: product.packagingTags,
                    carbonFootprint: product.carbonFootprint,
                    ecoScore: nil,
                    ecoScoreGrade: product.ecoScoreGrade
                ),
                status: 1
            )
        }
        return products
    }
    
    // Update the addProduct method to convert Product to OpenFoodFactsResponse
    func addProduct(_ product: Product) {
        var updatedProducts = localProducts ?? [:]
        let response = OpenFoodFactsResponse(
            code: product.code,
            product: OpenFoodFactsProductDetails(
                productName: product.name,
                packaging: product.packaging,
                packagingTags: product.packagingTags,
                carbonFootprint: product.carbonFootprint,
                ecoScore: product.ecoScore,
                ecoScoreGrade: product.ecoScoreGrade
            ),
            status: 1
        )
        updatedProducts[product.code] = response
        localProducts = updatedProducts
        saveLocalProducts()
    }
    
    private func saveLocalProducts() {
        guard let products = localProducts,
              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("indian_products.json")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            // Create ProductDatabase structure before encoding
            let database = ProductDatabase(products: products)
            let data = try encoder.encode(database)
            try data.write(to: fileURL)
        } catch {
            print("Error saving local products: \(error)")
        }
    }
} 
