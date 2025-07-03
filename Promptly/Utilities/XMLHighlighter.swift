import SwiftUI
import Foundation

/// XML syntax highlighter for SwiftUI Text
struct XMLHighlighter {
    
    /// Syntax element types
    enum SyntaxElement {
        case xmlTag(String)
        case xmlClosingTag(String)
        case xmlAttribute(String)
        case xmlAttributeValue(String)
        case xmlComment(String)
        case variable(String)
        case markdownHeader(String)
        case markdownBold(String)
        case markdownItalic(String)
        case inlineCode(String)
        case plainText(String)
    }
    
    /// Parse and highlight XML/Markdown content
    /// - Parameter content: Raw content string
    /// - Returns: SwiftUI Text with syntax highlighting
    static func highlight(_ content: String) -> Text {
        let elements = parseContent(content)
        return buildHighlightedText(from: elements)
    }
    
    /// Parse content into syntax elements
    /// - Parameter content: Raw content string
    /// - Returns: Array of syntax elements
    private static func parseContent(_ content: String) -> [SyntaxElement] {
        var elements: [SyntaxElement] = []
        var currentIndex = content.startIndex
        
        while currentIndex < content.endIndex {
            let remainingContent = String(content[currentIndex...])
            
            // Try to match different syntax patterns
            if let match = matchXMLComment(in: remainingContent) {
                let element = SyntaxElement.xmlComment(match.text)
                elements.append(element)
                currentIndex = content.index(currentIndex, offsetBy: match.length)
                
            } else if let match = matchXMLTag(in: remainingContent) {
                let element = match.isClosing ? 
                    SyntaxElement.xmlClosingTag(match.text) : 
                    SyntaxElement.xmlTag(match.text)
                elements.append(element)
                currentIndex = content.index(currentIndex, offsetBy: match.length)
                
            } else if let match = matchVariable(in: remainingContent) {
                let element = SyntaxElement.variable(match.text)
                elements.append(element)
                currentIndex = content.index(currentIndex, offsetBy: match.length)
                
            } else if let match = matchMarkdownHeader(in: remainingContent) {
                let element = SyntaxElement.markdownHeader(match.text)
                elements.append(element)
                currentIndex = content.index(currentIndex, offsetBy: match.length)
                
            } else if let match = matchMarkdownBold(in: remainingContent) {
                let element = SyntaxElement.markdownBold(match.text)
                elements.append(element)
                currentIndex = content.index(currentIndex, offsetBy: match.length)
                
            } else if let match = matchInlineCode(in: remainingContent) {
                let element = SyntaxElement.inlineCode(match.text)
                elements.append(element)
                currentIndex = content.index(currentIndex, offsetBy: match.length)
                
            } else {
                // Add single character as plain text
                let char = String(content[currentIndex])
                if let lastElement = elements.last,
                   case .plainText(let existingText) = lastElement {
                    elements[elements.count - 1] = .plainText(existingText + char)
                } else {
                    elements.append(.plainText(char))
                }
                currentIndex = content.index(after: currentIndex)
            }
        }
        
        return elements
    }
    
    /// Build highlighted text from syntax elements
    /// - Parameter elements: Array of syntax elements
    /// - Returns: SwiftUI Text with highlighting
    private static func buildHighlightedText(from elements: [SyntaxElement]) -> Text {
        var result = Text("")
        
        for element in elements {
            let textComponent = createTextComponent(for: element)
            result = result + textComponent
        }
        
        return result
    }
    
    /// Create SwiftUI Text component for syntax element
    /// - Parameter element: Syntax element
    /// - Returns: Styled SwiftUI Text
    private static func createTextComponent(for element: SyntaxElement) -> Text {
        let baseFont = Font.system(.body, design: .monospaced)
        
        switch element {
        case .xmlTag(let text):
            return Text(text)
                .font(baseFont.weight(.medium))
                .foregroundColor(.purple)
                
        case .xmlClosingTag(let text):
            return Text(text)
                .font(baseFont.weight(.medium))
                .foregroundColor(.purple.opacity(0.8))
                
        case .xmlAttribute(let text):
            return Text(text)
                .font(baseFont.weight(.medium))
                .foregroundColor(.green)
                
        case .xmlAttributeValue(let text):
            return Text(text)
                .font(baseFont)
                .foregroundColor(.orange)
                
        case .xmlComment(let text):
            return Text(text)
                .font(baseFont)
                .foregroundColor(.secondary)
                
        case .variable(let text):
            return Text(text)
                .font(baseFont.weight(.semibold))
                .foregroundColor(.blue)
                
        case .markdownHeader(let text):
            return Text(text)
                .font(baseFont.weight(.bold))
                .foregroundColor(.primary)
                
        case .markdownBold(let text):
            return Text(text)
                .font(baseFont.weight(.bold))
                .foregroundColor(.primary)
                
        case .markdownItalic(let text):
            return Text(text)
                .font(baseFont.italic())
                .foregroundColor(.primary)
                
        case .inlineCode(let text):
            return Text(text)
                .font(baseFont.weight(.medium))
                .foregroundColor(.orange)
                
        case .plainText(let text):
            return Text(text)
                .font(baseFont)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Pattern Matching Functions
    
    private static func matchXMLComment(in text: String) -> (text: String, length: Int)? {
        let pattern = #"<!--.*?-->"#
        return matchPattern(pattern, in: text)
    }
    
    private static func matchXMLTag(in text: String) -> (text: String, length: Int, isClosing: Bool)? {
        let pattern = #"</?[a-zA-Z][^>]*>"#
        if let match = matchPattern(pattern, in: text) {
            let isClosing = match.text.hasPrefix("</")
            return (match.text, match.length, isClosing)
        }
        return nil
    }
    
    private static func matchVariable(in text: String) -> (text: String, length: Int)? {
        let pattern = #"\{\{[^{}]+\}\}"#
        return matchPattern(pattern, in: text)
    }
    
    private static func matchMarkdownHeader(in text: String) -> (text: String, length: Int)? {
        let pattern = #"^#{1,6}\s+.*$"#
        return matchPattern(pattern, in: text, options: [.anchorsMatchLines])
    }
    
    private static func matchMarkdownBold(in text: String) -> (text: String, length: Int)? {
        let pattern = #"\*\*[^*]+\*\*"#
        return matchPattern(pattern, in: text)
    }
    
    private static func matchInlineCode(in text: String) -> (text: String, length: Int)? {
        let pattern = #"`[^`]+`"#
        return matchPattern(pattern, in: text)
    }
    
    private static func matchPattern(_ pattern: String, in text: String, options: NSRegularExpression.Options = []) -> (text: String, length: Int)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           match.range.location == 0,
           let swiftRange = Range(match.range, in: text) {
            let matchedText = String(text[swiftRange])
            return (matchedText, match.range.length)
        }
        
        return nil
    }
}



/// Content view with XML highlighting
struct XMLHighlightedContentView: View {
    let content: String
    
    var body: some View {
        XMLHighlighter.highlight(content)
            .textSelection(.enabled)
            .padding(8)
    }
} 