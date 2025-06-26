//
//  Color+Extensions.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI

// MARK: - Color Conversion
func colorForName(_ name: String) -> Color {
    switch name.lowercased() {
    case "blue": return .blue
    case "green": return .green
    case "orange": return .orange
    case "pink": return .pink
    case "red": return .red
    case "gray": return .gray
    default:
        if name.hasPrefix("#"), let color = Color(hex: name) {
            return color
        }
        return .black // Default or error color
    }
}

// MARK: - Color Extensions
extension Color {
    // 从十六进制字符串创建Color
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        let a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    // 转换为十六进制字符串
    func toHex() -> String {
        guard let components = cgColor?.components, components.count >= 3 else {
            return "#000000"
        }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#if canImport(AppKit)
import AppKit

extension NSColor {
    func toHex() -> String {
        guard let rgbColor = self.usingColorSpace(.sRGB) else {
            return "#000000"
        }
        
        let red = Int(round(rgbColor.redComponent * 255))
        let green = Int(round(rgbColor.greenComponent * 255))
        let blue = Int(round(rgbColor.blueComponent * 255))
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
#endif

#if canImport(UIKit)
import UIKit

extension UIColor {
    func toHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
#endif 
