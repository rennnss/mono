import SwiftUI

struct BookshelfView: View {
    @ObservedObject var viewModel: WalkmanViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]
    
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#".map { String($0) }
    
    @State private var showPlaylistCreation = false
    @State private var playlistToEdit: Playlist? = nil
    @State private var selectedPlaylistId: UUID? = nil
    
    var body: some View {
        ZStack(alignment: .top) { // Align to top
            // No background here - let parent background show through
            Color.clear.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("LIBRARY")
                        .font(Theme.Fonts.title)
                        .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                    Spacer()
                    
                    // Search Button
                    Button(action: {
                        withAnimation {
                            viewModel.isSearching.toggle()
                            if !viewModel.isSearching {
                                viewModel.searchText = "" // Clear search when closing
                            }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                        .frame(width: 40, height: 40)
                        .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                    }

                    // Create Playlist Button
                    Button(action: {
                        playlistToEdit = nil
                        showPlaylistCreation = true
                    }) {
                        Image(systemName: "music.note.list")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                        .frame(width: 40, height: 40)
                        .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                    }
                    
                    // Add Files Button
                    Button(action: {
                        viewModel.showDocumentPicker = true
                    }) {
                        Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                        .frame(width: 40, height: 40)
                        .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                    }
                }
                .padding()
                .background(viewModel.isDarkBackground ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                .zIndex(10)
                
                // Search Bar
                if viewModel.isSearching {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(viewModel.isDarkBackground ? .white.opacity(0.7) : Theme.Colors.text.opacity(0.7))
                        
                        TextField("Search Library...", text: $viewModel.searchText)
                            .font(Theme.Fonts.retro(size: 16))
                            .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                            .disableAutocorrection(true)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(viewModel.isDarkBackground ? .white.opacity(0.7) : Theme.Colors.text.opacity(0.7))
                            }
                        }
                    }
                    .padding()
                    .background(viewModel.isDarkBackground ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content Area
                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                if !viewModel.isSearching {
                                    // Playlists Header
                                    if !viewModel.playlists.isEmpty {
                                        HStack {
                                            Text("PLAYLISTS")
                                                .font(Theme.Fonts.retro(size: 14))
                                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                                .padding(.horizontal)
                                            
                                            Spacer()
                                        }
                                    }
                                    
                                    if let selectedId = selectedPlaylistId, let selectedPlaylist = viewModel.playlists.first(where: { $0.id == selectedId }) {
                                        // Single Selected Playlist View
                                        HStack {
                                            // Playlist Disk (Deselect)
                                            Button(action: {
                                                selectedPlaylistId = nil
                                                viewModel.filterLibrary(by: nil)
                                            }) {
                                                DiskView(name: selectedPlaylist.name, color: selectedPlaylist.color)
                                            }
                                            .contextMenu {
                                                Button {
                                                    playlistToEdit = selectedPlaylist
                                                    showPlaylistCreation = true
                                                } label: {
                                                    Label("Edit Playlist", systemImage: "pencil")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    viewModel.deletePlaylist(selectedPlaylist)
                                                } label: {
                                                    Label("Delete Playlist", systemImage: "trash")
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Play Button
                                            Button(action: {
                                                viewModel.playPlaylist(selectedPlaylist)
                                            }) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "play.fill")
                                                    Text("PLAY")
                                                        .font(Theme.Fonts.retro(size: 16))
                                                        .fontWeight(.bold)
                                                }
                                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 12)
                                                .background(viewModel.isDarkBackground ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                                .border(viewModel.isDarkBackground ? .white : Theme.Colors.border, width: 2)
                                            }
                                        }
                                        .padding(.horizontal)
                                    } else {
                                        // Grid View (All Playlists)
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(viewModel.playlists) { playlist in
                                                Button(action: {
                                                    selectedPlaylistId = playlist.id
                                                    viewModel.filterLibrary(by: playlist)
                                                }) {
                                                    VStack(spacing: 8) {
                                                        DiskView(name: playlist.name, color: playlist.color)
                                                    }
                                                }
                                                .contextMenu {
                                                    Button {
                                                        viewModel.playPlaylist(playlist)
                                                    } label: {
                                                        Label("Play Now", systemImage: "play.fill")
                                                    }
                                                    
                                                    Button {
                                                        playlistToEdit = playlist
                                                        showPlaylistCreation = true
                                                    } label: {
                                                        Label("Edit Playlist", systemImage: "pencil")
                                                    }
                                                    
                                                    Button(role: .destructive) {
                                                        viewModel.deletePlaylist(playlist)
                                                    } label: {
                                                        Label("Delete Playlist", systemImage: "trash")
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                // Songs Section
                                VStack(alignment: .leading) {
                                    Text(selectedPlaylistId != nil ? "PLAYLIST SONGS" : "SONGS")
                                        .font(Theme.Fonts.retro(size: 14))
                                        .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(viewModel.playlist) { item in
                                            Button(action: {
                                                viewModel.playTrack(item)
                                            }) {
                                                VStack(spacing: 8) {
                                                    ZStack {
                                                        if let artwork = item.artwork {
                                                            Image(uiImage: artwork)
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 100, height: 100)
                                                                .clipped()
                                                                .border(Theme.Colors.border, width: 2)
                                                                .shadow(color: .black.opacity(0.2), radius: 0, x: 4, y: 4)
                                                        } else {
                                                            Image("default_art_0")
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 100, height: 100)
                                                                .clipped()
                                                                .border(Theme.Colors.border, width: 2)
                                                                .shadow(color: .black.opacity(0.2), radius: 0, x: 4, y: 4)
                                                        }
                                                    }
                                                    
                                                    
                                                    Text(item.title)
                                                        .font(Theme.Fonts.label)
                                                        .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                                        .lineLimit(2)
                                                        .multilineTextAlignment(.center)
                                                }
                                            }
                                            .id(item.id)
                                            .contextMenu {
                                                Menu("Add to Playlist...") {
                                                    ForEach(viewModel.playlists) { playlist in
                                                        Button(playlist.name) {
                                                            viewModel.addToPlaylist(playlist, items: [item])
                                                        }
                                                    }
                                                }
                                                
                                                Button {
                                                    viewModel.addToQueue(item)
                                                } label: {
                                                    Label("Add to Queue", systemImage: "text.append")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                            .padding(.trailing, 20) // Make room for index
                        }
                        
                        // Alphabet Index
                        if !viewModel.isSearching {
                            GeometryReader { geo in
                                HStack {
                                    Spacer()
                                    VStack(spacing: 0) {
                                        ForEach(alphabet, id: \.self) { letter in
                                            Text(letter)
                                                .font(Theme.Fonts.retro(size: 10))
                                                .foregroundColor(viewModel.isDarkBackground ? .white : Theme.Colors.text)
                                                .frame(width: 20, height: geo.size.height / CGFloat(alphabet.count))
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    scrollToLetter(letter, proxy: proxy)
                                                }
                                        }
                                    }
                                    .background(Color.clear)
                                    .gesture(
                                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                            .onChanged { value in
                                                let totalHeight = geo.size.height
                                                let letterHeight = totalHeight / CGFloat(alphabet.count)
                                                let index = Int(value.location.y / letterHeight)
                                                
                                                if index >= 0 && index < alphabet.count {
                                                    let letter = alphabet[index]
                                                    scrollToLetter(letter, proxy: proxy)
                                                }
                                            }
                                    )
                                }
                            }
                            .frame(width: 30) // Fixed width for sidebar
                            .padding(.trailing, 4)
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer() // Ensure VStack fills height
            }
        }
        .sheet(isPresented: $showPlaylistCreation) {
            PlaylistCreationView(viewModel: viewModel, playlist: playlistToEdit)
        }
        .onAppear {
            // Reset to all songs when view appears (e.g. switching back from player)
            selectedPlaylistId = nil
            viewModel.filterLibrary(by: nil)
        }
    }
    
    private func scrollToLetter(_ letter: String, proxy: ScrollViewProxy) {
        if let match = viewModel.playlist.first(where: { item in
            let clean = viewModel.cleanTitle(item.title).uppercased()
            if letter == "#" {
                return clean.first?.isLetter == false
            }
            return clean.hasPrefix(letter)
        }) {
            // Provide haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation {
                proxy.scrollTo(match.id, anchor: .top)
            }
        }
    }

}
