//
//  ContentView.swift
//  Closure_crew
//
//  Created by isdp on 09/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var historyViewModel = HistoryViewModel()
    
    init() {
        LocalDatabaseManager.shared.copyBundleFileIfNeeded()
    }
    
    var body: some View {
        TabView {
            DashboardView(historyViewModel: historyViewModel)
                .tabItem {
                    Label("EcoScan", systemImage: "globe.americas.fill")
                }
            
            ScanView(historyViewModel: historyViewModel)
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
            
            HistoryView(viewModel: historyViewModel)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
        .accentColor(.green)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
