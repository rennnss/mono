import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WalkmanViewModel()
    
    @State private var selectedTab: Int = 0
    
    @State private var showDocumentPicker = false
    @State private var showPlaylistCreation = false
    @State private var showQueueEdit = false
    
    var body: some View {
        ZStack {
            ZStack {
                if !viewModel.backgroundColors.isEmpty {
                    DynamicBackgroundView(colors: viewModel.backgroundColors)
                } else {
                    viewModel.currentTheme.color.ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        Button(action: {
                            viewModel.togglePlaybackMode()
                        }) {
                            ZStack {
                                switch viewModel.playbackMode {
                                case .none:
                                    Image(systemName: "repeat")
                                        .font(.system(size: 16))
                                        .opacity(0.5)
                                case .repeatAll:
                                    Image(systemName: "repeat")
                                        .font(.system(size: 16))
                                case .repeatOne:
                                    Image(systemName: "repeat.1")
                                        .font(.system(size: 16))
                                case .shuffle:
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 16))
                                }
                            }
                            .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2)) // Liquid glass style
                            .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                        }
                        
                        Spacer()
                        
                        Text("mono")
                            .font(Theme.Fonts.title)
                            .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleLyrics()
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16))
                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2)) // Liquid glass style
                                .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleMute()
                        }) {
                            Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16))
                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2)) // Liquid glass style
                                .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                        }
                    }
                    .padding()
                    
                    if selectedTab == 0 {
                        // PLAYER VIEW
                        ScrollView {
                            VStack(spacing: 20) {
                                // Visualizer / Art Area
                                PixelBox(content: {
                                    ZStack {
                                        if let art = viewModel.albumArt {
                                            GeometryReader { geo in
                                                Image(uiImage: art)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: geo.size.width, height: 300)
                                                    .clipped()
                                            }
                                        } else {
                                            Rectangle()
                                                .fill(Color(hex: "555555"))
                                                .overlay(
                                                    Image(systemName: "waveform")
                                                        .font(.system(size: 60))
                                                        .foregroundColor(.white.opacity(0.5))
                                                )
                                        }
                                    }
                                    .frame(height: 300)
                                    .clipped()
                                    .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2) // Added border to album art
                                })
                                .padding(.horizontal)
                                
                                // Progress Bar (Visualizer)
                                ZStack {
                                    Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                                    
                                    RetroProgressBar(progress: viewModel.progress, trackName: viewModel.currentTrack, foregroundColor: viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                        .padding(2) // Inner padding
                                    
                                    // Invisible Slider
                                    GeometryReader { geo in
                                        Color.clear
                                            .contentShape(Rectangle())
                                            .gesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { value in
                                                        let width = geo.size.width
                                                        let percentage = value.location.x / width
                                                        let clamped = min(max(percentage, 0), 1)
                                                        viewModel.seek(to: clamped)
                                                    }
                                            )
                                    }
                                }
                                .frame(height: 28) // Height for progress bar container
                                .padding(.horizontal)
                                .padding(.top, -10) // Pull closer but keep separate, or adjust spacing in VStack
                                
                                // Info Box
                                PixelBox(foregroundColor: viewModel.isDarkBackground ? .white : Theme.Colors.text, borderColor: viewModel.isDarkBackground ? .white : Theme.Colors.border) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(viewModel.currentTrack)
                                                .font(Theme.Fonts.retro(size: 16))
                                                .fontWeight(.bold)
                                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                                .lineLimit(1) // Truncate long titles
                                                .truncationMode(.tail)
                                            
                                            Divider().background(viewModel.isDarkBackground ? .white : Theme.Colors.border)
                                            
                                            Text(viewModel.currentTimeString) // Real time
                                                .font(Theme.Fonts.retro(size: 24))
                                                .fontWeight(.bold)
                                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                        }
                                        .padding()
                                        
                                        Spacer()
                                    }
                                    .background(Color.white.opacity(0.2)) // White style liquid glass always
                                }
                                .padding(.horizontal)
                                
                                // Controls
                                HStack(spacing: 16) {
                                    RetroButton(iconName: viewModel.isPlaying ? "pause.fill" : "play.fill", foregroundColor: viewModel.isDarkBackground ? .white : Theme.Colors.text, backgroundColor: Color.white.opacity(0.2), action: {
                                        viewModel.togglePlayPause()
                                    })
                                    .frame(width: 100)
                                    
                                    Image(systemName: "circle.grid.3x3.fill") // Decorative speaker grill
                                        .font(.system(size: 30))
                                        .opacity(0.3)
                                        .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                    
                                    RetroButton(iconName: "backward.fill", foregroundColor: viewModel.isDarkBackground ? .white : Theme.Colors.text, backgroundColor: Color.white.opacity(0.2), action: {
                                        viewModel.playPrevious()
                                    })
                                    RetroButton(iconName: "forward.fill", foregroundColor: viewModel.isDarkBackground ? .white : Theme.Colors.text, backgroundColor: Color.white.opacity(0.2), action: {
                                        viewModel.playNext()
                                    })
                                }
                                .padding(.horizontal)
                                
                                // Queue View
                                if !viewModel.queue.isEmpty && (viewModel.playbackMode == .none || viewModel.playbackMode == .repeatAll) {
                                    HStack {
                                        Text("Up Next")
                                            .font(Theme.Fonts.retro(size: 18)) // Increased size
                                            .foregroundColor(viewModel.isDarkBackground ? .white.opacity(0.8) : Theme.Colors.text.opacity(0.8))
                                        
                                        if let first = viewModel.queue.first, let art = first.artwork {
                                            Image(uiImage: art)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40, height: 40) // Increased size
                                                .clipped()
                                                .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 1)
                                        }
                                        

                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            showQueueEdit = true
                                        }) {
                                            Text("Edit")
                                                .font(Theme.Fonts.retro(size: 16))
                                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            viewModel.queue.removeAll()
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 20))
                                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                                .frame(width: 40, height: 40)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    } else {
                        // LIBRARY VIEW
                        BookshelfView(viewModel: viewModel)
                    }
                    
                    Spacer()
                    
                    // Tab Bar
                    if !viewModel.isSearching {
                        VStack(spacing: 0) {
                            // Tab content with material background
                            HStack(spacing: 0) {
                                // Player Tab
                                Button(action: { selectedTab = 0 }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 20))
                                        Text("Player")
                                            .font(Theme.Fonts.retro(size: 10))
                                    }
                                    .foregroundColor(selectedTab == 0 ? (viewModel.isDarkBackground ? .white : .black) : (viewModel.isDarkBackground ? .white.opacity(0.5) : .black.opacity(0.5)))
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 20) // Shift down
                                    .padding(.bottom, 12)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.clear)
                                
                                // Mixtapes Tab
                                Button(action: { selectedTab = 1 }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "books.vertical")
                                            .font(.system(size: 20))
                                        Text("Mixtapes")
                                            .font(Theme.Fonts.retro(size: 10))
                                    }
                                    .foregroundColor(selectedTab == 1 ? (viewModel.isDarkBackground ? .white : .black) : (viewModel.isDarkBackground ? .white.opacity(0.5) : .black.opacity(0.5)))
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 20) // Shift down
                                    .padding(.bottom, 12)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.clear)
                            }
                            .frame(height: 70) // Increased height to accommodate shift
                            .background(Color.clear) // Transparent background
                        }
                        .background(Color.clear)
                        .padding(.bottom, 0) // Ensure it sits at the bottom
                        .ignoresSafeArea(.container, edges: .bottom) // Push below safe area
                        .frame(maxWidth: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showDocumentPicker) {
                DocumentPicker(isPresented: $viewModel.showDocumentPicker) { url in
                    viewModel.loadFile(url: url)
                }
            }
            .sheet(isPresented: $showQueueEdit) {
                QueueEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showLyrics) {
                ZStack {
                    if !viewModel.backgroundColors.isEmpty {
                        DynamicBackgroundView(colors: viewModel.backgroundColors)
                    } else {
                        viewModel.currentTheme.color.ignoresSafeArea()
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                viewModel.showLyrics = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                            }
                            .padding()
                        }
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                Text(viewModel.currentTrack)
                                    .font(Theme.Fonts.title)
                                    .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                    .multilineTextAlignment(.center)
                                
                                Text(viewModel.currentArtist)
                                    .font(Theme.Fonts.retro(size: 18))
                                    .foregroundColor(viewModel.isDarkBackground ? .white.opacity(0.8) : Theme.Colors.text.opacity(0.8))
                                
                                if let lyrics = viewModel.currentLyrics {
                                    Text(lyrics)
                                        .font(Theme.Fonts.retro(size: 16))
                                        .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                } else {
                                    VStack(spacing: 10) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: viewModel.isDarkBackground ? .white : Theme.Colors.text))
                                        Text("Fetching Lyrics...")
                                            .font(Theme.Fonts.retro(size: 14))
                                            .foregroundColor(viewModel.isDarkBackground ? .white.opacity(0.7) : Theme.Colors.text.opacity(0.7))
                                    }
                                    .padding(.top, 50)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            
            // Launch Screen Overlay
            if !viewModel.isReady {
                LaunchScreenView(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }
}
