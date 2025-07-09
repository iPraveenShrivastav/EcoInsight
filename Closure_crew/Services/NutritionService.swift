import Foundation

class NutritionService {
    private let appId = "ba3bbe96"
    private let appKey = "3d614ef1a3775b40701d800063273a0f"
    
    func fetchNutrition(for upc: String, completion: @escaping (NutritionFacts?) -> Void) {
        var comps = URLComponents(string: "https://api.nutritionix.com/v1_1/item")!
        comps.queryItems = [
            URLQueryItem(name: "upc", value: upc),
            URLQueryItem(name: "appId", value: appId),
            URLQueryItem(name: "appKey", value: appKey)
        ]
        
        print("🍎 NutritionService - UPC: \(upc)")
        
        URLSession.shared.dataTask(with: comps.url!) { data, _, _ in
            if let data = data {
                print("🍎 Nutritionix Raw:", String(data: data, encoding: .utf8) ?? "No response")
            }
            guard let data = data,
                  let facts = try? JSONDecoder().decode(NutritionFacts.self, from: data) else {
                return completion(nil)
            }
            completion(facts)
        }.resume()
    }
}
