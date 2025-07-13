import Foundation

class HistoryStorage {
    private let historyKey = "scanHistory"
    
    func save(_ products: [Product]) {
        print("💾 HistoryStorage: Saving \(products.count) products")
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(products)
            UserDefaults.standard.set(data, forKey: historyKey)
            print("💾 HistoryStorage: Successfully saved \(products.count) products")
        } catch {
            print("💾 HistoryStorage: Error saving products: \(error)")
            return
        }
    }
    
    func load() -> [Product] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            print("💾 HistoryStorage: No saved data found")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let products = try decoder.decode([Product].self, from: data)
            print("💾 HistoryStorage: Loaded \(products.count) products")
            return products
        } catch {
            print("💾 HistoryStorage: Error loading products: \(error)")
            return []
        }
    }
    
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
        // Immediately save an empty array to ensure observers update
        save([])
    }
} 