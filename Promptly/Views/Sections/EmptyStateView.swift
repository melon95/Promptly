//
//  EmptyStateView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI

struct EmptyStateView: View {
    let onCreatePrompt: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Prompts Found".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first prompt or adjust your search criteria.".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                onCreatePrompt()
            } label: {
                Label("Create Prompt".localized, systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// primary button style
struct PrimaryButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    
    init(backgroundColor: Color = .blue, 
         foregroundColor: Color = .white, 
         cornerRadius: CGFloat = 8) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
} 