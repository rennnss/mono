import ActivityKit
import WidgetKit
import SwiftUI

// WalkmanAttributes is now in a separate file shared between targets

struct WalkmanLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WalkmanAttributes.self) { context in
            // Lock Screen/Banner UI
            HStack(spacing: 16) {
                // Album Art (Left)
                if let data = context.state.albumArtData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                        )
                }
                
                // Track Info (Center)
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.trackName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(context.state.artistName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Visualizer (Right)
                HStack(spacing: 3) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.pink)
                            .frame(width: 4, height: 20) // Static for now, animation in LA is limited
                    }
                }
                .padding(.trailing)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    if let data = context.state.albumArtData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // Visualizer
                    HStack(spacing: 2) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.pink)
                                .frame(width: 3, height: 15)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.trackName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.top, 8)
                }
            } compactLeading: {
                if let data = context.state.albumArtData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                        .clipped()
                } else {
                    Image(systemName: "music.note")
                        .foregroundColor(.pink)
                }
            } compactTrailing: {
                HStack(spacing: 1) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.pink)
                            .frame(width: 2, height: 10)
                    }
                }
            } minimal: {
                Image(systemName: "music.note")
                    .foregroundColor(.pink)
            }
            .keylineTint(Color.red)
        }
    }
}
