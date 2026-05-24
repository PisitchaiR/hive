import AppKit
import SwiftUI

struct FileBrowserPanel: View {
    @Bindable var store: WorkspaceStore

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Theme.chromeHairline).frame(height: 1)
            if let root = rootURL, let workspace = store.active {
                FileTreeView(rootURL: root, workspace: workspace, store: store)
            } else {
                Text("No directory")
                    .foregroundStyle(Theme.chromeMuted)
                    .font(Theme.mono(11))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.chromeBackground)
    }

    private var rootURL: URL? {
        store.active?.activeSession?.currentDirectory
    }

    private var header: some View {
        HStack(spacing: Theme.space2) {
            Image(systemName: "folder")
                .foregroundStyle(Theme.chromeMuted)
                .font(.system(size: 11))
            Text(rootURL?.lastPathComponent ?? "Files")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.chromeForeground)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            HoverableIconButton(
                systemName: "xmark",
                fontSize: 9,
                size: 18,
                help: "Close file browser"
            ) {
                withAnimation(Theme.chromeTransition) {
                    store.rightPanel = .hidden
                }
            }
        }
        .padding(.horizontal, Theme.space4)
        .padding(.vertical, 6)
        .background(Theme.chromeBackground)
    }
}

private struct FileTreeView: View {
    let rootURL: URL
    let workspace: Workspace
    let store: WorkspaceStore
    @State private var items: [FileItem] = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(items) { item in
                    FileRowView(item: item, depth: 0, workspace: workspace, store: store)
                }
            }
            .padding(.vertical, 4)
        }
        .onAppear { load() }
        .onChange(of: rootURL) { _, _ in load() }
    }

    private func load() {
        items = FileItem.children(of: rootURL)
    }
}

@Observable
private final class FileItem: Identifiable {
    let id: URL
    let url: URL
    let isDirectory: Bool
    var isExpanded: Bool = false
    var children: [FileItem] = []

    init(url: URL, isDirectory: Bool) {
        self.id = url
        self.url = url
        self.isDirectory = isDirectory
    }

    static func children(of url: URL) -> [FileItem] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return entries
            .compactMap { entry -> FileItem? in
                let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                return FileItem(url: entry, isDirectory: isDir)
            }
            .sorted { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                return a.url.lastPathComponent.localizedCaseInsensitiveCompare(b.url.lastPathComponent) == .orderedAscending
            }
    }

    func expand() {
        guard isDirectory else { return }
        if children.isEmpty {
            children = FileItem.children(of: url)
        }
        isExpanded = true
    }

    func collapse() {
        isExpanded = false
    }
}

private struct FileRowView: View {
    @Bindable var item: FileItem
    let depth: Int
    let workspace: Workspace
    let store: WorkspaceStore

    private var isOpenAsTab: Bool {
        workspace.activePane?.tabs.contains(where: { $0.fileViewerURL == item.url }) ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row
            if item.isExpanded {
                ForEach(item.children) { child in
                    FileRowView(item: child, depth: depth + 1, workspace: workspace, store: store)
                }
            }
        }
    }

    private var row: some View {
        HStack(spacing: 4) {
            Color.clear.frame(width: CGFloat(depth) * 12)

            if item.isDirectory {
                Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.chromeMuted)
                    .frame(width: 10)
                Image(systemName: item.isExpanded ? "folder.fill" : "folder")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.chromeMuted)
            } else {
                Color.clear.frame(width: 10)
                Image(systemName: fileIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(isOpenAsTab ? Theme.chromeForeground : Theme.chromeMuted)
            }

            Text(item.url.lastPathComponent)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.chromeForeground)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()
        }
        .padding(.horizontal, Theme.space3)
        .padding(.vertical, 3)
        .background(isOpenAsTab ? Theme.chromeActive : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            guard !item.isDirectory else { return }
            NSWorkspace.shared.open(item.url)
        }
        .onTapGesture(count: 1) {
            if item.isDirectory {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if item.isExpanded { item.collapse() } else { item.expand() }
                }
            } else {
                store.openFileTab(url: item.url, in: workspace)
            }
        }
    }

    private var fileIcon: String {
        let ext = item.url.pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "py": return "doc.text"
        case "js", "ts", "jsx", "tsx": return "doc.text"
        case "json": return "doc.text"
        case "md": return "doc.richtext"
        case "png", "jpg", "jpeg", "gif", "svg", "webp": return "photo"
        case "pdf": return "doc.fill"
        case "sh", "zsh", "bash": return "terminal"
        default: return "doc"
        }
    }
}
