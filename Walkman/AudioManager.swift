import Foundation
import AVFoundation
import SwiftUI
import Combine
import MediaPlayer

class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    
    var audioPlayer: AVAudioPlayer?
    
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentTrackName: String = "No Tape Inserted"
    @Published var currentArtistName: String = "Unknown Artist"
    @Published var albumArt: UIImage? = nil
    @Published var isMuted: Bool = false
    
    var playbackFinished = PassthroughSubject<Void, Never>()
    var skipForward = PassthroughSubject<Void, Never>()
    var skipBackward = PassthroughSubject<Void, Never>()
    
    private var timer: Timer?
    private var previousVolume: Float = 0.5
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
    }
    
    private func setupAudioSession() {
        do {
            // Configure audio session for background playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }
        
        // Next track command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipForward.send()
            return .success
        }
        
        // Previous track command
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipBackward.send()
            return .success
        }
        
        // Seek commands
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrackName
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentArtistName
        
        if let albumArt = albumArt {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: albumArt.size) { _ in
                return albumArt
            }
        }
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func playFile(at url: URL) {
        // Robustness check
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Error: File does not exist at path: \(url.path)")
            return
        }
        
        let secure = url.startAccessingSecurityScopedResource()
        defer {
            if secure {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // Stop existing player if any
            stop()
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlaying = true
            duration = audioPlayer?.duration ?? 0
            currentTrackName = url.lastPathComponent
            
            extractMetadata(from: url)
            startTimer()
            updateNowPlayingInfo()
            
        } catch {
            print("Error playing file: \(error)")
        }
    }
    
    func togglePlayPause() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
        updateNowPlayingInfo()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func setVolume(_ volume: Float) {
        if !isMuted {
            audioPlayer?.volume = volume
        }
        previousVolume = volume
    }
    
    func toggleMute() {
        if isMuted {
            // Unmute
            isMuted = false
            audioPlayer?.volume = previousVolume
        } else {
            // Mute
            isMuted = true
            previousVolume = audioPlayer?.volume ?? 0.5
            audioPlayer?.volume = 0
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func extractMetadata(from url: URL) {
        Task {
            let asset = AVURLAsset(url: url)
            
            var newArt: UIImage? = nil
            var newTitle: String = url.lastPathComponent
            var newArtist: String = "Unknown Artist"
            
            do {
                let metadata = try await asset.load(.commonMetadata)
                
                for item in metadata {
                    if item.commonKey == .commonKeyArtwork {
                        if let data = try? await item.load(.dataValue),
                           let image = UIImage(data: data) {
                            newArt = image
                        }
                    } else if item.commonKey == .commonKeyTitle {
                        if let title = try? await item.load(.stringValue) {
                            newTitle = title
                        }
                    } else if item.commonKey == .commonKeyArtist {
                        if let artist = try? await item.load(.stringValue) {
                            newArtist = artist
                        }
                    }
                }
            } catch {
                print("Error loading metadata: \(error)")
            }
            
            await MainActor.run {
                self.albumArt = newArt
                self.currentTrackName = newTitle
                self.currentArtistName = newArtist
                self.updateNowPlayingInfo()
            }
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopTimer()
        playbackFinished.send()
    }
}
