import SwiftUI

struct LaunchScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: WalkmanViewModel
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // "mono" Text
                Text("mono")
                    .font(Theme.Fonts.retro(size: 60))
                    .foregroundColor(Theme.Colors.text)
                    .shadow(color: Theme.Colors.accentPink.opacity(0.5), radius: 10, x: 0, y: 0)
                
                // Vintage Cassette Graphic
                ZStack {
                    // Cassette Body
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "333333"))
                        .frame(width: 200, height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.Colors.border, lineWidth: 4)
                        )
                    
                    // Label Area
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.accentPink.opacity(0.2))
                        .frame(width: 180, height: 70)
                        .offset(y: -15)
                    
                    // Spools
                    HStack(spacing: 40) {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.black))
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.black))
                    }
                    .offset(y: -15)
                    
                    // Bottom Trapezoid (Head area)
                    Path { path in
                        path.move(to: CGPoint(x: 40, y: 120))
                        path.addLine(to: CGPoint(x: 160, y: 120))
                        path.addLine(to: CGPoint(x: 150, y: 100))
                        path.addLine(to: CGPoint(x: 50, y: 100))
                        path.closeSubpath()
                    }
                    .fill(Color(hex: "222222"))
                    .frame(width: 200, height: 120)
                }
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                // Loading Indicator or Start Button
                if viewModel.isFirstLaunch {
                    Button(action: {
                        viewModel.startListening()
                    }) {
                        Text("Start listening!")
                            .font(Theme.Fonts.retro(size: 20))
                            .foregroundColor(Theme.Colors.text)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Theme.Colors.accentPink.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.Colors.border, lineWidth: 2)
                            )
                    }
                    .padding(.bottom, 50)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.text))
                        .scaleEffect(1.5)
                        .padding(.bottom, 50)
                }
            }
        }
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView(viewModel: WalkmanViewModel())
    }
}
