import Foundation

class OpenFoodFactsService {
    func fetchAllergens(for upc: String, completion: @escaping ([String]?) -> Void) {
        let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(upc).json")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let product = json["product"] as? [String: Any],
                  let tags = product["allergens_tags"] as? [String] else {
                return completion(nil)
            }
            let clean = tags.compactMap { $0.split(separator: ":").last.map(String.init) }
            completion(clean)
        }.resume()
    }
}
