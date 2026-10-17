import Foundation
import UniformTypeIdentifiers

enum MediaType: String, Codable, CaseIterable {
    case image
    case gif
    case video

    var displayName: String {
        switch self {
        case .image: return "Image"
        case .gif: return "GIF"
        case .video: return "Video"
        }
    }

    var icon: String {
        switch self {
        case .image: return "photo"
        case .gif: return "livephoto.play"
        case .video: return "film"
        }
    }

    var allowedTypes: [UTType] {
        switch self {
        case .image: return [.png, .jpeg, .heic, .tiff, .bmp, .webP]
        case .gif: return [.gif]
        case .video: return [.mpeg4Movie, .quickTimeMovie, .movie, .avi]
        }
    }

    static var allAllowedTypes: [UTType] {
        allCases.flatMap(\.allowedTypes)
    }

    static func detect(from url: URL) -> MediaType? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "gif": return .gif
        case "mp4", "mov", "m4v", "avi", "mkv", "webm": return .video
        case "png", "jpg", "jpeg", "heic", "tiff", "bmp", "webp": return .image
        default: return nil
        }
    }
}

struct CatalogueItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var mediaType: MediaType
    var filePath: String
    var thumbnailPath: String?
    var tags: [String]
    var isFavorite: Bool
    var dateAdded: Date
    var lastUsed: Date?

    init(name: String, mediaType: MediaType, filePath: String, thumbnailPath: String? = nil, tags: [String] = []) {
        self.id = UUID()
        self.name = name
        self.mediaType = mediaType
        self.filePath = filePath
        self.thumbnailPath = thumbnailPath
        self.tags = tags
        self.isFavorite = false
        self.dateAdded = Date()
        self.lastUsed = nil
    }

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }

    var thumbnailURL: URL? {
        thumbnailPath.map { URL(fileURLWithPath: $0) }
    }
}

struct CatalogueCollection: Identifiable, Codable {
    let id: UUID
    var name: String
    var itemIDs: [UUID]
    var coverItemID: UUID?

    init(name: String, itemIDs: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self.itemIDs = itemIDs
        self.coverItemID = nil
    }
}
