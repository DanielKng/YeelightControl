// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "YeelightControl",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "YeelightControl",
            targets: ["YeelightControl"]),
        .library(
            name: "YeelightWidget",
            targets: ["YeelightWidget"])
    ],
    dependencies: [
        // Dependencies go here
    ],
    targets: [
        .target(
            name: "YeelightControl",
            dependencies: [],
            path: "Sources",
            exclude: ["Widget", "Tests"]),
        .target(
            name: "YeelightWidget",
            dependencies: ["YeelightControl"],
            path: "Sources/Widget"),
        .testTarget(
            name: "YeelightControlTests",
            dependencies: ["YeelightControl"],
            path: "Sources/Tests/UnitTests"),
        .testTarget(
            name: "YeelightControlUITests",
            dependencies: ["YeelightControl"],
            path: "Sources/Tests/UITests")
    ]
) 