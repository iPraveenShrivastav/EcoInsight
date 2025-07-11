import Foundation

class GeminiService {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func estimateCarbon(for productInfo: ProductInfo) async -> String? {
        let prompt = """
You are a sustainability expert. Estimate the total carbon footprint (in kg CO₂e) for the following packaged food product, using a life-cycle approach (cradle-to-grave). Use all available data: product name, ingredients, product weight, packaging material, eco-score, and any other relevant info.

Provide a brief explanation and breakdown if needed, but ALWAYS return the total carbon footprint as the LAST line, in the format:
Total carbon footprint: [number] kg CO₂e

Product name: \(productInfo.nutrition?.item_name ?? "Unknown")
Ingredients: \(productInfo.ingredients ?? "Unknown")
Product weight: \(productInfo.quantity ?? "Unknown")
Packaging: \(productInfo.packaging ?? "Unknown")
Eco-score: \(productInfo.ecoScoreGrade ?? "Unknown")
"""

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            print("❌ GeminiService - Invalid URL")
            return nil
        }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        print("🌱 GeminiService - Calling Gemini API for product: \(productInfo.nutrition?.item_name ?? "Unknown")")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print("🌱 GeminiService - Raw response: \(String(data: data, encoding: .utf8) ?? "No response")")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                // Extract the last line matching 'Total carbon footprint: [number] kg CO₂e'
                let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let pattern = #"([0-9]+\.?[0-9]*)\s*kg\s*CO[2₂]e"#
                // Search from the last line up
                for line in lines.reversed() {
                    if let match = line.range(of: pattern, options: .regularExpression) {
                        // Return only the matched value (e.g., '0.64 kg CO₂e')
                        return String(line[match])
                    }
                }
                // Fallback: last line containing 'kg'
                if let line = lines.reversed().first(where: { $0.lowercased().contains("kg") }) {
                    if let match = line.range(of: pattern, options: .regularExpression) {
                        return String(line[match])
                    }
                    return line
                }
                // Fallback: return the last non-empty line
                if let last = lines.reversed().first(where: { !$0.isEmpty }) {
                    return last
                }
                // Fallback: return the whole text
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("❌ Gemini API error: \(error)")
        }
        return nil
    }
} 

extension GeminiService {
    func sendPrompt(_ prompt: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }
        throw NSError(domain: "GeminiService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No text response from Gemini"])
    }

    func fetchCarbonFootprintBreakdown(for product: ProductInfo) async throws -> CarbonFootprintResult? {
        let prompt = """
Given the following product details, estimate the total carbon footprint in kilograms of CO₂ equivalent (kg CO₂e) for the product. Also, provide an eco-friendly label (Eco-Friendly or Not Eco-Friendly). Use the product's packaging, ingredients, quantity, and ecoScoreGrade to make your estimate. Do not use a default value. If information is missing, make your best estimate based on what is provided. Carefully analyze the provided product details. Your answer must be based on these details. Return the result in the following JSON format:
{
  \"total_kg_co2e\": <number, e.g. 0.15>,
  \"eco_friendly_label\": \"<Eco-Friendly or Not Eco-Friendly>\"
}
Product details:
- Name: \(product.nutrition?.item_name ?? "")
- Packaging: \(product.packaging ?? "")
- Ingredients: \(product.ingredients ?? "")
- Quantity: \(product.quantity ?? "")
- EcoScore Grade: \(product.ecoScoreGrade ?? "")
"""
        print("Gemini prompt for \(product.nutrition?.item_name ?? ""): \n\(prompt)")
        let response = try await self.sendPrompt(prompt)
        print("Gemini raw response for \(product.nutrition?.item_name ?? ""): \n\(response)")
        if let jsonString = extractJSON(from: response),
           let data = jsonString.data(using: String.Encoding.utf8) {
            let decoder = JSONDecoder()
            if let result = try? decoder.decode(CarbonFootprintResult.self, from: data) {
                return result
            }
        }
        return nil
    }
}

private func extractJSON(from text: String) -> String? {
    guard let start = text.firstIndex(of: "{"),
          let end = text.lastIndex(of: "}") else { return nil }
    return String(text[start...end])
} 

