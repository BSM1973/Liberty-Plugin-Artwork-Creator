// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibertyPluginArtworkCreator",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "LibertyPluginArtworkCreator", targets: ["LibertyPluginArtworkCreator"])],
    targets: [.executableTarget(name: "LibertyPluginArtworkCreator")]
)
