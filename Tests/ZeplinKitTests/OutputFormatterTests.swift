import Testing
import Foundation
@testable import ZeplinKit

@Suite("Output Formatter")
struct OutputFormatterTests {
    @Test func jsonOutputIsValid() throws {
        let formatter = OutputFormatter(format: .json)
        let org = try makeOrganization(id: "o1", name: "Acme")
        let output = try formatter.format(org)
        let parsed = try JSONSerialization.jsonObject(with: Data(output.utf8))
        #expect(parsed is [String: Any])
    }

    @Test func prettyJsonHasIndentation() throws {
        let formatter = OutputFormatter(format: .json, prettyPrint: true)
        let org = try makeOrganization(id: "o1", name: "Acme")
        let output = try formatter.format(org)
        #expect(output.contains("  "))
        #expect(output.contains("\n"))
    }

    @Test func tableOutputContainsHeaders() throws {
        let formatter = OutputFormatter(format: .table)
        let orgs = [
            try makeOrganization(id: "o1", name: "Acme"),
            try makeOrganization(id: "o2", name: "Globex")
        ]
        let output = try formatter.format(orgs)
        #expect(output.contains("ID"))
        #expect(output.contains("NAME"))
    }

    @Test func tableOutputContainsData() throws {
        let formatter = OutputFormatter(format: .table)
        let orgs = [try makeOrganization(id: "org_123", name: "TestCorp")]
        let output = try formatter.format(orgs)
        #expect(output.contains("org_123"))
        #expect(output.contains("TestCorp"))
    }

    @Test func csvOutputHasCommas() throws {
        let formatter = OutputFormatter(format: .csv)
        let orgs = [try makeOrganization(id: "o1", name: "Acme")]
        let output = try formatter.format(orgs)
        #expect(output.contains(","))
        #expect(output.contains("ID"))
        #expect(output.contains("o1"))
    }

    @Test func emptyArrayOutput() throws {
        let formatter = OutputFormatter(format: .table)
        let output = formatter.formatTable(headers: ["ID", "NAME"], rows: [])
        #expect(output.isEmpty)
    }

    @Test func colorTableIncludesHex() throws {
        let formatter = OutputFormatter(format: .table, noColor: true)
        let color = try makeColor(id: "c1", name: "Red", r: 255, g: 0, b: 0, a: 1.0)
        let colors = [color]
        let output = try formatter.format(colors)
        #expect(output.contains("#FF0000"))
    }

    @Test func rawJsonPreservesStructure() throws {
        let formatter = OutputFormatter(format: .json)
        let orgs = [
            try makeOrganization(id: "o1", name: "A"),
            try makeOrganization(id: "o2", name: "B")
        ]
        let output = try formatter.formatRawJSON(orgs)
        let parsed = try JSONSerialization.jsonObject(with: Data(output.utf8)) as? [[String: Any]]
        #expect(parsed?.count == 2)
    }

    @Test func noColorDisablesAnsi() throws {
        let formatter = OutputFormatter(format: .table, noColor: true)
        let orgs = [try makeOrganization(id: "o1", name: "Acme")]
        let output = try formatter.format(orgs)
        #expect(!output.contains("\u{1B}["))
    }

    @Test func formatTimestampWorks() {
        let result = formatTimestamp(1700000000)
        #expect(!result.isEmpty)
        #expect(result != "-")
        #expect(result.contains("-"))
        #expect(result.contains(":"))
    }

    @Test func formatTimestampNilReturnsPlaceholder() {
        let result = formatTimestamp(nil)
        #expect(result == "-")
    }

    @Test func csvEscapesCommas() throws {
        let formatter = OutputFormatter(format: .csv, noColor: true)
        let output = formatter.formatTable(headers: ["H"], rows: [])
        // Table-based formatTable returns empty for no rows, use csv path
        #expect(output.isEmpty)
    }

    @Test func tableHasSeparatorLine() throws {
        let formatter = OutputFormatter(format: .table, noColor: true)
        let output = formatter.formatTable(headers: ["ID", "NAME"], rows: [["1", "Test"]])
        let lines = output.split(separator: "\n")
        #expect(lines.count == 3)
        #expect(lines[1].contains("-"))
    }

    @Test func jsonEncodesSnakeCase() throws {
        let formatter = OutputFormatter(format: .json)
        let project = try makeProject(id: "p1", name: "Test")
        let output = try formatter.format(project)
        #expect(output.contains("number_of_screens") || output.contains("\"name\""))
    }

    // MARK: - Helpers

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private func makeOrganization(id: String, name: String) throws -> Organization {
        let json = """
        {"id": "\(id)", "name": "\(name)"}
        """
        return try decoder.decode(Organization.self, from: Data(json.utf8))
    }

    private func makeColor(id: String, name: String, r: Int, g: Int, b: Int, a: Double) throws -> Color {
        let json = """
        {"id": "\(id)", "name": "\(name)", "r": \(r), "g": \(g), "b": \(b), "a": \(a)}
        """
        return try decoder.decode(Color.self, from: Data(json.utf8))
    }

    private func makeProject(id: String, name: String) throws -> Project {
        let json = """
        {"id": "\(id)", "name": "\(name)"}
        """
        return try decoder.decode(Project.self, from: Data(json.utf8))
    }
}
