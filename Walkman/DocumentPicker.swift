import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            UTType(filenameExtension: "m4a") ?? .audio,
            .mp3,
            .wav,
            .aiff,
            .folder // Add folder support
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: false) // asCopy: false for security scoped access
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing security scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource: \(url)")
                return
            }
            
            // We need to stop accessing when we're done, but since we might be passing this URL around,
            // the responsibility often shifts. However, for a folder scan, we can do it here or in the VM.
            // For now, we'll pass it to the VM which should handle the scope or copy the data.
            // Note: If we are just playing a file, we keep access. If scanning a folder, we scan then release?
            // Actually, for the VM to play files later, it needs access.
            // A better pattern for long-term access is to create a bookmark, but for this session:
            
            parent.onPick(url)
            parent.isPresented = false
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}
