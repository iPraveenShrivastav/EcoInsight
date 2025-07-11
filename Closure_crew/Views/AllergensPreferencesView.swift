import SwiftUI

struct AllergensPreferencesView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("selectedAllergens") private var selectedAllergensString: String = ""
    @State private var selectedAllergens: Set<String> = []
    @State private var customAllergen: String = ""
    @State private var showSustainableOnly: Bool = true

    let commonAllergens = [
        ("Dairy", "drop.fill"), // changed from carton.fill
        ("Nuts", "carrot.fill"),
        ("Gluten", "circle.grid.3x3.fill"),
        ("Soy", "leaf.fill"),
        ("Eggs", "circle.fill"), // changed from egg.fill
        ("Fish", "fish.fill")
    ]

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Common Allergens
                Text("Common Allergens")
                    .font(.headline)
                    .foregroundColor(.black)
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(commonAllergens, id: \.0) { (name, icon) in
                        Button(action: {
                            if selectedAllergens.contains(name) {
                                selectedAllergens.remove(name)
                            } else {
                                selectedAllergens.insert(name)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: icon)
                                Text(name)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedAllergens.contains(name) ? Color.green : Color(.systemGray6))
                            .foregroundColor(selectedAllergens.contains(name) ? .white : .primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(selectedAllergens.contains(name) ? Color.green : Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                }
                // Custom Allergens
                Text("Custom Allergens")
                    .font(.headline)
                    .foregroundColor(.black)
                HStack {
                    TextField("Add custom allergen", text: $customAllergen)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        let trimmed = customAllergen.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !selectedAllergens.contains(trimmed) {
                            selectedAllergens.insert(trimmed)
                            customAllergen = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                // Show custom allergens as bubbles with remove "x"
                if !selectedAllergens.subtracting(commonAllergens.map { $0.0 }).isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(Array(selectedAllergens.subtracting(commonAllergens.map { $0.0 })).sorted(), id: \.self) { allergen in
                                HStack(spacing: 6) {
                                    Text(allergen)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .frame(minWidth: 44, maxWidth: 120, minHeight: 24)
                                    Button(action: {
                                        selectedAllergens.remove(allergen)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                // Sustainable Alternatives Toggle
                HStack {
                    VStack(alignment: .leading) {
                        Text("Only show sustainable alternatives")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text("Filter products with lower carbon footprint")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $showSustainableOnly)
                        .labelsHidden()
                }
                Spacer(minLength: 0)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Allergens & Preferences")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Load from storage
            let saved = selectedAllergensString.split(separator: ",").map { String($0) }
            selectedAllergens = Set(saved)
        }
        .onChange(of: selectedAllergens) { newValue in
            // Save to storage
            selectedAllergensString = newValue.joined(separator: ",")
        }
    }
}

// Preview
struct AllergensPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AllergensPreferencesView()
        }
    }
} 