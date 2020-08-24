// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "CovertSwiftObserver",
    products: [
        .library(
            name: "CovertSwiftObserver",
            targets: ["CovertSwiftObserver"]),
    ],
    targets: [
        .target(
            name: "CovertSwiftObserver"),
        .testTarget(
            name: "CovertSwiftObserverTests",
            dependencies: ["CovertSwiftObserver"]),
    ]
)
