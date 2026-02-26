import Testing
import Foundation
@testable import ZeplinCLI

@Suite("Update Checker")
struct UpdateCheckerTests {

    // MARK: - Version comparison

    @Test func newerMajor() {
        #expect(UpdateChecker.isNewer("1.0.0", than: "0.4.0") == true)
    }

    @Test func newerMinor() {
        #expect(UpdateChecker.isNewer("0.5.0", than: "0.4.0") == true)
    }

    @Test func newerPatch() {
        #expect(UpdateChecker.isNewer("0.4.1", than: "0.4.0") == true)
    }

    @Test func sameVersion() {
        #expect(UpdateChecker.isNewer("0.4.0", than: "0.4.0") == false)
    }

    @Test func olderVersion() {
        #expect(UpdateChecker.isNewer("0.3.0", than: "0.4.0") == false)
    }

    @Test func numericNotLexicographic() {
        #expect(UpdateChecker.isNewer("0.10.0", than: "0.9.0") == true)
    }

    @Test func twoComponentVersions() {
        #expect(UpdateChecker.isNewer("1.1", than: "1.0") == true)
        #expect(UpdateChecker.isNewer("1.0", than: "1.0") == false)
    }

    @Test func mismatchedComponentCounts() {
        #expect(UpdateChecker.isNewer("1.0.1", than: "1.0") == true)
        #expect(UpdateChecker.isNewer("1.0.0", than: "1.0") == false)
    }

    // MARK: - Cache round-trip

    @Test func cacheEncodeDecode() throws {
        let cache = UpdateChecker.Cache(
            lastCheck: 1740000000,
            latestVersion: "0.5.0",
            ignoredVersion: "0.5.0"
        )
        let data = try JSONEncoder().encode(cache)
        let decoded = try JSONDecoder().decode(UpdateChecker.Cache.self, from: data)
        #expect(decoded.lastCheck == 1740000000)
        #expect(decoded.latestVersion == "0.5.0")
        #expect(decoded.ignoredVersion == "0.5.0")
    }

    @Test func cacheEncodeDecodeNilIgnored() throws {
        let cache = UpdateChecker.Cache(
            lastCheck: 1740000000,
            latestVersion: "0.5.0",
            ignoredVersion: nil
        )
        let data = try JSONEncoder().encode(cache)
        let decoded = try JSONDecoder().decode(UpdateChecker.Cache.self, from: data)
        #expect(decoded.ignoredVersion == nil)
    }
}
