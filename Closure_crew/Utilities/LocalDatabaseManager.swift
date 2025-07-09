import Foundation

@MainActor
class LocalDatabaseManager {
    static let shared = LocalDatabaseManager()
    
    private init() {}
    
    func copyBundleFileIfNeeded() {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let destinationPath = documentsPath.appendingPathComponent("indian_products.json")
        
        if !fileManager.fileExists(atPath: destinationPath.path) {
            do {
                let initialProducts = createInitialProducts()
                let database = ProductDatabase(products: initialProducts)
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(database)
                try data.write(to: destinationPath)
            } catch {
                return
            }
        }
    }
    
    private func createInitialProducts() -> [String: OpenFoodFactsResponse] {
        var products: [String: OpenFoodFactsResponse] = [:]
        let initialProducts = [
            (code: "8901262010016", name: "Amul Butter"),
            (code: "8901058000252", name: "Maggi 2-Minute Noodles"),
            (code: "8901030695559", name: "Dairy Milk Silk"),
            (code: "0194253408079", name: "iPhone-14"),
            (code: "8901063092686", name: "Britannia Good Day")
        ]
        
        for product in initialProducts {
            products[product.code] = OpenFoodFactsResponse(
                code: product.code,
                product: OpenFoodFactsProductDetails(
                    productName: product.name,
                    packaging: "Plastic wrapper",
                    packagingTags: ["plastic", "recyclable"],
                    carbonFootprint: "1.5kg CO2"
                ),
                status: 1
            )
        }
        return products
    }
} 
