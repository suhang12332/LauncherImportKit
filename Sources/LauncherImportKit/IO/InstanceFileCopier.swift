import Foundation
import os

public enum InstanceFileCopier {
    private static let logger = Logger(subsystem: "com.su.code.LauncherImportKit", category: "InstanceFileCopier")

    public static func copyDirectory(
        from sourceDirectory: URL,
        to targetDirectory: URL,
        fileFilter: ((String) -> Bool)? = nil,
        onProgress: ((String, Int, Int) -> Void)?
    ) async throws {
        let fileManager = FileManager.default

        try fileManager.createDirectory(
            at: targetDirectory,
            withIntermediateDirectories: true
        )

        let allFiles = try getAllFiles(in: sourceDirectory)

        let standardizedSourceURL = sourceDirectory.resolvingSymlinksInPath()
        let sourcePath = getNormalizedPath(standardizedSourceURL.path)

        let filesToCopy = allFiles.compactMap { fileURL -> (sourceURL: URL, relativePath: String, targetURL: URL)? in
            let standardizedFileURL = fileURL.resolvingSymlinksInPath()
            let filePath = standardizedFileURL.path

            guard filePath.hasPrefix(sourcePath) else {
                logger.warning("File outside source directory: \(filePath, privacy: .public)")
                return nil
            }

            let relativePath = String(filePath.dropFirst(sourcePath.count))
            if let fileFilter, !fileFilter(relativePath) {
                return nil
            }

            let targetURL = targetDirectory.appendingPathComponent(relativePath)
            return (sourceURL: fileURL, relativePath: relativePath, targetURL: targetURL)
        }

        let totalFiles = filesToCopy.count
        let filteredCount = allFiles.count - totalFiles

        if filteredCount > 0 {
            logger.info("Copying \(totalFiles) files (\(filteredCount) filtered) from \(sourceDirectory.path, privacy: .public)")
        } else {
            logger.info("Copying \(totalFiles) files from \(sourceDirectory.path, privacy: .public)")
        }

        var completed = 0
        for (sourceURL, _, targetURL) in filesToCopy {
            try Task.checkCancellation()

            let targetDir = targetURL.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: targetDir,
                withIntermediateDirectories: true
            )

            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.copyItem(at: sourceURL, to: targetURL)

            completed += 1
            onProgress?(sourceURL.lastPathComponent, completed, totalFiles)

            try await Task.sleep(nanoseconds: 1_000_000)
        }

        logger.info("Copy completed: \(completed)/\(totalFiles) files")
    }

    public static func copyGameDirectory(
        from sourceDirectory: URL,
        to targetDirectory: URL,
        launcherType: ImportLauncherType,
        onProgress: ((String, Int, Int) -> Void)?
    ) async throws {
        try await copyDirectory(
            from: sourceDirectory,
            to: targetDirectory,
            fileFilter: { relativePath in
                !LauncherFileFilter.shouldFilter(fileName: relativePath, launcherType: launcherType)
            },
            onProgress: onProgress
        )
    }

    public static func getAllFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        var files: [URL] = []

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if resourceValues.isRegularFile == true {
                files.append(fileURL)
            }
        }

        return files
    }

    private static func getNormalizedPath(_ path: String) -> String {
        path.hasSuffix("/") ? path : path + "/"
    }
}
