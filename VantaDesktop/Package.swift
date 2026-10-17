// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VantaDesktop",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "VantaDesktop", targets: ["VantaDesktop"])
    ],
    targets: [
        .executableTarget(
            name: "VantaDesktop",
            path: "Sources",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
