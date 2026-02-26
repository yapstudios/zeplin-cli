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

- **Never create GitHub releases.** Tag only.
- Homebrew formula in `yapstudios/homebrew-tap` uses the tag tarball. Update URL and SHA256 when releasing.
- Mint uses the git tag directly.
- Update version in `Sources/ZeplinCLI/CLI.swift` and `CHANGELOG.md` before tagging.

## Dependencies

Only external dependency is `swift-argument-parser`. No third-party terminal UI libraries — interactive mode uses custom `SelectPrompt`/`TerminalUI` in ZeplinKit.
