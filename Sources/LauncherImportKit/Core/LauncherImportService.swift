import Foundation

public enum LauncherImportServiceError: LocalizedError, Sendable {
    case parseFailed(instanceName: String)
    case missingGameVersion(instanceName: String)
    case unsupportedModLoader(instanceName: String, modLoader: String)

    public var errorDescription: String? {
        switch self {
        case .parseFailed(let instanceName):
            return "Failed to parse instance: \(instanceName)"
        case .missingGameVersion(let instanceName):
            return "Instance \(instanceName) has no game version"
        case .unsupportedModLoader(let instanceName, let modLoader):
            return "Instance \(instanceName) uses unsupported mod loader: \(modLoader)"
        }
    }
}

public enum LauncherImportService {
    /// Parses the selected instance directory with the specified launcher type.
    public static func parseInstance(
        at instancePath: URL,
        launcherType: ImportLauncherType
    ) throws -> ImportInstanceInfo {
        let instanceName = instancePath.lastPathComponent
        let parser = LauncherInstanceParserFactory.createParser(for: launcherType)

        guard parser.isValidInstance(at: instancePath) else {
            throw LauncherImportServiceError.parseFailed(instanceName: instanceName)
        }

        guard let info = try parser.parseInstance(at: instancePath) else {
            throw LauncherImportServiceError.parseFailed(instanceName: instanceName)
        }

        guard !info.gameVersion.isEmpty else {
            throw LauncherImportServiceError.missingGameVersion(instanceName: instanceName)
        }

        return info
    }

    /// Parses instance metadata for UI preview. Returns nil when parsing fails or version is missing.
    public static func previewInstance(
        at instancePath: URL,
        launcherType: ImportLauncherType
    ) -> ImportInstanceInfo? {
        try? parseInstance(at: instancePath, launcherType: launcherType)
    }

    /// Parses, validates, and copies instance files to the target directory.
    public static func parseAndCopy(
        instancePath: URL,
        launcherType: ImportLauncherType,
        targetDirectory: URL,
        onProgress: ((String, Int, Int) -> Void)?
    ) async throws -> ImportInstanceInfo {
        let instanceInfo = try parseInstance(at: instancePath, launcherType: launcherType)
        let instanceName = instancePath.lastPathComponent

        guard LauncherImport.isModLoaderSupported(instanceInfo.modLoader) else {
            throw LauncherImportServiceError.unsupportedModLoader(
                instanceName: instanceName,
                modLoader: instanceInfo.modLoader
            )
        }

        try await InstanceFileCopier.copyGameDirectory(
            from: instanceInfo.sourceGameDirectory,
            to: targetDirectory,
            launcherType: instanceInfo.launcherType,
            onProgress: onProgress
        )

        return instanceInfo
    }
}
