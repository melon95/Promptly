//
//  PromptlyApp.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI
import SwiftData

@main
struct PromptlyApp: App {
    // SwiftData model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Prompt.self,
            Category.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        // main window
        WindowGroup("Promptly") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .modelContainer(sharedModelContainer)
        .commands {
            AppCommands()
        }
        
        // settings window
        Settings {
            SettingsView()
        }
    }
}

// app menu commands
struct AppCommands: Commands {
    var body: some Commands {
        // file menu
        CommandGroup(replacing: .newItem) {
                                    Button("New Prompt".localized) {
                NotificationCenter.default.post(name: .showAddPrompt, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        
        // edit menu
        CommandGroup(after: .pasteboard) {
            Divider()
            
                                    Button("Toggle Quick Access".localized) {
                NotificationCenter.default.post(name: .toggleQuickAccess, object: nil)
            }
            .keyboardShortcut("p", modifiers: [.option])
        }
        
        // view menu
        CommandGroup(after: .toolbar) {
                                    Button("Focus Search".localized) {
                NotificationCenter.default.post(name: .focusSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
            
            Button("Show Favorites".localized) {
                NotificationCenter.default.post(name: .showFavorites, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let showAddPrompt = Notification.Name("showAddPrompt")
    static let toggleQuickAccess = Notification.Name("toggleQuickAccess")
    static let focusSearch = Notification.Name("focusSearch")
    static let showFavorites = Notification.Name("showFavorites")
}
