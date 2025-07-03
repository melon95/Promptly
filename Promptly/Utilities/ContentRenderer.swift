import SwiftUI
import Foundation

/// unified content renderer - supports mixed markdown, xml and variable highlighting
struct ContentRenderer {
    
    /// render content as SwiftUI View (mixed format)
    /// - Parameter content: content to render
    /// - Returns: rendered view
    @ViewBuilder
    static func render(_ content: String) -> some View {
        MixedContentView(content: content)
    }
    
    /// check if the text contains variables
    /// - Parameter text: text to check
    /// - Returns: true if the text contains variables
    static func containsVariables(_ text: String) -> Bool {
        let pattern = #"\{\{[^{}]+\}\}"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// check if the text contains XML tags
    /// - Parameter text: text to check
    /// - Returns: true if the text contains XML tags
    static func containsXMLTags(_ text: String) -> Bool {
        let pattern = #"<[^>]+>"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// create a text view with comprehensive syntax highlighting
    /// - Parameter text: original text
    /// - Returns: text view with highlighted syntax elements
    static func highlightText(_ text: String) -> Text {
        return highlightSyntax(text)
    }
    
    /// create a text view with syntax highlighting optimized for full screen viewing
    /// - Parameter text: original text
    /// - Returns: text view with highlighted syntax elements and enhanced readability
    static func highlightTextForFullScreen(_ text: String) -> Text {
        return highlightSyntax(text, isFullScreen: true)
    }
    
    /// comprehensive syntax highlighting for variables, XML tags, and markdown
    /// - Parameter text: original text
    /// - Parameter isFullScreen: whether this is for full screen display
    /// - Returns: text view with multiple syntax highlighting
    private static func highlightSyntax(_ text: String, isFullScreen: Bool = false) -> Text {
        // Define patterns for different syntax elements
        let patterns: [(pattern: String, color: Color, weight: Font.Weight?)] = [
            // XML/HTML tags (e.g., <tag>, </tag>, <tag attr="value">)
            (#"</?[a-zA-Z][^>]*>"#, .purple, .medium),
            // Variables (e.g., {{variable}})
            (#"\{\{[^{}]+\}\}"#, .blue, .semibold),
            // Markdown headers (e.g., # Header, ## Header)
            (#"^#{1,6}\s+.*$"#, .primary, .bold),
            // Markdown bold (e.g., **bold**)
            (#"\*\*[^*]+\*\*"#, .primary, .bold),
            // Markdown italic (e.g., *italic*)
            (#"\*[^*]+\*"#, .primary, nil),
            // Markdown code inline (e.g., `code`)
            (#"`[^`]+`"#, .orange, .medium),
            // XML/HTML attributes (e.g., attr="value")
            (#"[a-zA-Z-]+=\"[^\"]*\""#, .green, .medium),
            // Comments (e.g., <!-- comment -->)
            (#"<!--.*?-->"#, .secondary, nil)
        ]
        
        var result = Text("")
        var processedRanges: [NSRange] = []
        
        // Process each pattern
        for (patternString, color, weight) in patterns {
            guard let regex = try? NSRegularExpression(pattern: patternString, options: [.anchorsMatchLines]) else {
                continue
            }
            
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                // Check if this range overlaps with already processed ranges
                let overlaps = processedRanges.contains { processedRange in
                    NSIntersectionRange(match.range, processedRange).length > 0
                }
                
                if !overlaps {
                    processedRanges.append(match.range)
                }
            }
        }
        
        // Sort processed ranges by location
        processedRanges.sort { $0.location < $1.location }
        
        // Build the highlighted text
        var lastLocation = 0
        
        for processedRange in processedRanges {
            // Add text before the highlighted part
            if processedRange.location > lastLocation {
                let beforeRange = NSRange(location: lastLocation, length: processedRange.location - lastLocation)
                if let swiftRange = Range(beforeRange, in: text) {
                    let beforeText = String(text[swiftRange])
                    result = result + Text(beforeText)
                        .font(.system(isFullScreen ? .title3 : .body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
            
            // Add the highlighted text
            if let swiftRange = Range(processedRange, in: text) {
                let highlightedText = String(text[swiftRange])
                let (color, weight) = getHighlightStyle(for: highlightedText, isFullScreen: isFullScreen)
                
                result = result + Text(highlightedText)
                    .font(.system(isFullScreen ? .title3 : .body, design: .monospaced, weight: weight ?? .regular))
                    .foregroundColor(color)
            }
            
            lastLocation = processedRange.location + processedRange.length
        }
        
        // Add the remaining text
        if lastLocation < text.count {
            let remainingRange = NSRange(location: lastLocation, length: text.count - lastLocation)
            if let swiftRange = Range(remainingRange, in: text) {
                let remainingText = String(text[swiftRange])
                result = result + Text(remainingText)
                    .font(.system(isFullScreen ? .title3 : .body, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        
        return processedRanges.isEmpty ? Text(text).font(.system(isFullScreen ? .title3 : .body, design: .monospaced)) : result
    }
    
    /// determine highlight style based on text content
    /// - Parameter text: text to analyze
    /// - Parameter isFullScreen: whether this is for full screen display
    /// - Returns: tuple of color and font weight
    private static func getHighlightStyle(for text: String, isFullScreen: Bool = false) -> (Color, Font.Weight?) {
        let colorIntensity: Double = isFullScreen ? 1.0 : 0.9
        
        // Variables {{...}}
        if text.hasPrefix("{{") && text.hasSuffix("}}") {
            return (.blue.opacity(colorIntensity), isFullScreen ? .bold : .semibold)
        }
        
        // XML/HTML tags
        if text.hasPrefix("<") && text.hasSuffix(">") {
            if text.hasPrefix("</") {
                return (.purple.opacity(0.7 * colorIntensity), .medium) // Closing tags
            } else if text.contains("=") {
                return (.purple.opacity(colorIntensity), .medium) // Tags with attributes
            } else {
                return (.purple.opacity(colorIntensity), .medium) // Opening tags
            }
        }
        
        // Markdown headers
        if text.hasPrefix("#") {
            return (.primary.opacity(colorIntensity), .bold)
        }
        
        // Markdown bold
        if text.hasPrefix("**") && text.hasSuffix("**") {
            return (.primary.opacity(colorIntensity), .bold)
        }
        
        // Markdown italic
        if text.hasPrefix("*") && text.hasSuffix("*") && !text.hasPrefix("**") {
            return (.primary.opacity(colorIntensity), nil)
        }
        
        // Inline code
        if text.hasPrefix("`") && text.hasSuffix("`") {
            return (.orange.opacity(colorIntensity), .medium)
        }
        
        // Attributes
        if text.contains("=") && text.contains("\"") {
            return (.green.opacity(colorIntensity), .medium)
        }
        
        // Comments
        if text.hasPrefix("<!--") && text.hasSuffix("-->") {
            return (.secondary.opacity(colorIntensity), nil)
        }
        
        return (.primary.opacity(colorIntensity), .regular)
    }
}

/// mixed content view - unified rendering markdown, xml and variable highlighting
struct MixedContentView: View {
    let content: String
    
    var body: some View {
        // always show the preview area, no background color, no title
        ContentRenderer.highlightText(content)
            .textSelection(.enabled)
            .padding(8)
    }
}

