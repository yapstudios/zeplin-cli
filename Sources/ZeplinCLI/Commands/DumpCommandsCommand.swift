import ArgumentParser
import Foundation

struct DumpCommandsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dump-commands",
        abstract: "Dump all commands as machine-readable JSON",
        shouldDisplay: false
    )

    mutating func run() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        process.arguments = ["--experimental-dump-help"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        FileHandle.standardOutput.write(data)

        throw ExitCode(process.terminationStatus)
    }
}
