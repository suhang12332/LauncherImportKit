import SwiftUI
import UniformTypeIdentifiers

public struct LauncherImportView: View {
    @StateObject private var viewModel: LauncherImportViewModel
    @State private var showFolderPicker = false

    private let configuration: LauncherImportConfiguration

    public init(configuration: LauncherImportConfiguration) {
        self.configuration = configuration
        _viewModel = StateObject(wrappedValue: LauncherImportViewModel(configuration: configuration))
    }

    private var usesExternalFolderPicker: Bool {
        configuration.folderPickerPresented != nil
    }

    public var body: some View {
        formContent
            .onAppear {
                configuration.hostCallbacks?.handleSelection = viewModel.handleFolderSelection
                configuration.hostCallbacks?.handleConfirm = viewModel.handleConfirm
                configuration.hostCallbacks?.handleCancel = viewModel.handleCancel
                configuration.hostCallbacks?.handleCleanup = viewModel.cleanup
                viewModel.updateParentState()
            }
            .onDisappear { viewModel.cleanup() }
            .onChange(of: viewModel.selectedInstancePath) { _, newValue in
                if newValue != nil {
                    viewModel.autoFillGameNameIfNeeded()
                    viewModel.checkAndNotifyUnsupportedModLoader()
                }
            }
            .onChange(of: configuration.gameName.wrappedValue) { _, _ in
                viewModel.updateParentState()
            }
            .onChange(of: configuration.isGameNameDuplicate.wrappedValue) { _, _ in
                viewModel.updateParentState()
            }
            .onChange(of: configuration.triggerConfirm.wrappedValue) { _, triggered in
                guard triggered else { return }
                configuration.triggerConfirm.wrappedValue = false
                viewModel.handleConfirm()
            }
            .onChange(of: configuration.triggerCancel.wrappedValue) { _, triggered in
                guard triggered else { return }
                configuration.triggerCancel.wrappedValue = false
                viewModel.handleCancel()
            }
            .modifier(InternalFolderPickerModifier(
                isEnabled: !usesExternalFolderPicker,
                isPresented: $showFolderPicker,
                onSelection: viewModel.handleFolderSelection
            ))
    }

    private var formContent: some View {
        VStack(spacing: 16) {
            pathSelectionSection
            instanceInfoSection(for: viewModel.currentInstanceInfo)
            gameNameSection
            if viewModel.shouldShowProgress {
                VStack(spacing: 24) {
                    if viewModel.isImporting, let progress = viewModel.importProgress {
                        copyProgressSection(progress: progress)
                    }
                    if let downloadProgressView = configuration.downloadProgressView {
                        downloadProgressView
                    }
                }
            }
        }
    }

    private var pathSelectionSection: some View {
        LauncherImportSection {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "launcher.import.select_instance_folder", bundle: .module))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    if let path = viewModel.selectedInstancePath?.path {
                        Text(path)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    } else {
                        Text(String(localized: "launcher.import.no_path_selected", bundle: .module))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(String(localized: "launcher.import.browse", bundle: .module)) {
                        if let folderPickerPresented = configuration.folderPickerPresented {
                            folderPickerPresented.wrappedValue = true
                        } else {
                            showFolderPicker = true
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func instanceInfoSection(for instanceInfo: ImportInstanceInfo?) -> some View {
        if let info = instanceInfo {
            LauncherImportSection {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(String(localized: "launcher.import.game_name", bundle: .module), value: info.gameName)
                    infoRow(String(localized: "launcher.import.game_version", bundle: .module), value: info.gameVersion)
                    if !info.modLoader.isEmpty, info.modLoader != "vanilla" {
                        let loaderText = info.modLoaderVersion.isEmpty
                            ? info.modLoader.capitalized
                            : "\(info.modLoader.capitalized) \(info.modLoaderVersion)"
                        infoRow(String(localized: "launcher.import.mod_loader", bundle: .module), value: loaderText)
                    }
                }
            }
        }
    }

    private var gameNameSection: some View {
        LauncherImportSection {
            LauncherImportGameNameField(
                gameName: configuration.gameName,
                isDuplicate: configuration.isGameNameDuplicate,
                isDisabled: viewModel.isImporting || configuration.isGameDownloading(),
                checkDuplicate: configuration.checkGameNameDuplicate
            )
            .onChange(of: configuration.gameName.wrappedValue) { _, _ in
                viewModel.updateParentState()
            }
        }
    }

    private func copyProgressSection(progress: (fileName: String, completed: Int, total: Int)) -> some View {
        LauncherImportSection {
            LauncherImportProgressRow(
                title: String(localized: "launcher.import.copying_files", bundle: .module),
                progress: progress.total > 0 ? Double(progress.completed) / Double(progress.total) : 0,
                currentFile: progress.fileName,
                completed: progress.completed,
                total: progress.total
            )
        }
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct InternalFolderPickerModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var isPresented: Bool
    let onSelection: (Result<[URL], Error>) -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .fileImporter(
                    isPresented: $isPresented,
                    allowedContentTypes: [.folder],
                    allowsMultipleSelection: false,
                    onCompletion: onSelection
                )
                .fileDialogDefaultDirectory(FileManager.default.homeDirectoryForCurrentUser)
        } else {
            content
        }
    }
}

private struct LauncherImportSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
                .padding(.top, 6)
                .padding(.bottom, 6)
        }
    }
}

private struct LauncherImportGameNameField: View {
    @Binding var gameName: String
    @Binding var isDuplicate: Bool
    let isDisabled: Bool
    let checkDuplicate: (String) async -> Bool

    @State private var showDuplicatePopover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "launcher.import.game_name", bundle: .module))
                .foregroundStyle(.primary)
            TextField(String(localized: "launcher.import.game_name.placeholder", bundle: .module), text: $gameName)
                .textFieldStyle(.roundedBorder)
                .disabled(isDisabled)
                .popover(isPresented: $showDuplicatePopover, arrowEdge: .trailing) {
                    Text(String(localized: "launcher.import.game_name.duplicate", bundle: .module))
                        .padding()
                }
                .onChange(of: gameName) { _, newName in
                    Task {
                        let duplicate = await checkDuplicate(newName)
                        await MainActor.run {
                            isDuplicate = duplicate
                            showDuplicatePopover = duplicate
                        }
                    }
                }
        }
    }
}

private struct LauncherImportProgressRow: View {
    let title: String
    let progress: Double
    let currentFile: String
    let completed: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(progressPercentText)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .animation(.easeOut(duration: 0.5), value: progress)
            HStack {
                Text(currentFile)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var progressPercentText: String {
        let clampedProgress = min(max(progress, 0), 1)
        return clampedProgress.formatted(.percent.precision(.fractionLength(0)))
    }
}
