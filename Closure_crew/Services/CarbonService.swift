import Foundation

class CarbonService {
    private let apiKey = "NHEGYMRXHS4XB8GZV6GMVDTH0RC"
    private let baseURL = "https://beta3.api.climatiq.io"
    
    func fetchCarbon(for upc: String, completion: @escaping (CarbonResponse?) -> Void) {
        let url = URL(string: "\(baseURL)/products/\(upc)/footprint")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        print("🌱 CarbonService - UPC: \(upc)")
        
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data = data {
                print("🌱 Climatiq Raw:", String(data: data, encoding: .utf8) ?? "No response")
            }
            guard let data = data,
                  let cr = try? JSONDecoder().decode(CarbonResponse.self, from: data) else {
                return completion(nil)
            }
            completion(cr)
        }.resume()
    }
}
