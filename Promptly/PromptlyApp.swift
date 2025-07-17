//
//  PromptlyApp.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI
import FirebaseCore
import FirebaseAnalytics


class AppDelegate: NSObject, NSApplicationDelegate {
    var modelContainer: ModelContainer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // configure Firebase
        FirebaseApp.configure()
        
        // enable Analytics with native Installation ID (stored in keychain)
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // set up analytics on main thread
        Task { @MainActor in
            configureAnalytics()
        }
        
        print("📊 Analytics: PV/UV tracking enabled with Firebase Installation ID")
    }
    
    @MainActor
    private func configureAnalytics() {
        // setup simplified analytics manager
        AnalyticsManager.shared.setupLifecycleTracking()
        
        // Version information collection will be handled in startSession
        print("📊 Analytics: ready for PV/UV tracking")
        
        // Setup periodic cleanup for recycle bin
        setupRecycleBinCleanup()
    }
    
    @MainActor
    private func setupRecycleBinCleanup() {
        // Create a timer that runs every 6 hours to cleanup expired items
        Timer.scheduledTimer(withTimeInterval: 6 * 60 * 60, repeats: true) { _ in
            Task { @MainActor in
                // Get the shared model container from the app delegate
                if let app = NSApplication.shared.delegate as? AppDelegate,
                   let modelContainer = app.modelContainer {
                    let modelContext = modelContainer.mainContext
                    let recycleBinManager = RecycleBinManager(modelContext: modelContext)
                    do {
                        try recycleBinManager.cleanupExpiredItems()
                    } catch {
                        print("Background cleanup failed: \(error)")
                    }
                }
            }
        }
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        print("📊 App Version: \(version)")
        return version
    }
}

@main
struct PromptlyApp: App {
    // register app delegate for Firebase setup
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // SwiftData model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Prompt.self,
            Category.self,
            RecycleBinItem.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

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
                .onAppear {
                    // Set the model container reference in the app delegate
                    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.modelContainer = sharedModelContainer
                    }
                }
        }
        .windowResizability(.contentSize)
        .modelContainer(sharedModelContainer)
        .commands {
            AppCommands()
        }
        
        // settings window
        Settings {
            SettingsView()
                .onAppear {
                    // record settings page view
                    AnalyticsManager.shared.logPageView(PageName.settings.rawValue)
                }
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
