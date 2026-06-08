import Foundation

/// Parsed instance metadata from a third-party launcher.
public struct ImportInstanceInfo: Sendable {
    public let gameName: String
    public let gameVersion: String
    public let modLoader: String
    public let modLoaderVersion: String
    public let gameIconPath: URL?
    public let iconDownloadUrl: String?
    public let sourceGameDirectory: URL
    public let launcherType: ImportLauncherType

    public init(
        gameName: String,
        gameVersion: String,
        modLoader: String,
        modLoaderVersion: String,
        gameIconPath: URL?,
        iconDownloadUrl: String?,
        sourceGameDirectory: URL,
        launcherType: ImportLauncherType
    ) {
        self.gameName = gameName
        self.gameVersion = gameVersion
        self.modLoader = modLoader
        self.modLoaderVersion = modLoaderVersion
        self.gameIconPath = gameIconPath
        self.iconDownloadUrl = iconDownloadUrl
        self.sourceGameDirectory = sourceGameDirectory
        self.launcherType = launcherType
    }
}
