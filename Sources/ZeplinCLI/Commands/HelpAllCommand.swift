import ArgumentParser

struct HelpAllCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "help-all",
        abstract: "Show all commands and subcommands",
        shouldDisplay: false
    )

    mutating func run() {
        let rootName = Zeplin.configuration.commandName ?? "zeplin-cli"
        print("\(rootName) - \(Zeplin.configuration.abstract)\n")
        print("COMMANDS:")

        let columnWidth = 38

        for sub in Zeplin.configuration.subcommands {
            let config = sub.configuration
            guard config.shouldDisplay else { continue }

            let name = config.commandName ?? String(describing: sub)
            printRow(indent: 2, name: name, abstract: config.abstract, columnWidth: columnWidth)

            for leaf in config.subcommands {
                let leafConfig = leaf.configuration
                guard leafConfig.shouldDisplay else { continue }
                let leafName = leafConfig.commandName ?? String(describing: leaf)
                printRow(indent: 4, name: "\(name) \(leafName)", abstract: leafConfig.abstract, columnWidth: columnWidth)
            }
        }
    }

    private func printRow(indent: Int, name: String, abstract: String, columnWidth: Int) {
        let prefix = String(repeating: " ", count: indent) + name
        let padding = max(2, columnWidth - prefix.count)
        print("\(prefix)\(String(repeating: " ", count: padding))\(abstract)")
    }
}
