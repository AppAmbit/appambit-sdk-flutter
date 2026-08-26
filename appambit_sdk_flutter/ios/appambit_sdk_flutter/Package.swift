// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "appambit_sdk_flutter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "appambit-sdk-flutter",
            type: .static,
            targets: ["appambit_sdk_flutter"]
        )
    ],
    dependencies: [
        // Flutter supplies this package when Swift Package Manager is enabled.
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/AppAmbit/appambit-sdk-ios.git",
            revision: "75ba2fff0abd785d7e442cf1711d62830caa08bb"
        )
    ],
    targets: [
        .target(
            name: "appambit_sdk_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AppAmbit", package: "appambit-sdk-ios")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
