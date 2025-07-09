import Foundation

class NutritionService {
    private let appId = Bundle.main.object(forInfoDictionaryKey: "NUTRITIONIX_APP_ID") as! String
    private let appKey = Bundle.main.object(forInfoDictionaryKey: "NUTRITIONIX_APP_KEY") as! String
    
    func fetchNutrition(for upc: String, completion: @escaping (NutritionFacts?) -> Void) {
        var comps = URLComponents(string: "https://api.nutritionix.com/v1_1/item")!
        comps.queryItems = [
            URLQueryItem(name: "upc", value: upc),
            URLQueryItem(name: "appId", value: appId),
            URLQueryItem(name: "appKey", value: appKey)
        ]
        
        URLSession.shared.dataTask(with: comps.url!) { data, _, _ in
            guard let data = data,
                  let facts = try? JSONDecoder().decode(NutritionFacts.self, from: data) else {
                return completion(nil)
            }
            completion(facts)
        }.resume()
    }
}
