// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,] 
        productTypes: [:]
    )
#endif

let package = Package(
    name: "People",
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
      .package(url: "https://github.com/groue/grdb.swift", from: "6.0.0"),
    ]
)
