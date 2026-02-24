import ArgumentParser
import Foundation
import ZeplinKit

struct UserCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user",
        abstract: "Show current user info"
    )

    @OptionGroup var options: GlobalOptions

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let verbose = options.verbose

        do {
            printVerbose("Fetching current user...", verbose: verbose)
            let user = try runAsync {
                try await client.getCurrentUser()
            }

            let formatter = options.outputFormatter()

            if options.output == .json {
                let output = try formatter.formatRawJSON(user)
                print(output)
            } else {
                let output = try formatter.format(user)
                print(output)
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
