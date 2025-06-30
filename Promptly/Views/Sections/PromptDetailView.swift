//
//  PromptDetailView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI

struct PromptDetailView: View {
    let prompt: Prompt?
    let showCopySuccess: Bool
    let onClose: () -> Void
    let onCopy: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Detail panel title bar (display prompt title + copy button + close button)
            HStack {
                if let prompt = prompt {
                    Text(prompt.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        onCopy(prompt.userPrompt)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                } else {
                    Text("Prompt Details".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail content
            if let prompt = prompt {
                // Prompt content
                ScrollView {
                    Text(prompt.userPrompt)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                        .padding(20)
                }
            } else {
                VStack {
                    Spacer()
                    Text("No prompt selected".localized)
                        .foregroundColor(.secondary)
                    Spacer()
                }
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
    
    // 复制成功提示
    @ViewBuilder
    private var copySuccessToast: some View {
        if showCopySuccess {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("prompt.copied".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(.regularMaterial)
            .cornerRadius(20)
            .shadow(radius: 5)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
} 