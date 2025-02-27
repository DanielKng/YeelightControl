// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YeelightControl",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .application(
            name: "YeelightControl",
            targets: ["YeelightControl"]
        ),
        .appExtension(
            name: "YeelightWidget",
            targets: ["YeelightWidget"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "YeelightControl",
            dependencies: [],
            path: "Sources/App"
        ),
        .target(
            name: "YeelightWidget",
            dependencies: [],
            path: "Sources/Widget"
        ),
        .testTarget(
            name: "YeelightControlTests",
            dependencies: ["YeelightControl"],
            path: "Tests"
        )
    ]
)
