import Foundation

extension String {
    var emojis: String {
        filter { $0.isEmoji }
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
    }
} 