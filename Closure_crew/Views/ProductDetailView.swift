import Foundation
import SwiftUI

struct AlternativeProduct: Identifiable {
    let id = UUID()
    let name: String
    let brandOrType: String
    let imageUrl: String
    let description: String
    let nutrition: [String: String]?
    let allergens: [String]?
    let barcode: String
}

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
    var alternatives: [AlternativeProduct]? = nil
    var isAlternative: Bool = false
    @State private var altDetailProduct: ProductInfo? = nil
    @State private var isLoadingAlt: Bool = false
    var onChooseAlternative: ((ProductInfo, String?) -> Void)? = nil // <-- Add replacingBarcode param
    var replacingBarcode: String? = nil // <-- Track which product to replace
    
    private var selectedAllergens: Set<String> {
        get { Set(selectedAllergensRaw.split(separator: ",").map { String($0) }) }
        set { selectedAllergensRaw = newValue.joined(separator: ",") }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
        ScrollView {
            VStack(spacing: 20) {
                    productCard
                    carbonFootprintCard
                    nutritionFactsCard
                    allergenWarningCard
                    if !isAlternative {
                        alternativesSection
                    }
                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
                .padding(.bottom, isAlternative ? 80 : 8) // Add space for button if needed
            }
            .navigationTitle("Product Insights")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $altDetailProduct) { altProduct in
                NavigationView {
                    ProductDetailView(
                        productInfo: altProduct,
                        scannerViewModel: scannerViewModel,
                        isAlternative: true,
                        onChooseAlternative: onChooseAlternative,
                        replacingBarcode: productInfo.barcode // Pass current product's barcode
                    )
                }
            }
            .onAppear {
                Task {
                    await fetchCarbonResult()
                }
            }
            // Sticky button for alternative products
            if isAlternative {
                VStack {
                    Button(action: {
                        if let scannerViewModel = scannerViewModel {
                            // Save to history
                            scannerViewModel.saveProductToHistory(productInfo: productInfo, carbonResult: carbonResult, carbonString: carbonString, replacingBarcode: replacingBarcode)
                        }
                        // Dismiss modal
                        presentationMode.wrappedValue.dismiss()
                        // Notify parent
                        onChooseAlternative?(productInfo, replacingBarcode)
                    }) {
                        Text("Choose This Product")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)
                }
                .background(Color(.systemBackground).opacity(0.95).ignoresSafeArea())
                .transition(.move(edge: .bottom))
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
    
    private var productCard: some View {
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
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(.gray)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        if let name = productInfo.nutrition?.item_name, !name.isEmpty {
                            Text(name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
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
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var carbonFootprintCard: some View {
        Group {
            if isLoadingCarbon {
                ProgressView("Loading carbon data...")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(15)
                    .shadow(radius: 3, x: 0, y: 2)
                    .padding(.horizontal)
            } else if let carbon = carbonResult {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Carbon Footprint")
                            .font(.headline)
                            .foregroundColor(.primary)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(String(format: "%.3f", carbon.totalKgCO2e))
                            .font(.title2.weight(.semibold))
                                .foregroundColor(.primary)
                        Text("kg CO₂e")
                            .font(.body)
                                .foregroundColor(.gray)
                        }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(15)
                .shadow(radius: 3, x: 0, y: 2)
                .padding(.horizontal)
            } else if let carbonString = carbonString {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Carbon Footprint")
                        .font(.headline)
                        .foregroundColor(.primary)
                    // Always use only the last non-empty line, and extract only the first valid number
                    let lastLine = carbonString
                        .components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .last { !$0.isEmpty } ?? carbonString
                    let numberString = lastLine.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
                    if let value = Double(numberString) {
                        Text("\(String(format: "%.3f", value)) kg CO₂e")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                    } else {
                        Text("Not available")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(15)
                .shadow(radius: 3, x: 0, y: 2)
                .padding(.horizontal)
            } else if let error = carbonError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(15)
                    .shadow(radius: 3, x: 0, y: 2)
                    .padding(.horizontal)
            }
        }
                }
                
    private var nutritionFactsCard: some View {
        Group {
                if let facts = productInfo.nutrition {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Facts")
                            .font(.headline)
                            .foregroundColor(.primary)
                    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: gridItems, spacing: 16) {
                        nutritionFactGridCell(label: "Calories", value: "\(facts.nf_calories ?? 0)", unit: "kcal")
                        nutritionFactGridCell(label: "Protein", value: "\(facts.nf_protein ?? 0)", unit: "g")
                        nutritionFactGridCell(label: "Sugar", value: "\(facts.nf_sugars ?? 0)", unit: "g")
                        nutritionFactGridCell(label: "Fat", value: "\(facts.nf_total_fat ?? 0)", unit: "g")
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(15)
                .shadow(radius: 3, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }

    private var allergenWarningCard: some View {
        Group {
            userAllergensWarning
            productAllergensWarning
        }
    }

    private var userAllergensWarning: some View {
        Group {
            if let userAllergensRaw = UserDefaults.standard.string(forKey: "selectedAllergens"),
               !userAllergensRaw.isEmpty {
                let userAllergens = Set(userAllergensRaw.split(separator: ",").map { String($0) })
                let productIngredients = (productInfo.ingredients ?? "").lowercased()
                let matching = userAllergens.filter { productIngredients.contains($0) }
                if !matching.isEmpty {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Contains: \(matching.sorted().joined(separator: ", ").capitalized)")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.brown)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.18))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
            }
        }
                }
                
    private var productAllergensWarning: some View {
        Group {
                if let allergens = productInfo.allergens {
                    let matching = Set(allergens).intersection(selectedAllergens)
                    if !matching.isEmpty {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.brown)
                            Text("Contains: \(matching.sorted().joined(separator: ", "))")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.brown)
                            .multilineTextAlignment(.leading)
                        }
                        .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.18))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                }
        }
    }

    private var alternativesSection: some View {
        Group {
            if !isAlternative {
                if let alternatives = alternatives, !alternatives.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        // Modern header with background
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                // Icon with background
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Allergen-Free Alternatives")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Safer options for your dietary needs")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Badge showing count
                                Text("\(alternatives.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(15)
                        .shadow(radius: 3, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // Alternatives cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(alternatives) { alt in
                                    alternativeCard(for: alt, forceNotEcoFriendly: true)
                                        .frame(width: 300)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        // Modern header with background (same as above, but count is 0)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Allergen-Free Alternatives")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("Safer options for your dietary needs")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("0")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(15)
                        .shadow(radius: 3, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        // No card below
                    }
                }
            }
        }
    }

    // Modified alternativeCard to accept forceNotEcoFriendly
    private func alternativeCard(for alt: AlternativeProduct, forceNotEcoFriendly: Bool = false) -> some View {
        AlternativeImageCard(barcode: alt.barcode, name: alt.name, brandOrType: alt.brandOrType, description: alt.description, onViewDetails: {
            isLoadingAlt = true
            fetchAlternativeProduct(barcode: alt.barcode)
        }, isLoading: isLoadingAlt, forceNotEcoFriendly: forceNotEcoFriendly)
    }

    // Card for 'No alternatives available'
    struct NoAlternativeCard: View {
        var body: some View {
            VStack(alignment: .center, spacing: 24) {
                Spacer(minLength: 12)
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                Text("No alternatives available")
                    .font(.headline)
                    .foregroundColor(.primary)
                HStack {
                    Spacer()
                    Label("Not Eco-Friendly", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .shadow(radius: 3, x: 0, y: 2)
                    Spacer()
                }
                Spacer(minLength: 12)
            }
            .padding(24)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .shadow(radius: 3, x: 0, y: 2)
        }
    }

    // Modified AlternativeImageCard to accept forceNotEcoFriendly
    struct AlternativeImageCard: View {
        let barcode: String
        let name: String
        let brandOrType: String
        let description: String
        let onViewDetails: () -> Void
        let isLoading: Bool
        var forceNotEcoFriendly: Bool = false
        @State private var imageUrl: String? = nil
        @State private var isLoadingImage = false
        @State private var isPressed = false
        @AppStorage("selectedAllergens") private var selectedAllergensRaw: String = ""

        // Allergen logic
        var userAllergens: [String] {
            selectedAllergensRaw.split(separator: ",").map { String($0) }
        }
        var containsAllergen: String? {
            let lowerDesc = description.lowercased()
            return userAllergens.first(where: { !$0.isEmpty && lowerDesc.contains($0) })
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 160)
                                            .frame(maxWidth: .infinity)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 160)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .foregroundColor(.gray)
                                            .frame(height: 160)
                                            .frame(maxWidth: .infinity)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else if isLoadingImage {
                                ProgressView()
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        // Allergen warning badge (if contains allergen and not forced not eco-friendly)
                        if let allergen = containsAllergen, !forceNotEcoFriendly {
                            VStack {
                                HStack {
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 10, weight: .bold))
                                        Text("Contains \(allergen.capitalized)")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.red.opacity(0.9))
                                            .shadow(radius: 3, x: 0, y: 2)
                                    )
                                }
                                .padding(.top, 12)
                                .padding(.trailing, 12)
                                Spacer()
                            }
                        }
                        // Safe badge overlay (if not forced not eco-friendly)
                        if !forceNotEcoFriendly {
                            VStack {
                                HStack {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.shield.fill")
                                            .font(.system(size: 10, weight: .bold))
                                        Text("SAFE")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.9))
                                            .shadow(radius: 3, x: 0, y: 2)
                                    )
                                    Spacer()
                                }
                                .padding(.top, 12)
                                .padding(.leading, 12)
                                Spacer()
                            }
                        }
                    }
                    
                    // Product info section
                    VStack(alignment: .leading, spacing: 12) {
                        // Product name
                        Text(name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        // Brand/Type with icon
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(brandOrType)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        // Description with icon
                        if !description.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                    .padding(.top, 2)
                                
                                Text(description)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.green)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        
                        // Action button
                        Button(action: onViewDetails) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .foregroundColor(.white)
                                } else {
                                    Text("View Details")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 3, x: 0, y: 2)
                        }
                        .disabled(isLoading)
                        .scaleEffect(isPressed ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isPressed)
                        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                            isPressed = pressing
                        }, perform: {})
                    }
                    .padding(20)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .shadow(radius: 3, x: 0, y: 2)
            .onAppear {
                if imageUrl == nil && !isLoadingImage {
                    isLoadingImage = true
                    let service = NutritionService()
                    service.fetchNutrition(for: barcode) { _, _, _, fetchedImageUrl, _, _, _ in
                        DispatchQueue.main.async {
                            self.imageUrl = fetchedImageUrl
                            self.isLoadingImage = false
                        }
                    }
                }
            }
        }
    }
    
    private func fetchCarbonResult() async {
        isLoadingCarbon = true
        carbonError = nil
        carbonResult = nil
        carbonString = nil
        
        // For alternative products, don't save to history
        let shouldSaveToHistory = scannerViewModel != nil && !isAlternative
        
        do {
            // Check if product is in history and has a carbon value (only for non-alternative products)
            if shouldSaveToHistory, let scannerViewModel = scannerViewModel,
               let historyProduct = scannerViewModel.historyViewModel.scannedProducts.first(where: { $0.code == productInfo.barcode }),
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
            
            // Use scannerViewModel's GeminiService if available, otherwise create a temporary one
            let geminiService: GeminiService
            if let scannerViewModel = scannerViewModel {
                geminiService = scannerViewModel.geminiService
            } else {
                geminiService = GeminiService(apiKey: "AIzaSyBFPSpiWUNLvL390wzHI0NUyN7ZDsh5EV0")
            }
            
            let response = try await geminiService.sendPrompt(prompt)
            print("Gemini raw response for \(productInfo.nutrition?.item_name ?? ""): \n\(response)")
            
            if let jsonString = extractJSON(from: response),
               let data = jsonString.data(using: String.Encoding.utf8) {
                let decoder = JSONDecoder()
                if let result = try? decoder.decode(CarbonFootprintResult.self, from: data) {
                    carbonResult = result
                    // Save to history only for non-alternative products
                    if shouldSaveToHistory, let scannerViewModel = scannerViewModel {
                        scannerViewModel.saveCarbonResultToHistory(for: productInfo, value: String(format: "%.2f kg CO₂e", result.totalKgCO2e))
                    }
                } else if let value = extractFinalCO2e(from: response) {
                    carbonString = value
                    if shouldSaveToHistory, let scannerViewModel = scannerViewModel {
                        scannerViewModel.saveCarbonResultToHistory(for: productInfo, value: value)
                    }
                } else {
                    carbonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if let value = extractFinalCO2e(from: response) {
                carbonString = value
                if shouldSaveToHistory, let scannerViewModel = scannerViewModel {
                    scannerViewModel.saveCarbonResultToHistory(for: productInfo, value: value)
                }
            } else {
                carbonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            carbonError = error.localizedDescription
        }
        isLoadingCarbon = false
    }

    private func fetchAlternativeProduct(barcode: String) {
        // Use NutritionService to fetch product info by barcode
        let service = NutritionService()
        service.fetchNutrition(for: barcode) { facts, ingredients, ecoScoreGrade, imageUrl, quantity, packaging, packagingTags in
            DispatchQueue.main.async {
                isLoadingAlt = false
                if let facts = facts {
                    altDetailProduct = ProductInfo(
                        barcode: barcode,
                        nutrition: facts,
                        carbon: nil,
                        allergens: nil,
                        ingredients: ingredients,
                        ecoScoreGrade: ecoScoreGrade,
                        productImageUrl: imageUrl,
                        quantity: quantity,
                        packaging: packaging,
                        packagingTags: packagingTags
                    )
                }
            }
        }
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
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
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

extension ProductDetailView {
    func nutritionFactGridCell(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
