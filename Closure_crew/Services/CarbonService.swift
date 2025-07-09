import Foundation

class CarbonService {
    private let apiKey = Bundle.main.object(forInfoDictionaryKey: "CLIMATIQ_API_KEY") as! String
    private let baseURL = "https://beta3.api.climatiq.io"
    
    func fetchCarbon(for upc: String, completion: @escaping (CarbonResponse?) -> Void) {
        let url = URL(string: "\(baseURL)/products/\(upc)/footprint")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let cr = try? JSONDecoder().decode(CarbonResponse.self, from: data) else {
                return completion(nil)
            }
            completion(cr)
        }.resume()
    }
}
