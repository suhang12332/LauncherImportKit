import Foundation

public struct LauncherImportSaveRequest: Sendable {
    public let gameName: String
    public let gameVersion: String
    public let modLoader: String
    public let modLoaderVersion: String

    public init(
        gameName: String,
        gameVersion: String,
        modLoader: String,
        modLoaderVersion: String
    ) {
        self.gameName = gameName
        self.gameVersion = gameVersion
        self.modLoader = modLoader
        self.modLoaderVersion = modLoaderVersion
    }
}
