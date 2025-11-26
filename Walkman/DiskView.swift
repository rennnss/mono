import SwiftUI

struct DiskView: View {
    @Environment(\.colorScheme) var colorScheme
    let name: String
    let color: Color
    var size: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Main Disk Body
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? .white : Theme.Colors.border, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 2, y: 2)
            
            // Inner Hole
            Circle()
                .fill(colorScheme == .dark ? Color.black : Theme.Colors.background) // Match background to look like a hole
                .frame(width: size * 0.2, height: size * 0.2)
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? .white : Theme.Colors.border, lineWidth: 1)
                )
            
            // Decorative Rings
            Circle()
                .stroke((colorScheme == .dark ? Color.white : Theme.Colors.border).opacity(0.3), lineWidth: 1)
                .frame(width: size * 0.6, height: size * 0.6)
            
            // Label/Name
            Text(name)
                .font(Theme.Fonts.retro(size: size * 0.12))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: size * 0.8)
                .shadow(color: (colorScheme == .dark ? Color.black : Color.white).opacity(0.5), radius: 0, x: 1, y: 1)
                .offset(y: size * 0.25) // Move text below center
        }
    }
}
