import Foundation

struct OpenFoodFactsResponse: Codable {
    let code: String
    let product: OpenFoodFactsProductDetails
    let status: Int?
    
    enum CodingKeys: String, CodingKey {
        case code
        case product
        case status
    }
}

struct OpenFoodFactsProductDetails: Codable {
    let productName: String?
    let packaging: String?
    let packagingTags: [String]?
    let carbonFootprint: String?
    let ecoScore: String?
    let ecoScoreGrade: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case packaging
        case packagingTags = "packaging_tags"
        case carbonFootprint = "carbon_footprint_100g"
        case ecoScore = "ecoscore_score"
        case ecoScoreGrade = "ecoscore_grade"
    }
} 