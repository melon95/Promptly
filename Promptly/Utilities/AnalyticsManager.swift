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
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("user_visit", parameters: [
            "event_type": "unique_visitor",
            "timestamp": Int(Date().timeIntervalSince1970),
            "app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        ])
        #endif
    }
    
    // MARK: - session management
    
    /// start new session
    func startSession() {
        // record UV - once per app launch
        logUserVisit()
        
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("session_start", parameters: [
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
        #endif
    }
    
    /// end session
    func endSession() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("session_end", parameters: [
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
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