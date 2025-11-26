import SwiftUI

struct DynamicBackgroundView: View {
    var colors: [Color]
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base background color (average of all or black)
            (colors.first ?? .black)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.3)) // Darken slightly for contrast
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                ZStack {
                    // Blob 1 - Top Left
                    Circle()
                        .fill(colors.count > 0 ? colors[0] : .blue)
                        .frame(width: width * 0.8, height: width * 0.8)
                        .blur(radius: 60)
                        .offset(x: animate ? -width * 0.2 : width * 0.1,
                                y: animate ? -height * 0.2 : height * 0.1)
                        .animation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animate)
                    
                    // Blob 2 - Top Right
                    Circle()
                        .fill(colors.count > 1 ? colors[1] : .purple)
                        .frame(width: width * 0.7, height: width * 0.7)
                        .blur(radius: 50)
                        .offset(x: animate ? width * 0.2 : -width * 0.1,
                                y: animate ? height * 0.1 : -height * 0.2)
                        .animation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)
                    
                    // Blob 3 - Bottom Left
                    Circle()
                        .fill(colors.count > 2 ? colors[2] : .pink)
                        .frame(width: width * 0.9, height: width * 0.9)
                        .blur(radius: 70)
                        .offset(x: animate ? -width * 0.1 : width * 0.2,
                                y: animate ? height * 0.2 : -height * 0.1)
                        .animation(Animation.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
                    
                    // Blob 4 - Bottom Right
                    Circle()
                        .fill(colors.count > 3 ? colors[3] : .orange)
                        .frame(width: width * 0.6, height: width * 0.6)
                        .blur(radius: 40)
                        .offset(x: animate ? width * 0.1 : -width * 0.2,
                                y: animate ? -height * 0.1 : height * 0.2)
                        .animation(Animation.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: animate)
                }
                .frame(width: width, height: height)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}
