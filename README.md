# zeplin-cli

A command-line interface for the Zeplin API.

## Features

- Interactive mode with arrow-key navigation
- All Zeplin read endpoints plus webhook CRUD, member invitations, and notification management
- Multiple output formats (JSON, table, CSV)
- Multiple auth profiles
- Client-side filtering
- Offset-based pagination with `--all` flag
- Shell completions (zsh, bash, fish)

## Commands

```
zeplin
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
brew install yapstudios/tap/zeplin
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
cp .build/release/zeplin /usr/local/bin/
```

## Shell Completions

Generate completions for your shell:

```sh
# zsh
zeplin --generate-completion-script zsh > ~/.zsh/completions/_zeplin

# bash
zeplin --generate-completion-script bash > /etc/bash_completion.d/zeplin

# fish
zeplin --generate-completion-script fish > ~/.config/fish/completions/zeplin.fish
```

## Quick Start

```sh
# Set up credentials
zeplin auth init

# Launch interactive mode
zeplin

# Or use commands directly
zeplin projects list -o table
zeplin screens list <project-id> -o table
zeplin user profile
```

## Authentication

### Getting a Personal Access Token

1. Go to https://app.zeplin.io/profile/developer
2. Under "Personal Access Tokens", click "Create new token"
3. Give it a name and copy the token

### Interactive Setup

```sh
zeplin auth init
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
zeplin projects list
```

### CLI Flag

```sh
zeplin projects list --token "your-personal-access-token"
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
zeplin auth init --profile work
zeplin auth init --profile personal

# Switch default
zeplin auth use work

# Use a specific profile for one command
zeplin projects list --profile personal

# List all profiles
zeplin auth profiles
```

## Usage

### List Projects

```sh
# All projects as JSON
zeplin projects list

# As a table
zeplin projects list -o table

# Filter by organization
zeplin projects list --organization <org-id>

# Filter by status
zeplin projects list --status active

# Filter by name
zeplin projects list --name "iOS App"

# Fetch all pages
zeplin projects list --all
```

### List Screens

```sh
zeplin screens list <project-id> -o table
zeplin screens list <project-id> --name "Login" -o table
zeplin screens list <project-id> --section <section-id>
```

### Get Screen Details

```sh
zeplin screens get <project-id> <screen-id>
zeplin screens versions <project-id> <screen-id> -o table
zeplin screens version-latest <project-id> <screen-id>
```

### Screen Notes and Annotations

```sh
zeplin screens notes <project-id> <screen-id> -o table
zeplin screens annotations <project-id> <screen-id> -o table
zeplin screens annotation-types <project-id>
```

### Screen Variants

```sh
zeplin screens variants <project-id> -o table
zeplin screens variant <project-id> <variant-id>
```

### Colors

```sh
zeplin colors list --project <project-id> -o table
zeplin colors list --styleguide <styleguide-id> -o table
```

### Text Styles

```sh
zeplin text-styles list --project <project-id> -o table
zeplin text-styles list --styleguide <styleguide-id>
```

### Spacing Tokens

```sh
zeplin spacing list --project <project-id> -o table
```

### Design Tokens

```sh
zeplin design-tokens get --project <project-id> --pretty
zeplin design-tokens get --styleguide <styleguide-id>
```

### Components

```sh
zeplin components list --project <project-id> -o table
zeplin components get <component-id> --project <project-id>
zeplin components version-latest <component-id> --project <project-id>
zeplin components connected --project <project-id> -o table
zeplin components sections --project <project-id> -o table
```

### Flow Boards

```sh
zeplin flows list <project-id> -o table
zeplin flows nodes <project-id> <board-id> -o table
zeplin flows node <project-id> <board-id> <node-id>
zeplin flows connectors <project-id> <board-id> -o table
zeplin flows connector <project-id> <board-id> <connector-id>
zeplin flows groups <project-id> <board-id> -o table
```

### Organizations

```sh
zeplin organizations styleguides <org-id> -o table
zeplin organizations workflow-statuses <org-id> -o table
zeplin organizations aliens <org-id> -o table
zeplin organizations member-projects <org-id> <member-id>
zeplin organizations member-styleguides <org-id> <member-id>
```

### Styleguide Linked Projects

```sh
zeplin styleguides linked-projects <styleguide-id> -o table
```

### Members

```sh
zeplin members list --organization <org-id> -o table
zeplin members list --project <project-id> -o table
zeplin members invite <org-id> --email user@example.com --role editor
```

### Webhooks

```sh
zeplin webhooks list --project <project-id> -o table
zeplin webhooks create --project <project-id> --url https://example.com/hook --events "project.screen"
zeplin webhooks delete <webhook-id> --project <project-id>
```

### Notifications

```sh
zeplin notifications list -o table
zeplin notifications list --unread
zeplin notifications read <notification-id>
```

### Current User

```sh
zeplin user                        # defaults to profile
zeplin user profile -o table
zeplin user projects -o table
zeplin user styleguides -o table
zeplin user webhooks -o table
zeplin user webhook <webhook-id>
```

### Pages, Spacing Sections, and Variables

```sh
zeplin pages list --project <project-id> -o table
zeplin spacing-sections list --project <project-id> -o table
zeplin variables list --project <project-id> -o table
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
zeplin projects list
zeplin projects list --pretty
```

### Table

```sh
zeplin projects list -o table
```

### CSV

```sh
zeplin projects list -o csv
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
zeplin projects list | jq '.[].id'

# Get active projects
zeplin projects list | jq '[.[] | select(.status == "active")]'

# Count screens in a project
zeplin screens list <project-id> --all | jq 'length'

# Extract color hex values
zeplin colors list --project <project-id> | jq '.[].hex'

# Export design tokens to file
zeplin design-tokens get --project <project-id> --pretty > tokens.json
```

## License

MIT
