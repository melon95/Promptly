//
//  VersionManager.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftUI

/// A utility for retrieving application version and build information.
///
/// This enum acts as a namespace for static properties and methods,
/// ensuring that version information is accessed in a simple and thread-safe manner.
enum VersionProvider {
    
    /// The application's version number from `CFBundleShortVersionString`.
    static var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0"
        }
        return version
    }
    
    /// The application's build number from `CFBundleVersion`.
    static var buildVersion: String {
        guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "1"
        }
        return build
    }
    
    /// A combined string of the app version and build number (e.g., "1.0 (1)").
    static var fullVersionString: String {
        return "\(appVersion) (\(buildVersion))"
    }
    
    /// The application's version number, suitable for display.
    static var shortVersionString: String {
        return appVersion
    }
    
    /// The application's display name from `CFBundleDisplayName` or `CFBundleName`.
    static var appName: String {
        guard let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
                        Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            return "Promptly"
        }
        return name
    }
    
    /// The application's bundle identifier.
    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.melon.Promptly"
    }
    
    /// The application's copyright information.
    static var copyright: String {
        guard let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String else {
            return "© 2025 Melon. All rights reserved."
        }
        return copyright
    }
    
    /// Returns a formatted version string for display in the UI.
    /// - Parameter includesBuild: If `true`, includes the build number in the string.
    /// - Returns: A localized, formatted version string.
    @MainActor
    static func getFormattedVersion(includesBuild: Bool = false) -> String {
        let versionString = includesBuild ? fullVersionString : shortVersionString
        let versionLabel = currentBundle.localizedString(forKey: "Version", value: "Version", table: nil)
        return "\(versionLabel) \(versionString)"
    }
} 
