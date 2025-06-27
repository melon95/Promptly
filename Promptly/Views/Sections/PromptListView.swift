//
//  PromptListView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI

struct PromptListView: View {
    let prompts: [Prompt]
    let onPromptSelected: (Prompt) -> Void
    let onCreatePrompt: () -> Void
    
    var body: some View {
        Group {
            if prompts.isEmpty {
                EmptyStateView(onCreatePrompt: onCreatePrompt)
            } else {
                promptList
            }
        }
    }
    
    // prompt list
    private var promptList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(prompts) { prompt in
                    PromptCard(prompt: prompt) {
                        onPromptSelected(prompt)
                    }
                }
            }
            .padding(20)
        }
    }
} 