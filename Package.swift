// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription

let package = Package(
    name: "NetworkEngine",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NetworkEngine",
            targets: ["NetworkEngine"]),
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .binaryTarget(
            name: "NetworkEngine",
            url: "https://github.com/SimformSolutionsPvtLtd/NetworkEngineXC/releases/download/v2.0.0/NetworkEngine.xcframework.zip",
            checksum: "0c4770a87b60eb1e53ed1a0d64cf9439c7be39dd84066f4e89eedf16c1e94ebe"
        )
    ]
)
