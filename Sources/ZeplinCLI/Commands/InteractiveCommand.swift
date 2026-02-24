import ArgumentParser
import Foundation
import ZeplinKit

struct InteractiveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "interactive",
        abstract: "Launch interactive mode",
        shouldDisplay: false
    )

    @OptionGroup var options: GlobalOptions

    mutating func run() throws {
        guard TerminalUI.isInteractiveTerminal else {
            printError("Interactive mode requires a terminal. Use direct commands instead.")
            printError("Run 'zeplin --help' for available commands.")
            throw ExitCode.failure
        }

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch {
            print("No credentials configured.\n")
            print("Run 'zeplin auth init' to set up credentials.")
            print("Or provide a token: zeplin --token <token> <command>")
            throw ExitCode.failure
        }

        try mainMenu(client: client)
    }

    private func mainMenu(client: APIClient) throws {
        while true {
            let choice = try SelectPrompt.run(
                prompt: "Zeplin CLI",
                choices: [
                    Choice(label: "Organizations", value: "organizations"),
                    Choice(label: "Projects", value: "projects"),
                    Choice(label: "Styleguides", value: "styleguides"),
                    Choice(label: "My Profile", value: "profile"),
                    Choice(label: "Exit", value: "exit")
                ]
            )

            switch choice.value {
            case "organizations":
                try organizationsMenu(client: client)
            case "projects":
                try projectsMenu(client: client)
            case "styleguides":
                try styleguidesMenu(client: client)
            case "profile":
                try showProfile(client: client)
            case "exit":
                return
            default:
                break
            }
        }
    }

    private func organizationsMenu(client: APIClient) throws {
        let orgs = try runAsync { try await client.listOrganizations() }

        guard !orgs.isEmpty else {
            print("No organizations found.")
            return
        }

        let choices = orgs.map { Choice(label: $0.name, value: $0.id) }
        let choice = try SelectPrompt.run(prompt: "Select organization", choices: choices)

        guard let org = orgs.first(where: { $0.id == choice.value }) else { return }
        try organizationDetail(client: client, org: org)
    }

    private func organizationDetail(client: APIClient, org: Organization) throws {
        while true {
            let choice = try SelectPrompt.run(
                prompt: org.name,
                choices: [
                    Choice(label: "Projects", value: "projects"),
                    Choice(label: "Styleguides", value: "styleguides"),
                    Choice(label: "Back", value: "back")
                ]
            )

            switch choice.value {
            case "projects":
                do {
                    let projects = try runAsync {
                        try await client.listAllProjects(organizationId: org.id)
                    }
                    if projects.isEmpty {
                        print("No projects found.")
                    } else {
                        let choices = projects.map {
                            Choice(label: $0.name, value: $0.id, description: $0.platform)
                        }
                        let selected = try SelectPrompt.run(prompt: "Select project", choices: choices)
                        if let project = projects.first(where: { $0.id == selected.value }) {
                            try projectDetail(client: client, project: project)
                        }
                    }
                } catch let error as CLIError {
                    printError(error.localizedDescription)
                }
            case "styleguides":
                do {
                    let styleguides = try runAsync {
                        try await client.listAllStyleguides()
                    }
                    if styleguides.isEmpty {
                        print("No styleguides found.")
                    } else {
                        let choices = styleguides.map {
                            Choice(label: $0.name, value: $0.id, description: $0.platform)
                        }
                        let selected = try SelectPrompt.run(prompt: "Select styleguide", choices: choices)
                        if let sg = styleguides.first(where: { $0.id == selected.value }) {
                            try styleguideDetail(client: client, styleguide: sg)
                        }
                    }
                } catch let error as CLIError {
                    printError(error.localizedDescription)
                }
            case "back":
                return
            default:
                break
            }
        }
    }

    private func projectsMenu(client: APIClient) throws {
        let projects = try runAsync { try await client.listAllProjects() }

        guard !projects.isEmpty else {
            print("No projects found.")
            return
        }

        let choices = projects.map {
            Choice(label: $0.name, value: $0.id, description: $0.platform)
        }
        let choice = try SelectPrompt.run(prompt: "Select project", choices: choices)

        guard let project = projects.first(where: { $0.id == choice.value }) else { return }
        try projectDetail(client: client, project: project)
    }

    private func projectDetail(client: APIClient, project: Project) throws {
        while true {
            let choice = try SelectPrompt.run(
                prompt: project.name,
                choices: [
                    Choice(label: "Screens", value: "screens", description: project.numberOfScreens.map { "\($0)" }),
                    Choice(label: "Components", value: "components", description: project.numberOfComponents.map { "\($0)" }),
                    Choice(label: "Colors", value: "colors", description: project.numberOfColors.map { "\($0)" }),
                    Choice(label: "Text Styles", value: "text-styles", description: project.numberOfTextStyles.map { "\($0)" }),
                    Choice(label: "Spacing Tokens", value: "spacing"),
                    Choice(label: "Members", value: "members"),
                    Choice(label: "Back", value: "back")
                ]
            )

            let formatter = OutputFormatter(format: .table, noColor: options.noColor)

            do {
                switch choice.value {
                case "screens":
                    var screens = try runAsync {
                        try await client.listAllScreens(projectId: project.id)
                    }
                    if screens.isEmpty {
                        print("No screens found.")
                    } else {
                        let sortChoice = try SelectPrompt.run(
                            prompt: "Sort by",
                            choices: [
                                Choice(label: "Name", value: "name"),
                                Choice(label: "Newest", value: "newest"),
                                Choice(label: "Recently Updated", value: "updated"),
                            ]
                        )
                        switch sortChoice.value {
                        case "name":
                            screens.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                        case "newest":
                            screens.sort { ($0.created ?? 0) > ($1.created ?? 0) }
                        case "updated":
                            screens.sort { ($0.updated ?? 0) > ($1.updated ?? 0) }
                        default: break
                        }
                        let choices = screens.map {
                            Choice(label: $0.name, value: $0.id, description: $0.section?.name)
                        }
                        let selected = try SelectPrompt.run(prompt: "Select screen", choices: choices)
                        if let screen = screens.first(where: { $0.id == selected.value }) {
                            try screenDetail(client: client, projectId: project.id, screen: screen)
                        }
                    }
                case "components":
                    let components = try runAsync {
                        try await client.listAllProjectComponents(projectId: project.id)
                    }
                    if components.isEmpty { print("No components found.") }
                    else { print(try formatter.format(components)) }
                case "colors":
                    let colors = try runAsync {
                        try await client.listAllProjectColors(projectId: project.id)
                    }
                    if colors.isEmpty { print("No colors found.") }
                    else { print(try formatter.format(colors)) }
                case "text-styles":
                    let styles = try runAsync {
                        try await client.listAllProjectTextStyles(projectId: project.id)
                    }
                    if styles.isEmpty { print("No text styles found.") }
                    else { print(try formatter.format(styles)) }
                case "spacing":
                    let tokens = try runAsync {
                        try await client.listAllProjectSpacingTokens(projectId: project.id)
                    }
                    if tokens.isEmpty { print("No spacing tokens found.") }
                    else { print(try formatter.format(tokens)) }
                case "members":
                    let members = try runAsync {
                        try await client.listAllProjectMembers(projectId: project.id)
                    }
                    if members.isEmpty { print("No members found.") }
                    else { print(try formatter.format(members)) }
                case "back":
                    return
                default:
                    break
                }
            } catch let error as CLIError {
                printError(error.localizedDescription)
            }
        }
    }

    private func screenDetail(client: APIClient, projectId: String, screen: Screen) throws {
        while true {
            var choices = [
                Choice(label: "Details", value: "details"),
                Choice(label: "Versions", value: "versions", description: screen.numberOfVersions.map { "\($0)" }),
            ]
            if screen.image?.originalUrl != nil {
                choices.append(Choice(label: "Open Image", value: "open-image"))
            }
            choices.append(Choice(label: "Back", value: "back"))

            let choice = try SelectPrompt.run(prompt: screen.name, choices: choices)
            let formatter = OutputFormatter(format: .table, noColor: options.noColor)

            do {
                switch choice.value {
                case "details":
                    let detail = try runAsync {
                        try await client.getScreen(projectId: projectId, screenId: screen.id)
                    }
                    print(try formatter.format(detail))
                    if let desc = detail.description, !desc.isEmpty {
                        print("\nDescription: \(desc)")
                    }
                    if let image = detail.image {
                        if let w = image.width, let h = image.height {
                            print("Dimensions: \(w) × \(h)")
                        }
                    }
                case "versions":
                    let versions = try runAsync {
                        try await client.listAllScreenVersions(projectId: projectId, screenId: screen.id)
                    }
                    if versions.isEmpty { print("No versions found.") }
                    else { print(try formatter.format(versions)) }
                case "open-image":
                    if let url = screen.image?.originalUrl {
                        print("Image URL:\n\(url)")
                    }
                case "back":
                    return
                default:
                    break
                }
            } catch let error as CLIError {
                printError(error.localizedDescription)
            }
        }
    }

    private func styleguidesMenu(client: APIClient) throws {
        let styleguides = try runAsync { try await client.listAllStyleguides() }

        guard !styleguides.isEmpty else {
            print("No styleguides found.")
            return
        }

        let choices = styleguides.map {
            Choice(label: $0.name, value: $0.id, description: $0.platform)
        }
        let choice = try SelectPrompt.run(prompt: "Select styleguide", choices: choices)

        guard let sg = styleguides.first(where: { $0.id == choice.value }) else { return }
        try styleguideDetail(client: client, styleguide: sg)
    }

    private func styleguideDetail(client: APIClient, styleguide: Styleguide) throws {
        while true {
            let choice = try SelectPrompt.run(
                prompt: styleguide.name,
                choices: [
                    Choice(label: "Components", value: "components"),
                    Choice(label: "Colors", value: "colors"),
                    Choice(label: "Text Styles", value: "text-styles"),
                    Choice(label: "Spacing Tokens", value: "spacing"),
                    Choice(label: "Back", value: "back")
                ]
            )

            let formatter = OutputFormatter(format: .table, noColor: options.noColor)

            do {
                switch choice.value {
                case "components":
                    let components = try runAsync {
                        try await client.listAllStyleguideComponents(styleguideId: styleguide.id)
                    }
                    if components.isEmpty { print("No components found.") }
                    else { print(try formatter.format(components)) }
                case "colors":
                    let colors = try runAsync {
                        try await client.listAllStyleguideColors(styleguideId: styleguide.id)
                    }
                    if colors.isEmpty { print("No colors found.") }
                    else { print(try formatter.format(colors)) }
                case "text-styles":
                    let styles = try runAsync {
                        try await client.listAllStyleguideTextStyles(styleguideId: styleguide.id)
                    }
                    if styles.isEmpty { print("No text styles found.") }
                    else { print(try formatter.format(styles)) }
                case "spacing":
                    let tokens = try runAsync {
                        try await client.listAllStyleguideSpacingTokens(styleguideId: styleguide.id)
                    }
                    if tokens.isEmpty { print("No spacing tokens found.") }
                    else { print(try formatter.format(tokens)) }
                case "back":
                    return
                default:
                    break
                }
            } catch let error as CLIError {
                printError(error.localizedDescription)
            }
        }
    }

    private func showProfile(client: APIClient) throws {
        let user = try runAsync { try await client.getCurrentUser() }
        let formatter = OutputFormatter(format: .table, noColor: options.noColor)
        print(try formatter.format(user))
    }
}
