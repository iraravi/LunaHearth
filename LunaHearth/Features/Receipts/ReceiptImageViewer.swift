import SwiftUI

struct ReceiptImageViewer: View {
    let pages: [Data]
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var zoomed = false
    var body: some View {
        NavigationStack {
            VStack {
                if pages.count > 1 {
                    Picker("Page", selection: $page) {
                        ForEach(pages.indices, id: \.self) { Text("Page \($0 + 1)").tag($0) }
                    }.pickerStyle(.menu)
                }
                if pages.indices.contains(page), let image = UIImage(data: pages[page]) {
                    Button(zoomed ? "Fit to screen" : "Zoom in") { zoomed.toggle() }.frame(minHeight: 44)
                    GeometryReader { geometry in
                        ScrollView([.horizontal, .vertical]) {
                            Image(uiImage: image).resizable().scaledToFit().frame(width: geometry.size.width * (zoomed ? 2 : 1))
                                .accessibilityLabel("Scanned receipt page \(page + 1). Compare the original text with the extracted items.")
                        }
                    }
                } else { ContentUnavailableView("No readable image", systemImage: "photo") }
            }.navigationTitle("Receipt image").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct SavedReceiptImagesView: View {
    let home: UUID
    let purchase: UUID
    @State private var pages: [Data] = []
    @State private var loading = true
    @State private var error: String?
    @State private var showing = false
    @State private var removing = false
    @State private var confirmRemoval = false
    private let storage: any ReceiptImageStorage = LocalReceiptImages()
    var body: some View {
        VStack(spacing: 20) {
            if loading { ProgressView("Loading receipt image") }
            else if pages.isEmpty {
                ContentUnavailableView("No saved receipt image", systemImage: "photo", description: Text("Images are optional and stay on the device where you save them."))
            } else {
                Label("\(pages.count) saved pages", systemImage: "photo.on.rectangle")
                Text(ByteCountFormatter.string(fromByteCount: Int64(pages.reduce(0) { $0 + $1.count }), countStyle: .file))
                Button("Open receipt image") { showing = true }.frame(minHeight: 44)
                Button("Remove saved image", role: .destructive) { confirmRemoval = true }.disabled(removing).frame(minHeight: 44)
                Text("Removing the copy leaves your expense, shopping and pantry records unchanged.").font(.caption)
            }
            if let error { Text(error).foregroundStyle(.secondary) }
        }.padding().navigationTitle("Saved receipt")
            .task {
                defer { loading = false }
                do { pages = try await storage.load(home: home, purchase: purchase) }
                catch { self.error = "Couldn’t load this image. Try again." }
            }
            .sheet(isPresented: $showing) { ReceiptImageViewer(pages: pages) }
            .confirmationDialog("Remove this device’s saved receipt image?", isPresented: $confirmRemoval, titleVisibility: .visible) {
                Button("Remove image", role: .destructive) { removing = true }
            }
            .task(id: removing) {
                guard removing else { return }
                defer { removing = false }
                do { try await storage.remove(home: home, purchase: purchase); pages = [] }
                catch { self.error = "Couldn’t remove the image. Try again." }
            }
    }
}
