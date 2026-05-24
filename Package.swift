// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Hive",
    platforms: [
        // .v14 floor — `@Observable` macro requires Sonoma+. Dropping further
        // would mean reverting all session models to ObservableObject + @Published.
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.2.0"),
    ],
    targets: [
        // Thin executable: main.swift only. Everything else lives in HiveKit so
        // tests can `@testable import` it (SPM doesn't allow importing executables).
        .executableTarget(
            name: "hive",
            dependencies: ["HiveKit"],
            path: "Sources/hive"
        ),
        // Tiny stand-alone CLI invoked from Claude Code / Codex hooks. Reads
        // $HIVE_SURFACE_ID from env, opens the unix socket the running app
        // owns, writes one JSON line, exits. Doesn't link HiveKit on purpose
        // — keeps the binary fast and dependency-free.
        .executableTarget(
            name: "HiveHook",
            path: "Sources/HiveHook"
        ),
        .target(
            name: "HiveKit",
            dependencies: [
                "GhosttyKit",
                "Highlightr",
            ],
            path: "Sources/HiveKit",
            resources: [
                .process("Resources"),
            ],
            linkerSettings: [
                // libghostty bundles C++ deps (glslang, spirv-cross, imgui)
                // and uses Metal for rendering; link the system frameworks.
                .linkedLibrary("c++"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("CoreText"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("IOSurface"),
                // Text Input Services — libghostty uses TIS to read the active
                // keyboard layout. Pulled in implicitly by SwiftTerm before;
                // now declared directly.
                .linkedFramework("Carbon"),
                .linkedFramework("CoreServices"),
            ]
        ),
        .binaryTarget(
            name: "GhosttyKit",
            // Run scripts/setup-libghostty.sh to populate this; not committed.
            path: "Vendor/GhosttyKit.xcframework"
        ),
        .testTarget(
            name: "HiveKitTests",
            dependencies: ["HiveKit"],
            path: "Tests/HiveKitTests"
        ),
    ]
)
