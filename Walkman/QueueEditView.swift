import SwiftUI

struct QueueEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: WalkmanViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                (colorScheme == .dark ? Color.black : Theme.Colors.background)
                    .ignoresSafeArea()
                
                List {
                    ForEach(viewModel.queue) { item in
                        HStack {
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
                                .font(Theme.Fonts.retro(size: 14))
                                .foregroundColor(colorScheme == .dark ? .white : Theme.Colors.text)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : Theme.Colors.text.opacity(0.5))
                                .font(.system(size: 12))
                        }
                        .padding(4)
                        .background(colorScheme == .dark ? Color(hex: "222222") : Theme.Colors.surface)
                        .overlay(
                            Rectangle()
                                .stroke(colorScheme == .dark ? .white : Theme.Colors.border, lineWidth: 1)
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16)) // Reduce default list row padding
                    }
                    .onMove(perform: moveItem)
                    .onDelete(perform: deleteItem)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Up Next")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(Theme.Fonts.retro(size: 14))
                    .foregroundColor(colorScheme == .dark ? .white : Theme.Colors.text)
                }
            }
        }
    }
    
    private func moveItem(from source: IndexSet, to destination: Int) {
        viewModel.queue.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteItem(at offsets: IndexSet) {
        viewModel.removeFromQueue(at: offsets)
    }
}
