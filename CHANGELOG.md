# Changelog

## 0.4.0

- Add `screens layers` command for browsing the layer tree of a screen
- Add `screens layer-image` command for downloading individual layer images
- Add layer tree browsing with drill-down navigation in interactive mode
- Support exported asset download (any format/density) and screen image cropping as fallback
- Sort layers by visual reading order (top-to-bottom, left-to-right)
- Parse `layers` and `assets` from screen version responses

## 0.3.1

- Fix help text examples to use correct `zeplin-cli` binary name

## 0.3.0

- Reorder interactive project menu by logical grouping (screens, design tokens, components, team)
- Show spacing token and member counts in interactive project menu
- Preserve cursor position when returning to menus
- Return to list with cursor preserved after viewing detail (screens, projects, styleguides)
- Align README with xcodecloud-cli structure and detail

## 0.2.2

- Add `screens image` command for downloading screen images (single, batch, filtered by name)
- Support thumbnail sizes via `--size` flag (original, large/1024px, medium/512px, small/256px)
- Add `ScreenImageThumbnails` model with small/medium/large URLs
- Show pagination hint on truncated list results (screens, projects)

## 0.2.0

- Add 35 read-only API endpoints for full GET coverage
- User command group: projects, styleguides, webhooks
- Screen subcommands: notes, annotations, variants, components, sections, versions
- Component subcommands: latest version, connected components, sections
- Organization subcommands: styleguides, workflow statuses, aliens, member resources
- Flow subcommands: individual node, connector, groups
- Styleguide subcommand: linked projects
- New commands: pages, spacing-sections, variables
- Interactive mode: expanded menus for screen, project, org, and styleguide detail
- Improved decode error messages with exact field path on failure

## 0.1.0

- Initial release
- Interactive mode with arrow-key navigation
- Organizations, projects, screens, components, styleguides commands
- Colors, text styles, spacing tokens, design tokens commands
- Flow boards with nodes and connectors
- Members management and invitations
- Webhook CRUD operations
- Notifications management
- Multiple output formats (JSON, table, CSV)
- Multiple auth profiles
- Client-side filtering
- Offset-based pagination
