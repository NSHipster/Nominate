import Ollama
import PDFKit
import QuickLookUI
import SwiftUI
import UniformTypeIdentifiers

struct PDFFile: Identifiable {
    let id = UUID()
    var url: URL
    var generatedFilename: String?
    var isProcessed = false
    var isLoading = false
    var progress: Double = 0
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.pdfFiles.isEmpty {
                dropZone
            } else {
                fileList
            }
            bottomBar
        }
        .frame(minWidth: 400, minHeight: 300)
        .onDrop(of: [UTType.pdf], isTargeted: $isTargeted) { providers in
            viewModel.handleDrop(providers: providers)
        }
        .overlay(
            Group {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 3)
                        .padding(8)
                }
            }
        )
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))

            VStack {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                Text("Drag and drop PDF files onto the area above")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileList: some View {
        List {
            ForEach(viewModel.pdfFiles) { file in
                fileRow(for: file)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal)
    }

    private func fileRow(for file: PDFFile) -> some View {
        HStack {
            Group {
                if file.isLoading {
                    ProgressView(value: file.progress)
                        .progressViewStyle(CircularProgressViewStyle())
                        .controlSize(.small)
                } else if file.isProcessed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(width: 20, height: 20)

            VStack(alignment: .leading) {
                Text(file.url.lastPathComponent)
                    .font(.headline)
                if let generatedFilename = file.generatedFilename {
                    Text(generatedFilename)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if file.generatedFilename != nil {
                HStack {
                    Button("Apply") { viewModel.applyFilename(for: file) }
                        .buttonStyle(.borderedProminent)
                }
            }

            Button(action: { viewModel.openQuickLook(for: file) }) {
                Image(systemName: "eye")
            }
            .buttonStyle(.plain)

            Button(action: { viewModel.openInFinder(file) }) {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomBar: some View {
        HStack {
            Button(action: { viewModel.addFiles() }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Drag and drop PDF files onto the area above")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

class ContentViewModel: ObservableObject {
    @Published var pdfFiles: [PDFFile] = []
    private let client: Ollama.Client = .default
    private var processingQueue: [PDFFile] = []
    private var isProcessing = false
    @Published var alertItem: AlertItem?
    private var quickLookDataSource: QuickLookDataSource?

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) {
                    item, error in
                    guard let url = item as? URL else { return }
                    DispatchQueue.main.async {
                        let newFile = PDFFile(url: url)
                        self.pdfFiles.append(newFile)
                        self.queueFileForProcessing(newFile)
                    }
                }
            }
        }
        return true
    }

    private func queueFileForProcessing(_ file: PDFFile) {
        processingQueue.append(file)
        processNextFileIfNeeded()
    }

    private func processNextFileIfNeeded() {
        guard !isProcessing, let nextFile = processingQueue.first else { return }
        isProcessing = true
        processingQueue.removeFirst()
        generate(for: nextFile)
    }

    func generate(for file: PDFFile) {
        Task { @MainActor in
            guard let index = pdfFiles.firstIndex(where: { $0.id == file.id }) else {
                self.isProcessing = false
                self.processNextFileIfNeeded()
                return
            }
            pdfFiles[index].isLoading = true
            pdfFiles[index].generatedFilename = nil
            pdfFiles[index].progress = 0

            do {
                let contents = try extractPDFContents(from: file.url)
                pdfFiles[index].progress = 0.25

                let date = try await extractDate(from: contents, using: client)
                pdfFiles[index].progress = 0.5

                let summary = try await generateSummary(of: contents, using: client)
                pdfFiles[index].progress = 0.75

                let filename = try await generateFilename(
                    for: summary, date: date, extension: file.url.pathExtension, with: client)
                pdfFiles[index].generatedFilename = filename
                pdfFiles[index].isProcessed = true
                pdfFiles[index].progress = 1.0
            } catch {
                print("Error generating filename: \(error)")
                pdfFiles[index].progress = 0
            }

            pdfFiles[index].isLoading = false
            self.isProcessing = false
            self.processNextFileIfNeeded()
        }
    }

    func applyFilename(for file: PDFFile) {
        guard let index = pdfFiles.firstIndex(where: { $0.id == file.id }),
            let newFilename = pdfFiles[index].generatedFilename
        else { return }

        let originalURL = file.url
        let directory = originalURL.deletingLastPathComponent()
        var newURL = directory.appendingPathComponent(newFilename)
        if newURL.pathExtension.isEmpty {
            newURL.appendPathExtension(originalURL.pathExtension)
        }

        do {
            try FileManager.default.moveItem(at: originalURL, to: newURL)
            pdfFiles[index].url = newURL
            pdfFiles[index].generatedFilename = nil
            pdfFiles[index].isProcessed = true
        } catch {
            print("Failed to rename file: \(error)")
            alertItem = AlertItem(
                title: "Failed to rename file",
                message: error.localizedDescription
            )
        }
    }

    func rejectFilename(for file: PDFFile) {
        guard let index = pdfFiles.firstIndex(where: { $0.id == file.id }) else { return }
        pdfFiles[index].generatedFilename = nil
        pdfFiles[index].isProcessed = false
    }

    func addFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.pdf]

        if panel.runModal() == .OK {
            for url in panel.urls {
                let newFile = PDFFile(url: url)
                pdfFiles.append(newFile)
                queueFileForProcessing(newFile)
            }
        }
    }

    func openInFinder(_ file: PDFFile) {
        NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: "")
    }

    func openQuickLook(for file: PDFFile) {
        guard let panel = QLPreviewPanel.shared() else { return }

        let previewItem = file.url as NSURL
        quickLookDataSource = QuickLookDataSource(item: previewItem)
        panel.dataSource = quickLookDataSource

        if !panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func extractPDFContents(from url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw NSError(
                domain: "PDFError", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Unable to open PDF document."])
        }

        return (0..<pdfDocument.pageCount)
            .compactMap { pdfDocument.page(at: $0)?.string }
            .joined()
    }
}

class QuickLookDataSource: NSObject, QLPreviewPanelDataSource {
    let item: NSURL

    init(item: NSURL) {
        self.item = item
        super.init()
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return item
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
