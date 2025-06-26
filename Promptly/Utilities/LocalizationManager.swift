//
//  LocalizationManager.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftUI
import os

// MARK: - Global Localization State

/// A thread-safe wrapper around a `Bundle` instance for localization.
/// This class uses a lock to provide safe mutable access to the bundle
/// from concurrent environments and conforms to `Sendable`.
final class ThreadSafeBundle: @unchecked Sendable {
    private var bundle: Bundle
    private let lock = OSAllocatedUnfairLock()

    init(_ bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func update(to newBundle: Bundle) {
        lock.withLock {
            self.bundle = newBundle
        }
    }

    func localizedString(forKey key: String, value: String?, table: String?) -> String {
        lock.withLock {
            self.bundle.localizedString(forKey: key, value: value, table: table)
        }
    }
}

let currentBundle = ThreadSafeBundle()

// MARK: - LocalizationManager
/// Manages the application's language settings and coordinates UI updates.
///
/// This class is isolated to the main actor to safely handle user interactions
/// and publish changes to the UI.
@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    /// The list of languages supported by the application.
    enum SupportedLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case simplifiedChinese = "zh-Hans"
        
        var id: String { rawValue }
        
        /// The name of the language in its own locale.
        var displayName: String {
            switch self {
            case .english:
                return "English"
            case .simplifiedChinese:
                return "简体中文"
            }
        }
        
        /// The localized name of the language for display in the UI.
        var localizedDisplayName: String {
            switch self {
            case .english:
                return "language.english".localized
            case .simplifiedChinese:
                return "language.chinese".localized
            }
        }
    }
    
    /// The currently selected language, published for SwiftUI views to observe.
    @Published var currentLanguage: SupportedLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selected_language")
            updateCurrentBundle()
            // Notify the user that a restart is needed to fully apply the language change.
            showRestartAlert()
        }
    }
    
    /// A flag to control the visibility of the restart alert, published for SwiftUI views.
    @Published var showingRestartAlert = false
    
    private init() {
        let savedLanguageCode = UserDefaults.standard.string(forKey: "selected_language") ?? ""
        self.currentLanguage = SupportedLanguage(rawValue: savedLanguageCode) ?? .english
        updateCurrentBundle()
    }
    
    /// Updates the global `currentLocalizationBundle` based on the selected language.
    private func updateCurrentBundle() {
        let targetBundle: Bundle
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            targetBundle = bundle
        } else {
            targetBundle = .main
        }
        
        // Safely update the global bundle.
        currentBundle.update(to: targetBundle)
    }
    
    /// Shows a restart alert to the user.
    private func showRestartAlert() {
        // A slight delay ensures the UI has time to update before presenting the alert.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingRestartAlert = true
        }
    }
    
    /// Terminates the application to apply changes.
    func restartApplication() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - String Extension
// String extension, provide convenient localization methods
extension String {
    /// Returns a localized version of the string.
    ///
    /// This computed property safely looks up the string in the currently selected language bundle.
    var localized: String {
        currentBundle.localizedString(forKey: self, value: self, table: nil)
    }
    
    /// Returns a localized, formatted string with the given arguments.
    func localized(with arguments: CVarArg...) -> String {
        let format = currentBundle.localizedString(forKey: self, value: self, table: nil)
        return String(format: format, arguments: arguments)
    }
    
    /// Returns a localized string, using a default value if the key is not found.
    func localized(defaultValue: String) -> String {
        currentBundle.localizedString(forKey: self, value: defaultValue, table: nil)
    }
}

// MARK: - SwiftUI Text Extension
// SwiftUI Text view localization extension
extension Text {
    /// Creates a `Text` view that displays a localized string.
    init(localized key: String) {
        self.init(key.localized)
    }
    
    /// Creates a `Text` view that displays a localized string with a default value.
    init(localized key: String, defaultValue: String) {
        self.init(key.localized(defaultValue: defaultValue))
    }
} 
