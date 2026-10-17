import SwiftUI
import UniformTypeIdentifiers
import AVKit

struct CatalogueView: View {
    @EnvironmentObject var catalogueManager: CatalogueManager
    @EnvironmentObject var wallpaperService: WallpaperService
    @State private var showImporter = false
    @State private var selectedItemID: UUID?
    @State private var showDetail = false
    @State private var columnCount: Int = 4
    @State private var showNewCollectionSheet = false
    @State private var newCollectionName = ""

    private let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            catalogueToolbar
            Divider()

            if catalogueManager.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(catalogueManager.filteredItems) { item in
                            CatalogueItemCard(item: item, isSelected: selectedItemID == item.id)
                                .onTapGesture {
                                    selectedItemID = item.id
                                    showDetail = true
                                }
                                .contextMenu {
                                    Button("Set as Wallpaper") {
                                        wallpaperService.setWallpaper(item: item)
                                    }
                                    Button(item.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                                        catalogueManager.toggleFavorite(item)
                                    }
                                    Divider()
                                    Button("Delete", role: .destructive) {
                                        catalogueManager.deleteItem(item)
                                    }
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            if let id = selectedItemID, let item = catalogueManager.items.first(where: { $0.id == id }) {
                ItemDetailView(item: item)
            }
        }
        .sheet(isPresented: $showNewCollectionSheet) {
            NewCollectionSheet(name: $newCollectionName) {
                catalogueManager.createCollection(name: newCollectionName)
                newCollectionName = ""
                showNewCollectionSheet = false
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: MediaType.allAllowedTypes,
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                Task {
                    await catalogueManager.importFiles(urls: urls)
                }
            }
        }
    }

    private var catalogueToolbar: some View {
        HStack(spacing: 12) {
            Text("Catalogue")
                .font(.title2.bold())

            Spacer()

            Picker("Filter", selection: $catalogueManager.selectedFilter) {
                Text("All").tag(MediaType?.none)
                ForEach(MediaType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(MediaType?.some(type))
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            TextField("Search...", text: $catalogueManager.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)

            Button {
                showNewCollectionSheet = true
            } label: {
                Image(systemName: "folder.badge.plus")
            }
            .help("New Collection")

            Button {
                showImporter = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .help("Import Media")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No media in catalogue")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Import images, GIFs, and videos to get started")
                .font(.body)
                .foregroundStyle(.tertiary)
            Button("Import Media") {
                showImporter = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}

struct CatalogueItemCard: View {
    let item: CatalogueItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let thumbURL = item.thumbnailURL, let image = NSImage(contentsOf: thumbURL) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 160)
                        .overlay {
                            Image(systemName: item.mediaType.icon)
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                        }
                }

                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: item.mediaType.icon)
                            .font(.caption)
                            .padding(4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    if item.isFavorite {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(4)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                            Spacer()
                        }
                    }
                }
                .padding(6)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(item.mediaType.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

struct ItemDetailView: View {
    let item: CatalogueItem
    @EnvironmentObject var wallpaperService: WallpaperService
    @EnvironmentObject var catalogueManager: CatalogueManager
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(item.name)
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            HStack(spacing: 0) {
                mediaPreview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    detailSection("Info") {
                        detailRow("Type", item.mediaType.displayName)
                        detailRow("Added", item.dateAdded.formatted(date: .abbreviated, time: .shortened))
                        if let lastUsed = item.lastUsed {
                            detailRow("Last Used", lastUsed.formatted(date: .abbreviated, time: .shortened))
                        }
                    }

                    detailSection("Tags") {
                        FlowLayout(spacing: 4) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.1), in: Capsule())
                            }
                        }
                        HStack {
                            TextField("Add tag", text: $newTag)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    if !newTag.isEmpty {
                                        catalogueManager.addTag(newTag, to: item)
                                        newTag = ""
                                    }
                                }
                        }
                    }

                    Spacer()

                    Button("Set as Wallpaper") {
                        wallpaperService.setWallpaper(item: item)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
                .frame(width: 260)
                .padding()
            }
        }
        .frame(width: 800, height: 500)
    }

    @ViewBuilder
    private var mediaPreview: some View {
        switch item.mediaType {
        case .image, .gif:
            if let image = NSImage(contentsOf: item.fileURL) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
        case .video:
            VideoPlayer(player: AVPlayer(url: item.fileURL))
                .padding()
        }
    }

    private func detailSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                                  proposal: ProposedViewSize(frame.size))
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

struct NewCollectionSheet: View {
    @Binding var name: String
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("New Collection")
                .font(.headline)
            TextField("Collection Name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create") { onCreate() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}
