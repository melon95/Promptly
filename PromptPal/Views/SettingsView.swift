//
//  SettingsView.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI

/// 主设置视图
struct SettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        TabView {
            // 通用设置标签页
            GeneralSettingsTab()
                .tabItem {
                    Label("settings.general".localized, systemImage: "gear")
                }
                .tag("general")
            
            // 高级设置标签页
            AdvancedSettingsTab()
                .tabItem {
                    Label("Advanced".localized, systemImage: "gearshape.2")
                }
                .tag("advanced")
        }
        .frame(width: 450, height: 300)
    }
}

/// 通用设置标签页
struct GeneralSettingsTab: View {
    var body: some View {
        Form {
            // 语言设置
            LanguageSettingRow()
            
            // 主题设置  
            ThemeSettingRow()
            
            Spacer()
        }
        .formStyle(.grouped)
        .padding(.top)
    }
}

/// 高级设置标签页
struct AdvancedSettingsTab: View {
    var body: some View {
        Form {
            // 全局快捷键
            HotkeySettingRow()
            
            // iCloud 同步
            iCloudSyncRow()
            
            // 关于信息
            Divider()
            AboutRow()
            
            Spacer()
        }
        .formStyle(.grouped)
        .padding(.top)
    }
}

/// 语言设置行
struct LanguageSettingRow: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingLanguageSettings = false
    
    var body: some View {
        HStack {
            Label {
                Text(localized: "settings.language")
            } icon: {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // 当前语言显示
            Text(localizationManager.currentLanguage.displayName)
                .foregroundColor(.secondary)
            
            // 语言选择器
            Picker("", selection: $localizationManager.currentLanguage) {
                ForEach(LocalizationManager.SupportedLanguage.allCases) { language in
                    Text(language.displayName)
                        .tag(language)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
        }
    }
}

/// 主题设置行
struct ThemeSettingRow: View {
    @State private var selectedTheme = "System"
    
    var body: some View {
        HStack {
            Label {
                Text(localized: "settings.theme")
            } icon: {
                Image(systemName: "paintbrush")
                    .foregroundColor(.purple)
            }
            
            Spacer()
            
            Picker("", selection: $selectedTheme) {
                Text("settings.theme.system".localized).tag("System")
                Text("settings.theme.light".localized).tag("Light")
                Text("settings.theme.dark".localized).tag("Dark")
            }
            .pickerStyle(.menu)
            .frame(width: 120)
        }
    }
}

/// 快捷键设置行
struct HotkeySettingRow: View {
    @State private var currentHotkey = "⌥P"
    
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized: "settings.hotkey")
                    Text("settings.hotkey.description".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "keyboard")
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // 当前快捷键显示
            Text("settings.hotkey.current".localized(with: currentHotkey))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

/// iCloud 同步行
struct iCloudSyncRow: View {
    @State private var iCloudSyncEnabled = true
    
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized: "settings.sync")
                    Text("settings.sync.description".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Toggle("", isOn: $iCloudSyncEnabled)
        }
    }
}

/// 关于行
struct AboutRow: View {
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("app.name".localized)
                        .fontWeight(.medium)
                    Text("app.tagline".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("Version".localized + " 1.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
} 