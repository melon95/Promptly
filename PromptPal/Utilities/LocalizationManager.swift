//
//  LocalizationManager.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftUI

/// 本地化管理器，处理应用的多语言支持
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    /// 支持的语言列表
    enum SupportedLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case simplifiedChinese = "zh-Hans"
        
        var id: String { rawValue }
        
        /// 语言显示名称
        var displayName: String {
            switch self {
            case .english:
                return "English"
            case .simplifiedChinese:
                return "简体中文"
            }
        }
        
        /// 本地化显示名称
        var localizedDisplayName: String {
            switch self {
            case .english:
                return NSLocalizedString("language.english", value: "English", comment: "English language name")
            case .simplifiedChinese:
                return NSLocalizedString("language.chinese", value: "简体中文", comment: "Chinese language name")
            }
        }
    }
    
    @Published var currentLanguage: SupportedLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selected_language")
            updateCurrentBundle()
        }
    }
    
    private var currentBundle: Bundle = Bundle.main
    
    private init() {
        // 从用户偏好设置中读取语言选择
        let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") ?? ""
        self.currentLanguage = SupportedLanguage(rawValue: savedLanguage) ?? .english
        updateCurrentBundle()
    }
    
    /// 更新当前的资源包
    private func updateCurrentBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
        } else {
            currentBundle = Bundle.main
        }
    }
    
    /// 获取本地化字符串
    /// - Parameters:
    ///   - key: 本地化键值
    ///   - defaultValue: 默认值
    ///   - comment: 注释
    /// - Returns: 本地化后的字符串
    func localizedString(forKey key: String, defaultValue: String = "", comment: String = "") -> String {
        return currentBundle.localizedString(forKey: key, value: defaultValue, table: nil)
    }
    
    /// 获取带参数的本地化字符串
    /// - Parameters:
    ///   - key: 本地化键值
    ///   - arguments: 格式化参数
    /// - Returns: 格式化后的本地化字符串
    func localizedString(forKey key: String, arguments: CVarArg...) -> String {
        let format = localizedString(forKey: key, defaultValue: key, comment: "")
        return String(format: format, arguments: arguments)
    }
}

/// String 扩展，提供便捷的本地化方法
extension String {
    /// 获取本地化字符串
    var localized: String {
        return LocalizationManager.shared.localizedString(forKey: self, defaultValue: self)
    }
    
    /// 获取带参数的本地化字符串
    /// - Parameter arguments: 格式化参数
    /// - Returns: 格式化后的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        let format = LocalizationManager.shared.localizedString(forKey: self, defaultValue: self, comment: "")
        return String(format: format, arguments: arguments)
    }
    
    /// 获取带默认值的本地化字符串
    /// - Parameter defaultValue: 默认值
    /// - Returns: 本地化字符串
    func localized(defaultValue: String) -> String {
        return LocalizationManager.shared.localizedString(forKey: self, defaultValue: defaultValue)
    }
}

/// SwiftUI Text 视图的本地化扩展
extension Text {
    /// 创建本地化的 Text 视图
    /// - Parameter key: 本地化键值
    init(localized key: String) {
        self.init(key.localized)
    }
    
    /// 创建带默认值的本地化 Text 视图
    /// - Parameters:
    ///   - key: 本地化键值
    ///   - defaultValue: 默认值
    init(localized key: String, defaultValue: String) {
        self.init(key.localized(defaultValue: defaultValue))
    }
} 