//
//  AnalyticsManager.swift
//  Promptly
//
//  simplified analytics manager - only tracking PV and UV
//
//  PV (Page View): page view tracking
//  UV (Unique Visitor): unique visitor tracking, using Firebase Installation ID
//

import Foundation
import AppKit
// ensure FirebaseAnalytics is correctly added to the Xcode project
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Version Collection
    
    /// Get application version information
    private func getVersionInfo() -> (version: String, build: String) {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        
        print("📊 Version Info - Version: \(version), Build: \(build)")
        return (version, build)
    }
    
    /// Set user properties (including detailed version information)
    func setUserProperties() {
        let versionInfo = getVersionInfo()
        
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty("macOS", forName: "platform")
        Analytics.setUserProperty(versionInfo.version, forName: "app_version")
        Analytics.setUserProperty(versionInfo.build, forName: "build_number")
        Analytics.setUserProperty("\(versionInfo.version)(\(versionInfo.build))", forName: "full_version")
        
        print("📊 Analytics: User properties set - Version: \(versionInfo.version), Build: \(versionInfo.build)")
        #else
        print("⚠️ Analytics: Firebase not available, version collection skipped")
        #endif
    }
    
    // MARK: - PV tracking (page view)
    
    /// record page view - PV tracking
    func logPageView(_ pageName: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: pageName,
            "event_type": "page_view",
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
        #endif
    }
    
    // MARK: - UV tracking (unique visitor)
    
    /// record user visit - UV tracking (once per app launch)
    func logUserVisit() {
        let versionInfo = getVersionInfo()
        
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("user_visit", parameters: [
            "event_type": "unique_visitor",
            "timestamp": Int(Date().timeIntervalSince1970),
            "app_version": versionInfo.version,
            "build_number": versionInfo.build,
            "full_version": "\(versionInfo.version)(\(versionInfo.build))"
        ])
        print("📊 Analytics: User visit logged with version \(versionInfo.version)")
        #else
        print("⚠️ Analytics: Firebase not available, user visit not logged")
        #endif
    }
    
    // MARK: - session management
    
    /// start new session
    func startSession() {
        // Set user properties
        setUserProperties()
        
        // record UV - once per app launch
        logUserVisit()
        
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("app_session_start", parameters: [
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
        print("📊 Analytics: App session started")
        #endif
    }
    
    /// end session
    func endSession() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("app_session_end", parameters: [
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
        print("📊 Analytics: App session ended")
        #endif
    }
}

// MARK: - page name enumeration

enum PageName: String, CaseIterable {
    case main = "main_view"
    case settings = "settings_view"
    case promptEditor = "prompt_editor"
    case promptDetail = "prompt_detail"
    case search = "search_view"
}

// MARK: - app lifecycle automatic tracking

extension AnalyticsManager {
    /// configure app lifecycle monitoring
    func setupLifecycleTracking() {
        // monitor app launch
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.startSession()
            }
        }
        
        // monitor app termination
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.endSession()
            }
        }
        
        // monitor app backgrounding
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.endSession()
            }
        }
    }
} 