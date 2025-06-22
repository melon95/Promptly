//
//  VersionManager.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import Foundation

/// 版本管理器 - 负责获取应用版本信息
class VersionManager {
    static let shared = VersionManager()
    
    private init() {}
    
    /// 应用版本号 (CFBundleShortVersionString)
    var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0"
        }
        return version
    }
    
    /// 构建版本号 (CFBundleVersion)
    var buildVersion: String {
        guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "1"
        }
        return build
    }
    
    /// 完整版本信息（版本号 + 构建号）
    var fullVersionString: String {
        return "\(appVersion) (\(buildVersion))"
    }
    
    /// 简洁版本信息（仅显示版本号）
    var shortVersionString: String {
        return appVersion
    }
    
    /// 应用名称
    var appName: String {
        guard let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
                        Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            return "Promptly"
        }
        return name
    }
    
    /// Bundle ID
    var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.melon.Promptly"
    }
    
    /// 版权信息
    var copyright: String {
        guard let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String else {
            return "© 2025 Melon. All rights reserved."
        }
        return copyright
    }
    
    /// 获取格式化的版本显示字符串
    /// - Parameter includesBuild: 是否包含构建版本号
    /// - Returns: 格式化的版本字符串
    func getFormattedVersion(includesBuild: Bool = false) -> String {
        if includesBuild {
            return "Version".localized + " " + fullVersionString
        } else {
            return "Version".localized + " " + shortVersionString
        }
    }
} 