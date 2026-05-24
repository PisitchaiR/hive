import AppKit
import SwiftUI

struct GitDiffViewer: View {
    let info: GitDiffInfo

    @State private var diffText: String = ""
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Theme.chromeHairline).frame(height: 1)
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(Theme.chromeMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.chromeBackground)
            } else if diffText.isEmpty {
                Text("No diff available")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.chromeMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.chromeBackground)
            } else {
                DiffTextView(diffText: diffText)
            }
        }
        .task(id: info) { await load() }
    }

    private var header: some View {
        HStack(spacing: Theme.space2) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 11))
                .foregroundStyle(Theme.chromeMuted)
            Text(info.fileName)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.chromeForeground)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(info.isUntracked ? "untracked" : info.staged ? "staged" : "unstaged")
                .font(Theme.mono(9))
                .foregroundStyle(Theme.chromeMuted)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.chromeFaint, lineWidth: 1)
                )
            Spacer()
        }
        .padding(.horizontal, Theme.space4)
        .padding(.vertical, 6)
        .background(Theme.chromeBackground)
    }

    private func load() async {
        isLoading = true
        let info = info
        let result = await Task.detached(priority: .utility) {
            GitStatusFetcher.fetchDiff(
                cwd: info.cwd,
                path: info.path,
                staged: info.staged,
                isUntracked: info.isUntracked
            )
        }.value
        diffText = result
        isLoading = false
    }
}

// MARK: - Diff Text View

private struct DiffTextView: NSViewRepresentable {
    let diffText: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = NSColor(srgbRed: 0x1B / 255, green: 0x1D / 255, blue: 0x22 / 255, alpha: 1)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = .width
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.textStorage?.setAttributedString(coloredDiff())
        textView.scrollToBeginningOfDocument(nil)
    }

    private func coloredDiff() -> NSAttributedString {
        let font = NSFont(name: "JetBrainsMono-Regular", size: 10.5)
            ?? NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)
        let defaultColor = NSColor(srgbRed: 0xEF / 255, green: 0xEF / 255, blue: 0xF1 / 255, alpha: 1)
        let addColor    = NSColor(srgbRed: 0x45 / 255, green: 0xC7 / 255, blue: 0x80 / 255, alpha: 1)
        let removeColor = NSColor(srgbRed: 0xE0 / 255, green: 0x64 / 255, blue: 0x64 / 255, alpha: 1)
        let metaColor   = NSColor(srgbRed: 0x67 / 255, green: 0x9D / 255, blue: 0xD0 / 255, alpha: 1)
        let hunkColor   = NSColor(srgbRed: 0x7A / 255, green: 0x67 / 255, blue: 0xC0 / 255, alpha: 1)

        let result = NSMutableAttributedString()
        for line in diffText.split(separator: "\n", omittingEmptySubsequences: false) {
            let str = String(line) + "\n"
            let color: NSColor
            if str.hasPrefix("+") && !str.hasPrefix("+++") {
                color = addColor
            } else if str.hasPrefix("-") && !str.hasPrefix("---") {
                color = removeColor
            } else if str.hasPrefix("@@") {
                color = hunkColor
            } else if str.hasPrefix("diff") || str.hasPrefix("index") || str.hasPrefix("---") || str.hasPrefix("+++") {
                color = metaColor
            } else {
                color = defaultColor
            }
            result.append(NSAttributedString(string: str, attributes: [.font: font, .foregroundColor: color]))
        }
        return result
    }
}
