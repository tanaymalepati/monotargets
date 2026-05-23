import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Generic Document Picker (folder or file)

struct DocumentPicker: UIViewControllerRepresentable {
    enum Mode {
        case folder
        case jsonFile
    }

    let mode: Mode
    let onPick: (URL) -> Void
    let onCancel: (() -> Void)?

    init(mode: Mode, onPick: @escaping (URL) -> Void, onCancel: (() -> Void)? = nil) {
        self.mode = mode
        self.onPick = onPick
        self.onCancel = onCancel
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = mode == .folder ? [.folder] : [.json, .text]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        picker.overrideUserInterfaceStyle = .dark
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: (() -> Void)?

        init(onPick: @escaping (URL) -> Void, onCancel: (() -> Void)?) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel?()
        }
    }
}
