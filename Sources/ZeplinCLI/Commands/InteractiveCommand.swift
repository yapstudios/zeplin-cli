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

    private func select(prompt: String, choices: [Choice], initialSelection: Int = 0) -> Choice? {
        do {
            return try SelectPrompt.run(prompt: prompt, choices: choices, initialSelection: initialSelection)
        } catch is SelectPromptError {
            return nil
        } catch {
            return nil
        }
    }

    mutating func run() throws {
        guard TerminalUI.isInteractiveTerminal else {
            printError("Interactive mode requires a terminal. Use direct commands instead.")
            printError("Run 'zeplin-cli --help' for available commands.")
            throw ExitCode.failure
        }

        var activeProfile: String? = options.profile

        var client: APIClient
        do {
            client = try options.apiClient()
            if activeProfile == nil {
                activeProfile = resolveActiveProfileName()
            }
        } catch is CLIError {
            printBanner()

            let choice: Choice
            do {
                choice = try SelectPrompt.run(
                    prompt: "No credentials configured. Set up now?",
                    choices: [
                        Choice(label: "Set up credentials", value: "setup"),
                        Choice(label: "Exit", value: "exit"),
                    ]
                )
            } catch is SelectPromptError {
                return
            }

            guard choice.value == "setup" else { return }

            try runAuthInit()

            do {
                client = try options.apiClient()
                activeProfile = resolveActiveProfileName()
            } catch let error as CLIError {
                printError(error.localizedDescription)
                throw ExitCode(rawValue: error.exitCode)
            }
        }

        while true {
            printBanner()

            let switchTo = try mainMenu(client: client, activeProfile: activeProfile)

            guard let newProfile = switchTo else { return }

            do {
                client = try options.apiClient(profile: newProfile)
                activeProfile = newProfile
            } catch let error as CLIError {
                printError(error.localizedDescription)
            }
        }
    }

    private func printBanner() {
        print(TerminalUI.bold("Zeplin CLI") + " " + TerminalUI.dim("v\(Zeplin.configuration.version)"))
        print(TerminalUI.dim("Tip: Run 'zeplin-cli --help' for non-interactive commands."))
        print(TerminalUI.dim("Docs: https://github.com/yapstudios/zeplin-cli"))
        print("")
    }

    private func resolveActiveProfileName() -> String? {
        let resolver = CredentialResolver()
        if let config = try? resolver.loadConfig(from: CredentialResolver.localConfigPath) {
            return config.defaultProfile
        }
        if let config = try? resolver.loadConfig(from: CredentialResolver.globalConfigPath) {
            return config.defaultProfile
        }
        return nil
    }

    private func hasMultipleProfiles() -> Bool {
        let resolver = CredentialResolver()
        let localCount = (try? resolver.loadConfig(from: CredentialResolver.localConfigPath))?.profiles.count ?? 0
        let globalCount = (try? resolver.loadConfig(from: CredentialResolver.globalConfigPath))?.profiles.count ?? 0
        return (localCount + globalCount) > 1
    }

    private func runAuthInit(profile: String = "default") throws {
        var initCmd = try AuthInitCommand.parseAsRoot(["--profile", profile]) as! AuthInitCommand
        do {
            try initCmd.run()
        } catch is ExitCode {
            // Don't let auth init failures exit interactive mode
        }
        print("")
    }

    /// Returns a profile name to switch to, or nil to exit
    private func mainMenu(client: APIClient, activeProfile: String?) throws -> String? {
        var lastSelection = 0
        while true {
            let profileName = activeProfile ?? "default"

            let choices = [
                Choice(label: "Organizations", value: "organizations", description: "- Browse organizations"),
                Choice(label: "Projects", value: "projects", description: "- Browse all projects"),
                Choice(label: "Styleguides", value: "styleguides", description: "- Browse styleguides"),
                Choice(label: "My Profile", value: "profile", description: "- View current user"),
                Choice(label: "Auth", value: "auth", description: "- Profiles, credentials"),
                Choice(label: "Exit", value: "exit"),
            ]

            let choice: Choice
            do {
                choice = try SelectPrompt.run(
                    prompt: "What would you like to do? (profile: \(profileName))",
                    choices: choices,
                    initialSelection: lastSelection
                )
            } catch is SelectPromptError {
                return nil
            }

            lastSelection = choices.firstIndex(where: { $0.value == choice.value }) ?? 0

            switch choice.value {
            case "organizations":
                try organizationsMenu(client: client)
            case "projects":
                try projectsMenu(client: client)
            case "styleguides":
                try styleguidesMenu(client: client)
            case "profile":
                try showProfile(client: client)
            case "auth":
                if let switchTo = try authMenu(client: client, activeProfile: activeProfile) {
                    return switchTo
                }
            case "exit":
                return nil
            default:
                break
            }
        }
    }

    /// Returns a profile name to switch to, or nil to stay
    private func authMenu(client: APIClient, activeProfile: String?) throws -> String? {
        var lastSelection = 0
        while true {
            var choices = [
                Choice(label: "Check credentials", value: "check"),
            ]

            let resolver = CredentialResolver()
            let localConfig = try? resolver.loadConfig(from: CredentialResolver.localConfigPath)
            let globalConfig = try? resolver.loadConfig(from: CredentialResolver.globalConfigPath)
            let allProfiles = (localConfig?.profiles ?? [:]).merging(globalConfig?.profiles ?? [:]) { local, _ in local }

            if allProfiles.count > 1 {
                choices.insert(Choice(label: "Switch profile", value: "switch", description: "- Current: \(activeProfile ?? "default")"), at: 0)
            }
            choices.append(Choice(label: "Add profile", value: "add"))
            choices.append(Choice(label: "Back", value: "back"))

            guard let choice = select(prompt: "Auth", choices: choices, initialSelection: lastSelection) else { return nil }
            lastSelection = choices.firstIndex(where: { $0.value == choice.value }) ?? 0

            switch choice.value {
            case "switch":
                let profileNames = allProfiles.keys.sorted()
                let profileChoices = profileNames.map { name in
                    let marker = name == activeProfile ? " *" : ""
                    return Choice(label: "\(name)\(marker)", value: name)
                }
                if let selected = select(prompt: "Switch to profile", choices: profileChoices) {
                    return selected.value
                }
            case "check":
                do {
                    let user = try runAsync { try await client.getCurrentUser() }
                    print("Credentials are valid")
                    print("  Username: \(user.username ?? "-")")
                    print("  Email: \(user.email ?? "-")")
                } catch let error as CLIError {
                    printError(error.localizedDescription)
                }
            case "add":
                print("Profile name:")
                print("> ", terminator: "")
                if let name = readLine()?.trimmingCharacters(in: .whitespaces), !name.isEmpty {
                    try runAuthInit(profile: name)
                }
            case "back":
                return nil
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
        guard let choice = select(prompt: "Select organization", choices: choices) else { return }
        guard let org = orgs.first(where: { $0.id == choice.value }) else { return }
        try organizationDetail(client: client, org: org)
    }

    private func organizationDetail(client: APIClient, org: Organization) throws {
        var lastSelection = 0
        while true {
            let choices = [
                Choice(label: "Projects", value: "projects"),
                Choice(label: "Styleguides", value: "styleguides"),
                Choice(label: "Workflow Statuses", value: "workflow-statuses"),
                Choice(label: "Back", value: "back")
            ]
            guard let choice = select(prompt: org.name, choices: choices, initialSelection: lastSelection) else { return }
            lastSelection = choices.firstIndex(where: { $0.value == choice.value }) ?? 0

            let formatter = OutputFormatter(format: .table, noColor: options.noColor)

            switch choice.value {
            case "projects":
                do {
                    let projects = try runAsync {
                        try await client.listAllProjects(organizationId: org.id)
                    }
                    if projects.isEmpty {
                        print("No projects found.")
                    } else {
                        let projectChoices = projects.map {
                            Choice(label: $0.name, value: $0.id, description: $0.platform)
                        }
                        var projectSelection = 0
                        while let selected = select(prompt: "Select project", choices: projectChoices, initialSelection: projectSelection),
                              let project = projects.first(where: { $0.id == selected.value }) {
                            projectSelection = projectChoices.firstIndex(where: { $0.value == selected.value }) ?? 0
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
                        let sgChoices = styleguides.map {
                            Choice(label: $0.name, value: $0.id, description: $0.platform)
                        }
                        var sgSelection = 0
                        while let selected = select(prompt: "Select styleguide", choices: sgChoices, initialSelection: sgSelection),
                              let sg = styleguides.first(where: { $0.id == selected.value }) {
                            sgSelection = sgChoices.firstIndex(where: { $0.value == selected.value }) ?? 0
                            try styleguideDetail(client: client, styleguide: sg)
                        }
                    }
                } catch let error as CLIError {
                    printError(error.localizedDescription)
                }
            case "workflow-statuses":
                do {
                    let statuses = try runAsync {
                        try await client.listOrganizationWorkflowStatuses(organizationId: org.id)
                    }
                    if statuses.isEmpty { print("No workflow statuses found.") }
                    else { print(try formatter.format(statuses)) }
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

        let projectChoices = projects.map {
            Choice(label: $0.name, value: $0.id, description: $0.platform)
        }
        var projectSelection = 0
        while let selected = select(prompt: "Select project", choices: projectChoices, initialSelection: projectSelection),
              let project = projects.first(where: { $0.id == selected.value }) {
            projectSelection = projectChoices.firstIndex(where: { $0.value == selected.value }) ?? 0
            try projectDetail(client: client, project: project)
        }
    }

    private func projectDetail(client: APIClient, project: Project) throws {
        var lastSelection = 0
        while true {
            let choices = [
                // Screens
                Choice(label: "Screens", value: "screens", description: project.numberOfScreens.map { "\($0)" }),
                Choice(label: "Pages", value: "pages"),
                Choice(label: "Screen Variants", value: "screen-variants"),
                Choice(label: "Flow Boards", value: "flow-boards"),
                // Design tokens
                Choice(label: "Colors", value: "colors", description: project.numberOfColors.map { "\($0)" }),
                Choice(label: "Text Styles", value: "text-styles", description: project.numberOfTextStyles.map { "\($0)" }),
                Choice(label: "Spacing Tokens", value: "spacing", description: project.numberOfSpacingTokens.map { "\($0)" }),
                Choice(label: "Variable Collections", value: "variables"),
                // Components
                Choice(label: "Components", value: "components", description: project.numberOfComponents.map { "\($0)" }),
                Choice(label: "Connected Components", value: "connected-components", description: project.numberOfConnectedComponents.map { "\($0)" }),
                Choice(label: "Component Sections", value: "component-sections"),
                // Team
                Choice(label: "Members", value: "members", description: project.numberOfMembers.map { "\($0)" }),
                Choice(label: "Back", value: "back")
            ]
            guard let choice = select(prompt: project.name, choices: choices, initialSelection: lastSelection) else { return }
            lastSelection = choices.firstIndex(where: { $0.value == choice.value }) ?? 0

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
                        let sortOptions = [
                            Choice(label: "Recently Modified", value: "modified"),
                            Choice(label: "Recently Created", value: "created"),
                            Choice(label: "Name A\u{2192}Z", value: "name"),
                        ]
                        let applySort = { (sortValue: String) in
                            switch sortValue {
                            case "modified":
                                screens.sort { ($0.updated ?? 0) > ($1.updated ?? 0) }
                            case "created":
                                screens.sort { ($0.created ?? 0) > ($1.created ?? 0) }
                            case "name":
                                screens.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                            default: break
                            }
                        }
                        let screenCount = screens.count
                        let promptLabel = "\(project.name) (\(screenCount))"
                        var screenSelection = 0
                        var activeSortIndex = 0
                        applySort(sortOptions[activeSortIndex].value)
                        var screenChoices = screens.map {
                            Choice(label: $0.name, value: $0.id, description: $0.section?.name)
                        }
                        while true {
                            let result: (choice: Choice, sortIndex: Int)
                            do {
                                result = try SelectPrompt.run(
                                    prompt: promptLabel,
                                    choices: screenChoices,
                                    sortOptions: sortOptions,
                                    initialSort: activeSortIndex,
                                    resort: { sortValue, choices in
                                        applySort(sortValue)
                                        choices = screens.map {
                                            Choice(label: $0.name, value: $0.id, description: $0.section?.name)
                                        }
                                    },
                                    initialSelection: screenSelection
                                )
                            } catch is SelectPromptError {
                                break
                            }
                            activeSortIndex = result.sortIndex
                            let selectedId = result.choice.value
                            guard let screen = screens.first(where: { $0.id == selectedId }) else { break }
                            try screenDetail(client: client, projectId: project.id, screen: screen)
                            applySort(sortOptions[activeSortIndex].value)
                            screenChoices = screens.map {
                                Choice(label: $0.name, value: $0.id, description: $0.section?.name)
                            }
                            screenSelection = screenChoices.firstIndex(where: { $0.value == selectedId }) ?? 0
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
                case "flow-boards":
                    let boards = try runAsync {
                        try await client.listAllFlowBoards(projectId: project.id)
                    }
                    if boards.isEmpty { print("No flow boards found.") }
                    else { print(try formatter.format(boards)) }
                case "screen-variants":
                    let variants = try runAsync {
                        try await client.listAllScreenVariants(projectId: project.id)
                    }
                    if variants.isEmpty { print("No screen variants found.") }
                    else { print(try formatter.format(variants)) }
                case "connected-components":
                    let connected = try runAsync {
                        try await client.listAllProjectConnectedComponents(projectId: project.id)
                    }
                    if connected.isEmpty { print("No connected components found.") }
                    else { print(try formatter.format(connected)) }
                case "component-sections":
                    let sections = try runAsync {
                        try await client.listAllProjectComponentSections(projectId: project.id)
                    }
                    if sections.isEmpty { print("No component sections found.") }
                    else { print(try formatter.format(sections)) }
                case "pages":
                    let pages = try runAsync {
                        try await client.listAllProjectPages(projectId: project.id)
                    }
                    if pages.isEmpty { print("No pages found.") }
                    else { print(try formatter.format(pages)) }
                case "variables":
                    let variables = try runAsync {
                        try await client.listAllProjectVariables(projectId: project.id)
                    }
                    if variables.isEmpty { print("No variable collections found.") }
                    else { print(try formatter.format(variables)) }
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
        var lastSelection = 0
        while true {
            var menuChoices: [Choice] = []
            if screen.image?.originalUrl != nil {
                menuChoices.append(Choice(label: "Open Image", value: "open-image"))
            }
            menuChoices.append(contentsOf: [
                Choice(label: "Details", value: "details"),
                Choice(label: "Versions", value: "versions", description: screen.numberOfVersions.map { "\($0)" }),
                Choice(label: "Notes", value: "notes", description: screen.numberOfNotes.map { "\($0)" }),
                Choice(label: "Annotations", value: "annotations"),
                Choice(label: "Components", value: "components"),
                Choice(label: "Back", value: "back"),
            ])

            guard let choice = select(prompt: screen.name, choices: menuChoices, initialSelection: lastSelection) else { return }
            lastSelection = menuChoices.firstIndex(where: { $0.value == choice.value }) ?? 0
            let formatter = OutputFormatter(format: .table, noColor: options.noColor)

            do {
                switch choice.value {
                case "details":
                    let detail = try runAsync {
                        try await client.getScreen(projectId: projectId, screenId: screen.id)
                    }
                    print(try formatter.format(detail))
                    if let desc = detail.description, !desc.isEmpty {
                        print("Description: \(desc)")
                    }
                    if let image = detail.image {
                        if let w = image.width, let h = image.height {
                            print("Dimensions: \(w) × \(h)")
                        }
                        if let url = image.originalUrl {
                            print("Image: \(url)")
                        }
                    }
                case "versions":
                    let versions = try runAsync {
                        try await client.listAllScreenVersions(projectId: projectId, screenId: screen.id)
                    }
                    if versions.isEmpty { print("No versions found.") }
                    else { print(try formatter.format(versions)) }
                case "notes":
                    let notes = try runAsync {
                        try await client.listAllScreenNotes(projectId: projectId, screenId: screen.id)
                    }
                    if notes.isEmpty { print("No notes found.") }
                    else { print(try formatter.format(notes)) }
                case "annotations":
                    let annotations = try runAsync {
                        try await client.listAllScreenAnnotations(projectId: projectId, screenId: screen.id)
                    }
                    if annotations.isEmpty { print("No annotations found.") }
                    else { print(try formatter.format(annotations)) }
                case "components":
                    let components = try runAsync {
                        try await client.listAllScreenComponents(projectId: projectId, screenId: screen.id)
                    }
                    if components.isEmpty { print("No components found.") }
                    else { print(try formatter.format(components)) }
                case "open-image":
                    if let url = screen.image?.originalUrl {
                        let process = Process()
                        #if os(macOS)
                        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                        #elseif os(Linux)
                        process.executableURL = URL(fileURLWithPath: "/usr/bin/xdg-open")
                        #endif
                        process.arguments = [url]
                        try process.run()
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

        let sgChoices = styleguides.map {
            Choice(label: $0.name, value: $0.id, description: $0.platform)
        }
        var sgSelection = 0
        while let selected = select(prompt: "Select styleguide", choices: sgChoices, initialSelection: sgSelection),
              let sg = styleguides.first(where: { $0.id == selected.value }) {
            sgSelection = sgChoices.firstIndex(where: { $0.value == selected.value }) ?? 0
            try styleguideDetail(client: client, styleguide: sg)
        }
    }

    private func styleguideDetail(client: APIClient, styleguide: Styleguide) throws {
        var lastSelection = 0
        while true {
            let choices = [
                Choice(label: "Components", value: "components"),
                Choice(label: "Colors", value: "colors"),
                Choice(label: "Text Styles", value: "text-styles"),
                Choice(label: "Spacing Tokens", value: "spacing"),
                Choice(label: "Connected Components", value: "connected-components"),
                Choice(label: "Component Sections", value: "component-sections"),
                Choice(label: "Pages", value: "pages"),
                Choice(label: "Variable Collections", value: "variables"),
                Choice(label: "Linked Projects", value: "linked-projects"),
                Choice(label: "Back", value: "back")
            ]
            guard let choice = select(prompt: styleguide.name, choices: choices, initialSelection: lastSelection) else { return }
            lastSelection = choices.firstIndex(where: { $0.value == choice.value }) ?? 0

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
                case "connected-components":
                    let connected = try runAsync {
                        try await client.listAllStyleguideConnectedComponents(styleguideId: styleguide.id)
                    }
                    if connected.isEmpty { print("No connected components found.") }
                    else { print(try formatter.format(connected)) }
                case "component-sections":
                    let sections = try runAsync {
                        try await client.listAllStyleguideComponentSections(styleguideId: styleguide.id)
                    }
                    if sections.isEmpty { print("No component sections found.") }
                    else { print(try formatter.format(sections)) }
                case "pages":
                    let pages = try runAsync {
                        try await client.listAllStyleguidePages(styleguideId: styleguide.id)
                    }
                    if pages.isEmpty { print("No pages found.") }
                    else { print(try formatter.format(pages)) }
                case "variables":
                    let variables = try runAsync {
                        try await client.listAllStyleguideVariables(styleguideId: styleguide.id)
                    }
                    if variables.isEmpty { print("No variable collections found.") }
                    else { print(try formatter.format(variables)) }
                case "linked-projects":
                    let projects = try runAsync {
                        try await client.listAllStyleguideLinkedProjects(styleguideId: styleguide.id)
                    }
                    if projects.isEmpty { print("No linked projects found.") }
                    else { print(try formatter.format(projects)) }
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
