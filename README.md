# zeplin-cli

[![CI](https://github.com/yapstudios/zeplin-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/yapstudios/zeplin-cli/actions/workflows/ci.yml)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138.svg)](https://swift.org)
[![macOS 12+](https://img.shields.io/badge/macOS-12%2B-000000.svg)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Homebrew](https://img.shields.io/badge/Homebrew-yapstudios%2Ftap-FBB040.svg)](https://github.com/yapstudios/homebrew-tap)

A command-line interface for the [Zeplin API](https://docs.zeplin.dev/).

## Features

- **Interactive mode** — arrow-key navigation through projects, screens, and design tokens
- **Full API coverage** — all Zeplin read endpoints plus webhook CRUD, member invitations, and notifications
- **Screen image downloads** — original or thumbnails (large, medium, small)
- **Multiple output formats** — JSON (default), table, or CSV
- **Profile support** — manage multiple Zeplin accounts
- **Client-side filtering** — filter by name, status, tag, section
- **Pagination** — offset-based with `--all` flag
- **Zero dependencies** — pure Swift, no external libraries for terminal UI
- **Shell completions** — zsh, bash, and fish

## Commands

```
zeplin-cli
├── (no args)                          → Interactive mode (arrow-key navigation)
├── auth
│   ├── init                           → Set up credentials interactively
│   ├── check                          → Verify credentials are valid
│   ├── profiles                       → List configured profiles
│   └── use <name>                     → Set the default profile
├── user
│   ├── profile                        → Show current user info (default)
│   ├── projects                       → List user's projects
│   ├── styleguides                    → List user's styleguides
│   ├── webhooks                       → List user's webhooks
│   └── webhook <id>                   → Get a user webhook
├── organizations
│   ├── list                           → List organizations
│   ├── get <id>                       → Get organization details
│   ├── styleguides <id>               → List organization styleguides
│   ├── workflow-statuses <id>         → List workflow statuses
│   ├── aliens <id>                    → List external collaborators
│   ├── member-projects <org> <member> → List member's projects
│   └── member-styleguides <org> <m>   → List member's styleguides
├── projects
│   ├── list                           → List projects
│   └── get <id>                       → Get project details
├── screens
│   ├── list <project>                 → List screens in a project
│   ├── get <project> <screen>         → Get screen details
│   ├── image <project> [<screen>]     → Download screen images
│   ├── versions <project> <screen>    → List screen versions
│   ├── version <project> <s> <ver>    → Get a specific screen version
│   ├── version-latest <project> <s>   → Get the latest screen version
│   ├── section <project> <section>    → Get a screen section
│   ├── notes <project> <screen>       → List screen notes
│   ├── note <project> <s> <note>      → Get a screen note
│   ├── annotations <project> <screen> → List screen annotations
│   ├── annotation <project> <s> <a>   → Get a screen annotation
│   ├── annotation-types <project>     → List annotation note types
│   ├── components <project> <screen>  → List components in a screen
│   ├── variants <project>             → List screen variants
│   └── variant <project> <variant>    → Get a screen variant
├── components
│   ├── list                           → List components
│   ├── get <id>                       → Get component details
│   ├── version-latest <id>            → Get latest component version
│   ├── connected                      → List connected components
│   └── sections                       → List component sections
├── styleguides
│   ├── list                           → List styleguides
│   ├── get <id>                       → Get styleguide details
│   └── linked-projects <id>           → List linked projects
├── colors
│   └── list                           → List colors
├── text-styles
│   └── list                           → List text styles
├── spacing
│   └── list                           → List spacing tokens
├── design-tokens
│   └── get                            → Get design tokens
├── flows
│   ├── list <project>                 → List flow boards
│   ├── get <project> <board>          → Get flow board details
│   ├── nodes <project> <board>        → List nodes in a flow board
│   ├── node <project> <board> <node>  → Get a specific node
│   ├── connectors <project> <board>   → List connectors in a flow board
│   ├── connector <project> <b> <c>    → Get a specific connector
│   └── groups <project> <board>       → List groups in a flow board
├── members
│   ├── list                           → List members
│   └── invite <org-id>                → Invite a member
├── webhooks
│   ├── list                           → List webhooks
│   ├── create                         → Create a webhook
│   ├── get <id>                       → Get webhook details
│   ├── update <id>                    → Update a webhook
│   └── delete <id>                    → Delete a webhook
├── notifications
│   ├── list                           → List notifications
│   └── read <id>                      → Mark as read
├── pages
│   └── list                           → List pages
├── spacing-sections
│   └── list                           → List spacing sections
└── variables
    └── list                           → List variable collections
```

## Installation

### Using Homebrew (recommended)

```sh
brew install yapstudios/tap/zeplin-cli
```

To update later:

```sh
brew upgrade zeplin-cli
```

This builds from source and automatically installs shell completions for zsh, bash, and fish.

### Using Mint

[Mint](https://github.com/yonaskolb/Mint) is a package manager for Swift CLI tools.

```sh
brew install mint
mint install yapstudios/zeplin-cli
```

Make sure `~/.mint/bin` is in your PATH:

```sh
echo 'export PATH="$HOME/.mint/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

To update later:

```sh
mint install yapstudios/zeplin-cli
```

### Building from source

Requires Xcode 16+ (Swift 6) to build. Runs on macOS 12 (Monterey) or later.

```sh
git clone https://github.com/yapstudios/zeplin-cli.git
cd zeplin-cli
swift build -c release
cp .build/release/zeplin-cli /usr/local/bin/
```

### Shell completions

Enable tab-completion for all commands and flags:

**Zsh (default on macOS):**

```sh
zeplin-cli --generate-completion-script zsh > ~/.zsh/completions/_zeplin-cli
```

Then add this to your `~/.zshrc` (if not already present):

```sh
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

**Bash:**

```sh
zeplin-cli --generate-completion-script bash > ~/.bash_completions/zeplin-cli.bash
echo 'source ~/.bash_completions/zeplin-cli.bash' >> ~/.bash_profile
```

**Fish:**

```sh
zeplin-cli --generate-completion-script fish > ~/.config/fish/completions/zeplin-cli.fish
```

## Quick Start

```sh
# Launch interactive mode — prompts to set up credentials on first run
zeplin-cli

# Or set up credentials directly
zeplin-cli auth init

# Use commands directly
zeplin-cli projects list -o table
zeplin-cli screens list <project-id> -o table
zeplin-cli user profile
```

## Authentication

### Getting a Personal Access Token

1. Go to https://app.zeplin.io/profile/developer
2. Under "Personal Access Tokens", click "Create new token"
3. Give it a name and copy the token

### Interactive Setup

```sh
zeplin-cli auth init
```

This prompts for your token, optionally a default organization ID, and saves credentials to `~/.zeplin/config.json` with restricted permissions (600). It also verifies the token works.

### Manual Config File

Create `~/.zeplin/config.json`:

```json
{
  "defaultProfile": "default",
  "profiles": {
    "default": {
      "token": "your-personal-access-token",
      "organizationId": "optional-default-org-id"
    }
  }
}
```

### Environment Variable

```sh
export ZEPLIN_TOKEN="your-personal-access-token"
zeplin-cli projects list
```

### CLI Flag

```sh
zeplin-cli projects list --token "your-personal-access-token"
```

### Credential Resolution Order

Credentials are resolved in this order (first match wins):

1. `--token` command-line flag
2. `ZEPLIN_TOKEN` environment variable
3. Project-local config (`.zeplin/config.json`)
4. Global config (`~/.zeplin/config.json`)

### Multiple Profiles

```sh
# Create profiles
zeplin-cli auth init --profile work
zeplin-cli auth init --profile personal

# Switch default
zeplin-cli auth use work

# Use a specific profile for one command
zeplin-cli projects list --profile personal

# List all profiles
zeplin-cli auth profiles
```

## Usage

### Interactive mode

```sh
zeplin-cli
```

Navigate with arrow keys, select with Enter, go back or quit with `q`.

If no credentials are configured, interactive mode will offer to set them up on first launch.

### List Projects

```sh
# All projects as JSON
zeplin-cli projects list

# As a table
zeplin-cli projects list -o table

# Filter by organization
zeplin-cli projects list --organization <org-id>

# Filter by status
zeplin-cli projects list --status active

# Filter by name
zeplin-cli projects list --name "iOS App"

# Fetch all pages
zeplin-cli projects list --all
```

### List Screens

```sh
zeplin-cli screens list <project-id> -o table
zeplin-cli screens list <project-id> --name "Login" -o table
zeplin-cli screens list <project-id> --section <section-id>
```

### Get Screen Details

```sh
zeplin-cli screens get <project-id> <screen-id>
zeplin-cli screens versions <project-id> <screen-id> -o table
zeplin-cli screens version-latest <project-id> <screen-id>
```

### Screen Notes and Annotations

```sh
zeplin-cli screens notes <project-id> <screen-id> -o table
zeplin-cli screens annotations <project-id> <screen-id> -o table
zeplin-cli screens annotation-types <project-id>
```

### Screen Variants

```sh
zeplin-cli screens variants <project-id> -o table
zeplin-cli screens variant <project-id> <variant-id>
```

### Download Screen Images

```sh
# Single screen
zeplin-cli screens image <project-id> <screen-id>

# All screens to a directory
zeplin-cli screens image <project-id> --all --output-dir ./images/

# Filter by name
zeplin-cli screens image <project-id> --all --name "Login" --output-dir ./images/

# Download thumbnails instead of originals (small, medium, large)
zeplin-cli screens image <project-id> --all --size small --output-dir ./thumbs/
```

### Colors

```sh
zeplin-cli colors list --project <project-id> -o table
zeplin-cli colors list --styleguide <styleguide-id> -o table
```

### Text Styles

```sh
zeplin-cli text-styles list --project <project-id> -o table
zeplin-cli text-styles list --styleguide <styleguide-id>
```

### Spacing Tokens

```sh
zeplin-cli spacing list --project <project-id> -o table
```

### Design Tokens

```sh
zeplin-cli design-tokens get --project <project-id> --pretty
zeplin-cli design-tokens get --styleguide <styleguide-id>
```

### Components

```sh
zeplin-cli components list --project <project-id> -o table
zeplin-cli components get <component-id> --project <project-id>
zeplin-cli components version-latest <component-id> --project <project-id>
zeplin-cli components connected --project <project-id> -o table
zeplin-cli components sections --project <project-id> -o table
```

### Flow Boards

```sh
zeplin-cli flows list <project-id> -o table
zeplin-cli flows nodes <project-id> <board-id> -o table
zeplin-cli flows node <project-id> <board-id> <node-id>
zeplin-cli flows connectors <project-id> <board-id> -o table
zeplin-cli flows connector <project-id> <board-id> <connector-id>
zeplin-cli flows groups <project-id> <board-id> -o table
```

### Organizations

```sh
zeplin-cli organizations styleguides <org-id> -o table
zeplin-cli organizations workflow-statuses <org-id> -o table
zeplin-cli organizations aliens <org-id> -o table
zeplin-cli organizations member-projects <org-id> <member-id>
zeplin-cli organizations member-styleguides <org-id> <member-id>
```

### Styleguide Linked Projects

```sh
zeplin-cli styleguides linked-projects <styleguide-id> -o table
```

### Members

```sh
zeplin-cli members list --organization <org-id> -o table
zeplin-cli members list --project <project-id> -o table
zeplin-cli members invite <org-id> --email user@example.com --role editor
```

### Webhooks

```sh
zeplin-cli webhooks list --project <project-id> -o table
zeplin-cli webhooks create --project <project-id> --url https://example.com/hook --events "project.screen"
zeplin-cli webhooks delete <webhook-id> --project <project-id>
```

### Notifications

```sh
zeplin-cli notifications list -o table
zeplin-cli notifications list --unread
zeplin-cli notifications read <notification-id>
```

### Current User

```sh
zeplin-cli user                       # defaults to profile
zeplin-cli user profile -o table
zeplin-cli user projects -o table
zeplin-cli user styleguides -o table
zeplin-cli user webhooks -o table
zeplin-cli user webhook <webhook-id>
```

### Pages, Spacing Sections, and Variables

```sh
zeplin-cli pages list --project <project-id> -o table
zeplin-cli spacing-sections list --project <project-id> -o table
zeplin-cli variables list --project <project-id> -o table
```

## API Coverage

### Supported

All GET endpoints across: users, organizations, projects, screens, components, styleguides, colors, text styles, spacing tokens, design tokens, flows, members, webhooks, notifications, pages, spacing sections, and variables.

Write operations:

- **Webhooks** — full CRUD (create, read, update, delete) scoped to organizations, projects, and styleguides
- **Members** — organization member invitations
- **Notifications** — list and mark as read

### Not Supported

The CLI uses personal access tokens and does not implement the OAuth flow. The following write/mutate operations are not covered:

- Project, screen, component, and styleguide create/update/delete
- Screen note, annotation, and comment create/update/delete
- Color, text style, and spacing token create/update/delete
- Design token updates
- Member role changes and removal (except org invitations)
- File uploads (screen images, assets)

## Output Formats

### JSON (default)

```sh
zeplin-cli projects list
zeplin-cli projects list --pretty
```

### Table

```sh
zeplin-cli projects list -o table
```

### CSV

```sh
zeplin-cli projects list -o csv
```

## Global Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--token` | | Personal access token |
| `--organization` | | Default organization ID |
| `--profile` | | Use named auth profile |
| `--output` | `-o` | Output format: `json`, `table`, `csv` |
| `--pretty` | | Pretty-print JSON output |
| `--no-color` | | Disable colored output |
| `--verbose` | `-v` | Enable verbose output |
| `--quiet` | `-q` | Suppress non-essential output |
| `--limit <n>` | | Maximum number of results per page (for list commands) |
| `--all` | | Fetch all pages of results (for list commands) |
| `--help` | `-h` | Show help for any command |

## Filtering

List commands support client-side filtering. Filters are applied after fetching results from the API.

| Command | Flag | Description |
|---------|------|-------------|
| `projects list` | `--name <text>` | Filter by name |
| `projects list` | `--status <s>` | Filter by status (active, archived) |
| `projects list` | `--org-id <id>` | Filter by organization |
| `screens list` | `--name <text>` | Filter by name |
| `screens list` | `--section <id>` | Filter by section |
| `screens list` | `--tag <text>` | Filter by tag |
| `screens image` | `--name <text>` | Filter by name |
| `screens image` | `--size <size>` | Image size: original, large, medium, small |

## Scripting

Pipe JSON output to `jq` for further processing:

```sh
# Get all project IDs
zeplin-cli projects list | jq '.[].id'

# Get active projects
zeplin-cli projects list | jq '[.[] | select(.status == "active")]'

# Count screens in a project
zeplin-cli screens list <project-id> --all | jq 'length'

# Extract color hex values
zeplin-cli colors list --project <project-id> | jq '.[].hex'

# Export design tokens to file
zeplin-cli design-tokens get --project <project-id> --pretty > tokens.json
```

## Troubleshooting

### "Missing credentials: No credentials configured"

Run `zeplin-cli auth init` to set up credentials interactively. In interactive mode (`zeplin-cli` with no arguments), you'll be prompted to set up credentials automatically.

You can also check that your config file exists at `~/.zeplin/config.json`.

### "Unauthorized" errors

- Verify your personal access token is correct
- Tokens may have expired — regenerate at https://app.zeplin.io/profile/developer
- Run `zeplin-cli auth check` to verify credentials

### "Forbidden" errors

Your token may not have access to the requested project or organization. Check that the token owner has been granted access.

### Rate limited

The Zeplin API enforces rate limits. If you hit them in scripts:
- Use `--limit` to reduce page sizes
- Add delays between requests in loops
- Avoid `--all` on very large projects

### Interactive mode not working

Interactive mode requires a TTY. It won't work when:
- Output is piped (`zeplin-cli | grep ...`)
- Running in a non-interactive shell
- Running in some CI environments

Use direct commands with `-o table` or `-o json` instead.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes by version.

## Support

If you find this tool useful, consider giving it a star on GitHub — it helps others discover it.

## License

[MIT](LICENSE)
