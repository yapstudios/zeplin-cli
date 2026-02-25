import Foundation

public enum OutputFormat: String, CaseIterable, Sendable {
    case json
    case table
    case csv
}

public protocol OutputFormattable {
    static var tableHeaders: [String] { get }
    var tableRow: [String] { get }
}

public struct OutputFormatter: Sendable {
    public let format: OutputFormat
    public let prettyPrint: Bool
    public let noColor: Bool

    public init(format: OutputFormat = .table, prettyPrint: Bool = false, noColor: Bool = false) {
        self.format = format
        self.prettyPrint = prettyPrint
        self.noColor = noColor
    }

    public func format<T: Codable & OutputFormattable>(_ item: T) throws -> String {
        switch format {
        case .json: return try formatJSON(item)
        case .table: return formatTable([item])
        case .csv: return formatCSV([item])
        }
    }

    public func format<T: Codable & OutputFormattable>(_ items: [T]) throws -> String {
        switch format {
        case .json: return try formatJSON(items)
        case .table: return formatTable(items)
        case .csv: return formatCSV(items)
        }
    }

    public func formatRawJSON<T: Codable>(_ data: T) throws -> String {
        try formatJSON(data)
    }

    public func formatTable(headers: [String], rows: [[String]]) -> String {
        guard !rows.isEmpty else { return "" }

        var widths = headers.map(\.count)
        for row in rows {
            for (i, cell) in row.enumerated() where i < widths.count {
                widths[i] = max(widths[i], cell.count)
            }
        }

        var lines = [String]()

        let headerLine = headers.enumerated().map { i, h in
            colorize(h.padding(toLength: widths[i], withPad: " ", startingAt: 0), .bold)
        }.joined(separator: "  ")
        lines.append(headerLine)

        let separator = widths.map { String(repeating: "-", count: $0) }.joined(separator: "  ")
        lines.append(separator)

        for row in rows {
            let rowLine = row.enumerated().map { i, cell in
                let w = i < widths.count ? widths[i] : cell.count
                return cell.padding(toLength: w, withPad: " ", startingAt: 0)
            }.joined(separator: "  ")
            lines.append(rowLine)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private func formatJSON<T: Codable>(_ data: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let jsonData = try encoder.encode(data)
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }

    private func formatTable<T: OutputFormattable>(_ items: [T]) -> String {
        formatTable(headers: T.tableHeaders, rows: items.map(\.tableRow))
    }

    private func formatCSV<T: OutputFormattable>(_ items: [T]) -> String {
        var lines = [String]()
        lines.append(T.tableHeaders.map(escapeCSV).joined(separator: ","))
        for item in items {
            lines.append(item.tableRow.map(escapeCSV).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    private enum ANSIColor: String {
        case bold = "1"
        case green = "32"
        case red = "31"
        case yellow = "33"
        case cyan = "36"

        static let reset = "\u{1B}[0m"
    }

    private func colorize(_ text: String, _ color: ANSIColor) -> String {
        guard !noColor else { return text }
        return "\u{1B}[\(color.rawValue)m\(text)\(ANSIColor.reset)"
    }
}

// MARK: - OutputFormattable Conformances

extension Organization: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME"] }
    public var tableRow: [String] { [id, name] }
}

extension OrganizationMember: OutputFormattable {
    public static var tableHeaders: [String] { ["USERNAME", "EMAIL", "ROLE"] }
    public var tableRow: [String] { [user?.username ?? "-", user?.email ?? "-", role ?? "-"] }
}

extension Project: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "PLATFORM", "STATUS", "SCREENS"] }
    public var tableRow: [String] {
        [id, name, platform ?? "-", status ?? "-", numberOfScreens.map(String.init) ?? "-"]
    }
}

extension ProjectMember: OutputFormattable {
    public static var tableHeaders: [String] { ["USERNAME", "EMAIL", "ROLE"] }
    public var tableRow: [String] { [user?.username ?? "-", user?.email ?? "-", role ?? "-"] }
}

extension Screen: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "SECTION", "TAGS"] }
    public var tableRow: [String] {
        [id, name, section?.name ?? "-", tags?.joined(separator: ", ") ?? "-"]
    }
}

extension ScreenVersion: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "SOURCE", "COMMIT", "CREATED"] }
    public var tableRow: [String] {
        [id, source ?? "-", commit?.message ?? "-", formatTimestamp(created)]
    }
}

extension ScreenSection: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME"] }
    public var tableRow: [String] { [id, name] }
}

extension Component: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "DESCRIPTION"] }
    public var tableRow: [String] { [id, name, description ?? "-"] }
}

extension Color: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "R", "G", "B", "A", "HEX"] }
    public var tableRow: [String] {
        let hex = String(format: "#%02X%02X%02X", r, g, b)
        return [id, name ?? "-", String(r), String(g), String(b), String(format: "%.2f", a), hex]
    }
}

extension TextStyle: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "FONT", "SIZE", "WEIGHT"] }
    public var tableRow: [String] {
        [
            id,
            name ?? "-",
            fontFamily ?? postscriptName ?? "-",
            fontSize.map { String(format: "%.0f", $0) } ?? "-",
            fontWeight.map(String.init) ?? "-",
        ]
    }
}

extension SpacingToken: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "VALUE"] }
    public var tableRow: [String] {
        [id, name ?? "-", value.map { String(format: "%.0f", $0) } ?? "-"]
    }
}

extension Styleguide: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "PLATFORM", "STATUS"] }
    public var tableRow: [String] { [id, name, platform ?? "-", status ?? "-"] }
}

extension StyleguideMember: OutputFormattable {
    public static var tableHeaders: [String] { ["USERNAME", "EMAIL", "ROLE"] }
    public var tableRow: [String] { [user?.username ?? "-", user?.email ?? "-", role ?? "-"] }
}

extension FlowBoard: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "NODES", "CONNECTORS"] }
    public var tableRow: [String] {
        [id, name, numberOfNodes.map(String.init) ?? "-", numberOfConnectors.map(String.init) ?? "-"]
    }
}

extension FlowBoardNode: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME"] }
    public var tableRow: [String] { [id, name ?? "-"] }
}

extension FlowBoardConnector: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "LABEL"] }
    public var tableRow: [String] { [id, label ?? "-"] }
}

extension Webhook: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "URL", "STATUS", "EVENTS"] }
    public var tableRow: [String] {
        [id, url ?? "-", status ?? "-", events?.joined(separator: ", ") ?? "-"]
    }
}

extension User: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "USERNAME", "EMAIL"] }
    public var tableRow: [String] { [id, username ?? "-", email ?? "-"] }
}

extension ZeplinNotification: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "TYPE", "READ", "CREATED"] }
    public var tableRow: [String] {
        [id, type ?? "-", isRead.map { $0 ? "yes" : "no" } ?? "-", formatTimestamp(created)]
    }
}

extension ScreenNote: OutputFormattable {
    public static var tableHeaders: [String] { ["ORDER", "STATUS", "COMMENT", "CREATOR", "CREATED"] }
    public var tableRow: [String] {
        let firstComment = comments?.first?.content ?? "-"
        let truncated = firstComment.count > 60 ? String(firstComment.prefix(57)) + "..." : firstComment
        return [
            order ?? "-",
            status ?? "-",
            truncated,
            creator?.username ?? "-",
            formatTimestamp(created),
        ]
    }
}

extension ScreenAnnotation: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "CONTENT", "TYPE", "CREATED"] }
    public var tableRow: [String] {
        [id, content ?? "-", noteType?.name ?? "-", formatTimestamp(created)]
    }
}

extension ScreenAnnotationNoteType: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "COLOR"] }
    public var tableRow: [String] { [id, name ?? "-", color ?? "-"] }
}

extension ScreenVariantGroup: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "VARIANTS"] }
    public var tableRow: [String] {
        [id, name, "\(variants.count)"]
    }
}

extension ConnectedComponent: OutputFormattable {
    public static var tableHeaders: [String] { ["NAME", "DESCRIPTION", "FILE PATH"] }
    public var tableRow: [String] { [name ?? "-", description ?? "-", filePath ?? "-"] }
}

extension ComponentSection: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME"] }
    public var tableRow: [String] { [id, name] }
}

extension ComponentVersion: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "COMMIT", "CREATED"] }
    public var tableRow: [String] {
        [id, commit?.message ?? "-", formatTimestamp(created)]
    }
}

extension FlowBoardGroup: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME"] }
    public var tableRow: [String] { [id, name ?? "-"] }
}

extension WorkflowStatus: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME"] }
    public var tableRow: [String] { [id, name ?? "-"] }
}

extension UserWebhook: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "URL", "STATUS", "EVENTS"] }
    public var tableRow: [String] {
        [id, url ?? "-", status ?? "-", events?.joined(separator: ", ") ?? "-"]
    }
}

extension Page: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME", "TYPE"] }
    public var tableRow: [String] { [id, name ?? "-", type ?? "-"] }
}

extension SpacingSection: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME"] }
    public var tableRow: [String] { [id, name ?? "-"] }
}

extension VariableCollection: OutputFormattable {
    public static var tableHeaders: [String] { ["ID", "NAME"] }
    public var tableRow: [String] { [id, name ?? "-"] }
}

// MARK: - Helpers

public func formatTimestamp(_ timestamp: Int?) -> String {
    guard let ts = timestamp else { return "-" }
    let date = Date(timeIntervalSince1970: TimeInterval(ts))
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.string(from: date)
}
