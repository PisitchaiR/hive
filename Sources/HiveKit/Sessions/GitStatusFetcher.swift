import Foundation

/// Snapshot of a working tree's git state for the pane footer.
/// `branch == nil` means "not in a repo" (or git unavailable / errored).
struct GitStatus: Equatable {
    var branch: String?
    var filesChanged: Int
    var insertions: Int
    var deletions: Int

    static let empty = GitStatus(branch: nil, filesChanged: 0, insertions: 0, deletions: 0)
}

/// Status of a single file in the index (staged) or worktree (unstaged).
enum GitChangeType: Equatable {
    case unmodified, modified, added, deleted, renamed, copied, untracked, ignored
}

/// One file entry from `git status --porcelain=v1`.
struct GitChangedFile: Identifiable, Equatable {
    let id: String          // relative path — unique per repo
    let path: String        // relative path from repo root
    let stagedStatus: GitChangeType    // index column (XY[0])
    let unstagedStatus: GitChangeType  // worktree column (XY[1])

    var isStaged: Bool { stagedStatus != .unmodified && stagedStatus != .untracked && stagedStatus != .ignored }
    var isUnstaged: Bool { unstagedStatus != .unmodified && unstagedStatus != .ignored }
    var isUntracked: Bool { stagedStatus == .untracked }
}

/// Spawns `git` on a background queue to populate `Session.gitStatus`.
/// Refreshes are kicked from `WorkspaceStore` on (a) tab spawn, (b) cwd
/// change via OSC 7, and (c) command finished via OSC 133;D. No polling.
///
/// A monotonic per-session generation token drops stale results: if the user
/// `cd`s rapidly, several fetches may be in flight, but only the latest one's
/// result lands on the session.
@MainActor
final class GitStatusFetcher {
    private var generation: [UUID: Int] = [:]

    /// Schedules a fetch for `cwd`. `completion` fires on main with the
    /// freshest result; older in-flight results are silently dropped.
    func fetch(sessionId: UUID, cwd: URL, completion: @MainActor @escaping (GitStatus) -> Void) {
        let token = (generation[sessionId] ?? 0) + 1
        generation[sessionId] = token
        let path = cwd.path
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = Self.run(cwd: path)
            DispatchQueue.main.async {
                guard let self else { return }
                guard self.generation[sessionId] == token else { return }
                completion(result)
            }
        }
    }

    nonisolated private static func run(cwd: String) -> GitStatus {
        // `--abbrev-ref HEAD` returns the branch name, or "HEAD" when detached.
        // Failure here usually means cwd isn't inside a repo — fall through to
        // empty so the footer hides cleanly.
        guard let head = runGit(["-C", cwd, "--no-optional-locks", "rev-parse", "--abbrev-ref", "HEAD"]) else {
            return .empty
        }
        let branch: String
        if head == "HEAD" {
            branch = runGit(["-C", cwd, "--no-optional-locks", "rev-parse", "--short", "HEAD"]) ?? "HEAD"
        } else {
            branch = head
        }
        let stat = runGit(["-C", cwd, "--no-optional-locks", "diff", "--shortstat", "HEAD"]) ?? ""
        let (files, ins, del) = parseShortstat(stat)
        return GitStatus(branch: branch, filesChanged: files, insertions: ins, deletions: del)
    }

    /// Runs `git <args>` with a 1-second timeout; returns trimmed stdout on
    /// exit 0, nil otherwise. Uses `/usr/bin/env` so the spawned subprocess
    /// resolves git via PATH (covers Apple's /usr/bin/git stub + Homebrew).
    nonisolated static func runGit(_ args: [String], timeout: TimeInterval = 1.0) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["git"] + args
        task.environment = ["PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"]
        let stdout = Pipe()
        task.standardOutput = stdout
        task.standardError = Pipe()

        let semaphore = DispatchSemaphore(value: 0)
        task.terminationHandler = { _ in semaphore.signal() }

        do {
            try task.run()
        } catch {
            return nil
        }

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            task.terminate()
            _ = semaphore.wait(timeout: .now() + 0.1)
            return nil
        }
        guard task.terminationStatus == 0 else { return nil }
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns the absolute path to the git repo root containing `cwd`, or nil if not in a repo.
    nonisolated static func repoRoot(cwd: String) -> String? {
        runGit(["-C", cwd, "rev-parse", "--show-toplevel"], timeout: 2.0)
    }

    /// Returns all changed files in the working tree by parsing `git status --porcelain=v1`.
    nonisolated static func fetchChangedFiles(cwd: String) -> [GitChangedFile] {
        guard let output = runGit(["-C", cwd, "--no-optional-locks", "status", "--porcelain=v1"], timeout: 2.0) else {
            return []
        }
        return output.split(whereSeparator: \.isNewline).compactMap { parsePorcelainLine(String($0)) }
    }

    /// Returns the diff text for a single file. For staged files uses `--cached`; for untracked
    /// files returns the raw file content prefixed with `+` lines (no git diff available).
    nonisolated static func fetchDiff(cwd: String, path: String, staged: Bool, isUntracked: Bool) -> String {
        if isUntracked {
            let url = URL(fileURLWithPath: cwd).appendingPathComponent(path)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
            return text.split(whereSeparator: \.isNewline)
                .map { "+ \($0)" }
                .joined(separator: "\n")
        }
        if staged {
            return runGit(["-C", cwd, "--no-optional-locks", "diff", "--cached", "--", path], timeout: 5.0) ?? ""
        } else {
            return runGit(["-C", cwd, "--no-optional-locks", "diff", "HEAD", "--", path], timeout: 5.0) ?? ""
        }
    }

    nonisolated private static func parsePorcelainLine(_ line: String) -> GitChangedFile? {
        guard line.count >= 3 else { return nil }
        let chars = Array(line)
        let x = chars[0]
        let y = chars[1]
        // space + space = clean; skip
        guard !(x == " " && y == " ") else { return nil }
        let rawPath = String(chars.dropFirst(3))
        guard !rawPath.isEmpty else { return nil }
        let trimmed = rawPath.hasSuffix("/") ? String(rawPath.dropLast()) : rawPath
        // Rename format: "old -> new" — use destination
        let effectivePath: String
        if trimmed.contains(" -> "), let dest = trimmed.components(separatedBy: " -> ").last {
            effectivePath = unquoteGitPath(dest)
        } else {
            effectivePath = unquoteGitPath(trimmed)
        }
        return GitChangedFile(
            id: effectivePath,
            path: effectivePath,
            stagedStatus: changeType(from: x),
            unstagedStatus: changeType(from: y)
        )
    }

    /// Strips git's C-style path quoting. Git wraps paths that contain special
    /// characters (spaces, non-ASCII, etc.) in double quotes and escapes the
    /// contents. Returns the original string unchanged if it is not quoted.
    nonisolated private static func unquoteGitPath(_ s: String) -> String {
        guard s.hasPrefix("\""), s.hasSuffix("\""), s.count >= 2 else { return s }
        var result = ""
        var i = s.index(after: s.startIndex)
        let end = s.index(before: s.endIndex)
        while i < end {
            if s[i] == "\\" {
                let next = s.index(after: i)
                guard next < end else { break }
                switch s[next] {
                case "n":  result.append("\n"); i = s.index(after: next)
                case "t":  result.append("\t"); i = s.index(after: next)
                case "\"": result.append("\""); i = s.index(after: next)
                case "\\": result.append("\\"); i = s.index(after: next)
                default:   result.append(s[i]); i = s.index(after: i)
                }
            } else {
                result.append(s[i])
                i = s.index(after: i)
            }
        }
        return result
    }

    nonisolated private static func changeType(from ch: Character) -> GitChangeType {
        switch ch {
        case "M": return .modified
        case "A": return .added
        case "D": return .deleted
        case "R": return .renamed
        case "C": return .copied
        case "?": return .untracked
        case "!": return .ignored
        default:  return .unmodified
        }
    }

    /// Parses `git diff --shortstat` lines like
    /// ` 3 files changed, 47 insertions(+), 12 deletions(-)`.
    /// Returns `(0, 0, 0)` for empty / unparseable input — all fields drop.
    nonisolated static func parseShortstat(_ s: String) -> (files: Int, insertions: Int, deletions: Int) {
        var files = 0
        var ins = 0
        var del = 0
        for token in s.split(separator: ",") {
            let trimmed = token.trimmingCharacters(in: .whitespaces)
            let parts = trimmed.split(separator: " ", maxSplits: 1)
            guard parts.count == 2, let n = Int(parts[0]) else { continue }
            let label = parts[1]
            if label.hasPrefix("file") {
                files = n
            } else if label.hasPrefix("insertion") {
                ins = n
            } else if label.hasPrefix("deletion") {
                del = n
            }
        }
        return (files, ins, del)
    }
}

enum GitBranchInventory {
    static func localBranches(cwd: URL) -> [String] {
        let output = GitStatusFetcher.runGit([
            "-C", cwd.path,
            "--no-optional-locks",
            "for-each-ref",
            "--sort=-committerdate",
            "--format=%(refname:short)",
            "refs/heads",
        ]) ?? ""
        return parseBranches(output)
    }

    static func shellSwitchCommand(branch: String) -> String {
        "git switch \(HiveShellIntegration.quote(branch))\r"
    }

    static func parseBranches(_ output: String) -> [String] {
        var seen = Set<String>()
        return output
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }
}
