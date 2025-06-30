//
//  ContentView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        MainView()
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
                // record main page view - PV tracking
                AnalyticsManager.shared.logPageView(PageName.main.rawValue)
            }
    }
}

#Preview {
    ContentView()
}
