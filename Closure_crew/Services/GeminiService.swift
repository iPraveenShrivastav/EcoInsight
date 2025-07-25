import Foundation

class GeminiService {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func estimateCarbon(for productInfo: ProductInfo) async -> String? {
        let prompt = """
Given the following product details, estimate the total carbon footprint in kilograms of CO₂ equivalent (kg CO₂e) for the product, and determine if it is eco-friendly or not. 
Base your answer strictly on the product's packaging, ingredients, and quantity. 
If the packaging is recyclable, minimal, or compostable, and the ingredients are plant-based or have low environmental impact, label as "Eco-Friendly". Otherwise, label as "Not Eco-Friendly".

Return your answer in the following format, with no explanation or extra text:
<carbon_footprint_value> <eco_friendly_label>

Example:
0.15 Eco-Friendly

Product details:
- Name: \(productInfo.nutrition?.item_name ?? "Unknown")
- Packaging: \(productInfo.packaging ?? "Unknown")
- Ingredients: \(productInfo.ingredients ?? "Unknown")
- Quantity: \(productInfo.quantity ?? "Unknown")
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
                // Extract the last non-empty line
                if let last = text.components(separatedBy: .newlines).map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }).reversed().first(where: { !$0.isEmpty }) {
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
Given the following product details, estimate the total carbon footprint in kilograms of CO₂ equivalent (kg CO₂e) for the product, and determine if it is eco-friendly or not. 
Base your answer strictly on the product's packaging, ingredients, and quantity. 
If the packaging is recyclable, minimal, or compostable, and the ingredients are plant-based or have low environmental impact, label as "Eco-Friendly". Otherwise, label as "Not Eco-Friendly".

Return your answer in the following format, with no explanation or extra text:
<carbon_footprint_value> <eco_friendly_label>

Example:
0.15 Eco-Friendly

Product details:
- Name: \(product.nutrition?.item_name ?? "")
- Packaging: \(product.packaging ?? "")
- Ingredients: \(product.ingredients ?? "")
- Quantity: \(product.quantity ?? "")
"""
        print("Gemini prompt for \(product.nutrition?.item_name ?? ""): \n\(prompt)")
        let response = try await self.sendPrompt(prompt)
        print("Gemini raw response for \(product.nutrition?.item_name ?? ""): \n\(response)")
        // Parse the last non-empty line
        let lines = response.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let last = lines.reversed().first(where: { !$0.isEmpty }) {
            let parts = last.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            if parts.count == 2, let value = Double(parts[0]) {
                let label = String(parts[1])
                return CarbonFootprintResult(
                    totalKgCO2e: value,
                    breakdown: CarbonFootprintResult.Breakdown(productionPercent: 0, packagingPercent: 0, transportPercent: 0),
                    ecoFriendlyLabel: label
                )
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

