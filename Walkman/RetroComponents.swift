import SwiftUI

struct RetroButton: View {
    let iconName: String
    let label: String?
    let action: () -> Void
    var foregroundColor: Color = Theme.Colors.text
    var backgroundColor: Color = Theme.Colors.surface
    
    init(iconName: String, label: String? = nil, foregroundColor: Color = Theme.Colors.text, backgroundColor: Color = Theme.Colors.surface, action: @escaping () -> Void) {
        self.iconName = iconName
        self.label = label
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .border(Theme.Colors.border, width: 2)
                    .shadow(color: .black.opacity(0.2), radius: 0, x: 4, y: 4)
                
                if let label = label {
                    Text(label.uppercased())
                        .font(Theme.Fonts.retro(size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(foregroundColor)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(foregroundColor)
                }
            }
            .frame(height: 50)
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
    }
}

struct RetroProgressBar: View {
    var progress: Double // 0.0 to 1.0
    var trackName: String
    var foregroundColor: Color = Theme.Colors.text
    
    var body: some View {
        GeometryReader { geometry in
            let barWidth: CGFloat = 3
            let spacing: CGFloat = 1
            let totalWidth = barWidth + spacing
            let count = Int(geometry.size.width / totalWidth)
            
            HStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { index in
                    // Pseudo-random height based on trackName and index
                    let seed = trackName.hashValue ^ index
                    // Use a combination of sine waves for a more "musical" look
                    let random = abs(sin(Double(seed) * 0.1) * 10 + sin(Double(index) * 0.5) * 5)
                    let height = CGFloat(4 + (Int(random * 100) % 18)) // Height between 4 and 22
                    
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Double(index) / Double(count) < progress ? foregroundColor : foregroundColor.opacity(0.2))
                            .frame(width: barWidth, height: height)
                    }
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
        .frame(height: 24)
        .clipped()
    }
}

struct PixelBox<Header: View, Footer: View>: View {
    let header: Header?
    let footer: Footer?
    let content: AnyView
    var foregroundColor: Color = Theme.Colors.text
    var borderColor: Color = Theme.Colors.border
    
    init(title: String? = nil, foregroundColor: Color = Theme.Colors.text, borderColor: Color = Theme.Colors.border, @ViewBuilder content: () -> some View) where Header == Text, Footer == EmptyView {
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        if let title = title {
            self.header = Text(title.uppercased())
                .font(Theme.Fonts.retro(size: 12))
                .fontWeight(.bold)
                .foregroundColor(foregroundColor)
        } else {
            self.header = nil
        }
        self.footer = nil
        self.content = AnyView(content())
    }
    
    init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> some View) where Footer == EmptyView {
        self.header = header()
        self.footer = nil
        self.content = AnyView(content())
    }
    
    init(@ViewBuilder content: () -> some View, @ViewBuilder footer: () -> Footer) where Header == EmptyView {
        self.header = nil
        self.footer = footer()
        self.content = AnyView(content())
    }
    
    init(@ViewBuilder header: () -> Header, @ViewBuilder footer: () -> Footer, @ViewBuilder content: () -> some View) {
        self.header = header()
        self.footer = footer()
        self.content = AnyView(content())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let header = header {
                HStack {
                    header
                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(Theme.Colors.surface)
                .border(borderColor, width: 2)
                .offset(y: 2) // Overlap border
                .zIndex(1)
            }
            
            ZStack {
                Rectangle()
                    .fill(Color.clear) // Allow background to show through or be set by caller
                    .background(Color.clear) // Changed from Material.ultraThin to Color.clear
                    .border(borderColor, width: 2)
                
                content
            }
            
            if let footer = footer {
                HStack {
                    footer
                }
                .frame(height: 24)
                .background(Theme.Colors.surface)
                .border(borderColor, width: 2)
                .offset(y: -2) // Overlap border
                .zIndex(1)
            }
        }
    }
}

struct RetroTab: View {
    let iconName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                Text(title)
                    .font(Theme.Fonts.retro(size: 10))
            }
            .foregroundColor(isSelected ? Theme.Colors.text : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            // Removed active border
        }
    }
}

struct RetroSearchBar: View {
    @Binding var text: String
    var placeholder: String = "SEARCH..."
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.text)
                    .font(.system(size: 16, weight: .bold))
                
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(Theme.Colors.text.opacity(0.5))
                            .font(Theme.Fonts.retro(size: 14))
                    }
                    .foregroundColor(Theme.Colors.text)
                    .font(Theme.Fonts.retro(size: 14))
                    .accentColor(Theme.Colors.text)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.text)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(12)
            .background(Theme.Colors.surface)
            .border(Theme.Colors.border, width: 2)
            
            if let onCancel = onCancel {
                Button(action: onCancel) {
                    Text("CANCEL")
                        .font(Theme.Fonts.retro(size: 12))
                        .foregroundColor(Theme.Colors.text)
                }
                .padding(.leading, 8)
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
