//
//  PromptPalApp.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI
import SwiftData

@main
struct PromptPalApp: App {
    /// SwiftData 模型容器
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Prompt.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        // 主窗口
        WindowGroup("main-window") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .modelContainer(sharedModelContainer)
        .commands {
            AppCommands()
        }
        
        // 设置窗口
        Settings {
            SettingsView()
        }
    }
}

/// 应用菜单命令
struct AppCommands: Commands {
    var body: some Commands {
        // 使用默认的设置菜单项，它会自动调用 Settings 场景
    }
}
