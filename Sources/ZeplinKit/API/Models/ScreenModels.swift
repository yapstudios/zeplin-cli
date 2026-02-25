import Foundation

public struct Screen: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let tags: [String]?
    public let image: ScreenImage?
    public let updated: Int?
    public let created: Int?
    public let numberOfVersions: Int?
    public let numberOfNotes: Int?
    public let section: ScreenSectionRef?
}

public struct ScreenImage: Codable, Sendable {
    public let width: Int?
    public let height: Int?
    public let originalUrl: String?
    public let thumbnails: ScreenImageThumbnails?
}

public struct ScreenImageThumbnails: Codable, Sendable {
    public let small: String?
    public let medium: String?
    public let large: String?
}

public struct ScreenSectionRef: Codable, Sendable {
    public let id: String
    public let name: String?
}

public struct ScreenSection: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
}

public struct ScreenVersion: Codable, Sendable, Identifiable {
    public let id: String
    public let commit: VersionCommit?
    public let source: String?
    public let imageUrl: String?
    public let width: Int?
    public let height: Int?
    public let created: Int?
}

public struct VersionCommit: Codable, Sendable {
    public let message: String?
    public let author: String?
}

public struct ScreenNote: Codable, Sendable, Identifiable {
    public let id: String
    public let order: String?
    public let status: String?
    public let position: ScreenNotePosition?
    public let color: ScreenNoteColor?
    public let comments: [ScreenNoteComment]?
    public let created: Int?
    public let creator: User?
}

public struct ScreenNotePosition: Codable, Sendable {
    public let x: Double?
    public let y: Double?
    public let xStart: Double?
    public let yStart: Double?
}

public struct ScreenNoteColor: Codable, Sendable {
    public let name: String?
    public let r: Int?
    public let g: Int?
    public let b: Int?
    public let a: Double?
}

public struct ScreenNoteComment: Codable, Sendable, Identifiable {
    public let id: String
    public let content: String?
    public let author: User?
    public let updated: Int?
    public let reactions: [Reaction]?
    public let screenVersionId: String?
}

public struct Reaction: Codable, Sendable, Identifiable {
    public let id: String
    public let shortCode: String?
    public let unicode: String?
    public let users: [User]?
}

public struct ScreenAnnotation: Codable, Sendable, Identifiable {
    public let id: String
    public let content: String?
    public let noteType: ScreenAnnotationNoteType?
    public let position: AnnotationPosition?
    public let created: Int?
    public let updated: Int?
}

public struct AnnotationPosition: Codable, Sendable {
    public let x: Double?
    public let y: Double?
}

public struct ScreenAnnotationNoteType: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let color: String?
}

public struct ScreenVariantGroupValue: Codable, Sendable {
    public let screenId: String
    public let value: String
}

public struct ScreenVariantGroup: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let variants: [ScreenVariantGroupValue]
}
