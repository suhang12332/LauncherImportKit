import Foundation

public struct SJMCLInstanceParser: LauncherInstanceParser {
    public let launcherType: ImportLauncherType = .sjmcLauncher

    public init() {}

    public func isValidInstance(at instancePath: URL) -> Bool {
        let sjmclcfgPath = instancePath.appendingPathComponent("sjmclcfg.json")
        guard FileManager.default.fileExists(atPath: sjmclcfgPath.path) else {
            return false
        }

        do {
            _ = try parseSJMCLInstanceJson(at: sjmclcfgPath)
            return true
        } catch {
            return false
        }
    }

    public func parseInstance(at instancePath: URL) throws -> ImportInstanceInfo? {
        let fileManager = FileManager.default

        let sjmclcfgPath = instancePath.appendingPathComponent("sjmclcfg.json")
        guard fileManager.fileExists(atPath: sjmclcfgPath.path) else {
            return nil
        }

        let sjmclInstance = try parseSJMCLInstanceJson(at: sjmclcfgPath)

        let gameName = sjmclInstance.name.isEmpty ? instancePath.lastPathComponent : sjmclInstance.name
        let gameVersion = sjmclInstance.version
        var modLoader = ImportModLoader.vanilla.displayName
        var modLoaderVersion = ""

        if let modLoaderInfo = sjmclInstance.modLoader {
            let loaderType = modLoaderInfo.loaderType.lowercased()
            switch loaderType {
            case ImportModLoader.fabric.displayName,
                 ImportModLoader.forge.displayName,
                 ImportModLoader.neoforge.displayName,
                 ImportModLoader.quilt.displayName:
                modLoader = loaderType
            default:
                modLoader = ImportModLoader.vanilla.displayName
            }
            modLoaderVersion = modLoaderInfo.version
        }

        return ImportInstanceInfo(
            gameName: gameName,
            gameVersion: gameVersion,
            modLoader: modLoader,
            modLoaderVersion: modLoaderVersion,
            gameIconPath: nil,
            iconDownloadUrl: nil,
            sourceGameDirectory: instancePath,
            launcherType: launcherType
        )
    }

    private func parseSJMCLInstanceJson(at path: URL) throws -> SJMCLInstance {
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(SJMCLInstance.self, from: data)
    }
}

private struct SJMCLInstance: Codable {
    let id: String
    let name: String
    let description: String?
    let iconSrc: String
    let starred: Bool?
    let playTime: Int64?
    let version: String
    let versionPath: String?
    let modLoader: SJMCLModLoader?
    let useSpecGameConfig: Bool?
    let specGameConfig: SJMCLSpecGameConfig?
}

private struct SJMCLModLoader: Codable {
    let status: String
    let loaderType: String
    let version: String
    let branch: String?
}

private struct SJMCLSpecGameConfig: Codable {}
