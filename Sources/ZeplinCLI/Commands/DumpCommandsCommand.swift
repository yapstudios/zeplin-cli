import ArgumentParser
import Foundation

struct DumpCommandsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dump-commands",
        abstract: "Dump all commands as machine-readable JSON",
        shouldDisplay: false
    )

    mutating func run() throws {
        guard let executableURL = Bundle.main.executableURL else {
            throw ExitCode.failure
        }

        let process = Process()
        process.executableURL = executableURL
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
