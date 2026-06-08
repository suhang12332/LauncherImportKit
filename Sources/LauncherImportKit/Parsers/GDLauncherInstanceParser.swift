import Foundation

public struct GDLauncherInstanceParser: LauncherInstanceParser {
    public let launcherType: ImportLauncherType = .gdLauncher

    public init() {}

    public func isValidInstance(at instancePath: URL) -> Bool {
        let instanceJsonPath = instancePath.appendingPathComponent("instance.json")
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: instanceJsonPath.path) else {
            return false
        }

        do {
            _ = try parseInstanceJson(at: instanceJsonPath)
            return true
        } catch {
            return false
        }
    }

    public func parseInstance(at instancePath: URL) throws -> ImportInstanceInfo? {
        let instanceJsonPath = instancePath.appendingPathComponent("instance.json")
        let instanceConfig = try parseInstanceJson(at: instanceJsonPath)

        let gameVersion = instanceConfig.gameConfiguration.version.release

        var modLoader = ImportModLoader.vanilla.displayName
        var modLoaderVersion = ""

        if let firstModLoader = instanceConfig.gameConfiguration.version.modloaders.first {
            modLoader = firstModLoader.type.lowercased()
            modLoaderVersion = firstModLoader.version
        }

        let gameName = instanceConfig.name

        var gameIconPath: URL?
        if let iconName = instanceConfig.icon {
            let iconPath = instancePath.appendingPathComponent(iconName)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: iconPath.path) {
                gameIconPath = iconPath
            }
        }

        return ImportInstanceInfo(
            gameName: gameName,
            gameVersion: gameVersion,
            modLoader: modLoader,
            modLoaderVersion: modLoaderVersion,
            gameIconPath: gameIconPath,
            iconDownloadUrl: nil,
            sourceGameDirectory: instancePath,
            launcherType: launcherType
        )
    }

    private func parseInstanceJson(at path: URL) throws -> GDLauncherInstanceConfig {
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(GDLauncherInstanceConfig.self, from: data)
    }
}

private struct GDLauncherInstanceConfig: Codable {
    let name: String
    let icon: String?
    let gameConfiguration: GDLauncherGameConfiguration

    enum CodingKeys: String, CodingKey {
        case name
        case icon
        case gameConfiguration = "game_configuration"
    }
}

private struct GDLauncherGameConfiguration: Codable {
    let version: GDLauncherVersion
}

private struct GDLauncherVersion: Codable {
    let release: String
    let modloaders: [GDLauncherModLoader]
}

private struct GDLauncherModLoader: Codable {
    let type: String
    let version: String
}
