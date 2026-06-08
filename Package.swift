// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LauncherImportKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "LauncherImportKit",
            targets: ["LauncherImportKit"]
        ),
    ],
    targets: [
        .target(
            name: "LauncherImportKit",
            path: "Sources/LauncherImportKit",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
