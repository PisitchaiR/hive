import Foundation
import AppKit

@MainActor
@Observable
final class AutoUpdater {
    enum Phase {
        case idle
        case downloading
        case extracting
        case failed(String)
    }

    var phase: Phase = .idle

    func start(zipURL: URL) async {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent("hive-update-\(UUID().uuidString)")

        do { try fm.createDirectory(at: tempDir, withIntermediateDirectories: true) }
        catch { phase = .failed("Cannot create temp directory."); return }

        phase = .downloading
        let zipPath = tempDir.appendingPathComponent("update.zip")
        do {
            let (data, response) = try await URLSession.shared.data(from: zipURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                phase = .failed("Download failed (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)).")
                return
            }
            try data.write(to: zipPath)
        } catch {
            phase = .failed("Download error: \(error.localizedDescription)")
            return
        }

        phase = .extracting
        let extractDir = tempDir.appendingPathComponent("extracted")
        do { try fm.createDirectory(at: extractDir, withIntermediateDirectories: true) }
        catch { phase = .failed("Cannot create extraction directory."); return }

        let exitCode = await runUnzip(zip: zipPath, into: extractDir)
        guard exitCode == 0 else {
            phase = .failed("Extraction failed (code \(exitCode)).")
            return
        }

        guard let newAppURL = findApp(in: extractDir) else {
            phase = .failed("Hive.app not found in update package.")
            return
        }

        launchInstaller(from: newAppURL.path, replacingCurrentApp: Bundle.main.bundlePath)
    }

    // MARK: Private

    private func runUnzip(zip: URL, into dir: URL) async -> Int32 {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        proc.arguments = ["-q", zip.path, "-d", dir.path]
        return await withCheckedContinuation { continuation in
            proc.terminationHandler = { p in continuation.resume(returning: p.terminationStatus) }
            do { try proc.run() } catch { continuation.resume(returning: -1) }
        }
    }

    private func findApp(in directory: URL) -> URL? {
        let fm = FileManager.default
        guard let top = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return nil }
        if let hit = top.first(where: { $0.lastPathComponent == "Hive.app" }) { return hit }
        for sub in top {
            if let hit = (try? fm.contentsOfDirectory(at: sub, includingPropertiesForKeys: nil))?.first(where: { $0.lastPathComponent == "Hive.app" }) {
                return hit
            }
        }
        return nil
    }

    private func launchInstaller(from newPath: String, replacingCurrentApp currentPath: String) {
        func q(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }
        let script = """
        #!/bin/bash
        sleep 0.5
        rm -rf \(q(currentPath))
        mv \(q(newPath)) \(q(currentPath))
        open \(q(currentPath))
        """
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("hive-install-\(UUID().uuidString).sh")
        guard (try? script.write(to: scriptURL, atomically: true, encoding: .utf8)) != nil,
              (try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)) != nil
        else { phase = .failed("Cannot write installer script."); return }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/bash")
        proc.arguments = [scriptURL.path]
        guard (try? proc.run()) != nil else { phase = .failed("Cannot launch installer."); return }

        NSApp.terminate(nil)
    }
}
