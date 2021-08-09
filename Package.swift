// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuxlJSONFormatter",
    products: [
        .library(
            name: "AuxlJSONFormatter",
            targets: ["AuxlJSONFormatter"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "jsmn",
            dependencies: []
        ),
        .target(
            name: "AuxlJSONFormatter",
            dependencies: ["jsmn"],
            cSettings: [
                .define("JSMN_STRICT")
            ]
        ),
        .testTarget(
            name: "AuxlJSONFormatterTests",
            dependencies: ["AuxlJSONFormatter"],
            exclude: ["jsmn"],
            resources: [
                .process("test.json"),
                .process("test2.json")
            ]
            
        ),
    ]
)
