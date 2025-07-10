import Foundation

@MainActor
class HistoryViewModel: ObservableObject {
    @Published private(set) var scannedProducts: [Product] = []
    private let historyStorage = HistoryStorage()
    
    init() {
        loadHistory()
    }
    
    func addScan(_ product: Product) {
        // Prevent duplicate barcodes in history
        if !scannedProducts.contains(where: { $0.code == product.code }) {
            scannedProducts.insert(product, at: 0)
            saveHistory()
        }
    }
    
    func deleteProduct(at offsets: IndexSet) {
        scannedProducts.remove(atOffsets: offsets)
        saveHistory()
    }
    
    func deleteProduct(_ product: Product) {
        if let index = scannedProducts.firstIndex(where: { $0.id == product.id }) {
            scannedProducts.remove(at: index)
            saveHistory()
        }
    }
    
    func clearHistory() {
        scannedProducts.removeAll()
        historyStorage.clearHistory()
    }
    
    private func loadHistory() {
        scannedProducts = historyStorage.load()
    }
    
    private func saveHistory() {
        historyStorage.save(scannedProducts)
    }
} 