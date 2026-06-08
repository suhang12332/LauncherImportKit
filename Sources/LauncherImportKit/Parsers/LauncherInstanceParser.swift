import Foundation

public protocol LauncherInstanceParser: Sendable {
    var launcherType: ImportLauncherType { get }

    func isValidInstance(at instancePath: URL) -> Bool

    func parseInstance(at instancePath: URL) throws -> ImportInstanceInfo?
}

public enum LauncherInstanceParserFactory {
    public static func createParser(for launcherType: ImportLauncherType) -> any LauncherInstanceParser {
        switch launcherType {
        case .multiMC, .prismLauncher:
            return MultiMCInstanceParser(launcherType: launcherType)
        case .gdLauncher:
            return GDLauncherInstanceParser()
        case .xmcl:
            return XMCLInstanceParser()
        case .sjmcLauncher:
            return SJMCLInstanceParser()
        }
    }
}
