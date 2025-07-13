import Foundation

class NutritionService {
    func fetchNutrition(for upc: String, completion: @escaping (NutritionFacts?, String?, String?, String?, String?, String?, [String]?) -> Void) {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(upc)?fields=product_name,ingredients_text,nutriments,nutrition_grades,nutriscore_data,ecoscore_grade,quantity,packaging,packaging_tags,image_url"
        guard let url = URL(string: urlString) else {
            completion(nil, nil, nil, nil, nil, nil, nil)
            return
        }
        print("🍎 OpenFoodFacts NutritionService - UPC: \(upc)")
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                print("🍎 OpenFoodFacts Nutrition Raw:", String(data: data, encoding: .utf8) ?? "No response")
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let product = json["product"] as? [String: Any],
                   let nutriments = product["nutriments"] as? [String: Any] {
                    let facts = NutritionFacts(
                        item_name: product["product_name"] as? String ?? "",
                        nf_calories: nutriments["energy-kcal_100g"] as? Double ?? 0,
                        nf_total_fat: nutriments["fat_100g"] as? Double ?? 0,
                        nf_protein: nutriments["proteins_100g"] as? Double ?? 0,
                        nf_total_carbohydrate: nutriments["carbohydrates_100g"] as? Double ?? 0,
                        nf_sugars: nutriments["sugars_100g"] as? Double ?? 0
                    )
                    let ingredients = product["ingredients_text"] as? String
                    let ecoScoreGrade = product["ecoscore_grade"] as? String
                    let imageUrl = product["image_url"] as? String
                    let quantity = product["quantity"] as? String
                    let packaging = product["packaging"] as? String
                    let packagingTags = product["packaging_tags"] as? [String]
                    completion(facts, ingredients, ecoScoreGrade, imageUrl, quantity, packaging, packagingTags)
                    return
                }
            }
            completion(nil, nil, nil, nil, nil, nil, nil)
        }.resume()
    }
}
