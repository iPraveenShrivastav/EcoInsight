import SwiftUI

struct ProductImpactView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Product Header
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Packaging: \(product.packaging)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Impact Score
            VStack(alignment: .leading, spacing: 12) {
                Text("Environmental Impact")
                    .font(.headline)
                
                HStack {
                    Text("Score:")
                    Spacer()
                    Text(String(format: "%.1f/10", product.environmentalImpact.score))
                        .foregroundColor(scoreColor)
                }
                
                ProgressView(value: product.environmentalImpact.score, total: 10)
                    .tint(scoreColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(title: "Recyclable", value: product.environmentalImpact.recyclable ? "Yes" : "No", icon: "arrow.3.trianglepath")
                DetailRow(title: "Biodegradable", value: product.environmentalImpact.biodegradable ? "Yes" : "No", icon: "leaf")
                DetailRow(title: "Carbon Footprint", value: product.environmentalImpact.carbonFootprint, icon: "smoke")
            }
            
            Spacer()
            
            // Recommendations
            if product.environmentalImpact.score < 5 {
                RecommendationView()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var scoreColor: Color {
        switch product.environmentalImpact.score {
        case 0..<4: return .red
        case 4..<7: return .orange
        default: return .green
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct RecommendationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommendations")
                .font(.headline)
            
            Text("Consider alternatives with:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                BulletPoint(text: "Recyclable packaging")
                BulletPoint(text: "Biodegradable materials")
                BulletPoint(text: "Lower carbon footprint")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
            Text(text)
        }
    }
} 
