import Foundation

// Updated to match actual API response
struct BarcodeLookupResponse: Codable {
    let products: [BarcodeProduct]?
    let message: String?
    let statusCode: Int?
}

struct BarcodeProduct: Codable {
    let title: String?  // API returns 'title' instead of 'product_name'
    let barcode: String?
    let manufacturer: String?
    let brand: String?
    let category: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case barcode = "barcode_number"
        case manufacturer
        case brand
        case category
        case description
    }
}

// Make it an actor to prevent data races
actor BarcodeLookupService {
    private let apiKey = "87yfns9q2k8e4jq16hj9ogitckp1ji"
    private let baseURL = "https://api.barcodelookup.com/v3/products"
    
    // List of verified Indian product barcodes
    private let indianBarcodes = [
        "0685450116442",  // Parle-G
        "8901063142125",  // Maggi Noodles
        "8901058000991",  // Parle Products
        "8901052089844",  // Britannia Biscuits
        "8901030578728",  // Cadbury Dairy Milk
    ]
    
    // Function to lookup a single barcode
    func lookupBarcode(_ barcode: String) async throws -> OpenFoodFactsResponse {
        let urlString = "\(baseURL)?barcode=\(barcode)&formatted=y&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        print("Fetching from URL: \(urlString)")  // Debug print
        
        let (data, httpResponse) = try await URLSession.shared.data(from: url)
        
        // Debug print the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw API Response: \(jsonString)")
        }
        
        guard let httpResponse = httpResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Invalid response", code: -1)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(BarcodeLookupResponse.self, from: data)
        
        guard let product = apiResponse.products?.first,
              let productName = product.title else {
            throw NSError(domain: "No product found or invalid data", code: -1)
        }
        
        return OpenFoodFactsResponse(
            code: product.barcode ?? barcode,
            product: OpenFoodFactsProductDetails(
                productName: productName,
                packaging: determinePackaging(product),
                packagingTags: determinePackagingTags(product),
                carbonFootprint: estimateCarbonFootprint(product)
            ),
            status: 1
        )
    }
    
    // Function to fetch all products for database
    func fetchAllProducts() async throws -> [String: OpenFoodFactsResponse] {
        var products: [String: OpenFoodFactsResponse] = [:]
        
        for barcode in indianBarcodes {
            do {
                print("Fetching barcode: \(barcode)")  // Debug print
                let product = try await lookupBarcode(barcode)
                products[barcode] = product
                print("Successfully added product: \(product.product.productName ?? "")")
                
                // Add delay to respect API rate limits
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            } catch {
                print("Error fetching barcode \(barcode): \(error)")
            }
        }
        
        return products
    }
    
    private func determinePackaging(_ product: BarcodeProduct) -> String {
        if product.category?.lowercased().contains("beverages") ?? false {
            return "Plastic bottle"
        } else if product.category?.lowercased().contains("snacks") ?? false {
            return "Plastic wrapper"
        } else if product.category?.lowercased().contains("dairy") ?? false {
            return "Tetra pack"
        }
        return "Plastic wrapper"
    }
    
    private func determinePackagingTags(_ product: BarcodeProduct) -> [String] {
        var tags: [String] = []
        
        if product.category?.lowercased().contains("beverages") ?? false {
            tags = ["plastic", "recyclable"]
        } else if product.category?.lowercased().contains("snacks") ?? false {
            tags = ["plastic", "wrapper"]
        } else if product.category?.lowercased().contains("dairy") ?? false {
            tags = ["tetra", "recyclable"]
        } else {
            tags = ["plastic", "wrapper"]
        }
        
        return tags
    }
    
    private func estimateCarbonFootprint(_ product: BarcodeProduct) -> String {
        // Simple estimation based on category
        if product.category?.lowercased().contains("beverages") ?? false {
            return "2.0kg CO2"
        } else if product.category?.lowercased().contains("snacks") ?? false {
            return "1.5kg CO2"
        } else if product.category?.lowercased().contains("dairy") ?? false {
            return "2.5kg CO2"
        }
        return "1.8kg CO2"
    }
} 