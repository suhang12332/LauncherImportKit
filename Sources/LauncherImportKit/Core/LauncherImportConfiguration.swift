import SwiftUI

/// Host-app callbacks wired from outside the kit view hierarchy.
@MainActor
public final class LauncherImportHostCallbacks {
    public var handleSelection: ((Result<[URL], Error>) -> Void)?
    public var handleConfirm: (() -> Void)?
    public var handleCancel: (() -> Void)?
    public var handleCleanup: (() -> Void)?

    public init() {}
}

public struct LauncherImportConfiguration {
    public let launcherType: ImportLauncherType
    public var folderPickerPresented: Binding<Bool>?
    public var hostCallbacks: LauncherImportHostCallbacks?
    public var isDownloading: Binding<Bool>
    public var isFormValid: Binding<Bool>
    public var triggerConfirm: Binding<Bool>
    public var triggerCancel: Binding<Bool>
    public var gameName: Binding<String>
    public var isGameNameDuplicate: Binding<Bool>

    public var onComplete: () -> Void
    public var onCancel: () -> Void
    public var profileDirectory: (String) -> URL
    public var saveGame: (LauncherImportSaveRequest) async -> Bool
    public var cleanupGame: (String) -> Void
    public var reportError: (LauncherImportUserError) -> Void
    public var isGameNameValid: () -> Bool
    public var checkGameNameDuplicate: (String) async -> Bool
    public var cancelDownload: () -> Void
    public var resetDownloadState: () -> Void
    public var isGameDownloading: () -> Bool
    public var downloadProgressView: AnyView?

    public init(
        launcherType: ImportLauncherType,
        folderPickerPresented: Binding<Bool>? = nil,
        hostCallbacks: LauncherImportHostCallbacks? = nil,
        isDownloading: Binding<Bool>,
        isFormValid: Binding<Bool>,
        triggerConfirm: Binding<Bool>,
        triggerCancel: Binding<Bool>,
        gameName: Binding<String>,
        isGameNameDuplicate: Binding<Bool>,
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        profileDirectory: @escaping (String) -> URL,
        saveGame: @escaping (LauncherImportSaveRequest) async -> Bool,
        cleanupGame: @escaping (String) -> Void,
        reportError: @escaping (LauncherImportUserError) -> Void,
        isGameNameValid: @escaping () -> Bool,
        checkGameNameDuplicate: @escaping (String) async -> Bool,
        cancelDownload: @escaping () -> Void,
        resetDownloadState: @escaping () -> Void,
        isGameDownloading: @escaping () -> Bool,
        downloadProgressView: AnyView? = nil
    ) {
        self.launcherType = launcherType
        self.folderPickerPresented = folderPickerPresented
        self.hostCallbacks = hostCallbacks
        self.isDownloading = isDownloading
        self.isFormValid = isFormValid
        self.triggerConfirm = triggerConfirm
        self.triggerCancel = triggerCancel
        self.gameName = gameName
        self.isGameNameDuplicate = isGameNameDuplicate
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.profileDirectory = profileDirectory
        self.saveGame = saveGame
        self.cleanupGame = cleanupGame
        self.reportError = reportError
        self.isGameNameValid = isGameNameValid
        self.checkGameNameDuplicate = checkGameNameDuplicate
        self.cancelDownload = cancelDownload
        self.resetDownloadState = resetDownloadState
        self.isGameDownloading = isGameDownloading
        self.downloadProgressView = downloadProgressView
    }
}
