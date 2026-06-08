import Foundation
import os

enum LauncherFileFilter {
    private static let logger = Logger(subsystem: "com.su.code.LauncherImportKit", category: "LauncherFileFilter")

    static func getFilterPatterns(for launcherType: ImportLauncherType) -> [String] {
        switch launcherType {
        case .multiMC, .prismLauncher:
            return [
                ".*\\.mmc-pack\\.json$",
                ".*instance\\.cfg$",
                ".*\\.log$",
                "^pack\\.meta$",
            ]

        case .gdLauncher:
            return [
                ".*config\\.json$",
                ".*\\.log$",
                "^metadata\\.json$",
            ]

        case .sjmcLauncher:
            return [
                ".*sjmclcfg\\.json$",
                ".*\\.log$",
                "^\\d+.*-.*\\.json$",
                "^\\d+.*-.*\\.jar$",
            ]

        case .xmcl:
            return [
                ".*instance\\.json$",
                ".*\\.log$",
                "^metadata\\.json$",
            ]
        }
    }

    static func shouldFilter(fileName: String, launcherType: ImportLauncherType) -> Bool {
        let patterns = getFilterPatterns(for: launcherType)

        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(fileName.startIndex..<fileName.endIndex, in: fileName)

                if regex.firstMatch(in: fileName, options: [], range: range) != nil {
                    logger.debug("Filtered file: \(fileName, privacy: .public) (pattern: \(pattern, privacy: .public))")
                    return true
                }
            } catch {
                logger.warning("Invalid regex pattern: \(pattern, privacy: .public)")
            }
        }

        return false
    }
}
