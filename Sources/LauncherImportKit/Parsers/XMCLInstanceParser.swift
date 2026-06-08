import Foundation

public struct XMCLInstanceParser: LauncherInstanceParser {
    public let launcherType: ImportLauncherType = .xmcl

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
        let instance = try parseInstanceJson(at: instanceJsonPath)

        let gameVersion = instance.runtime.minecraft
        let (modLoader, modLoaderVersion) = extractModLoader(from: instance)
        let gameName = instance.name.isEmpty ? "XMCL-\(instancePath.lastPathComponent)" : instance.name

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

    private func parseInstanceJson(at path: URL) throws -> XMCLInstance {
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(XMCLInstance.self, from: data)
    }

    private func extractModLoader(from instance: XMCLInstance) -> (loader: String, version: String) {
        let runtime = instance.runtime

        if !runtime.forge.isEmpty {
            return (ImportModLoader.forge.displayName, runtime.forge)
        } else if !runtime.neoForged.isEmpty {
            return (ImportModLoader.neoforge.displayName, runtime.neoForged)
        } else if !runtime.fabricLoader.isEmpty {
            return (ImportModLoader.fabric.displayName, runtime.fabricLoader)
        } else if !runtime.quiltLoader.isEmpty {
            return (ImportModLoader.quilt.displayName, runtime.quiltLoader)
        } else {
            return (ImportModLoader.vanilla.displayName, "")
        }
    }
}

private struct XMCLInstance: Codable {
    let name: String
    let url: String
    let icon: String
    let runtime: XMCLRuntime
    let java: String
    let version: String
    let server: XMCLServer?
    let author: String
    let description: String
    let lastAccessDate: Int64
    let creationDate: Int64
    let modpackVersion: String
    let fileApi: String
    let tags: [String]
    let lastPlayedDate: Int64
    let playtime: Int64
}

private struct XMCLRuntime: Codable {
    let minecraft: String
    let forge: String
    let liteloader: String
    let fabricLoader: String
    let yarn: String
    let optifine: String
    let quiltLoader: String
    let neoForged: String
    let labyMod: String
}

private struct XMCLServer: Codable {}
