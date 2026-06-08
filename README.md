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

> 本包服务于 [Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher)