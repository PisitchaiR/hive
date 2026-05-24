import AppKit
import Highlightr
import SwiftUI

// MARK: - Load state

private enum LoadState: @unchecked Sendable {
    case idle
    case loading
    case loaded(NSAttributedString)
    case image(NSImage)
    case plainText(String)
    case error(String)
}

// MARK: - Main view

struct FileContentViewer: View {
    let url: URL?
    @State private var loadState: LoadState = .idle

    var body: some View {
        content
            .background(Theme.chromeBackground)
            .task(id: url) {
                guard let url else { loadState = .idle; return }
                loadState = .loading
                let result = await Task.detached(priority: .userInitiated) {
                    await FileLoader.load(url: url)
                }.value
                guard !Task.isCancelled else { return }
                loadState = result
            }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .idle:
            emptyPlaceholder("Select a file to preview")
        case .loading:
            ProgressView()
                .controlSize(.small)
                .tint(Theme.chromeMuted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let attrStr):
            HighlightedTextView(attributedString: attrStr)
        case .image(let img):
            ScrollView([.vertical, .horizontal]) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding(Theme.space3)
            }
        case .plainText(let text):
            HighlightedTextView(attributedString: plainAttrStr(text))
        case .error(let msg):
            emptyPlaceholder(msg, color: Theme.chromeMuted)
        }
    }

    @ViewBuilder
    private func emptyPlaceholder(_ text: String, color: Color = Theme.chromeMuted) -> some View {
        Text(text)
            .font(Theme.mono(10))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .padding(Theme.space3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func plainAttrStr(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont(name: "JetBrainsMono-Regular", size: 12.5)
                    ?? NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular),
                .foregroundColor: NSColor(srgbRed: 0xEF / 255, green: 0xEF / 255, blue: 0xF1 / 255, alpha: 1),
            ]
        )
    }
}

// MARK: - NSTextView wrapper

struct HighlightedTextView: NSViewRepresentable {
    let attributedString: NSAttributedString

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
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
        textView.textStorage?.setAttributedString(attributedString)
        textView.scrollToBeginningOfDocument(nil)
    }
}

// MARK: - File loader

private enum FileLoader {
    private static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "tiff", "bmp", "heic", "svg",
    ]

    static func load(url: URL) async -> LoadState {
        let ext = url.pathExtension.lowercased()

        // Image files — render without text processing
        if imageExtensions.contains(ext) {
            guard let img = NSImage(contentsOf: url) else { return .error("Could not load image") }
            return .image(img)
        }

        // Check file size before reading
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        if fileSize > 524_288 {
            return .error("File too large to preview (max 512 KB)")
        }

        // Read raw bytes
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return .error("Could not read file")
        }

        if data.isEmpty { return .error("Empty file") }

        // Binary detection: null byte in first 8 KB
        if data.prefix(8192).contains(0) { return .error("Binary file — cannot preview") }

        // Decode to string
        guard
            let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .windowsCP1252)
                ?? String(data: data, encoding: .isoLatin1)
        else { return .error("Binary file — cannot preview") }

        // Syntax highlight
        let language = languageForURL(url)
        if let box = await HighlightService.shared.highlight(text, language: language) {
            return .loaded(box.value)
        }
        return .plainText(text)
    }

    // MARK: Language detection

    private static func languageForURL(_ url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        if !ext.isEmpty { return languageForExtension(ext) }
        // Extensionless filenames
        switch url.lastPathComponent.lowercased() {
        case "dockerfile": return "dockerfile"
        case "makefile", "gnumakefile": return "makefile"
        case "rakefile": return "ruby"
        case ".gitignore", ".dockerignore": return "bash"
        default: return nil
        }
    }

    private static func languageForExtension(_ ext: String) -> String? {
        switch ext {
        case "swift": return "swift"
        case "py": return "python"
        case "js", "jsx": return "javascript"
        case "ts", "tsx": return "typescript"
        case "json": return "json"
        case "md", "markdown": return "markdown"
        case "sh", "bash", "zsh": return "bash"
        case "rb": return "ruby"
        case "go": return "go"
        case "rs": return "rust"
        case "c": return "c"
        case "cpp", "cc", "cxx": return "cpp"
        case "h", "hpp": return "cpp"
        case "java": return "java"
        case "kt": return "kotlin"
        case "html", "htm": return "html"
        case "css": return "css"
        case "scss", "sass": return "scss"
        case "yaml", "yml": return "yaml"
        case "toml": return "ini"
        case "xml", "plist": return "xml"
        case "sql": return "sql"
        case "lua": return "lua"
        case "r": return "r"
        default: return nil
        }
    }
}

// MARK: - Sendable wrapper for NSAttributedString

// NSAttributedString is immutable and safe to pass across concurrency boundaries,
// but lacks an explicit Sendable conformance in the SDK headers we're building against.
struct HighlightedString: @unchecked Sendable {
    let value: NSAttributedString
}

// MARK: - Highlightr actor (serialises JSContext access)

actor HighlightService {
    static let shared = HighlightService()

    private let highlightr: Highlightr

    private init() {
        guard let h = Highlightr() else {
            fatalError("Highlightr failed to initialise — JavaScriptCore unavailable")
        }
        h.setTheme(to: "atom-one-dark")
        // Override background to match Hive's chromeBackground (#1B1D22)
        h.theme.themeBackgroundColor = NSColor(
            srgbRed: 0x1B / 255,
            green: 0x1D / 255,
            blue: 0x22 / 255,
            alpha: 1
        )
        highlightr = h
    }

    func highlight(_ code: String, language: String?) -> HighlightedString? {
        let raw: NSAttributedString?
        if let lang = language {
            raw = highlightr.highlight(code, as: lang, fastRender: true)
        } else {
            raw = highlightr.highlight(code, fastRender: true)
        }
        guard let raw else { return nil }

        // Replace Highlightr's chosen font with JetBrainsMono
        let mutable = NSMutableAttributedString(attributedString: raw)
        let font = NSFont(name: "JetBrainsMono-Regular", size: 12.5)
            ?? NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular)
        mutable.addAttribute(.font, value: font, range: NSRange(location: 0, length: mutable.length))
        return HighlightedString(value: NSAttributedString(attributedString: mutable))
    }
}
