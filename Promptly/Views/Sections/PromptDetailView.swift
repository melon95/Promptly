//
//  PromptDetailView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI
import Foundation

struct PromptDetailView: View {
    let prompt: Prompt?
    let showCopySuccess: Bool
    let onClose: () -> Void
    let onCopy: (String) -> Void
    let onFullScreen: (Prompt) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Simplified header - no title bar, just action buttons
            if let prompt = prompt {
                HStack {
                    // Compact prompt title
                    Text(prompt.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    // Compact action buttons
                    HStack(spacing: 8) {
                        // Copy button
                        Button {
                            onCopy(prompt.userPrompt)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Copy prompt".localized)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        // Fullscreen button
                        Button {
                            onFullScreen(prompt)
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Full screen".localized)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        // Close button
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Close detail panel".localized)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                
                // Subtle divider
                Divider()
                    .opacity(0.5)
            }
            
            // Main content area
            if let prompt = prompt {
                // Prompt content with improved layout
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ContentRenderer.render(prompt.userPrompt)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .padding(20)
                }
                .background(Color(NSColor.textBackgroundColor))
            } else {
                // Empty state with enhanced instructions
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Text("Select a prompt to view details".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.draw")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Drag the separator above to resize this panel".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Double-click to auto-size".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            // Copy success toast
            copySuccessToast
                .allowsHitTesting(false)
        )
        .onAppear {
            // record prompt detail page view - PV tracking
            AnalyticsManager.shared.logPageView(PageName.promptDetail.rawValue)
        }
    }
    
    // copy success toast
    @ViewBuilder
    private var copySuccessToast: some View {
        if showCopySuccess {
            VStack {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Copied to Clipboard".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(.regularMaterial)
                .cornerRadius(20)
                .shadow(radius: 5)
                .transition(.move(edge: .top).combined(with: .opacity))
                
                Spacer()
            }
            .padding(.top, 20)
        }
    }
}  