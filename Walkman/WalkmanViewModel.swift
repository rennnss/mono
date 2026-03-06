import SwiftUI
import Combine
import AVFoundation
import AVFAudio
import ActivityKit

struct MusicItem: Identifiable, Hashable, Codable, @unchecked Sendable {
    let id: UUID
    let url: URL
    let title: String
    var artwork: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case id, url, title
    }
    
    init(url: URL, title: String, artwork: UIImage? = nil) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.artwork = artwork
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        title = try container.decode(String.self, forKey: .title)
        artwork = nil // Artwork not persisted, reloaded from URL
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(title, forKey: .title)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MusicItem, rhs: MusicItem) -> Bool {
        lhs.id == rhs.id
    }
    
    // Helper to create a copy with a new ID
    func duplicateWithNewID() -> MusicItem {
        return MusicItem(id: UUID(), url: self.url, title: self.title, artwork: self.artwork)
    }
    
    // Internal init for duplication/hydration
    init(id: UUID, url: URL, title: String, artwork: UIImage?) {
        self.id = id
        self.url = url
        self.title = title
        self.artwork = artwork
    }
}

struct Playlist: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var items: [MusicItem]
    var colorHex: String // Store color as hex string
    
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() ?? "B9D7EA" }
    }
    
    init(name: String, items: [MusicItem], color: Color) {
        self.id = UUID()
        self.name = name
        self.items = items
        self.colorHex = color.toHex() ?? "B9D7EA"
    }
}

enum PlaybackMode {
    case none
    case repeatAll
    case repeatOne
    case shuffle
}

class WalkmanViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTrack: String = "No Tape"
    @Published var currentArtist: String = "Unknown Artist"
    @Published var albumArt: UIImage? = nil
    @Published var volume: Float = 0.5
    @Published var showDocumentPicker: Bool = false
    @Published var allSongs: [MusicItem] = [] // Store all songs
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var isReady: Bool = false
    @Published var isFirstLaunch: Bool = false
    private var currentPlaylistFilter: Playlist? = nil
    
    @Published var playlist: [MusicItem] = []
    @Published var queue: [MusicItem] = [] // Queue for "Play Next"
    @Published var playlists: [Playlist] = [] // New playlists property
    @Published var progress: Double = 0.0
    @Published var isMuted: Bool = false
    @Published var currentTheme: Theme.VintageColor = Theme.VintageColor.presets[0]
    @Published var showThemePicker: Bool = false // Keeping this for now, but will repurpose UI
    
    @Published var backgroundColors: [Color] = []
    @Published var isDarkBackground: Bool = false

    @Published var currentTimeString: String = "0:00"
    
    @Published var playbackMode: PlaybackMode = .none
    
    @Published var currentLyrics: String? = nil
    @Published var showLyrics: Bool = false
    private let lyricsService = LyricsService.shared
    
    private var audioManager = AudioManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var activity: Activity<WalkmanAttributes>?
    private var accessedFolderURL: URL?
    
    deinit {
        if let url = accessedFolderURL {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    // Default Album Art
    private var defaultArtImages: [UIImage] = []
    private var currentDefaultArtIndex = 0
    
    init() {
        setupBindings()
        loadTheme()
        loadBookmark() // Load persisted folder
        loadDefaultArt() // Load default art from folder
        loadPlaylists() // Load persisted playlists
        
        // Load persist default art index
        currentDefaultArtIndex = UserDefaults.standard.integer(forKey: "currentDefaultArtIndex")
        
        // Set initial default art
        setNextDefaultArt()
    }
    
    private func setupBindings() {
        audioManager.$isPlaying
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying
                if isPlaying {
                    self?.startOrUpdateActivity()
                } else {
                    self?.startOrUpdateActivity()
                }
            }
            .store(in: &cancellables)
        
            //.store(in: &cancellables)
        
        audioManager.$currentTrackName
            .combineLatest(audioManager.$currentArtistName)
            .sink { [weak self] name, artist in
                self?.currentTrack = name
                self?.currentArtist = artist
                self?.startOrUpdateActivity()
                self?.fetchLyrics(title: name, artist: artist)
            }
            .store(in: &cancellables)
            
        audioManager.$albumArt
            .sink { [weak self] art in
                if let art = art {
                    self?.albumArt = art
                    self?.backgroundColors = art.dominantColors()
                    self?.isDarkBackground = art.isDarkBackground()
                } else {
                    // Use default art if no art is present
                    // We only change the default art if we are transitioning to a new track that has no art
                    // But here we just want to ensure *some* art is shown.
                    // The requirement says "alternates".
                    // Let's assume we change it whenever we get a nil art (which happens on track change).
                    self?.setNextDefaultArt()
                }
                self?.startOrUpdateActivity()
            }
            .store(in: &cancellables)
            
        audioManager.$isMuted
            .assign(to: \.isMuted, on: self)
            .store(in: &cancellables)
            
        // Calculate progress and time string
        Publishers.CombineLatest(audioManager.$currentTime, audioManager.$duration)
            .sink { [weak self] current, duration in
                guard let self = self else { return }
                self.progress = duration > 0 ? current / duration : 0.0
                self.currentTimeString = self.formatTime(current)
            }
            .store(in: &cancellables)
            
        // Listen for playback finished
        audioManager.playbackFinished
            .sink { [weak self] in
                self?.handlePlaybackFinished()
            }
            .store(in: &cancellables)
        
        // Listen for skip forward from remote controls
        audioManager.skipForward
            .sink { [weak self] in
                self?.playNext()
            }
            .store(in: &cancellables)
        
        // Listen for skip backward from remote controls
        audioManager.skipBackward
            .sink { [weak self] in
                self?.playPrevious()
            }
            .store(in: &cancellables)
            
        // Listen for search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Live Activity
    private func startOrUpdateActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = WalkmanAttributes()
        let contentState = WalkmanAttributes.ContentState(
            trackName: currentTrack,
            artistName: currentArtist,
            albumArtData: albumArt?.jpegData(compressionQuality: 0.5), // Compress to save size
            isPlaying: isPlaying
        )
        
        if let activity = activity {
            Task {
                let content = ActivityContent(state: contentState, staleDate: nil)
                await activity.update(content)
            }
        } else if isPlaying {
            do {
                let content = ActivityContent(state: contentState, staleDate: nil)
                activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                print("Error starting activity: \(error)")
            }
        }
    }
    
    private func endActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
        }
    }
    
    func togglePlayPause() {
        audioManager.togglePlayPause()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func toggleMute() {
        audioManager.toggleMute()
    }
    
    func toggleLyrics() {
        showLyrics.toggle()
    }
    
    private func fetchLyrics(title: String, artist: String) {
        currentLyrics = nil // Reset while fetching
        
        // Don't fetch if unknown
        guard title != "No Tape", artist != "Unknown Artist" else { return }
        
        Task {
            do {
                let lyrics = try await lyricsService.fetchLyrics(title: title, artist: artist)
                await MainActor.run {
                    // Check if track hasn't changed while fetching
                    if self.currentTrack == title && self.currentArtist == artist {
                        self.currentLyrics = lyrics
                    }
                }
            } catch {
                print("Error fetching lyrics: \(error)")
            }
        }
    }
    
    func setTheme(_ theme: Theme.VintageColor) {
        currentTheme = theme
        UserDefaults.standard.set(theme.name, forKey: "selectedThemeName")
    }
    
    private func loadTheme() {
        // Default to Classic Beige if nothing saved or found
        currentTheme = Theme.VintageColor.presets.first ?? Theme.VintageColor(name: "Classic Beige", color: Color(hex: "FDFBF7"))
    }
    
    func updateVolume(_ value: Float) {
        volume = value
        audioManager.setVolume(value)
    }
    
    func seek(to progress: Double) {
        let duration = audioManager.duration
        guard duration > 0 else { return }
        let time = duration * progress
        audioManager.seek(to: time)
    }
    
    // MARK: - Playlist Management
    
    func createPlaylist(name: String, items: [MusicItem], color: Color) {
        // Filter out duplicates within the input array itself (by URL)
        var uniqueURLs = Set<URL>()
        let uniqueItemsInput = items.filter { item in
            if uniqueURLs.contains(item.url) {
                return false
            } else {
                uniqueURLs.insert(item.url)
                return true
            }
        }
        
        // Ensure unique IDs for playlist items
        let uniqueItems = uniqueItemsInput.map { $0.duplicateWithNewID() }
        let newPlaylist = Playlist(name: name, items: uniqueItems, color: color)
        playlists.append(newPlaylist)
        savePlaylists()
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            let deletedPlaylist = playlists[index]
            playlists.remove(at: index)
            savePlaylists()
            
            // If we are currently viewing this playlist, reset to All Songs
            if currentPlaylistFilter?.id == deletedPlaylist.id {
                currentPlaylistFilter = nil
                applyFilters()
            }
        }
    }
    
    func updatePlaylist(_ playlist: Playlist, name: String, color: Color, items: [MusicItem]? = nil) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            var updatedPlaylist = playlists[index]
            updatedPlaylist.name = name
            updatedPlaylist.color = color
            if let items = items {
                updatedPlaylist.items = items
            }
            playlists[index] = updatedPlaylist
            savePlaylists()
            
            // If we are currently viewing this playlist, update the filter
            if currentPlaylistFilter?.id == updatedPlaylist.id {
                currentPlaylistFilter = updatedPlaylist
                applyFilters()
            }
        }
    }
    
    func addToPlaylist(_ playlist: Playlist, items: [MusicItem]) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            var updatedPlaylist = playlists[index]
            
            // Filter out items that are already in the playlist (by URL)
            let existingURLs = Set(updatedPlaylist.items.map { $0.url })
            let newItems = items.filter { !existingURLs.contains($0.url) }
            
            guard !newItems.isEmpty else { return } // Nothing to add
            
            // Ensure unique IDs for added items
            let uniqueItems = newItems.map { $0.duplicateWithNewID() }
            updatedPlaylist.items.append(contentsOf: uniqueItems)
            playlists[index] = updatedPlaylist
            savePlaylists()
            
            // If we are currently viewing this playlist, update the filter
            if currentPlaylistFilter?.id == updatedPlaylist.id {
                currentPlaylistFilter = updatedPlaylist
                applyFilters()
            }
        }
    }

    func addToQueue(_ item: MusicItem) {
        // Reset playback mode to default if in Shuffle or Repeat One
        if playbackMode == .shuffle || playbackMode == .repeatOne {
            playbackMode = .none
        }
        queue.append(item)
    }

    func removeFromQueue(at offsets: IndexSet) {
        queue.remove(atOffsets: offsets)
    }
    
    private func startAccessingFolder(url: URL) {
        // Stop accessing previous folder if any
        if let previousURL = accessedFolderURL {
            previousURL.stopAccessingSecurityScopedResource()
        }
        
        // Start accessing new folder
        if url.startAccessingSecurityScopedResource() {
            accessedFolderURL = url
        } else {
            print("Failed to access security scoped resource: \(url)")
        }
    }
    
    func loadFile(url: URL) {
        if url.hasDirectoryPath {
            saveBookmark(for: url)
            startAccessingFolder(url: url)
            scanFolder(at: url)
        } else {
            // Single file - maybe add to a temp playlist?
            // For now, just play it
            let item = MusicItem(url: url, title: url.lastPathComponent, artwork: nil)
            playlist = [item]
            playTrack(item)
        }
    }
    
    func scanFolder(at url: URL) {
        // Access is now handled by startAccessingFolder before calling this
        
        // Collect file URLs synchronously before entering async context
        var audioFiles: [URL] = []
        
        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            // Iterate through all files recursively
            for case let fileURL as URL in enumerator {
                // Check if it's a regular file (not a directory)
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                   let isRegularFile = resourceValues.isRegularFile,
                   isRegularFile {
                    let ext = fileURL.pathExtension.lowercased()
                    if ["mp3", "m4a", "wav", "aiff"].contains(ext) {
                        audioFiles.append(fileURL)
                    }
                }
            }
        }
        
        Task {
            // Parallel Processing using TaskGroup
            
            // Parallel Processing using TaskGroup
            // Return tuple (URL, String, UIImage?) to avoid MainActor isolation issues with MusicItem.init
            let results = await withTaskGroup(of: (URL, String, UIImage?).self) { group -> [(URL, String, UIImage?)] in
                for fileURL in audioFiles {
                    group.addTask {
                        let asset = AVURLAsset(url: fileURL)
                        var art: UIImage? = nil
                        
                        if let metadata = try? await asset.load(.commonMetadata) {
                            for item in metadata {
                                if item.commonKey == .commonKeyArtwork {
                                    if let data = try? await item.load(.dataValue),
                                       let image = UIImage(data: data) {
                                        // Downsample image for library performance
                                        art = image.preparingThumbnail(of: CGSize(width: 100, height: 100))
                                    }
                                }
                            }
                        }
                        
                        return (fileURL, fileURL.lastPathComponent, art)
                    }
                }
                
                var collected: [(URL, String, UIImage?)] = []
                for await item in group {
                    collected.append(item)
                }
                return collected
            }
            
            // Sort results by clean title
            let sortedResults = results.sorted { item1, item2 in
                let title1 = self.cleanTitle(item1.1)
                let title2 = self.cleanTitle(item2.1)
                return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
            }
            
            await MainActor.run {
                // Create MusicItems on MainActor
                self.allSongs = sortedResults.map { MusicItem(url: $0.0, title: $0.1, artwork: $0.2) }
                self.hydratePlaylists()
                
                self.hydratePlaylists()
                
                // Always apply filters to update the view with new songs
                self.applyFilters()
                
                // Signal that the app is ready (Dismiss Launch Screen)
                
                // Signal that the app is ready (Dismiss Launch Screen)
                withAnimation {
                    self.isReady = true
                }
            }
        }
    }
    
    private func hydratePlaylists() {
        for i in 0..<playlists.count {
            var hydratedItems: [MusicItem] = []
            for item in playlists[i].items {
                // Match by URL instead of ID to ensure artwork persists across launches
                if let match = allSongs.first(where: { $0.url == item.url }) {
                    // Create a copy with the *original playlist item ID* but the *fresh data* (artwork/title)
                    let hydratedItem = MusicItem(id: item.id, url: match.url, title: match.title, artwork: match.artwork)
                    hydratedItems.append(hydratedItem)
                } else {
                    hydratedItems.append(item)
                }
            }
            playlists[i].items = hydratedItems
        }
    }

    func filterLibrary(by playlist: Playlist?) {
        currentPlaylistFilter = playlist
        applyFilters()
    }
    
    private func applyFilters() {
        var items = allSongs
        
        // 1. Filter by Playlist
        if let playlist = currentPlaylistFilter {
            items = playlist.items
        }
        
        // 2. Filter by Search Text
        if !searchText.isEmpty {
            items = items.filter { item in
                let clean = cleanTitle(item.title)
                return clean.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        self.playlist = items
    }
    
    func playTrack(_ item: MusicItem, populateQueue: Bool = true) {
        audioManager.playFile(at: item.url)
        
        // Only populate queue if requested (default behavior for manual clicks)
        // When playing from queue (playNext), we pass false to avoid overwriting the queue
        if populateQueue {
            // Auto-populate queue with subsequent songs from current context in Default or Repeat All mode
            if playbackMode == .none || playbackMode == .repeatAll {
                if let currentIndex = playlist.firstIndex(where: { $0.id == item.id }) {
                    let nextIndex = currentIndex + 1
                    if nextIndex < playlist.count {
                        let subsequentItems = Array(playlist[nextIndex...])
                        self.queue = subsequentItems
                    } else {
                        self.queue = []
                    }
                }
            }
        }
    }
    
    func playTrack(at url: URL) {
        // Helper for legacy calls or direct URL usage
        if let item = playlist.first(where: { $0.url == url }) {
            playTrack(item)
        } else {
            audioManager.playFile(at: url)
        }
    }
    
    func playPlaylist(_ playlist: Playlist) {
        guard !playlist.items.isEmpty else { return }
        
        // Set the current context to this playlist
        self.playlist = playlist.items
        
        // Play the first track
        if let first = playlist.items.first {
            playTrack(first)
        }
    }
    
    // MARK: - Track Navigation
    func playNext(currentIndex: Int? = nil, loop: Bool = false) {
        // Check queue first
        if !queue.isEmpty {
            let nextItem = queue.removeFirst()
            playTrack(nextItem, populateQueue: false)
            return
        }

        // Shuffle Mode
        if playbackMode == .shuffle {
            if let randomItem = playlist.randomElement() {
                playTrack(randomItem)
            }
            return
        }
        
        let idx = currentIndex ?? playlist.firstIndex(where: { $0.url == audioManager.audioPlayer?.url })
        guard let currentIndex = idx else {
             if let first = playlist.first { playTrack(first) }
             return
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < playlist.count {
            playTrack(playlist[nextIndex])
        } else if loop || playbackMode == .repeatAll {
            if let first = playlist.first {
                playTrack(first)
            }
        }
    }
    
    func playPrevious() {
        guard !playlist.isEmpty else { return }
        guard let currentURL = audioManager.audioPlayer?.url,
              let currentIndex = playlist.firstIndex(where: { $0.url == currentURL }) else {
            if let first = playlist.first { playTrack(first) }
            return
        }
        
        // In Shuffle mode, Previous always restarts the song
        if playbackMode == .shuffle {
            audioManager.seek(to: 0)
            return
        }
        
        if audioManager.currentTime > 3.0 {
            audioManager.seek(to: 0)
            return
        }
        
        let previousIndex = currentIndex - 1
        if previousIndex >= 0 {
            // Do NOT populate queue when going back, to preserve any custom queue
            playTrack(playlist[previousIndex], populateQueue: false)
        } else if playbackMode == .repeatAll {
            playTrack(playlist[playlist.count - 1], populateQueue: false)
        }
    }
    
    // MARK: - Persistence
    private func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: "folderBookmark")
        } catch {
            print("Failed to save bookmark: \(error)")
        }
    }
    
    private func loadBookmark() {
        guard let data = UserDefaults.standard.data(forKey: "folderBookmark") else {
            // No bookmark found (first launch)
            self.isFirstLaunch = true
            // Do NOT set isReady = true here, wait for user interaction
            return
        }
        
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                saveBookmark(for: url)
            }
            
            startAccessingFolder(url: url)
            scanFolder(at: url)
        } catch {
            print("Failed to load bookmark: \(error)")
            // Failed to load, so we are ready (empty state)
            self.isReady = true
        }
    }
    
    private func savePlaylists() {
        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: "savedPlaylists")
        } catch {
            print("Failed to save playlists: \(error)")
        }
    }
    
    private func loadPlaylists() {
        guard let data = UserDefaults.standard.data(forKey: "savedPlaylists") else { return }
        do {
            playlists = try JSONDecoder().decode([Playlist].self, from: data)
        } catch {
            print("Failed to load playlists: \(error)")
        }
    }
    
    func startListening() {
        withAnimation {
            self.isReady = true
            self.isFirstLaunch = false
        }
    }
    
    // MARK: - Playback Controls
    func togglePlaybackMode() {
        switch playbackMode {
        case .none: playbackMode = .repeatAll
        case .repeatAll: playbackMode = .repeatOne
        case .repeatOne: playbackMode = .shuffle
        case .shuffle: playbackMode = .none
        }
        
        // Clear queue if entering Shuffle or Repeat One
        if playbackMode == .shuffle || playbackMode == .repeatOne {
            queue.removeAll()
        }
    }
    
    private func handlePlaybackFinished() {
        guard let currentURL = audioManager.audioPlayer?.url,
              let currentIndex = playlist.firstIndex(where: { $0.url == currentURL }) else { return }
        
        switch playbackMode {
        case .none:
            // Check queue here as well if not handled by playNext logic implicitly, 
            // but playNext handles it. However, we need to pass the index.
            // If queue has items, playNext will prioritize them.
            playNext(currentIndex: currentIndex)
        case .repeatAll:
            playNext(currentIndex: currentIndex, loop: true)
        case .repeatOne:
            if let item = playlist.indices.contains(currentIndex) ? playlist[currentIndex] : nil {
                playTrack(item)
            }
        case .shuffle:
            if let randomItem = playlist.randomElement() {
                playTrack(randomItem)
            }
        }
    }

    
    private func loadDefaultArt() {
        // Look for the DefaultArt folder in the bundle
        if let resourcePath = Bundle.main.resourcePath {
            let defaultArtPath = (resourcePath as NSString).appendingPathComponent("DefaultArt")
            if FileManager.default.fileExists(atPath: defaultArtPath) {
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: defaultArtPath)
                    for item in items.sorted() {
                        if ["png", "jpg", "jpeg"].contains((item as NSString).pathExtension.lowercased()) {
                            let fullPath = (defaultArtPath as NSString).appendingPathComponent(item)
                            if let image = UIImage(contentsOfFile: fullPath) {
                                defaultArtImages.append(image)
                            }
                        }
                    }
                } catch {
                    print("Error loading default art: \(error)")
                }
            }
        }
        
        // Fallback
        if defaultArtImages.isEmpty {
             for i in 0...10 {
                 if let path = Bundle.main.path(forResource: "default_art_\(i)", ofType: "png") ?? Bundle.main.path(forResource: "default_art_\(i)", ofType: "jpg"),
                    let image = UIImage(contentsOfFile: path) {
                     defaultArtImages.append(image)
                 }
             }
        }
    }

    private func setNextDefaultArt() {
        guard !defaultArtImages.isEmpty else { return }
        
        let image = defaultArtImages[currentDefaultArtIndex]
        self.albumArt = image
        // Do NOT update background colors for default art as requested
        // self.backgroundColors = image.dominantColors()
        // self.isDarkBackground = image.isDarkBackground()
        
        // Reset background to default/empty so it uses theme
        self.backgroundColors = []
        self.isDarkBackground = false
        
        // Prepare index for next time
        currentDefaultArtIndex = (currentDefaultArtIndex + 1) % defaultArtImages.count
        UserDefaults.standard.set(currentDefaultArtIndex, forKey: "currentDefaultArtIndex")
    }

    
    // MARK: - Helpers
    func cleanTitle(_ title: String) -> String {
        // Remove file extension
        let name = (title as NSString).deletingPathExtension
        
        // Remove leading numbers and whitespace/punctuation
        // Regex: ^[\d\s\p{Punct}]+
        // This removes digits, whitespace, and punctuation from the start
        if let range = name.range(of: "^[\\d\\s\\p{Punct}]+", options: .regularExpression) {
            let cleaned = String(name[range.upperBound...])
            return cleaned.isEmpty ? name : cleaned
        }
        return name
    }
}

// MARK: - Lyrics Service
struct LyricsResponse: Codable {
    let lyrics: String
}

class LyricsService {
    static let shared = LyricsService()
    private let fileManager = FileManager.default
    private let lyricsDirectoryName = "Lyrics"
    
    private init() {
        createLyricsDirectory()
    }
    
    private var lyricsDirectoryURL: URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(lyricsDirectoryName)
    }
    
    private func createLyricsDirectory() {
        guard let url = lyricsDirectoryURL else { return }
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                print("Failed to create lyrics directory: \(error)")
            }
        }
    }
    
    private func getLyricsFileURL(title: String, artist: String) -> URL? {
        guard let dirURL = lyricsDirectoryURL else { return nil }
        let safeTitle = title.replacingOccurrences(of: "/", with: "_")
        let safeArtist = artist.replacingOccurrences(of: "/", with: "_")
        let filename = "\(safeArtist)-\(safeTitle).txt"
        return dirURL.appendingPathComponent(filename)
    }
    
    func loadLyrics(title: String, artist: String) -> String? {
        guard let fileURL = getLyricsFileURL(title: title, artist: artist) else { return nil }
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                return try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                print("Failed to load lyrics from file: \(error)")
            }
        }
        return nil
    }
    
    func saveLyrics(_ lyrics: String, title: String, artist: String) {
        guard let fileURL = getLyricsFileURL(title: title, artist: artist) else { return }
        do {
            try lyrics.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save lyrics to file: \(error)")
        }
    }
    
    func fetchLyrics(title: String, artist: String) async throws -> String? {
        // First check local storage
        if let cachedLyrics = loadLyrics(title: title, artist: artist) {
            return cachedLyrics
        }
        
        // Fetch from API
        // Clean up strings for URL (simple encoding)
        guard let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        
        let urlString = "https://api.lyrics.ovh/v1/\(encodedArtist)/\(encodedTitle)"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // 404 means no lyrics found usually
            return nil
        }
        
        let lyricsResponse = try JSONDecoder().decode(LyricsResponse.self, from: data)
        let lyrics = lyricsResponse.lyrics
        
        // Save to local storage
        if !lyrics.isEmpty {
            saveLyrics(lyrics, title: title, artist: artist)
        }
        
        return lyrics
    }
}
