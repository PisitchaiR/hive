import Foundation

/// Single source of truth for product metadata — surfaced by the About panel,
/// Help menu, and window title. Bump `displayVersion` on every release so the
/// About panel matches the latest CHANGELOG `vX.Y` tag.
enum HiveApp {
    static let name = "hive"
    static let displayVersion = "0.15.2"
    /// Bundle version string from Info.plist — same as `displayVersion` for
    /// release builds, but dev builds via `scripts/build-app.sh` append
    /// `+<sha>` (or `+<sha>-dirty`) so the About panel reveals which
    /// commit is actually running. Falls back to `displayVersion` when the
    /// plist key is missing (e.g. `swift run` without a bundle).
    static var bundleVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? displayVersion
    }
    static let tagline = "A minimal modern terminal for AI coding"
    static let author = "Corey Chiu"
    static let authorURL = URL(string: "https://coreychiu.com")!
    static let copyrightYear = "2026"

    static let repositoryURL = URL(string: "https://github.com/PisitchaiR/hive")!
    static let issuesURL = URL(string: "https://github.com/PisitchaiR/hive/issues")!
    /// Mirrors `repositoryURL`; update both if the repo is ever renamed.
    static let releasesAPIURL = URL(string: "https://api.github.com/repos/PisitchaiR/hive/releases/latest")!
}
