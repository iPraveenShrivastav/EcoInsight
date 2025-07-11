import Foundation
import SwiftUI

struct ProductDetailView: View {
    let productInfo: ProductInfo
    var scannerViewModel: ScannerViewModel? = nil
    var onBack: (() -> Void)? = nil
    @AppStorage("selectedAllergens") private var selectedAllergensRaw: String = ""
    @State private var showingEcoGradeInfo = false
    @State private var selectedEcoGrade: String = ""
    @State private var carbonResult: CarbonFootprintResult?
    @State private var carbonString: String? // fallback for string result
    @State private var isLoadingCarbon = false
    @State private var carbonError: String?
    @Environment(\.presentationMode) private var presentationMode
    
    private var selectedAllergens: Set<String> {
        get { Set(selectedAllergensRaw.split(separator: ",").map { String($0) }) }
        set { selectedAllergensRaw = newValue.joined(separator: ",") }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // REMOVE custom header HStack with chevron and title (if still present)
                // Product Card
                HStack(alignment: .top, spacing: 16) {
                    if let imageUrl = productInfo.productImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 72, height: 72)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 72, height: 72)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        if let name = productInfo.nutrition?.item_name, !name.isEmpty {
                            Text(name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                        }
                        // Show eco-friendly label under product name
                        if let label = ecoFriendlyLabel(), !label.isEmpty {
                            Text(label)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(label == "Eco-Friendly" ? Color.green : Color.red)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)
                // Carbon Footprint Card (always in card)
                Group {
                    if isLoadingCarbon {
                        ProgressView("Loading carbon data...")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                    } else if let carbon = carbonResult {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Carbon Footprint")
                                .font(.headline)
                                .foregroundColor(.black)
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(String(format: "%.3f", carbon.totalKgCO2e))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                Text("kg CO₂e")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    } else if let carbonString = carbonString {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Carbon Footprint")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text(parseCO2eValue(from: carbonString))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    } else if let error = carbonError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                    }
                }
                // Nutrition Facts Card
                if let facts = productInfo.nutrition {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Facts")
                            .font(.headline)
                            .foregroundColor(.black)
                        HStack(spacing: 16) {
                            nutritionFactCard(label: "Calories", value: "\(facts.nf_calories ?? 0)", unit: "kcal")
                            nutritionFactCard(label: "Protein", value: "\(facts.nf_protein ?? 0)", unit: "g")
                        }
                        HStack(spacing: 16) {
                            nutritionFactCard(label: "Sugar", value: "\(facts.nf_sugars ?? 0)", unit: "g")
                            nutritionFactCard(label: "Fat", value: "\(facts.nf_total_fat ?? 0)", unit: "g")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
                // Allergen Warning Card (based on ingredients)
                if let userAllergensRaw = UserDefaults.standard.string(forKey: "selectedAllergens"),
                   !userAllergensRaw.isEmpty {
                    let userAllergens = Set(userAllergensRaw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                    let productIngredients = (productInfo.ingredients ?? "").lowercased()
                    let matching = userAllergens.filter { productIngredients.contains($0) }
                    if !matching.isEmpty {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Contains: \(matching.sorted().joined(separator: ", ").capitalized)")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.brown)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.18))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                }
                // Allergen Alert Card
                if let allergens = productInfo.allergens {
                    let matching = Set(allergens).intersection(selectedAllergens)
                    if !matching.isEmpty {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.brown)
                            Text("Contains: \(matching.sorted().joined(separator: ", "))")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.brown)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.18))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                }
                Spacer(minLength: 24)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            // No background color here; let system default show through
        }
        .navigationTitle("Product Insights")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await fetchCarbonResult()
            }
        }
    }
    
    private func fetchCarbonResult() async {
        guard let scannerViewModel = scannerViewModel else { return }
        isLoadingCarbon = true
        carbonError = nil
        carbonResult = nil
        carbonString = nil
        do {
            // Check if product is in history and has a carbon value
            if let historyProduct = scannerViewModel.historyViewModel.scannedProducts.first(where: { $0.code == productInfo.barcode }),
               let savedValue = historyProduct.geminiCarbonResult, !savedValue.isEmpty {
                carbonString = savedValue
                isLoadingCarbon = false
                return
            }
            let prompt = """
Given the following product details, estimate the total carbon footprint in kilograms of CO₂ equivalent (kg CO₂e) for the product. Also, provide an eco-friendly label (Eco-Friendly or Not Eco-Friendly). Use the product's packaging, ingredients, quantity, and ecoScoreGrade to make your estimate. Do not use a default value. If information is missing, make your best estimate based on what is provided. Carefully analyze the provided product details. Your answer must be based on these details. Return the result in the following JSON format:
{
  \"total_kg_co2e\": <number, e.g. 0.15>,
  \"eco_friendly_label\": \"<Eco-Friendly or Not Eco-Friendly>\"
}
Product details:
- Name: \(productInfo.nutrition?.item_name ?? "")
- Packaging: \(productInfo.packaging ?? "")
- Ingredients: \(productInfo.ingredients ?? "")
- Quantity: \(productInfo.quantity ?? "")
- EcoScore Grade: \(productInfo.ecoScoreGrade ?? "")
"""
            let response = try await scannerViewModel.geminiService.sendPrompt(prompt)
            print("Gemini raw response for \(productInfo.nutrition?.item_name ?? ""): \n\(response)")
            if let jsonString = extractJSON(from: response),
               let data = jsonString.data(using: String.Encoding.utf8) {
                let decoder = JSONDecoder()
                if let result = try? decoder.decode(CarbonFootprintResult.self, from: data) {
                    carbonResult = result
                    // Save to history in kg
                    scannerViewModel.saveCarbonResultToHistory(for: productInfo, value: String(format: "%.2f kg CO₂e", result.totalKgCO2e))
                } else if let value = extractFinalCO2e(from: response) {
                    carbonString = value
                    scannerViewModel.saveCarbonResultToHistory(for: productInfo, value: value)
                } else {
                    carbonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if let value = extractFinalCO2e(from: response) {
                carbonString = value
                scannerViewModel.saveCarbonResultToHistory(for: productInfo, value: value)
            } else {
                carbonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            carbonError = error.localizedDescription
        }
        isLoadingCarbon = false
    }
    // Helper to extract JSON from Gemini response
    private func extractJSON(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        return String(text[start...end])
    }
    // Helper to extract the final CO2e value from Gemini response
    private func extractFinalCO2e(from response: String) -> String? {
        let lines = response.components(separatedBy: .newlines)
        for line in lines.reversed() {
            if line.lowercased().contains("total carbon footprint:") {
                let pattern = #"([0-9]+\.?[0-9]*)\s*kg\s*CO[2₂]e"#
                if let match = line.range(of: pattern, options: .regularExpression) {
                    return String(line[match])
                }
            }
        }
        let pattern = #"([0-9]+\.?[0-9]*)\s*kg\s*CO[2₂]e"#
        if let match = response.range(of: pattern, options: .regularExpression) {
            return String(response[match])
        }
        return nil
    }
    
    private func nutritionFactCard(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                Text(unit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
    }
    // Add this helper to parse only the value from a JSON string or code block
    private func parseCO2eValue(from string: String) -> String {
        return string
    }
    // Add this helper to determine the eco-friendly label
    private func ecoFriendlyLabel() -> String? {
        if let label = carbonResult?.ecoFriendlyLabel, !label.isEmpty {
            return label
        }
        // Fallback: check packaging
        let packaging = productInfo.packaging?.lowercased() ?? ""
        if packaging.contains("plastic") {
            return "Not Eco-Friendly"
        } else if !packaging.isEmpty {
            return "Eco-Friendly"
        }
        return nil
    }
    // EcoGradeInfoSheet and other views remain unchanged...
}

struct EcoGradeInfoSheet: View {
    let grade: String
    @Environment(\.dismiss) private var dismiss
    
    var ecoGradeInfo: EcoGradeInfo {
        EcoGradeInfo(grade: grade)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with grade
                    VStack(spacing: 16) {
                        Image(systemName: ecoGradeInfo.icon)
                            .font(.system(size: 60))
                            .foregroundColor(ecoGradeInfo.color)
                        
                        Text(ecoGradeInfo.displayGrade)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(ecoGradeInfo.color)
                        
                        Text(ecoGradeInfo.description)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // What this grade means
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What This Grade Means")
                            .font(.headline)
                        
                        Text(gradeExplanation)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Environmental impact factors
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Environmental Impact Factors")
                            .font(.headline)
                        
                        ForEach(impactFactors, id: \.self) { factor in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ecoGradeInfo.color)
                                Text(factor)
                                    .font(.body)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Tips for better choices
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips for Better Environmental Choices")
                            .font(.headline)
                        
                        ForEach(environmentalTips, id: \.self) { tip in
                            HStack(alignment: .top) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .padding(.top, 2)
                                Text(tip)
                                    .font(.body)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("Eco Grade Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var gradeExplanation: String {
        switch grade.uppercased() {
        case "A":
            return "Products with grade A have excellent environmental performance. They typically use sustainable ingredients, eco-friendly packaging, and have minimal carbon footprint throughout their lifecycle."
        case "B":
            return "Grade B products show good environmental practices. They generally use responsible sourcing and have moderate environmental impact, making them good choices for conscious consumers."
        case "C":
            return "Grade C represents average environmental impact. These products meet basic standards but have room for improvement in sustainability practices and packaging choices."
        case "D":
            return "Grade D indicates poor environmental performance. These products may use unsustainable ingredients, excessive packaging, or have high carbon footprint, requiring significant improvements."
        case "E":
            return "Grade E represents very poor environmental impact. These products typically have major sustainability issues and should be avoided when better alternatives are available."
        default:
            return "This grade indicates unknown or unavailable environmental impact data. Consider choosing products with known eco grades when possible."
        }
    }
    
    private var impactFactors: [String] {
        switch grade.uppercased() {
        case "A":
            return [
                "Sustainable ingredient sourcing",
                "Minimal carbon footprint",
                "Eco-friendly packaging",
                "Reduced water usage",
                "Low waste production"
            ]
        case "B":
            return [
                "Good ingredient practices",
                "Moderate environmental impact",
                "Recyclable packaging",
                "Efficient resource use",
                "Responsible manufacturing"
            ]
        case "C":
            return [
                "Standard ingredient sourcing",
                "Average environmental impact",
                "Mixed packaging materials",
                "Moderate resource usage",
                "Basic sustainability practices"
            ]
        case "D":
            return [
                "Questionable ingredient sources",
                "High environmental impact",
                "Non-recyclable packaging",
                "Excessive resource usage",
                "Poor sustainability practices"
            ]
        case "E":
            return [
                "Unsustainable ingredients",
                "Very high environmental impact",
                "Harmful packaging materials",
                "Excessive resource consumption",
                "Minimal sustainability efforts"
            ]
        default:
            return [
                "Unknown environmental factors",
                "Limited sustainability data",
                "Unclear packaging impact",
                "Uncertain resource usage",
                "No verified eco practices"
            ]
        }
    }
    
    private var environmentalTips: [String] {
        switch grade.uppercased() {
        case "A":
            return [
                "Continue choosing grade A products",
                "Share your eco-friendly choices with others",
                "Support brands with strong sustainability practices",
                "Consider local alternatives to reduce transport impact"
            ]
        case "B":
            return [
                "Look for grade A alternatives when available",
                "Support brands improving their eco practices",
                "Consider the full lifecycle impact of products",
                "Choose products with better packaging options"
            ]
        case "C":
            return [
                "Seek out grade A or B alternatives",
                "Prioritize products with recyclable packaging",
                "Choose locally sourced products when possible",
                "Support brands with clear sustainability goals"
            ]
        case "D":
            return [
                "Strongly consider grade A-C alternatives",
                "Avoid products with excessive packaging",
                "Choose products with clear eco certifications",
                "Support brands actively improving sustainability"
            ]
        case "E":
            return [
                "Avoid these products when possible",
                "Look for certified eco-friendly alternatives",
                "Choose products with transparent sustainability data",
                "Support brands with strong environmental commitments"
            ]
        default:
            return [
                "Look for products with known eco grades",
                "Choose products with clear sustainability information",
                "Support brands with transparent environmental data",
                "Consider the overall environmental impact of your choices"
            ]
        }
    }
}

// Reusable EcoGradeView component
struct EcoGradeView: View {
    let grade: String?
    let showDetails: Bool
    
    init(grade: String?, showDetails: Bool = true) {
        self.grade = grade
        self.showDetails = showDetails
    }
    
    var ecoGradeInfo: EcoGradeInfo {
        EcoGradeInfo(grade: grade)
    }
    
    var body: some View {
        VStack(spacing: showDetails ? 12 : 8) {
            HStack(spacing: 12) {
                Image(systemName: ecoGradeInfo.icon)
                    .font(showDetails ? .title : .title2)
                    .foregroundColor(ecoGradeInfo.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(showDetails ? "Environmental Impact" : "Eco Grade")
                        .font(showDetails ? .headline : .subheadline)
                        .foregroundColor(.primary)
                    
                    if showDetails {
                        Text(ecoGradeInfo.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if showDetails {
                        Text("Grade")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(ecoGradeInfo.displayGrade)
                        .font(showDetails ? .title : .headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: showDetails ? 50 : 40, height: showDetails ? 50 : 40)
                        .background(ecoGradeInfo.color)
                        .clipShape(Circle())
                }
            }
            
            if showDetails {
                // Environmental impact indicators
                HStack(spacing: 16) {
                    Label("Low Carbon", systemImage: "leaf.fill")
                        .font(.caption)
                        .foregroundColor(ecoGradeInfo.color)
                    
                    Label("Sustainable", systemImage: "leaf")
                        .font(.caption)
                        .foregroundColor(ecoGradeInfo.color)
                }
            }
        }
        .padding(showDetails ? 16 : 12)
        .background(ecoGradeInfo.color.opacity(0.1))
        .cornerRadius(showDetails ? 16 : 12)
        .overlay(
            RoundedRectangle(cornerRadius: showDetails ? 16 : 12)
                .stroke(ecoGradeInfo.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Environmental impact grade: \(ecoGradeInfo.displayGrade), \(ecoGradeInfo.description)")
    }
}

struct AllergenAlert: View {
    let allergens: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Allergen Warning", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Contains: \(allergens.joined(separator: ", "))")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.red)
        .cornerRadius(10)
        .accessibilityLabel("Allergen warning: Contains \(allergens.joined(separator: ", "))")
    }
}

struct CarbonFootprintSection: View {
    let carbonResponse: CarbonResponse?
    let geminiResult: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carbon Footprint")
                .font(.headline)
            
            if let carbon = carbonResponse {
                Text("\(String(format: "%.2f", carbon.co2e)) kg CO2e")
                    .font(.title2)
                    .foregroundColor(.green)
                
                ForEach(carbon.co2e_breakdown, id: \.scope) { breakdown in
                    HStack {
                        Text(breakdown.scope.capitalized)
                        Spacer()
                        Text("\(String(format: "%.2f", breakdown.co2e)) kg CO2e")
                            .foregroundColor(.secondary)
                    }
                }
            } else if let geminiResult = geminiResult {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                    Text("AI Estimate:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(geminiResult)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            } else {
                Text("Carbon data not available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
    }
}

struct NutritionFactsSection: View {
    let nutritionFacts: NutritionFacts?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Facts")
                .font(.headline)
            
            if let facts = nutritionFacts {
                VStack(alignment: .leading, spacing: 8) {
                    NutritionRow(label: "Calories", value: String(format: "%.0f", facts.nf_calories))
                    NutritionRow(label: "Total Fat", value: String(format: "%.1fg", facts.nf_total_fat))
                    NutritionRow(label: "Protein", value: String(format: "%.1fg", facts.nf_protein))
                    NutritionRow(label: "Total Carbohydrates", value: String(format: "%.1fg", facts.nf_total_carbohydrate))
                    NutritionRow(label: "Sugars", value: String(format: "%.1fg", facts.nf_sugars))
                }
            } else {
                Text("Nutrition data not available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("\(label): \(value)")
    }
}

struct IngredientsSection: View {
    let ingredients: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
            Text(ingredients)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
    }
}

struct EcoScoreBadge: View {
    let grade: String
    
    var ecoGradeInfo: EcoGradeInfo {
        EcoGradeInfo(grade: grade)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: ecoGradeInfo.icon)
                    .font(.title)
                    .foregroundColor(ecoGradeInfo.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Environmental Impact")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(ecoGradeInfo.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Grade")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(ecoGradeInfo.displayGrade)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(ecoGradeInfo.color)
                        .clipShape(Circle())
                }
            }
            
            // Additional environmental indicators
            HStack(spacing: 16) {
                Label("Low Carbon", systemImage: "leaf.fill")
                    .font(.caption)
                    .foregroundColor(ecoGradeInfo.color)
                
                Label("Sustainable", systemImage: "leaf")
                    .font(.caption)
                    .foregroundColor(ecoGradeInfo.color)
            }
        }
        .padding(16)
        .background(ecoGradeInfo.color.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ecoGradeInfo.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Environmental impact grade: \(ecoGradeInfo.displayGrade), \(ecoGradeInfo.description)")
    }
}



struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailView(productInfo: ProductInfo(
            barcode: "1234567890",
            nutrition: NutritionFacts(
                item_name: "Sample Product",
                nf_calories: 250,
                nf_total_fat: 10,
                nf_protein: 5,
                nf_total_carbohydrate: 30,
                nf_sugars: 15
            ),
            carbon: CarbonResponse(
                co2e: 1.23,
                co2e_breakdown: [
                    Breakdown(scope: "production", co2e: 0.8),
                    Breakdown(scope: "transport", co2e: 0.43)
                ]
            ),
            allergens: ["Peanuts", "Soy"]
        ))
    }
}
