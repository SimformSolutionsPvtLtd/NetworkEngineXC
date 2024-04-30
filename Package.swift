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
            url: "https://github.com/SimformSolutionsPvtLtd/NetworkEngineXC/releases/download/v1.1.0/NetworkEngine.xcframework.zip",
            checksum: "d6356bda57e75409c0ede63192d586e13739060cfbecf32ccd934b7ef6a3cf79"
        )
    ]
)
