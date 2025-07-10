import SwiftUI

struct ProductDetailView: View {
    let productInfo: ProductInfo
    var scannerViewModel: ScannerViewModel? = nil
    @AppStorage("selectedAllergens") private var selectedAllergensRaw: String = ""
    @State private var showingEcoGradeInfo = false
    @State private var selectedEcoGrade: String = ""
    
    private var selectedAllergens: Set<String> {
        get { Set(selectedAllergensRaw.split(separator: ",").map { String($0) }) }
        set { selectedAllergensRaw = newValue.joined(separator: ",") }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Product Image
                if let imageUrl = productInfo.productImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 180)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 180)
                                .cornerRadius(16)
                                .shadow(radius: 6)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.top, 8)
                }
                // Product Name
                if let name = productInfo.nutrition?.item_name, !name.isEmpty {
                    Text(name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                // EcoScore Badge
                if let ecoScore = productInfo.ecoScoreGrade {
                    EcoScoreBadge(grade: ecoScore)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                        .onTapGesture {
                            // Show detailed eco grade information
                            showEcoGradeInfo(ecoScore)
                        }
                }

                // Quantity & Packaging
                HStack(spacing: 16) {
                    if let quantity = productInfo.quantity, !quantity.isEmpty {
                        Label(quantity, systemImage: "scalemass")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let packaging = productInfo.packaging, !packaging.isEmpty {
                        Label(packaging.capitalized, systemImage: "shippingbox")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                // Only show packaging tags if they add extra info
                if let tags = productInfo.packagingTags, !tags.isEmpty {
                    let cleanTags = tags.map { $0.replacingOccurrences(of: "en:", with: "").capitalized }
                    let mainPackaging = productInfo.packaging?.lowercased() ?? ""
                    let filteredTags = cleanTags.filter { !mainPackaging.contains($0.lowercased()) }
                    if !filteredTags.isEmpty {
                        HStack {
                            ForEach(filteredTags.prefix(2), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                // Allergen Alerts
                if let allergens = productInfo.allergens {
                    let matching = Set(allergens).intersection(selectedAllergens)
                    if !matching.isEmpty {
                        AllergenAlert(allergens: Array(matching))
                    }
                }
                // Carbon Footprint
                CarbonFootprintSection(
                    carbonResponse: productInfo.carbon,
                    geminiResult: scannerViewModel?.geminiCarbonResult
                )
                // Ingredients Section
                if let ingredients = productInfo.ingredients, !ingredients.isEmpty {
                    IngredientsSection(ingredients: ingredients)
                }
                // Nutrition Facts
                NutritionFactsSection(nutritionFacts: productInfo.nutrition)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Product Details")
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $showingEcoGradeInfo) {
            EcoGradeInfoSheet(grade: selectedEcoGrade)
        }
    }
    
    private func showEcoGradeInfo(_ grade: String) {
        selectedEcoGrade = grade
        showingEcoGradeInfo = true
    }
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
