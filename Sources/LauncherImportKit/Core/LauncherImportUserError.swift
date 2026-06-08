import Foundation

public enum LauncherImportUserError: Sendable {
    case fileAccessFailed
    case invalidInstance
    case parseFailed(instanceName: String)
    case missingGameVersion(instanceName: String)
    case unsupportedModLoader(instanceName: String, modLoader: String, supported: [String])
    case copyFailed(message: String)
}
