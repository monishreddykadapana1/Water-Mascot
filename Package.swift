// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WaterMascot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "WaterMascotCore", targets: ["WaterMascotCore"]),
        .executable(name: "WaterMascot", targets: ["WaterMascot"])
    ],
    targets: [
        .target(name: "WaterMascotCore"),
        .executableTarget(
            name: "WaterMascot",
            dependencies: ["WaterMascotCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "WaterMascotTests",
            dependencies: ["WaterMascotCore"]
        )
    ]
)
