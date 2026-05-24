import Foundation

/// Polls GitHub's `releases/latest` endpoint and compares its `tag_name`
/// against `HiveApp.displayVersion`. Manual-only for now (Help → Check
/// for Updates…); no startup poll, no Settings toggle.
enum UpdateChecker {
    enum Outcome {
        case upToDate(current: String)
        /// `assetURL` is a direct zip/dmg download; nil means only a release page is available.
        case newer(latest: String, assetURL: URL?, pageURL: URL, releaseNotes: String)
        case failed(String)
    }

    private struct LatestRelease: Decodable {
        let tagName: String
        let htmlUrl: String
        let body: String?
        let assets: [Asset]?
        struct Asset: Decodable {
            let name: String
            let browserDownloadUrl: String
            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadUrl = "browser_download_url"
            }
        }
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlUrl = "html_url"
            case body
            case assets
        }
    }

    static func check(currentVersion: String = HiveApp.displayVersion) async -> Outcome {
        var request = URLRequest(url: HiveApp.releasesAPIURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failed("No response from GitHub.")
            }
            guard http.statusCode == 200 else {
                return .failed("GitHub returned HTTP \(http.statusCode).")
            }
            let release = try JSONDecoder().decode(LatestRelease.self, from: data)
            guard let pageURL = URL(string: release.htmlUrl) else {
                return .failed("Couldn't parse release URL.")
            }
            let downloadAsset = release.assets?.first {
                let n = $0.name.lowercased()
                return n.hasSuffix(".zip") || n.hasSuffix(".dmg")
            }
            let assetURL = downloadAsset.flatMap { URL(string: $0.browserDownloadUrl) }
            let latest = Version.stripLeadingV(release.tagName)
            if Version.compare(latest, currentVersion) == .orderedDescending {
                let notes = release.body?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return .newer(latest: latest, assetURL: assetURL, pageURL: pageURL, releaseNotes: notes)
            }
            return .upToDate(current: currentVersion)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
