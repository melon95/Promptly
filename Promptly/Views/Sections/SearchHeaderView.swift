//
//  SearchHeaderView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI

struct SearchHeaderView: View {
    @Binding var searchText: String
    @Binding var selectedTags: Set<String>
    @FocusState var isSearchFocused: Bool
    
    let tagsWithCount: [(tag: String, count: Int)]
    
    var body: some View {
        VStack(spacing: 8) {
            searchBar
            
            // Tag visualization area
            if !tagsWithCount.isEmpty {
                tagVisualizationSection
            }
        }
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // search bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search Prompts...".localized, text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // tag可视化区域
    private var tagVisualizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Tags".localized)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if !selectedTags.isEmpty {
                    Button("main.tags.search.clear".localized) {
                        selectedTags.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                Spacer()
            }
            
            // Tag cloud display - stream layout
            SimpleTagFlowLayout(spacing: 8) {
                ForEach(tagsWithCount, id: \.tag) { tagInfo in
                    TagButton(
                        tag: tagInfo.tag,
                        count: tagInfo.count,
                        isSelected: selectedTags.contains(tagInfo.tag)
                    ) {
                        toggleTag(tagInfo.tag)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Switch tag selection state
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        // record search page view - PV tracking (when user interacts with search feature)
        AnalyticsManager.shared.logPageView(PageName.search.rawValue)
    }
}

// MARK: - TagButton component
struct TagButton: View {
    let tag: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tag)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.secondary.opacity(0.15))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Stream layout
struct SimpleTagFlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }.reduce(0) { $0 + $1 + spacing } - spacing
        
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let availableWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentRowWidth: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + subviewSize.width > availableWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [subview]
                currentRowWidth = subviewSize.width
            } else {
                currentRow.append(subview)
                currentRowWidth += subviewSize.width + (currentRow.count > 1 ? spacing : 0)
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
} 