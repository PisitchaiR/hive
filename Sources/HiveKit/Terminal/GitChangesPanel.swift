import AppKit
import SwiftUI

struct GitChangesPanel: View {
    @Bindable var session: Session
    @Bindable var store: WorkspaceStore

    @State private var files: [GitChangedFile] = []
    @State private var repoRoot: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Theme.chromeHairline).frame(height: 1)
            fileList
        }
        .background(Theme.chromeBackground)
        .task(id: session.id) { await loadFiles() }
        .onChange(of: session.gitStatus) { _, _ in
            Task { await loadFiles() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.space2) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 11))
                .foregroundStyle(Theme.chromeMuted)
            Text("Git Changes")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.chromeForeground)
            if session.gitStatus.filesChanged > 0 {
                Text("\(session.gitStatus.filesChanged)")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.chromeMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Theme.chromeFaint, lineWidth: 1)
                    )
            }
            Spacer()
            HoverableIconButton(
                systemName: "xmark",
                fontSize: 9,
                size: 18,
                help: "Close git panel"
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

    // MARK: - File List

    private var fileList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                let staged = files.filter { $0.isStaged }
                let changes = files.filter { !$0.isStaged }

                if !staged.isEmpty {
                    sectionHeader("Staged Changes")
                    ForEach(staged) { file in
                        GitFileRow(file: file, status: file.stagedStatus) {
                            openDiff(file, staged: true)
                        }
                    }
                }

                if !changes.isEmpty {
                    sectionHeader("Changes")
                    ForEach(changes) { file in
                        GitFileRow(file: file, status: file.isUntracked ? .untracked : file.unstagedStatus) {
                            openDiff(file, staged: false)
                        }
                    }
                }

                if files.isEmpty {
                    Text("No changes")
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.chromeMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, Theme.space4)
                }
            }
            .padding(.vertical, 4)
        }
        .background(Theme.chromeBackground)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(Theme.mono(9))
            .foregroundStyle(Theme.chromeMuted)
            .padding(.horizontal, Theme.space4)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }

    // MARK: - Actions

    private func openDiff(_ file: GitChangedFile, staged: Bool) {
        guard let workspace = store.active else { return }
        let info = GitDiffInfo(
            cwd: repoRoot.isEmpty ? session.currentDirectory.path : repoRoot,
            path: file.path,
            staged: staged,
            isUntracked: file.isUntracked
        )
        store.openDiffTab(info: info, in: workspace)
    }

    private func loadFiles() async {
        let cwd = session.currentDirectory.path
        let (root, result) = await Task.detached(priority: .utility) {
            let root = GitStatusFetcher.repoRoot(cwd: cwd) ?? cwd
            let files = GitStatusFetcher.fetchChangedFiles(cwd: root)
            return (root, files)
        }.value
        repoRoot = root
        files = result
    }
}

// MARK: - File Row

private struct GitFileRow: View {
    let file: GitChangedFile
    let status: GitChangeType
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.space2) {
            statusBadge
            Text(displayName)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.chromeForeground)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
        .padding(.horizontal, Theme.space3)
        .padding(.vertical, 3)
        .background(isHovered ? Theme.chromeActive : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onHover { isHovered = $0 }
    }

    private var displayName: String {
        file.path.components(separatedBy: "/").last ?? file.path
    }

    private var statusBadge: some View {
        Text(statusLetter)
            .font(Theme.mono(10).weight(.semibold))
            .foregroundStyle(statusColor)
            .frame(width: 14)
    }

    private var statusLetter: String {
        switch status {
        case .modified:   return "M"
        case .added:      return "A"
        case .deleted:    return "D"
        case .renamed:    return "R"
        case .copied:     return "C"
        case .untracked:  return "?"
        case .ignored:    return "!"
        case .unmodified: return " "
        }
    }

    private var statusColor: Color {
        switch status {
        case .modified:   return Color(NSColor.systemYellow)
        case .added:      return Theme.gitInsertion
        case .deleted:    return Theme.gitDeletion
        case .renamed:    return Color(NSColor.systemBlue)
        case .copied:     return Color(NSColor.systemCyan)
        case .untracked:  return Theme.chromeMuted
        default:          return Theme.chromeMuted
        }
    }
}
