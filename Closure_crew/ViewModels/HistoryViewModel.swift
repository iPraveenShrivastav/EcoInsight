import Foundation

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var scannedProducts: [Product] = [] // Make @Published public for observation
    private let historyStorage = HistoryStorage()
    
    init() {
        loadHistory()
    }
    
    func addScan(_ product: Product) {
        print("📱 HistoryViewModel: Adding product to history - \(product.name) (barcode: \(product.code))")
        // Prevent duplicate barcodes in history
        if !scannedProducts.contains(where: { $0.code == product.code }) {
            scannedProducts.insert(product, at: 0)
            print("📱 HistoryViewModel: Product added successfully. Total products: \(scannedProducts.count)")
            saveHistory()
        } else {
            print("📱 HistoryViewModel: Product already exists in history, skipping")
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
        loadHistory() // Ensure in-memory and storage are in sync
    }
    
    func loadHistory() {
        print("📱 HistoryViewModel: Loading history from storage")
        scannedProducts = historyStorage.load()
        print("📱 HistoryViewModel: Loaded \(scannedProducts.count) products from storage")
    }
    
    private func saveHistory() {
        print("📱 HistoryViewModel: Saving \(scannedProducts.count) products to storage")
        historyStorage.save(scannedProducts)
    }
} 