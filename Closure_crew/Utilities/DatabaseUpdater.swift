import Foundation

@MainActor
class DatabaseUpdater {
    static func updateDatabase() async {
        let service = BarcodeLookupService()
        
        do {
            print("Starting database update...")
            let products = try await service.fetchAllProducts()
            
            if products.isEmpty {
                print("No products were fetched. Keeping existing database.")
                return
            }
            
            let database = ProductDatabase(products: products)
            
            // Get the documents directory path
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Could not access documents directory")
                return
            }
            
            let fileURL = documentsDirectory.appendingPathComponent("indian_products.json")
            
            // Convert to JSON and write to file
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(database)
            
            // Write to documents directory
            try jsonData.write(to: fileURL)
            
            // Verify the file was written
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // Read back and print the contents to verify
                let savedData = try Data(contentsOf: fileURL)
                if let jsonString = String(data: savedData, encoding: .utf8) {
                    print("Successfully updated database. Contents:")
                    print(jsonString)
                }
                print("Database updated at: \(fileURL.path)")
                print("Added \(products.count) products")
            } else {
                print("Error: File was not created")
            }
            
        } catch {
            print("Error updating database: \(error)")
        }
    }
    
    // Call this function to trigger the update
    static func updateDatabaseFromAPI() {
        Task {
            print("Starting database update...")
            await updateDatabase()
        }
    }
} 