import Foundation
import SwiftUI

@MainActor
public final class LauncherImportViewModel: ObservableObject {
    @Published public var selectedInstancePath: URL?
    @Published public var currentInstanceInfo: ImportInstanceInfo?
    @Published public var isImporting = false
    @Published public var importProgress: (fileName: String, completed: Int, total: Int)?

    private let configuration: LauncherImportConfiguration
    private var copyTask: Task<ImportInstanceInfo, Error>?
    private var importTask: Task<Void, Never>?

    public init(configuration: LauncherImportConfiguration) {
        self.configuration = configuration
    }

    private func refreshCurrentInstanceInfo() {
        guard let instancePath = selectedInstancePath else {
            currentInstanceInfo = nil
            return
        }
        currentInstanceInfo = LauncherImportService.previewInstance(
            at: instancePath,
            launcherType: configuration.launcherType
        )
    }

    public var shouldShowProgress: Bool {
        configuration.isGameDownloading() || isImporting
    }

    public func cleanup() {
        copyTask?.cancel()
        copyTask = nil
        importTask?.cancel()
        importTask = nil
        selectedInstancePath = nil
        currentInstanceInfo = nil
        importProgress = nil
        isImporting = false
        configuration.resetDownloadState()
        updateParentState()
    }

    public func updateParentState() {
        let downloading = configuration.isGameDownloading() || isImporting
        let valid = selectedInstancePath != nil
            && configuration.isGameNameValid()
            && currentInstanceInfo.map { LauncherImport.isModLoaderSupported($0.modLoader) } == true

        configuration.isDownloading.wrappedValue = downloading
        configuration.isFormValid.wrappedValue = valid
    }

    public func autoFillGameNameIfNeeded() {
        guard let info = currentInstanceInfo, configuration.gameName.wrappedValue.isEmpty else { return }
        configuration.gameName.wrappedValue = info.gameName
        updateParentState()
    }

    public func checkAndNotifyUnsupportedModLoader() {
        guard let info = currentInstanceInfo,
              !LauncherImport.isModLoaderSupported(info.modLoader) else { return }

        let instanceName = selectedInstancePath?.lastPathComponent ?? "Unknown"
        configuration.reportError(
            .unsupportedModLoader(
                instanceName: instanceName,
                modLoader: info.modLoader,
                supported: LauncherImport.supportedModLoaders
            )
        )
    }

    public func handleFolderSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScopedAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard LauncherImport.validateInstance(at: url, launcherType: configuration.launcherType) else {
                configuration.reportError(.invalidInstance)
                return
            }

            selectedInstancePath = url
            refreshCurrentInstanceInfo()
            autoFillGameNameIfNeeded()
            updateParentState()
        case .failure:
            break
        }
    }

    public func handleConfirm() {
        guard let instancePath = selectedInstancePath else { return }
        importTask?.cancel()
        importTask = Task {
            await importInstance(at: instancePath)
        }
    }

    public func handleCancel() {
        if configuration.isGameDownloading() || isImporting {
            copyTask?.cancel()
            copyTask = nil
            importTask?.cancel()
            importTask = nil
            configuration.cancelDownload()
            Task { await performCancelCleanup() }
        } else {
            configuration.onCancel()
        }
    }

    public func performCancelCleanup() async {
        if let instancePath = selectedInstancePath,
           let info = LauncherImportService.previewInstance(
               at: instancePath,
               launcherType: configuration.launcherType
           ) {
            let gameName = configuration.gameName.wrappedValue.isEmpty
                ? info.gameName
                : configuration.gameName.wrappedValue
            configuration.cleanupGame(gameName)
        }

        isImporting = false
        importProgress = nil
        configuration.resetDownloadState()
        configuration.onCancel()
        updateParentState()
    }

    private func importInstance(at instancePath: URL) async {
        let instanceName = instancePath.lastPathComponent
        let finalGameName = configuration.gameName.wrappedValue.isEmpty
            ? (currentInstanceInfo?.gameName ?? instanceName)
            : configuration.gameName.wrappedValue
        let targetDirectory = configuration.profileDirectory(finalGameName)

        isImporting = true
        updateParentState()
        defer {
            isImporting = false
            updateParentState()
        }

        let instanceInfo: ImportInstanceInfo
        do {
            copyTask = Task {
                try await LauncherImportService.parseAndCopy(
                    instancePath: instancePath,
                    launcherType: configuration.launcherType,
                    targetDirectory: targetDirectory
                ) { fileName, completed, total in
                    Task { @MainActor in
                        self.importProgress = (fileName, completed, total)
                    }
                }
            }
            instanceInfo = try await copyTask!.value
            copyTask = nil
        } catch is CancellationError {
            copyTask = nil
            await performCancelCleanup()
            return
        } catch let error as LauncherImportServiceError {
            copyTask = nil
            reportServiceError(error, instanceName: instanceName)
            return
        } catch {
            copyTask = nil
            configuration.reportError(.copyFailed(message: error.localizedDescription))
            return
        }

        let saveRequest = LauncherImportSaveRequest(
            gameName: finalGameName,
            gameVersion: instanceInfo.gameVersion,
            modLoader: instanceInfo.modLoader,
            modLoaderVersion: instanceInfo.modLoaderVersion
        )

        guard await configuration.saveGame(saveRequest) else { return }

        configuration.resetDownloadState()
        configuration.onComplete()
        updateParentState()
    }

    private func reportServiceError(_ error: LauncherImportServiceError, instanceName: String) {
        switch error {
        case .parseFailed:
            configuration.reportError(.parseFailed(instanceName: instanceName))
        case .missingGameVersion:
            configuration.reportError(.missingGameVersion(instanceName: instanceName))
        case .unsupportedModLoader(_, let modLoader):
            configuration.reportError(
                .unsupportedModLoader(
                    instanceName: instanceName,
                    modLoader: modLoader,
                    supported: LauncherImport.supportedModLoaders
                )
            )
        }
    }
}
