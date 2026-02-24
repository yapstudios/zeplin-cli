import Testing
import Foundation
@testable import ZeplinKit

private let hasCredentials: Bool = {
    let resolver = CredentialResolver()
    return (try? resolver.resolve()) != nil
}()

@Suite("Integration Tests", .enabled(if: hasCredentials, "No credentials available"))
struct IntegrationTests {
    let client: APIClient = {
        let resolver = CredentialResolver()
        let credentials = try! resolver.resolve()
        return APIClient(credentials: credentials)
    }()

    @Test func getCurrentUser() async throws {
        let user = try await client.getCurrentUser()
        #expect(!user.id.isEmpty)
    }

    @Test func listProjects() async throws {
        let projects = try await client.listProjects(limit: 5)
        #expect(projects.count >= 0)
    }

    @Test func listOrganizations() async throws {
        let orgs = try await client.listOrganizations()
        #expect(orgs.count >= 0)
    }
}
