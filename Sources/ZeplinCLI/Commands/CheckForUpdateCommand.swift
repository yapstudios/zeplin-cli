import ArgumentParser

struct CheckForUpdateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check-for-update",
        abstract: "Check for a newer version of zeplin-cli"
    )

    @Flag(name: .long, help: "Dismiss the update notice for the current latest version")
    var ignore: Bool = false

    mutating func run() {
        if ignore {
            print(UpdateChecker.ignoreLatest())
        } else {
            print(UpdateChecker.forceCheck())
        }
    }
}
