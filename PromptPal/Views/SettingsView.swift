//
//  SettingsView.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI

// main settings view
struct SettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        TabView {
            // general settings tab
            GeneralSettingsTab()
                .tabItem {
                    Label("settings.general".localized, systemImage: "gear")
                }
                .tag("general")
            
            // advanced settings tab
            AdvancedSettingsTab()
                .tabItem {
                    Label("Advanced".localized, systemImage: "gearshape.2")
                }
                .tag("advanced")
        }
        .frame(width: 450, height: 300)
        .alert("language.changed.title".localized, isPresented: $localizationManager.showingRestartAlert) {
            Button("language.changed.restart".localized) {
                localizationManager.restartApplication()
            }
            Button("language.changed.later".localized, role: .cancel) { }
        } message: {
            Text("language.changed.message".localized)
        }
    }
}

// general settings tab
struct GeneralSettingsTab: View {
    var body: some View {
        Form {
            // language settings
            LanguageSettingRow()
            
            // theme settings  
            ThemeSettingRow()
            
            Spacer()
        }
        .formStyle(.grouped)
        .padding(.top)
    }
}

// advanced settings tab
struct AdvancedSettingsTab: View {
    var body: some View {
        Form {
            // global shortcuts
            HotkeySettingRow()
            
            // iCloud sync
            iCloudSyncRow()
            
            // about information
            Divider()
            AboutRow()
            
            Spacer()
        }
        .formStyle(.grouped)
        .padding(.top)
    }
}

// language settings row
struct LanguageSettingRow: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingLanguageSettings = false
    
    var body: some View {
        HStack {
            Label {
                Text("settings.language".localized)
            } icon: {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // current language display
            // Text(localizationManager.currentLanguage.displayName)
            //     .foregroundColor(.secondary)
            
            // language picker
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

// theme settings row
struct ThemeSettingRow: View {
    @State private var selectedTheme = "System"
    
    var body: some View {
        HStack {
            Label {
                Text("settings.theme".localized)
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

// hotkey settings row
struct HotkeySettingRow: View {
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @State private var showingHotkeySettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.hotkey".localized)
                        Text("Customize keyboard shortcuts".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "keyboard")
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Button("Customize".localized) {
                    showingHotkeySettings = true
                }
                .buttonStyle(.link)
            }
            
            // display main hotkeys
            VStack(alignment: .leading, spacing: 4) {
                HotkeyDisplayRow(
                    title: "Quick Access",
                    keyCombo: hotkeyManager.getHotkey(for: .quickAccess)
                )
                HotkeyDisplayRow(
                    title: "New Prompt",
                    keyCombo: hotkeyManager.getHotkey(for: .newPrompt)
                )
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingHotkeySettings) {
            HotkeySettingsView()
        }
    }
}

// hotkey display row
struct HotkeyDisplayRow: View {
    let title: String
    let keyCombo: String
    
    var body: some View {
        HStack {
            Text(title.localized)
            Spacer()
            Text(keyCombo)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

// hotkey settings view
struct HotkeySettingsView: View {
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(HotkeyManager.HotkeyType.allCases) { hotkeyType in
                        HotkeyEditRow(hotkeyType: hotkeyType)
                    }
                } header: {
                    Text("Keyboard Shortcuts".localized)
                } footer: {
                    Text("Click on a shortcut to customize it. Press Escape to cancel editing.".localized)
                        .font(.caption)
                }
                
                Section {
                    Button("Reset to Defaults".localized) {
                        hotkeyManager.resetAllHotkeys()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Keyboard Shortcuts".localized)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

// hotkey edit row
struct HotkeyEditRow: View {
    let hotkeyType: HotkeyManager.HotkeyType
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @State private var isEditing = false
    @State private var tempKeyCombo = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(hotkeyType.displayName)
                    .fontWeight(.medium)
                Text(hotkeyType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isEditing {
                TextField("Press keys...", text: $tempKeyCombo)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onSubmit {
                        saveHotkey()
                    }
                    .onExitCommand {
                        cancelEditing()
                    }
            } else {
                Button(hotkeyManager.getHotkey(for: hotkeyType)) {
                    startEditing()
                }
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
    
    private func startEditing() {
        isEditing = true
        tempKeyCombo = hotkeyManager.getHotkey(for: hotkeyType)
    }
    
    private func cancelEditing() {
        isEditing = false
        tempKeyCombo = ""
    }
    
    private func saveHotkey() {
        guard !tempKeyCombo.isEmpty else {
            cancelEditing()
            return
        }
        
        if hotkeyManager.isHotkeyConflicting(tempKeyCombo, excludeType: hotkeyType) {
            // show conflict warning
            // here can add a warning dialog
            cancelEditing()
            return
        }
        
        hotkeyManager.updateHotkey(for: hotkeyType, to: tempKeyCombo)
        isEditing = false
        tempKeyCombo = ""
    }
}

// iCloud sync row
struct iCloudSyncRow: View {
    @State private var iCloudSyncEnabled = true
    
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.sync".localized)
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

// about row
struct AboutRow: View {
    var body: some View {
        VStack(spacing: 12) {
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
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(VersionManager.shared.getFormattedVersion())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// info display row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title.localized + ":")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    SettingsView()
} 