//
//  ContentView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        MainView()
            .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
