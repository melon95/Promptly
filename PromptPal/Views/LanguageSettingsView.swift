//
//  LanguageSettingsView.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI

/// 语言设置视图
struct LanguageSettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                VStack(alignment: .leading, spacing: 8) {
                    Text(localized: "settings.language")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose your preferred language for the app interface.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // 语言选项列表
                List {
                    ForEach(LocalizationManager.SupportedLanguage.allCases) { language in
                        LanguageRow(
                            language: language,
                            isSelected: localizationManager.currentLanguage == language
                        ) {
                            localizationManager.currentLanguage = language
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .navigationTitle("settings.language".localized)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 语言选项行
struct LanguageRow: View {
    let language: LocalizationManager.SupportedLanguage
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(language.localizedDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .fontWeight(.semibold)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 语言设置快速访问视图
struct LanguageQuickSelectorView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.accentColor)
                
                Text(localized: "settings.language")
                    .font(.headline)
                
                Spacer()
            }
            
            Picker("Language", selection: $localizationManager.currentLanguage) {
                ForEach(LocalizationManager.SupportedLanguage.allCases) { language in
                    Text(language.displayName)
                        .tag(language)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview("Language Settings") {
    LanguageSettingsView()
}

#Preview("Quick Selector") {
    LanguageQuickSelectorView()
        .padding()
} 