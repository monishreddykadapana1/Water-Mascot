// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WaterMascot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "WaterMascotCore", targets: ["WaterMascotCore"]),
        .library(name: "WaterMascotUI", targets: ["WaterMascotUI"]),
        .executable(name: "WaterMascot", targets: ["WaterMascot"]),
        .executable(name: "WaterMascotPreviewHost", targets: ["WaterMascotPreviewHost"])
    ],
    targets: [
        .target(name: "WaterMascotCore"),
        .target(
            name: "WaterMascotUI",
            dependencies: ["WaterMascotCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "WaterMascot",
            dependencies: ["WaterMascotCore", "WaterMascotUI"]
        ),
        .executableTarget(
            name: "WaterMascotPreviewHost",
            dependencies: ["WaterMascotUI"]
        ),
        .testTarget(
            name: "WaterMascotTests",
            dependencies: ["WaterMascotCore"]
        )
    ]
)
