import Foundation

/// Public entry points for launcher instance import.
public enum LauncherImport {
    public static let supportedModLoaders: [String] = ImportModLoader.allCases.map(\.rawValue)

    /// Validates whether the selected folder is a valid instance for the specified launcher type.
    public static func validateInstance(
        at instancePath: URL,
        launcherType: ImportLauncherType
    ) -> Bool {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: instancePath.path) else {
            return false
        }

        let resourceValues = try? instancePath.resourceValues(forKeys: [.isDirectoryKey])
        guard resourceValues?.isDirectory == true else {
            return false
        }

        let parser = LauncherInstanceParserFactory.createParser(for: launcherType)
        return parser.isValidInstance(at: instancePath)
    }

    /// Returns whether the mod loader string is supported by Swift Craft Launcher.
    public static func isModLoaderSupported(_ modLoader: String) -> Bool {
        supportedModLoaders.contains(modLoader.lowercased())
    }
}
