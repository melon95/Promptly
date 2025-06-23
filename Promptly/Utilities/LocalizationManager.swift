//
//  LocalizationManager.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftUI

// localization manager, handle multi-language support
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // supported languages list
    enum SupportedLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case simplifiedChinese = "zh-Hans"
        
        var id: String { rawValue }
        
        // language display name
        var displayName: String {
            switch self {
            case .english:
                return "English"
            case .simplifiedChinese:
                return "简体中文"
            }
        }
        
        // localized display name
        var localizedDisplayName: String {
            switch self {
            case .english:
                return "language.english".localized
            case .simplifiedChinese:
                return "language.chinese".localized
            }
        }
    }
    
    @Published var currentLanguage: SupportedLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selected_language")
            updateCurrentBundle()
            // 通知需要重启应用以完全应用语言更改
            showRestartAlert()
        }
    }
    
    @Published var showingRestartAlert = false
    
    private var currentBundle: Bundle = Bundle.main
    
    private init() {
        // read language selection from user preferences
        let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") ?? ""
        self.currentLanguage = SupportedLanguage(rawValue: savedLanguage) ?? .english
        updateCurrentBundle()
    }
    
    // update current bundle
    private func updateCurrentBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
        } else {
            currentBundle = Bundle.main
        }
    }
    
    // get localized string
    // - Parameters:
    //   - key: localized key
    //   - defaultValue: default value
    //   - comment: comment
    // - Returns: localized string
    func localizedString(forKey key: String, defaultValue: String = "", comment: String = "") -> String {
        return currentBundle.localizedString(forKey: key, value: defaultValue, table: nil)
    }
    
    // get localized string with arguments
    // - Parameters:
    //   - key: localized key
    //   - arguments: arguments
    // - Returns: localized string
    func localizedString(forKey key: String, arguments: CVarArg...) -> String {
        let format = localizedString(forKey: key, defaultValue: key, comment: "")
        return String(format: format, arguments: arguments)
    }
    
    // 显示重启提示
    private func showRestartAlert() {
        // 延迟一点时间显示提示，让UI有时间更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingRestartAlert = true
        }
    }
    
    // 重启应用
    func restartApplication() {
        NSApplication.shared.terminate(nil)
    }
}

// String extension, provide convenient localization methods
extension String {
    // get localized string
    var localized: String {
        return LocalizationManager.shared.localizedString(forKey: self, defaultValue: self)
    }
    
    // get localized string with arguments
    // - Parameter arguments: arguments
    // - Returns: localized string
    func localized(with arguments: CVarArg...) -> String {
        let format = LocalizationManager.shared.localizedString(forKey: self, defaultValue: self, comment: "")
        return String(format: format, arguments: arguments)
    }
    
    // get localized string with default value
    // - Parameter defaultValue: default value
    // - Returns: localized string
    func localized(defaultValue: String) -> String {
        return LocalizationManager.shared.localizedString(forKey: self, defaultValue: defaultValue)
    }
}

// SwiftUI Text view localization extension
extension Text {
    // create localized Text view
    // - Parameter key: localized key
    init(localized key: String) {
        self.init(key.localized)
    }
    
    // create localized Text view with default value
    // - Parameters:
    //   - key: localized key
    //   - defaultValue: default value
    init(localized key: String, defaultValue: String) {
        self.init(key.localized(defaultValue: defaultValue))
    }
} 
