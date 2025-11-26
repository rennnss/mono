import SwiftUI

struct Theme {
    struct Colors {
        static let background = Color(hex: "FDFBF7") // Classic Beige
        static let text = Color.black
        static let border = Color.black
        static let surface = Color(hex: "FDFBF7")
        static let accentPink = Color(hex: "FFB7B2")
        static let accentGreen = Color(hex: "E2F0CB")
        static let accentYellow = Color(hex: "FFFACD")
        static let accentBlue = Color(hex: "B9D7EA")
        
        // Legacy mappings for compatibility if needed, or just replace usage
        static let chassisDark = border
        static let chassisLight = background
        static let chassisGradientStart = background
        static let chassisGradientEnd = background
        
        static let buttonBackgroundStart = Color.white
        static let buttonBackgroundEnd = Color(hex: "EEEEEE")
        
        static let labelBackground = Color.white
        static let textSecondary = Color.gray
    }
    
    struct Fonts {
        static func retro(size: CGFloat) -> Font {
            return .system(size: size, weight: .bold, design: .monospaced)
        }
        
        static let label = Font.system(size: 10, weight: .regular, design: .monospaced)
        static let title = Font.system(size: 18, weight: .heavy, design: .monospaced)
    }
    
    struct VintageColor: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let color: Color
        
        static let presets: [VintageColor] = [
            VintageColor(name: "Classic Beige", color: Color(hex: "FDFBF7"))
        ]
    }
}

extension Color {


    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != 1.0 {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
