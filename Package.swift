// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPAComponents",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SPAComponents",
            targets: ["SPAComponents"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nspassov/SPAExtensions.git", branch: "main"),
        .package(url: "https://github.com/SwiftKickMobile/SwiftMessages", from: "10.0.0"),
        .package(url: "https://github.com/ninjaprox/NVActivityIndicatorView.git", from: "5.2.0"),
        .package(url: "https://github.com/nspassov/fuse-swift", branch: "master"),
        .package(url: "https://github.com/cianru/ios-datepicker", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SPAComponents",
            dependencies: [
                .product(name: "SPAExtensions", package: "SPAExtensions"),
                .product(name: "SwiftMessages", package: "SwiftMessages"),
                .product(name: "NVActivityIndicatorView", package: "NVActivityIndicatorView"),
                .product(name: "Fuse", package: "fuse-swift"),
                .product(name: "DatePicker", package: "ios-datepicker"),
            ],
            path: "Sources"),
        .testTarget(
            name: "SPAComponentsTests",
            dependencies: ["SPAComponents"]),
    ]
)
