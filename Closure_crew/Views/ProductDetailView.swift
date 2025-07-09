import SwiftUI

struct ProductDetailView: View {
    let productInfo: ProductInfo
    @AppStorage("selectedAllergens") private var selectedAllergensRaw: String = ""
    
    private var selectedAllergens: Set<String> {
        get { Set(selectedAllergensRaw.split(separator: ",").map { String($0) }) }
        set { selectedAllergensRaw = newValue.joined(separator: ",") }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Allergen Alerts
                if let allergens = productInfo.allergens {
                    let matching = Set(allergens).intersection(selectedAllergens)
                    if !matching.isEmpty {
                        AllergenAlert(allergens: Array(matching))
                    }
                }
                
                // Carbon Footprint
                CarbonFootprintSection(carbonResponse: productInfo.carbon)
                
                // Nutrition Facts
                NutritionFactsSection(nutritionFacts: productInfo.nutrition)
                
                // Attribution
                Text("Data provided by Nutritionix")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Product Details")
        .accessibilityElement(children: .contain)
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
