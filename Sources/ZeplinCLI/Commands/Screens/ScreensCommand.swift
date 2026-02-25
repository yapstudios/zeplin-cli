import ArgumentParser
import Foundation
import ZeplinKit

struct ScreensCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screens",
        abstract: "Manage screens",
        discussion: """
            EXAMPLES
              List screens in a project:
                $ zeplin-cli screens list <project-id> -o table

              Filter by section:
                $ zeplin-cli screens list <project-id> --section <section-id>

              Get screen details:
                $ zeplin-cli screens get <project-id> <screen-id>

              List screen versions:
                $ zeplin-cli screens versions <project-id> <screen-id>

              List screen notes:
                $ zeplin-cli screens notes <project-id> <screen-id>

              Download a screen image:
                $ zeplin-cli screens image <project-id> <screen-id>

              Download all screen images:
                $ zeplin-cli screens image <project-id> --all --output-dir ./images/

              Download thumbnails:
                $ zeplin-cli screens image <project-id> --all --size small --output-dir ./thumbs/
            """,
        subcommands: [
            ScreensListCommand.self,
            ScreensGetCommand.self,
            ScreensImageCommand.self,
            ScreensVersionsCommand.self,
            ScreensNotesCommand.self,
            ScreensNoteGetCommand.self,
            ScreensAnnotationsCommand.self,
            ScreensAnnotationGetCommand.self,
            ScreensAnnotationTypesCommand.self,
            ScreensComponentsCommand.self,
            ScreensVersionGetCommand.self,
            ScreensVersionLatestCommand.self,
            ScreensSectionGetCommand.self,
            ScreensVariantsCommand.self,
            ScreensVariantGetCommand.self,
        ]
    )
}

struct ScreensListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List screens in a project"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Option(name: .long, help: "Filter by section ID")
    var section: String?

    @Option(name: .long, help: "Filter by name (case-insensitive)")
    var name: String?

    @Option(name: .long, help: "Filter by tag")
    var tag: String?

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    @Flag(name: .long, help: "Fetch all pages of results")
    var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let pid = projectId
        let sectionId = section
        let nameFilter = name
        let tagFilter = tag
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching screens...", verbose: options.verbose)
            var screens: [Screen] = try runAsync {
                if fetchAll {
                    return try await client.listAllScreens(projectId: pid, sectionId: sectionId)
                }
                return try await client.listScreens(projectId: pid, sectionId: sectionId, limit: limitVal)
            }

            if !fetchAll {
                let pageSize = limitVal ?? 100
                if screens.count >= pageSize {
                    FileHandle.standardError.write(Data("Showing \(screens.count) results. Use --all to fetch all.\n".utf8))
                }
            }

            if let nameFilter {
                screens = screens.filter {
                    $0.name.localizedCaseInsensitiveContains(nameFilter)
                }
            }
            if let tagFilter {
                screens = screens.filter {
                    $0.tags?.contains(where: { $0.localizedCaseInsensitiveContains(tagFilter) }) == true
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(screens))
            } else {
                print(try formatter.format(screens))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensImageCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "image",
        abstract: "Download screen images"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Argument(help: "Screen ID (for single screen download)")
    var screenId: String?

    @Option(name: .customLong("output-dir"), help: "Output directory (default: current directory)")
    var outputDir: String?

    @Flag(name: .long, help: "Download all screens")
    var all: Bool = false

    @Option(name: .long, help: "Filter by name (case-insensitive)")
    var name: String?

    @Option(name: .long, help: "Image size: original, large (1024px), medium (512px), small (256px)")
    var size: ImageSize = .original

    mutating func run() throws {
        guard screenId != nil || all else {
            printError("Provide a screen ID or use --all to download all screens")
            throw ExitCode(rawValue: 1)
        }

        let client = try createClient(options: options)
        let pid = projectId
        let sid = screenId
        let nameFilter = name
        let fetchAll = all
        let outputDir = outputDir ?? "."
        let imageSize = size

        do {
            let fm = FileManager.default
            if !fm.fileExists(atPath: outputDir) {
                try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
            }

            if let sid, !fetchAll {
                printVerbose("Fetching screen \(sid)...", verbose: options.verbose)
                let screen: Screen = try runAsync {
                    try await client.getScreen(projectId: pid, screenId: sid)
                }
                try downloadScreenImage(screen: screen, to: outputDir, size: imageSize, client: client, verbose: options.verbose)
            } else {
                printVerbose("Fetching all screens...", verbose: options.verbose)
                var screens: [Screen] = try runAsync {
                    try await client.listAllScreens(projectId: pid)
                }
                if let nameFilter {
                    screens = screens.filter {
                        $0.name.localizedCaseInsensitiveContains(nameFilter)
                    }
                }
                for screen in screens {
                    try downloadScreenImage(screen: screen, to: outputDir, size: imageSize, client: client, verbose: options.verbose)
                }
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

enum ImageSize: String, ExpressibleByArgument, CaseIterable {
    case original, large, medium, small
}

private func imageURL(for screen: Screen, size: ImageSize) -> String? {
    switch size {
    case .original:
        return screen.image?.originalUrl
    case .large:
        return screen.image?.thumbnails?.large ?? screen.image?.originalUrl
    case .medium:
        return screen.image?.thumbnails?.medium ?? screen.image?.originalUrl
    case .small:
        return screen.image?.thumbnails?.small ?? screen.image?.originalUrl
    }
}

private func sanitizeFilename(_ name: String) -> String {
    let invalid = CharacterSet(charactersIn: "/:\\")
    let parts = name.unicodeScalars.map { invalid.contains($0) ? "-" : String($0) }
    return parts.joined().replacingOccurrences(of: " ", with: "-")
}

private func downloadScreenImage(screen: Screen, to directory: String, size: ImageSize, client: APIClient, verbose: Bool) throws {
    guard let urlString = imageURL(for: screen, size: size) else {
        FileHandle.standardError.write(Data("warning: no image URL for screen '\(screen.name)'\n".utf8))
        return
    }

    printVerbose("Downloading \(screen.name)...", verbose: verbose)
    let data: Data = try runAsync {
        try await client.downloadData(from: urlString)
    }

    let ext = URL(string: urlString).flatMap { $0.pathExtension.isEmpty ? nil : $0.pathExtension } ?? "png"
    let filename = "\(sanitizeFilename(screen.name)).\(ext)"
    let path = (directory as NSString).appendingPathComponent(filename)
    try data.write(to: URL(fileURLWithPath: path))
    print(path)
}

struct ScreensGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get screen details"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Argument(help: "Screen ID")
    var screenId: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let pid = projectId
        let sid = screenId

        do {
            printVerbose("Fetching screen \(sid)...", verbose: options.verbose)
            let screen = try runAsync {
                try await client.getScreen(projectId: pid, screenId: sid)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(screen))
            } else {
                print(try formatter.format(screen))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensVersionsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "versions",
        abstract: "List screen versions"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Argument(help: "Screen ID")
    var screenId: String

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    @Flag(name: .long, help: "Fetch all pages of results")
    var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let pid = projectId
        let sid = screenId
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching screen versions...", verbose: options.verbose)
            let versions: [ScreenVersion] = try runAsync {
                if fetchAll {
                    return try await client.listAllScreenVersions(projectId: pid, screenId: sid)
                }
                return try await client.listScreenVersions(projectId: pid, screenId: sid, limit: limitVal)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(versions))
            } else {
                print(try formatter.format(versions))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensNotesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notes",
        abstract: "List screen notes"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Screen ID") var screenId: String
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, sid = screenId, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching screen notes...", verbose: options.verbose)
            let notes: [ScreenNote] = try runAsync {
                if fetchAll { return try await client.listAllScreenNotes(projectId: pid, screenId: sid) }
                return try await client.listScreenNotes(projectId: pid, screenId: sid, limit: limitVal)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(notes)) }
            else { print(try formatter.format(notes)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensNoteGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "note",
        abstract: "Get a screen note"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Screen ID") var screenId: String
    @Argument(help: "Note ID") var noteId: String

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, sid = screenId, nid = noteId

        do {
            printVerbose("Fetching note \(nid)...", verbose: options.verbose)
            let note = try runAsync {
                try await client.getScreenNote(projectId: pid, screenId: sid, noteId: nid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(note)) }
            else { print(try formatter.format(note)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensAnnotationsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "annotations",
        abstract: "List screen annotations"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Screen ID") var screenId: String
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, sid = screenId, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching screen annotations...", verbose: options.verbose)
            let annotations: [ScreenAnnotation] = try runAsync {
                if fetchAll { return try await client.listAllScreenAnnotations(projectId: pid, screenId: sid) }
                return try await client.listScreenAnnotations(projectId: pid, screenId: sid, limit: limitVal)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(annotations)) }
            else { print(try formatter.format(annotations)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensAnnotationGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "annotation",
        abstract: "Get a screen annotation"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Screen ID") var screenId: String
    @Argument(help: "Annotation ID") var annotationId: String

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, sid = screenId, aid = annotationId

        do {
            printVerbose("Fetching annotation \(aid)...", verbose: options.verbose)
            let annotation = try runAsync {
                try await client.getScreenAnnotation(projectId: pid, screenId: sid, annotationId: aid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(annotation)) }
            else { print(try formatter.format(annotation)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensAnnotationTypesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "annotation-types",
        abstract: "List annotation note types for a project"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId

        do {
            printVerbose("Fetching annotation types...", verbose: options.verbose)
            let types: [ScreenAnnotationNoteType] = try runAsync {
                try await client.listScreenAnnotationNoteTypes(projectId: pid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(types)) }
            else { print(try formatter.format(types)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensComponentsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "components",
        abstract: "List components in a screen"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Screen ID") var screenId: String
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, sid = screenId, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching screen components...", verbose: options.verbose)
            let components: [Component] = try runAsync {
                if fetchAll { return try await client.listAllScreenComponents(projectId: pid, screenId: sid) }
                return try await client.listScreenComponents(projectId: pid, screenId: sid, limit: limitVal)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(components)) }
            else { print(try formatter.format(components)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensVersionGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Get a specific screen version"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Screen ID") var screenId: String
    @Argument(help: "Version ID") var versionId: String

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, sid = screenId, vid = versionId

        do {
            printVerbose("Fetching version \(vid)...", verbose: options.verbose)
            let version = try runAsync {
                try await client.getScreenVersion(projectId: pid, screenId: sid, versionId: vid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(version)) }
            else { print(try formatter.format(version)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensVersionLatestCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version-latest",
        abstract: "Get the latest screen version"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Screen ID") var screenId: String

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, sid = screenId

        do {
            printVerbose("Fetching latest version...", verbose: options.verbose)
            let version = try runAsync {
                try await client.getScreenLatestVersion(projectId: pid, screenId: sid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(version)) }
            else { print(try formatter.format(version)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensSectionGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "section",
        abstract: "Get a screen section"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Section ID") var sectionId: String

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, sid = sectionId

        do {
            printVerbose("Fetching section \(sid)...", verbose: options.verbose)
            let section = try runAsync {
                try await client.getScreenSection(projectId: pid, sectionId: sid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(section)) }
            else { print(try formatter.format(section)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensVariantsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "variants",
        abstract: "List screen variants in a project"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching screen variants...", verbose: options.verbose)
            let variants: [ScreenVariantGroup] = try runAsync {
                if fetchAll { return try await client.listAllScreenVariants(projectId: pid) }
                return try await client.listScreenVariants(projectId: pid, limit: limitVal)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(variants)) }
            else { print(try formatter.format(variants)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensVariantGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "variant",
        abstract: "Get a screen variant"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Variant ID") var variantId: String

    mutating func run() throws {
        let client = try createClient(options: options)
        let pid = projectId, vid = variantId

        do {
            printVerbose("Fetching variant \(vid)...", verbose: options.verbose)
            let variant = try runAsync {
                try await client.getScreenVariant(projectId: pid, variantId: vid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(variant)) }
            else { print(try formatter.format(variant)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

private func createClient(options: GlobalOptions) throws -> APIClient {
    do {
        return try options.apiClient()
    } catch let error as CLIError {
        printError(error.localizedDescription)
        throw ExitCode(rawValue: error.exitCode)
    }
}
