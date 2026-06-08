import Foundation

/// Supported third-party launcher types for instance import.
public enum ImportLauncherType: String, CaseIterable, Sendable {
    case multiMC = "MultiMC"
    case prismLauncher = "PrismLauncher"
    case gdLauncher = "GDLauncher"
    case sjmcLauncher = "SJMCLauncher"
    case xmcl = "XMCL"
}
