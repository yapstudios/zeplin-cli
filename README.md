# zeplin-cli

A command-line interface for the Zeplin API.

## Features

- Interactive mode with arrow-key navigation
- All Zeplin read endpoints plus webhook CRUD, member invitations, and notification management
- Screen image downloads (original, large, medium, small thumbnails)
- Multiple output formats (JSON, table, CSV)
- Multiple auth profiles
- Client-side filtering
- Offset-based pagination with `--all` flag
- Shell completions (zsh, bash, fish)

## Commands

```
zeplin-cli
  (default)                Launch interactive mode
  auth
    init                   Set up credentials interactively
    check                  Verify credentials are valid
    profiles               List configured profiles
    use <name>             Set the default profile
  user
    profile                Show current user info (default)
    projects               List user's projects
    styleguides            List user's styleguides
    webhooks               List user's webhooks
    webhook <id>           Get a user webhook
  organizations
    list                   List organizations
    get <id>               Get organization details
    styleguides <id>       List organization styleguides
    workflow-statuses <id> List workflow statuses
    aliens <id>            List external collaborators
    member-projects <org-id> <member-id>
                           List projects accessible to a member
    member-styleguides <org-id> <member-id>
                           List styleguides accessible to a member
  projects
    list                   List projects
    get <id>               Get project details
  screens
    list <project-id>      List screens in a project
    get <project-id> <screen-id>
                           Get screen details
    image <project-id> [<screen-id>]
                           Download screen images
    versions <project-id> <screen-id>
                           List screen versions
    version <project-id> <screen-id> <version-id>
                           Get a specific screen version
    version-latest <project-id> <screen-id>
                           Get the latest screen version
    section <project-id> <section-id>
                           Get a screen section
    notes <project-id> <screen-id>
                           List screen notes
    note <project-id> <screen-id> <note-id>
                           Get a screen note
    annotations <project-id> <screen-id>
                           List screen annotations
    annotation <project-id> <screen-id> <annotation-id>
                           Get a screen annotation
    annotation-types <project-id>
                           List annotation note types
    components <project-id> <screen-id>
                           List components in a screen
    variants <project-id>  List screen variants
    variant <project-id> <variant-id>
                           Get a screen variant
  components
    list                   List components (--project or --styleguide)
    get <id>               Get component details
    version-latest <component-id>
                           Get latest component version (--project or --styleguide)
    connected              List connected components (--project or --styleguide)
    sections               List component sections (--project or --styleguide)
  styleguides
    list                   List styleguides
    get <id>               Get styleguide details
    linked-projects <id>   List projects linked to a styleguide
  colors
    list                   List colors (--project or --styleguide)
  text-styles
    list                   List text styles (--project or --styleguide)
  spacing
    list                   List spacing tokens (--project or --styleguide)
  design-tokens
    get                    Get design tokens (--project or --styleguide)
  flows
    list <project-id>      List flow boards
    get <project-id> <board-id>
                           Get flow board details
    nodes <project-id> <board-id>
                           List nodes in a flow board
    node <project-id> <board-id> <node-id>
                           Get a specific flow board node
    connectors <project-id> <board-id>
                           List connectors in a flow board
    connector <project-id> <board-id> <connector-id>
                           Get a specific flow board connector
    groups <project-id> <board-id>
                           List groups in a flow board
  members
    list                   List members (--organization, --project, or --styleguide)
    invite <org-id>        Invite a member to an organization
  webhooks
    list                   List webhooks (--organization, --project, or --styleguide)
    create                 Create a webhook
    get <id>               Get webhook details
    update <id>            Update a webhook
    delete <id>            Delete a webhook
  notifications
    list                   List notifications
    read <id>              Mark a notification as read
  pages
    list                   List pages (--project or --styleguide)
  spacing-sections
    list                   List spacing sections (--project or --styleguide)
  variables
    list                   List variable collections (--project or --styleguide)
```

## Installation

### Homebrew

```sh
brew install yapstudios/tap/zeplin-cli
```

### Mint

```sh
mint install yapstudios/zeplin-cli
```

### From Source

Requires Swift 6.0+:

```sh
git clone https://github.com/yapstudios/zeplin-cli.git
cd zeplin-cli
swift build -c release
cp .build/release/zeplin-cli /usr/local/bin/
```

## Upgrading

### Homebrew

```sh
brew update && brew upgrade zeplin-cli
```

### Mint

```sh
mint install yapstudios/zeplin-cli
```

### From Source

```sh
git pull && swift build -c release
cp .build/release/zeplin-cli /usr/local/bin/
```

## Shell Completions

Generate completions for your shell:

```sh
# zsh
zeplin-cli --generate-completion-script zsh > ~/.zsh/completions/_zeplin-cli

# bash
zeplin-cli --generate-completion-script bash > /etc/bash_completion.d/zeplin-cli

# fish
zeplin-cli --generate-completion-script fish > ~/.config/fish/completions/zeplin-cli.fish
```

## Quick Start

```sh
# Set up credentials
zeplin-cli auth init

# Launch interactive mode
zeplin-cli

# Or use commands directly
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
| `--output` | `-o` | Output format: json, table, csv |
| `--pretty` | | Pretty-print JSON output |
| `--no-color` | | Disable colored output |
| `--verbose` | `-v` | Enable verbose output |
| `--quiet` | `-q` | Suppress non-essential output |

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

## License

MIT
