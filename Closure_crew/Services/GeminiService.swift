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

