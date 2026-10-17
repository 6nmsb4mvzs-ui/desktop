import Foundation

extension FileManager {
    var appSupportDirectory: URL {
        let dir = urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("VantaDesktop", isDirectory: true)
        try? createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func sizeOfFile(at url: URL) -> String {
        guard let attrs = try? attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
