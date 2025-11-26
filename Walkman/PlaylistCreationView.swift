import SwiftUI

struct PlaylistCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: WalkmanViewModel
    
    @State private var playlistName: String = ""
    @State private var selectedColor: Color = Theme.Colors.accentBlue
    @State private var selectedSongs: Set<UUID> = []
    
    var existingPlaylist: Playlist?
    
    init(viewModel: WalkmanViewModel, playlist: Playlist? = nil) {
        self.viewModel = viewModel
        self.existingPlaylist = playlist
        _playlistName = State(initialValue: playlist?.name ?? "")
        _selectedColor = State(initialValue: playlist?.color ?? Theme.Colors.accentBlue)
        _selectedSongs = State(initialValue: Set(playlist?.items.map { $0.id } ?? []))
    }
    
    let colors: [Color] = [
        Theme.Colors.accentBlue,
        Theme.Colors.accentPink,
        Theme.Colors.accentGreen,
        Theme.Colors.accentYellow,
        Color(hex: "E0E0E0"), // Light Grey
        Color(hex: "FFD700"), // Gold
        Color(hex: "FF6B6B"), // Red
        Color(hex: "4ECDC4")  // Teal
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                (colorScheme == .dark ? Color.black : Theme.Colors.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Preview
                    DiskView(name: playlistName.isEmpty ? "Playlist" : playlistName, color: selectedColor, size: 120)
                        .padding(.top)
                    
                    // Name Input
                    TextField("Playlist Name", text: $playlistName)
                        .font(Theme.Fonts.retro(size: 16))
                        .padding()
                        .background(colorScheme == .dark ? Color(hex: "222222") : Theme.Colors.surface)
                        .foregroundColor(colorScheme == .dark ? .white : Theme.Colors.text)
                        .border(colorScheme == .dark ? .white : Theme.Colors.border, width: 2)
                        .padding(.horizontal)
                    
                    // Color Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(colorScheme == .dark ? .white : Theme.Colors.border, lineWidth: selectedColor == color ? 3 : 1)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .background(colorScheme == .dark ? .white : Theme.Colors.border)
                    
                    // Song Selection
                    Text("Select Songs")
                        .font(Theme.Fonts.retro(size: 14))
                        .foregroundColor(colorScheme == .dark ? .white : Theme.Colors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(viewModel.allSongs) { item in
                            HStack {
                                Image(systemName: selectedSongs.contains(item.id) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(colorScheme == .dark ? .white : Theme.Colors.text)
                                    .onTapGesture {
                                        if selectedSongs.contains(item.id) {
                                            selectedSongs.remove(item.id)
                                        } else {
                                            selectedSongs.insert(item.id)
                                        }
                                    }
                                
                                if let art = item.artwork {
                                    Image(uiImage: art)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipped()
                                        .border(colorScheme == .dark ? .white : Theme.Colors.border, width: 1)
                                } else {
                                    Rectangle()
                                        .fill(Theme.Colors.accentPink)
                                        .frame(width: 40, height: 40)
                                        .border(colorScheme == .dark ? .white : Theme.Colors.border, width: 1)
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                Text(item.title)
                                    .font(Theme.Fonts.label)
                                    .foregroundColor(colorScheme == .dark ? .white : Theme.Colors.text)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.bottom) // Add some bottom padding
            .background(colorScheme == .dark ? Color.black : Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : Theme.Colors.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePlaylist()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(playlistName.isEmpty)
                    .foregroundColor(playlistName.isEmpty ? .gray : (colorScheme == .dark ? .white : Theme.Colors.text))
                    .font(Theme.Fonts.retro(size: 14))
                }
            }
        }
    }
    
    private func savePlaylist() {
        let selectedItems = viewModel.allSongs.filter { selectedSongs.contains($0.id) }
        
        if let existing = existingPlaylist {
            viewModel.updatePlaylist(existing, name: playlistName, color: selectedColor, items: selectedItems)
        } else {
            viewModel.createPlaylist(name: playlistName, items: selectedItems, color: selectedColor)
        }
    }
}
