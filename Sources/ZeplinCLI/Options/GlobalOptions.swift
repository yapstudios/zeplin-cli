import ArgumentParser
import ZeplinKit

struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: "Use named auth profile")
    var profile: String?

    @Option(name: .long, help: "Personal access token")
    var token: String?

    @Option(name: .long, help: "Default organization ID")
    var organization: String?

    @Option(name: [.customShort("o"), .long], help: "Output format: json, table, csv")
    var output: OutputFormat = .json

    @Flag(name: .long, help: "Pretty-print JSON output")
    var pretty: Bool = false

    @Flag(name: .long, help: "Disable colored output")
    var noColor: Bool = false

    @Flag(name: [.customShort("v"), .customLong("verbose")], help: "Enable verbose output")
    var verbose: Bool = false

    @Flag(name: [.customShort("q"), .long], help: "Suppress non-essential output")
    var quiet: Bool = false

    @Flag(name: .long, help: "Skip automatic update check")
    var noUpdateCheck: Bool = false

    func credentialOptions() -> CredentialOptions {
        CredentialOptions(
            token: token,
            organizationId: organization,
            profile: profile
        )
    }

    func outputFormatter() -> OutputFormatter {
        OutputFormatter(format: output, prettyPrint: pretty, noColor: noColor)
    }

    func apiClient() throws -> APIClient {
        let resolver = CredentialResolver()
        let credentials = try resolver.resolve(options: credentialOptions())
        return APIClient(credentials: credentials)
    }

    func apiClient(profile: String) throws -> APIClient {
        var opts = credentialOptions()
        opts.profile = profile
        let resolver = CredentialResolver()
        let credentials = try resolver.resolve(options: opts)
        return APIClient(credentials: credentials)
    }
}

extension OutputFormat: ExpressibleByArgument {}
