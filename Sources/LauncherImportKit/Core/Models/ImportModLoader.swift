import Foundation

/// Minecraft mod loader identifiers used by launcher import parsers.
public enum ImportModLoader: String, CaseIterable, Sendable {
    case vanilla
    case fabric
    case forge
    case neoforge
    case quilt

    public var displayName: String { rawValue }
}
