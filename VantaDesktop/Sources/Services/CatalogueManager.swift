import Foundation
import AppKit
import AVFoundation
import Combine

@MainActor
class CatalogueManager: ObservableObject {
    @Published var items: [CatalogueItem] = []
    @Published var collections: [CatalogueCollection] = []
    @Published var selectedFilter: MediaType?
    @Published var searchText: String = ""
    @Published var isImporting: Bool = false

    private let storageDir: URL
    private let thumbnailDir: URL
    private let catalogueFile: URL

    var filteredItems: [CatalogueItem] {
        items.filter { item in
            if let filter = selectedFilter, item.mediaType != filter { return false }
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                return item.name.lowercased().contains(query) ||
                       item.tags.contains(where: { $0.lowercased().contains(query) })
            }
            return true
        }
    }

    var favoriteItems: [CatalogueItem] {
        items.filter(\.isFavorite)
    }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("VantaDesktop", isDirectory: true)
        self.storageDir = appDir.appendingPathComponent("Media", isDirectory: true)
        self.thumbnailDir = appDir.appendingPathComponent("Thumbnails", isDirectory: true)
        self.catalogueFile = appDir.appendingPathComponent("catalogue.json")

        createDirectories()
        loadCatalogue()
    }

    private func createDirectories() {
        let fm = FileManager.default
        try? fm.createDirectory(at: storageDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: thumbnailDir, withIntermediateDirectories: true)
    }

    func importFiles(urls: [URL]) async {
        isImporting = true
        defer { isImporting = false }

        for url in urls {
            guard let mediaType = MediaType.detect(from: url) else { continue }
            let fileName = url.lastPathComponent
            let destURL = storageDir.appendingPathComponent(UUID().uuidString + "." + url.pathExtension)

            do {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    try FileManager.default.copyItem(at: url, to: destURL)
                } else {
                    try FileManager.default.copyItem(at: url, to: destURL)
                }

                let thumbPath = await generateThumbnail(for: destURL, mediaType: mediaType)
                let item = CatalogueItem(
                    name: (fileName as NSString).deletingPathExtension,
                    mediaType: mediaType,
                    filePath: destURL.path,
                    thumbnailPath: thumbPath
                )
                items.append(item)
            } catch {
                print("Import failed for \(fileName): \(error)")
            }
        }

        saveCatalogue()
    }

    private func generateThumbnail(for url: URL, mediaType: MediaType) async -> String? {
        let thumbURL = thumbnailDir.appendingPathComponent(UUID().uuidString + ".png")

        switch mediaType {
        case .image, .gif:
            guard let image = NSImage(contentsOf: url) else { return nil }
            let thumbSize = NSSize(width: 300, height: 300)
            let thumbImage = NSImage(size: thumbSize)
            thumbImage.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: thumbSize),
                       from: NSRect(origin: .zero, size: image.size),
                       operation: .copy, fraction: 1.0)
            thumbImage.unlockFocus()
            guard let tiffData = thumbImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else { return nil }
            try? pngData.write(to: thumbURL)
            return thumbURL.path

        case .video:
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 300, height: 300)
            do {
                let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                let bitmap = NSBitmapImageRep(cgImage: cgImage)
                guard let pngData = bitmap.representation(using: .png, properties: [:]) else { return nil }
                try pngData.write(to: thumbURL)
                return thumbURL.path
            } catch {
                return nil
            }
        }
    }

    func deleteItem(_ item: CatalogueItem) {
        let fm = FileManager.default
        try? fm.removeItem(at: item.fileURL)
        if let thumbURL = item.thumbnailURL {
            try? fm.removeItem(at: thumbURL)
        }
        items.removeAll(where: { $0.id == item.id })
        for i in collections.indices {
            collections[i].itemIDs.removeAll(where: { $0 == item.id })
        }
        saveCatalogue()
    }

    func toggleFavorite(_ item: CatalogueItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isFavorite.toggle()
        saveCatalogue()
    }

    func addTag(_ tag: String, to item: CatalogueItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        if !items[idx].tags.contains(tag) {
            items[idx].tags.append(tag)
            saveCatalogue()
        }
    }

    func createCollection(name: String) {
        collections.append(CatalogueCollection(name: name))
        saveCatalogue()
    }

    func addToCollection(_ item: CatalogueItem, collection: CatalogueCollection) {
        guard let idx = collections.firstIndex(where: { $0.id == collection.id }) else { return }
        if !collections[idx].itemIDs.contains(item.id) {
            collections[idx].itemIDs.append(item.id)
            saveCatalogue()
        }
    }

    private func saveCatalogue() {
        let data = CatalogueData(items: items, collections: collections)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let jsonData = try? encoder.encode(data) else { return }
        try? jsonData.write(to: catalogueFile)
    }

    private func loadCatalogue() {
        guard let data = try? Data(contentsOf: catalogueFile) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let catalogue = try? decoder.decode(CatalogueData.self, from: data) else { return }
        items = catalogue.items.filter { FileManager.default.fileExists(atPath: $0.filePath) }
        collections = catalogue.collections
    }
}

private struct CatalogueData: Codable {
    let items: [CatalogueItem]
    let collections: [CatalogueCollection]
}
