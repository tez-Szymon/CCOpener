# CCOpener

A native macOS menu bar app for quickly launching Claude Code in a selected project.

## Features

- Add projects manually.
- Add folders whose immediate subfolders are automatically listed as projects.
- Pin favorite projects to the top of the list.
- Search by project name or path.
- Launch `claude` in a new system Terminal window.
- Run from the menu bar without an additional Dock icon.
- Find indexed projects in Spotlight by searching for `CCOpener` or a project name and pressing Return.
- Store configuration locally.

## Running

Requires macOS 14 or later, Xcode Command Line Tools, and the `claude` command installed.

```bash
swift run CCOpener
```

On first launch, macOS may ask for permission to control Terminal.

## Building the `.app`

```bash
./scripts/build-app.sh
open dist/CCOpener.app
```

You can move the built app from `dist` to `/Applications`.

## Xcode

You can open the package without generating an Xcode project:

```bash
open Package.swift
```

Then select the `CCOpener` scheme and run the app.
