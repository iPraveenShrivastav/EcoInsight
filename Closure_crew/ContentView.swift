//
//  ContentView.swift
//  Closure_crew
//
//  Created by isdp on 09/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var historyViewModel = HistoryViewModel()
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency // UI only - no logic change: iOS 26 accessibility support
    
    init() {
        LocalDatabaseManager.shared.copyBundleFileIfNeeded()
    }
    
    var body: some View {
        TabView {
            DashboardView(historyViewModel: historyViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "globe.americas.fill")
                }
                .onAppear {
                    print("📱 ContentView: Dashboard tab appeared")
                }
            
            ScanView(historyViewModel: historyViewModel)
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
                .onAppear {
                    print("📱 ContentView: Scan tab appeared")
                }
            
            HistoryView(viewModel: historyViewModel)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .onAppear {
                    print("📱 ContentView: History tab appeared")
                }
        }
        .accentColor(.green)
        .background(.ultraThinMaterial.opacity(reduceTransparency ? 0 : 0.8)) // UI only - no logic change: Material background with accessibility support
        .onChange(of: historyViewModel.scannedProducts.count) { count in
            print("📱 ContentView: Products count changed to \(count)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
