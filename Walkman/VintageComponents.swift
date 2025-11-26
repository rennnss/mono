import SwiftUI
import Combine

struct WalkmanChassis: View {
    var body: some View {
        ZStack {
            // Brushed Metal Background
            LinearGradient(gradient: Gradient(colors: [Theme.Colors.chassisGradientStart, Theme.Colors.chassisGradientEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            // Texture Overlay (Noise)
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .blendMode(.overlay)
            
            // Main Body Shape
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(gradient: Gradient(colors: [Theme.Colors.chassisDark, Theme.Colors.chassisLight]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 350, height: 600)
                .shadow(color: .black.opacity(0.5), radius: 20, x: 10, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct VintageButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
    }
}

struct VintageButton: View {
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [Theme.Colors.buttonBackgroundStart, Theme.Colors.buttonBackgroundEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.8), radius: 5, x: 3, y: 3)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: iconName)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .font(.system(size: 24))
            }
        }
        .buttonStyle(VintageButtonStyle())
    }
}

struct CassetteView: View {
    @Binding var isPlaying: Bool
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Cassette Body
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "333333"))
                .frame(width: 280, height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 2)
                )
            
            // Label Area
            RoundedRectangle(cornerRadius: 5)
                .fill(Theme.Colors.labelBackground)
                .frame(width: 260, height: 100)
                .offset(y: -20)
            
            // Reels
            HStack(spacing: 40) {
                CassetteReel(isPlaying: $isPlaying)
                CassetteReel(isPlaying: $isPlaying)
            }
            .offset(y: 10)
            
            // Window
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.black.opacity(0.5), lineWidth: 1)
                .frame(width: 180, height: 50)
                .background(Material.ultraThin) // Native Material
                .offset(y: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cassette Tape")
        .accessibilityValue(isPlaying ? "Playing" : "Stopped")
    }
}

struct CassetteReel: View {
    @Binding var isPlaying: Bool
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "gear")
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(.white)
            .rotationEffect(.degrees(rotation))
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                if isPlaying {
                    withAnimation(.linear(duration: 0.1)) {
                        rotation += 10
                    }
                }
            }
    }
}

struct VolumeWheel: View {
    @Binding var value: Float
    
    var body: some View {
        VStack {
            Text("VOL")
                .font(Theme.Fonts.label)
                .foregroundColor(Theme.Colors.textSecondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.black)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(gradient: Gradient(colors: [.green, .yellow, .red]), startPoint: .bottom, endPoint: .top))
                        .frame(height: geometry.size.height * CGFloat(value))
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let newValue = 1.0 - Float(gesture.location.y / geometry.size.height)
                            value = min(max(newValue, 0.0), 1.0)
                        }
                )
            }
            .frame(width: 20, height: 100)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
        .accessibilityElement()
        .accessibilityLabel("Volume")
        .accessibilityValue(String(format: "%.0f percent", value * 100))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + 0.1, 1.0)
            case .decrement:
                value = max(value - 0.1, 0.0)
            @unknown default:
                break
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
