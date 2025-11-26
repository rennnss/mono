import ActivityKit
import Foundation

struct WalkmanAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var trackName: String
        var artistName: String
        var albumArtData: Data?
        var isPlaying: Bool
    }

    // Fixed non-changing properties about your activity go here!
}
