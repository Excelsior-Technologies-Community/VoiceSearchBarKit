// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceSearchBarKit",

    platforms: [
        .iOS(.v15)
    ],

    products: [
        .library(
            name: "VoiceSearchBarKit",
            targets: ["VoiceSearchBarKit"]
        )
    ],

    targets: [
        .target(
            name: "VoiceSearchBarKit",
            path: "Sources/VoiceSearchBarKit"
        )
    ]
)
