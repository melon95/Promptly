//
//  PromptViewer.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI
import SwiftData
import Foundation

/// Full-screen mode prompt viewer component
struct PromptViewer: View {
    let prompt: Prompt
    let onClose: () -> Void
    let onCopy: (String) -> Void
    
    @State private var showCopySuccess = false
    
    var body: some View {
        ZStack {
            // Background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Header toolbar
                headerToolbar
                
                // Content area
                contentArea
            }
            
            // Copy success toast
            copySuccessToast
        }
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
    }
    
    // MARK: - Header Toolbar
    private var headerToolbar: some View {
        HStack {
            // Title section
            VStack(alignment: .leading, spacing: 4) {
                Text(prompt.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !prompt.promptDescription.isEmpty {
                    Text(prompt.promptDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // Copy button
                Button(action: copyContent) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Copy Content".localized)
                .keyboardShortcut("c", modifiers: .command)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.3))
            , alignment: .bottom
        )
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Use ContentRenderer for syntax highlighting
                ContentRenderer.highlightTextForFullScreen(prompt.userPrompt)
                    .textSelection(.enabled)
                    .lineSpacing(4)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    // MARK: - Copy Success Toast
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
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(.regularMaterial)
                .cornerRadius(25)
                .shadow(radius: 5)
                .transition(.move(edge: .top).combined(with: .opacity))
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
    
    // MARK: - Methods Implementation
    
    private func copyContent() {
        onCopy(prompt.userPrompt)
        withAnimation(.spring()) {
            showCopySuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                showCopySuccess = false
            }
        }
    }
}

// Preview functionality removed, Prompt object is passed from MainView in actual usage 