//
//  HotkeyManager.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftUI

// hotkey manager
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    // supported hotkey types
    enum HotkeyType: String, CaseIterable, Identifiable {
        case quickAccess = "quick_access"
        case newPrompt = "new_prompt"
        case focusSearch = "focus_search"
        case showFavorites = "show_favorites"
        
        var id: String { rawValue }
        
        // hotkey display name
        var displayName: String {
            switch self {
            case .quickAccess:
                return "settings.hotkey.quick_access".localized
            case .newPrompt:
                return "settings.hotkey.new_prompt".localized
            case .focusSearch:
                return "settings.hotkey.focus_search".localized
            case .showFavorites:
                return "settings.hotkey.show_favorites".localized
            }
        }
        
        // default hotkey combination
        var defaultKeyCombo: String {
            switch self {
            case .quickAccess:
                return "⌥P"
            case .newPrompt:
                return "⌘N"
            case .focusSearch:
                return "⌘F"
            case .showFavorites:
                return "⌘⇧F"
            }
        }
        
        // hotkey description
        var description: String {
            switch self {
            case .quickAccess:
                return "settings.hotkey.quick_access.description".localized
            case .newPrompt:
                return "settings.hotkey.new_prompt.description".localized
            case .focusSearch:
                return "settings.hotkey.focus_search.description".localized
            case .showFavorites:
                return "settings.hotkey.show_favorites.description".localized
            }
        }
    }
    
    // current hotkey settings
    @Published var hotkeySettings: [HotkeyType: String] = [:]
    
    private init() {
        loadHotkeySettings()
    }
    
    // load hotkey settings
    private func loadHotkeySettings() {
        for hotkeyType in HotkeyType.allCases {
            let savedHotkey = UserDefaults.standard.string(forKey: "hotkey_\(hotkeyType.rawValue)")
            hotkeySettings[hotkeyType] = savedHotkey ?? hotkeyType.defaultKeyCombo
        }
    }
    
    // save hotkey settings
    private func saveHotkeySettings() {
        for (hotkeyType, keyCombo) in hotkeySettings {
            UserDefaults.standard.set(keyCombo, forKey: "hotkey_\(hotkeyType.rawValue)")
        }
    }
    
    // update hotkey
    // - Parameters:
    //   - hotkeyType: hotkey type
    //   - keyCombo: key combination
    func updateHotkey(for hotkeyType: HotkeyType, to keyCombo: String) {
        hotkeySettings[hotkeyType] = keyCombo
        saveHotkeySettings()
    }
    
    // get hotkey
    // - Parameter hotkeyType: hotkey type
    // - Returns: key combination string
    func getHotkey(for hotkeyType: HotkeyType) -> String {
        return hotkeySettings[hotkeyType] ?? hotkeyType.defaultKeyCombo
    }
    
    // reset hotkey to default value
    // - Parameter hotkeyType: hotkey type
    func resetHotkey(for hotkeyType: HotkeyType) {
        updateHotkey(for: hotkeyType, to: hotkeyType.defaultKeyCombo)
    }
    
    // reset all hotkeys to default value
    func resetAllHotkeys() {
        for hotkeyType in HotkeyType.allCases {
            resetHotkey(for: hotkeyType)
        }
    }
    
    // check if hotkey is conflicting with other hotkeys
    // - Parameters:
    //   - keyCombo: key combination to check
    //   - excludeType: excluded hotkey type (usually the current editing type)
    // - Returns: whether there is a conflict
    func isHotkeyConflicting(_ keyCombo: String, excludeType: HotkeyType? = nil) -> Bool {
        for (hotkeyType, existingKeyCombo) in hotkeySettings {
            if hotkeyType != excludeType && existingKeyCombo == keyCombo {
                return true
            }
        }
        return false
    }
} 