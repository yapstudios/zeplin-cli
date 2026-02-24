import ArgumentParser
import Foundation
import ZeplinKit

struct DesignTokensCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "design-tokens",
        abstract: "Get design tokens",
        discussion: """
            Returns design tokens as a JSON structure containing colors,
            text styles, and spacing tokens in a standardized format.

            EXAMPLES
              Get project design tokens:
                $ zeplin design-tokens get --project <id>

              Get styleguide design tokens:
                $ zeplin design-tokens get --styleguide <id> --pretty
            """,
        subcommands: [
            DesignTokensGetCommand.self
        ]
    )
}

struct DesignTokensGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get design tokens"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    mutating func run() throws {
        guard project != nil || styleguide != nil else {
            printError("Either --project or --styleguide is required")
            throw ExitCode.failure
        }

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let projectId = project
        let styleguideId = styleguide

        do {
            printVerbose("Fetching design tokens...", verbose: options.verbose)
            let data: Data = try runAsync {
                if let pid = projectId {
                    return try await client.getProjectDesignTokens(projectId: pid)
                } else {
                    return try await client.getStyleguideDesignTokens(styleguideId: styleguideId!)
                }
            }

            if options.pretty {
                if let json = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                   let output = String(data: prettyData, encoding: .utf8) {
                    print(output)
                    return
                }
            }

            if let output = String(data: data, encoding: .utf8) {
                print(output)
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
