import Foundation

class HistoryStorage {
    private let historyKey = "scanHistory"
    
    func save(_ products: [Product]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(products)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            return
        }
    }
    
    func load() -> [Product] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Product].self, from: data)
        } catch {
            return []
        }
    }
    
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
} 