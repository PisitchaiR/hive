import AppKit

/// Terminal engine stub used for non-terminal tabs (file viewer).
/// Provides a blank view and silently ignores all PTY operations.
@MainActor
final class NoOpEngine: TerminalEngine {
    let view: NSView
    var backgroundColor: NSColor { NSColor(srgbRed: 0x1B / 255, green: 0x1D / 255, blue: 0x22 / 255, alpha: 1) }
    var onPwdChange: ((String) -> Void)? = nil
    var onTitleChange: ((String) -> Void)? = nil
    var onFocus: (() -> Void)? = nil
    var onCommandFinished: ((Int?, TimeInterval) -> Void)? = nil
    var onSearchStart: ((String) -> Void)? = nil
    var onSearchEnd: (() -> Void)? = nil
    var onSearchTotal: ((Int) -> Void)? = nil
    var onSearchSelected: ((Int) -> Void)? = nil
    var foregroundPid: pid_t? = nil
    var liveWorkingDirectory: URL? { nil }
    var onProcessExitedCleanly: (() -> Void)? = nil

    init() {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(srgbRed: 0x1B / 255, green: 0x1D / 255, blue: 0x22 / 255, alpha: 1).cgColor
        view = v
    }

    func start(config: TerminalSessionConfig) {}
    func terminate() {}
    @discardableResult func performAction(_ name: String) -> Bool { false }
    func sendInput(_ text: String) {}
    func paste(_ text: String) {}
    func readSelection() -> String? { nil }
}
