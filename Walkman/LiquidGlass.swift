import SwiftUI

struct LiquidGlass: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Material.ultraThin)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlass())
    }
}

struct GlassContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
        }
        .padding()
        .liquidGlass()
    }
}
