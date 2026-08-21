// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "appambit_sdk_push_notifications",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "appambit-sdk-push-notifications",
            type: .static,
            targets: ["appambit_sdk_push_notifications"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/AppAmbit/appambit-sdk-ios.git",
            revision: "75ba2fff0abd785d7e442cf1711d62830caa08bb"
        )
    ],
    targets: [
        .target(
            name: "appambit_sdk_push_notifications",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AppAmbit", package: "appambit-sdk-ios"),
                .product(name: "AppAmbitPushNotifications", package: "appambit-sdk-ios")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
