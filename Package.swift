// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "JustACourierAppData",
  platforms: [
    .iOS(.v16)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "JustACourierAppData",
      targets: ["JustACourierAppData"]),
  ],
  dependencies: [
    .package(url: "https://github.com/vespinola/mobile-courier-app-domain.git", branch: "main"),
//      .package(path: "../mobile-courier-app-domain"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "JustACourierAppData",
      dependencies: [
        .product(name: "JustACourierAppDomain", package: "mobile-courier-app-domain"),
      ],
      path: "Sources",
      resources: [ .process("Resources") ]
    ),

  ]
)

