import SwiftUI
import Foundation

/// variable highlighter tool
struct VariableHighlighter {
    
    /// create a text view with highlighted variables
    /// - Parameter text: original text
    /// - Returns: text view with highlighted variables
    static func highlightText(_ text: String) -> Text {
        let pattern = #"\{\{[^{}]+\}\}"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return Text(text).font(.system(.body, design: .monospaced))
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        
        if matches.isEmpty {
            return Text(text).font(.system(.body, design: .monospaced))
        }
        
        var result = Text("")
        var lastLocation = 0
        
        for match in matches {
            // add text before the variable
            if match.range.location > lastLocation {
                let beforeRange = NSRange(location: lastLocation, length: match.range.location - lastLocation)
                if let swiftRange = Range(beforeRange, in: text) {
                    let beforeText = String(text[swiftRange])
                    result = result + Text(beforeText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
            
            // add highlighted variable
            if let swiftRange = Range(match.range, in: text) {
                let variableText = String(text[swiftRange])
                result = result + Text(variableText)
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            lastLocation = match.range.location + match.range.length
        }
        
        // add the remaining text
        if lastLocation < text.count {
            let remainingRange = NSRange(location: lastLocation, length: text.count - lastLocation)
            if let swiftRange = Range(remainingRange, in: text) {
                let remainingText = String(text[swiftRange])
                result = result + Text(remainingText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        
        return result
    }
    
    /// extract all variables from the text
    /// - Parameter text: original text
    /// - Returns: variable names array (without curly braces)
    static func extractVariables(from text: String) -> [String] {
        let pattern = #"\{\{[^{}]+\}\}"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        
        return matches.compactMap { match in
            if let swiftRange = Range(match.range, in: text) {
                let fullMatch = String(text[swiftRange])
                // remove the curly braces
                return String(fullMatch.dropFirst(2).dropLast(2))
            }
            return nil
        }
    }
    
    /// check if the text contains variables
    /// - Parameter text: text to check
    /// - Returns: true if the text contains variables
    static func containsVariables(_ text: String) -> Bool {
        let pattern = #"\{\{[^{}]+\}\}"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }
} 