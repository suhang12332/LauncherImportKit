# LauncherImportKit

Swift package for importing Minecraft launcher instances from third-party launchers.

## Features

- Parse instance metadata (version, mod loader, game name) for a specified launcher type
- Copy instance files with launcher-specific filtering
- SwiftUI import form (`LauncherImportView`)

## Localization

`LauncherImportKit` ships its own `Localizable.xcstrings` with 22 languages:

`ar`, `da`, `de`, `en`, `es`, `fi`, `fr`, `hi`, `it`, `ja`, `ko`, `nb`, `nl`, `pl`, `pt`, `ru`, `sv`, `th`, `tr`, `vi`, `zh-Hans`, `zh-Hant`

UI strings are resolved from the package bundle via `Bundle.module`.

## Supported launchers

- MultiMC / Prism Launcher
- GDLauncher
- SJMCLauncher
- XMCL

## Usage

### Core API

```swift
import LauncherImportKit

let launcherType: ImportLauncherType = .multiMC
let info = try LauncherImportService.parseInstance(at: instancePath, launcherType: launcherType)

try await LauncherImportService.parseAndCopy(
    instancePath: instancePath,
    launcherType: launcherType,
    targetDirectory: targetDirectory,
    onProgress: nil
)
```

### SwiftUI

Host app provides paths, save-game logic, and error reporting via `LauncherImportConfiguration`:

```swift
LauncherImportView(
    configuration: LauncherImportConfiguration(
        launcherType: .multiMC,
        isDownloading: $isDownloading,
        isFormValid: $isFormValid,
        triggerConfirm: $triggerConfirm,
        triggerCancel: $triggerCancel,
        gameName: $gameName,
        isGameNameDuplicate: $isGameNameDuplicate,
        onComplete: { dismiss() },
        onCancel: { dismiss() },
        profileDirectory: { profileURL(for: $0) },
        saveGame: { request in await saveGame(request) },
        cleanupGame: { cleanup($0) },
        reportError: { show($0) },
        isGameNameValid: { !gameName.isEmpty && !isDuplicate },
        checkGameNameDuplicate: { await checkDuplicate($0) },
        cancelDownload: { cancel() },
        resetDownloadState: { reset() },
        isGameDownloading: { isDownloading }
    )
)
```
