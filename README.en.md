# CleanMyScreen

[中文](./README.md)

CleanMyScreen is a native macOS utility app for cleaning a MacBook screen. It turns every connected display black, prevents accidental input from reaching the desktop or other apps, and lets you return with `Esc` or the on-screen `Done` button.

## Features

- Native macOS `SwiftUI + AppKit` app
- Multi-display black screen cleaning mode
- Automatic UI localization based on the macOS preferred language list
- Localized UI support for English, Simplified Chinese, Traditional Chinese, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese
- Built-in packaging script for `.app`, `.pkg`, `.dmg`, and `.zip`

## Development

```bash
swift build
swift run CleanMyScreenVerification
swift run CleanMyScreen
```

## Packaging

```bash
./scripts/package_release.sh
```

Generated artifacts are written to `dist/`.
