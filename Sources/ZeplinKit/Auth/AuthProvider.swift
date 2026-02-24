import Foundation

public actor AuthProvider {
    private let credentials: Credentials

    public init(credentials: Credentials) {
        self.credentials = credentials
    }

    public func getToken() -> String {
        credentials.token
    }

    public func getOrganizationId() -> String? {
        credentials.organizationId
    }
}
