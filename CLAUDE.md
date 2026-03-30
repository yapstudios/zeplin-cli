# Project Instructions

## Architecture

Three targets with layered responsibilities:

- **zeplin-cli** — Executable entry point (`main.swift`). Pre-flight logic only.
- **ZeplinCLI** — Commands, options, CLI orchestration. Depends on ZeplinKit + ArgumentParser.
- **ZeplinKit** — API client, auth, models, output formatting, terminal UI. No CLI dependencies.

Tests mirror this: `ZeplinCLITests` (command parsing), `ZeplinKitTests` (models, formatting, credentials), `IntegrationTests` (end-to-end API).

## Commands

Commands follow a strict pattern: `struct` conforming to `ParsableCommand`, `@OptionGroup var options: GlobalOptions`, async work via `runAsync {}`, output via `OutputFormatter`. Parent commands define a `subcommands` array. Look at existing commands for the template.

New commands must be registered in `Zeplin.configuration.subcommands` in `CLI.swift`.

## Testing

Uses Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), not XCTest. Command parsing tests verify argument wiring via `Zeplin.parseAsRoot()`.

## Releases

- Update version in `Sources/ZeplinCLI/CLI.swift` and `CHANGELOG.md` before tagging.
- Pushing a tag triggers `.github/workflows/release.yml`, which builds a universal binary and creates a GitHub Release with `zeplin-cli-macos.tar.gz` attached.
- After the release, update the Homebrew formula in `yapstudios/homebrew-tap` with the new URL and SHA256 from the release notes.
- Mint uses the git tag directly (no formula update needed).

## Dependencies

Only external dependency is `swift-argument-parser`. No third-party terminal UI libraries — interactive mode uses custom `SelectPrompt`/`TerminalUI` in ZeplinKit.
