import Testing
import Foundation
@testable import ZeplinKit

@Suite("API Models")
struct APIModelsTests {
    let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    @Test func decodesUser() throws {
        let json = """
        {"id": "abc123", "email": "user@example.com", "username": "johndoe", "emotar": "1f600", "avatar": "https://cdn.zeplin.io/avatar.png"}
        """
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        #expect(user.id == "abc123")
        #expect(user.email == "user@example.com")
        #expect(user.username == "johndoe")
        #expect(user.emotar == "1f600")
        #expect(user.avatar == "https://cdn.zeplin.io/avatar.png")
    }

    @Test func decodesOrganization() throws {
        let json = """
        {"id": "org001", "name": "Acme Corp", "logo": "https://cdn.zeplin.io/logo.png"}
        """
        let org = try decoder.decode(Organization.self, from: Data(json.utf8))
        #expect(org.id == "org001")
        #expect(org.name == "Acme Corp")
        #expect(org.logo == "https://cdn.zeplin.io/logo.png")
    }

    @Test func decodesProject() throws {
        let json = """
        {
            "id": "proj001",
            "name": "Mobile App",
            "description": "iOS app design",
            "platform": "ios",
            "status": "active",
            "thumbnail": "https://cdn.zeplin.io/thumb.png",
            "number_of_screens": 42,
            "number_of_components": 15,
            "number_of_connected_components": 3,
            "number_of_text_styles": 8,
            "number_of_colors": 12,
            "number_of_members": 10,
            "number_of_spacing_tokens": 5,
            "organization": {"id": "org001", "name": "My Org"},
            "linked_styleguide": {"id": "sg001"},
            "workflow_status": {"id": "ws001", "name": "In Progress"},
            "created": 1700000000,
            "updated": 1700100000
        }
        """
        let project = try decoder.decode(Project.self, from: Data(json.utf8))
        #expect(project.id == "proj001")
        #expect(project.name == "Mobile App")
        #expect(project.description == "iOS app design")
        #expect(project.platform == "ios")
        #expect(project.status == "active")
        #expect(project.numberOfScreens == 42)
        #expect(project.numberOfComponents == 15)
        #expect(project.numberOfConnectedComponents == 3)
        #expect(project.numberOfTextStyles == 8)
        #expect(project.numberOfColors == 12)
        #expect(project.numberOfMembers == 10)
        #expect(project.numberOfSpacingTokens == 5)
        #expect(project.organization?.id == "org001")
        #expect(project.organization?.name == "My Org")
        #expect(project.linkedStyleguide?.id == "sg001")
        #expect(project.workflowStatus?.name == "In Progress")
        #expect(project.created == 1700000000)
        #expect(project.updated == 1700100000)
    }

    @Test func decodesScreen() throws {
        let json = """
        {
            "id": "scr001",
            "name": "Login Screen",
            "description": "Main login flow",
            "tags": ["auth", "onboarding"],
            "image": {"width": 375, "height": 812, "original_url": "https://cdn.zeplin.io/screen.png"},
            "updated": 1700000000,
            "created": 1699000000,
            "number_of_versions": 3,
            "number_of_notes": 7,
            "section": {"id": "sec001", "name": "Authentication"}
        }
        """
        let screen = try decoder.decode(Screen.self, from: Data(json.utf8))
        #expect(screen.id == "scr001")
        #expect(screen.name == "Login Screen")
        #expect(screen.tags == ["auth", "onboarding"])
        #expect(screen.image?.width == 375)
        #expect(screen.image?.height == 812)
        #expect(screen.image?.originalUrl == "https://cdn.zeplin.io/screen.png")
        #expect(screen.numberOfVersions == 3)
        #expect(screen.numberOfNotes == 7)
        #expect(screen.section?.id == "sec001")
        #expect(screen.section?.name == "Authentication")
    }

    @Test func decodesScreenVersion() throws {
        let json = """
        {
            "id": "ver001",
            "commit": {"message": "Updated layout", "author": "johndoe"},
            "source": "sketch",
            "image_url": "https://cdn.zeplin.io/version.png",
            "width": 375,
            "height": 812,
            "created": 1700000000
        }
        """
        let version = try decoder.decode(ScreenVersion.self, from: Data(json.utf8))
        #expect(version.id == "ver001")
        #expect(version.commit?.message == "Updated layout")
        #expect(version.commit?.author == "johndoe")
        #expect(version.source == "sketch")
        #expect(version.imageUrl == "https://cdn.zeplin.io/version.png")
        #expect(version.width == 375)
        #expect(version.height == 812)
    }

    @Test func decodesComponent() throws {
        let json = """
        {
            "id": "comp001",
            "name": "PrimaryButton",
            "description": "Main action button",
            "image": {"width": 200, "height": 50},
            "created": 1699000000,
            "updated": 1700000000,
            "section": {"id": "sec001", "name": "Buttons"}
        }
        """
        let component = try decoder.decode(Component.self, from: Data(json.utf8))
        #expect(component.id == "comp001")
        #expect(component.name == "PrimaryButton")
        #expect(component.description == "Main action button")
        #expect(component.image?.width == 200)
        #expect(component.section?.name == "Buttons")
    }

    @Test func decodesColor() throws {
        let json = """
        {"id": "clr001", "name": "Brand Red", "r": 255, "g": 59, "b": 48, "a": 1.0, "created": 1700000000}
        """
        let color = try decoder.decode(Color.self, from: Data(json.utf8))
        #expect(color.id == "clr001")
        #expect(color.name == "Brand Red")
        #expect(color.r == 255)
        #expect(color.g == 59)
        #expect(color.b == 48)
        #expect(color.a == 1.0)
    }

    @Test func decodesTextStyle() throws {
        let json = """
        {
            "id": "ts001",
            "name": "Heading 1",
            "postscript_name": "SFProDisplay-Bold",
            "font_family": "SF Pro Display",
            "font_size": 28.0,
            "font_weight": 700,
            "font_style": "normal",
            "font_stretch": "normal",
            "line_height": 34.0,
            "letter_spacing": -0.5,
            "text_align": "left",
            "color": {"r": 0, "g": 0, "b": 0, "a": 1.0},
            "created": 1700000000
        }
        """
        let style = try decoder.decode(TextStyle.self, from: Data(json.utf8))
        #expect(style.id == "ts001")
        #expect(style.name == "Heading 1")
        #expect(style.fontFamily == "SF Pro Display")
        #expect(style.fontSize == 28.0)
        #expect(style.fontWeight == 700)
        #expect(style.lineHeight == 34.0)
        #expect(style.letterSpacing == -0.5)
        #expect(style.color?.r == 0)
        #expect(style.color?.a == 1.0)
    }

    @Test func decodesSpacingToken() throws {
        let json = """
        {"id": "sp001", "name": "spacing-md", "value": 16.0, "created": 1700000000}
        """
        let token = try decoder.decode(SpacingToken.self, from: Data(json.utf8))
        #expect(token.id == "sp001")
        #expect(token.name == "spacing-md")
        #expect(token.value == 16.0)
    }

    @Test func decodesFlowBoard() throws {
        let json = """
        {
            "id": "fb001",
            "name": "Onboarding Flow",
            "number_of_connectors": 5,
            "number_of_nodes": 8,
            "number_of_groups": 2,
            "created": 1699000000,
            "updated": 1700000000
        }
        """
        let board = try decoder.decode(FlowBoard.self, from: Data(json.utf8))
        #expect(board.id == "fb001")
        #expect(board.name == "Onboarding Flow")
        #expect(board.numberOfConnectors == 5)
        #expect(board.numberOfNodes == 8)
        #expect(board.numberOfGroups == 2)
    }

    @Test func decodesWebhook() throws {
        let json = """
        {
            "id": "wh001",
            "url": "https://example.com/hook",
            "name": "Screen Updates",
            "status": "active",
            "url_health": "healthy",
            "events": ["project.screen", "project.color"],
            "created": 1699000000,
            "updated": 1700000000
        }
        """
        let webhook = try decoder.decode(Webhook.self, from: Data(json.utf8))
        #expect(webhook.id == "wh001")
        #expect(webhook.url == "https://example.com/hook")
        #expect(webhook.status == "active")
        #expect(webhook.events == ["project.screen", "project.color"])
    }

    @Test func decodesNotification() throws {
        let json = """
        {
            "id": "notif001",
            "type": "screen_version",
            "is_read": false,
            "action": "created",
            "created": 1700000000,
            "updated": 1700100000,
            "actor": {"user": {"id": "u001", "username": "johndoe"}},
            "resource": {"id": "scr001", "type": "screen"}
        }
        """
        let notif = try decoder.decode(ZeplinNotification.self, from: Data(json.utf8))
        #expect(notif.id == "notif001")
        #expect(notif.type == "screen_version")
        #expect(notif.isRead == false)
        #expect(notif.action == "created")
        #expect(notif.actor?.user?.username == "johndoe")
        #expect(notif.resource?.type == "screen")
    }

    @Test func decodesStyleguide() throws {
        let json = """
        {
            "id": "sg001",
            "name": "Design System",
            "description": "Company-wide design system",
            "platform": "web",
            "status": "active",
            "thumbnail": "https://cdn.zeplin.io/sg.png",
            "number_of_components": 50,
            "number_of_text_styles": 12,
            "number_of_colors": 24,
            "number_of_spacing_tokens": 8,
            "created": 1699000000,
            "updated": 1700000000
        }
        """
        let sg = try decoder.decode(Styleguide.self, from: Data(json.utf8))
        #expect(sg.id == "sg001")
        #expect(sg.name == "Design System")
        #expect(sg.platform == "web")
        #expect(sg.numberOfComponents == 50)
        #expect(sg.numberOfColors == 24)
    }

    @Test func decodesErrorResponse() throws {
        let json = """
        {"message": "Not found", "detail": "Project not found", "code": "not_found"}
        """
        let err = try decoder.decode(APIErrorResponse.self, from: Data(json.utf8))
        #expect(err.message == "Not found")
        #expect(err.detail == "Project not found")
        #expect(err.code == "not_found")
    }

    @Test func decodesUserMinimalFields() throws {
        let json = """
        {"id": "abc123"}
        """
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        #expect(user.id == "abc123")
        #expect(user.email == nil)
        #expect(user.username == nil)
        #expect(user.emotar == nil)
        #expect(user.avatar == nil)
    }

    @Test func decodesProjectMinimalFields() throws {
        let json = """
        {"id": "proj001", "name": "Minimal"}
        """
        let project = try decoder.decode(Project.self, from: Data(json.utf8))
        #expect(project.id == "proj001")
        #expect(project.name == "Minimal")
        #expect(project.description == nil)
        #expect(project.platform == nil)
        #expect(project.status == nil)
        #expect(project.numberOfScreens == nil)
        #expect(project.linkedStyleguide == nil)
    }

    @Test func decodesOrganizationMember() throws {
        let json = """
        {"user": {"id": "u001", "username": "admin"}, "role": "owner", "restricted": false}
        """
        let member = try decoder.decode(OrganizationMember.self, from: Data(json.utf8))
        #expect(member.user?.username == "admin")
        #expect(member.role == "owner")
        #expect(member.restricted == false)
    }

    @Test func decodesFlowBoardNode() throws {
        let json = """
        {"id": "node001", "name": "Start", "created": 1700000000}
        """
        let node = try decoder.decode(FlowBoardNode.self, from: Data(json.utf8))
        #expect(node.id == "node001")
        #expect(node.name == "Start")
    }

    @Test func decodesFlowBoardConnector() throws {
        let json = """
        {"id": "conn001", "label": "on success", "created": 1700000000}
        """
        let connector = try decoder.decode(FlowBoardConnector.self, from: Data(json.utf8))
        #expect(connector.id == "conn001")
        #expect(connector.label == "on success")
    }

    @Test func decodesProjectMember() throws {
        let json = """
        {"user": {"id": "u001", "email": "dev@example.com"}, "role": "editor"}
        """
        let member = try decoder.decode(ProjectMember.self, from: Data(json.utf8))
        #expect(member.user?.email == "dev@example.com")
        #expect(member.role == "editor")
    }

    @Test func decodesComponentVersion() throws {
        let json = """
        {"id": "cv001", "commit": {"message": "New variant"}, "created": 1700000000}
        """
        let version = try decoder.decode(ComponentVersion.self, from: Data(json.utf8))
        #expect(version.id == "cv001")
        #expect(version.commit?.message == "New variant")
    }

    @Test func decodesWebhookCreateBody() throws {
        let body = WebhookCreateBody(url: "https://hook.example.com", events: ["project.screen"])
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        let decoded = try JSONDecoder().decode(WebhookCreateBody.self, from: data)
        #expect(decoded.url == "https://hook.example.com")
        #expect(decoded.events == ["project.screen"])
    }

    @Test func decodesScreenSection() throws {
        let json = """
        {"id": "sec001", "name": "Onboarding", "description": "First-time user screens"}
        """
        let section = try decoder.decode(ScreenSection.self, from: Data(json.utf8))
        #expect(section.id == "sec001")
        #expect(section.name == "Onboarding")
        #expect(section.description == "First-time user screens")
    }

    // MARK: - New Model Tests

    @Test func decodesScreenNote() throws {
        let json = """
        {
            "id": "note001",
            "order": "1",
            "status": "open",
            "position": {"x": 0.45, "y": 0.32},
            "color": {"name": "yellow", "r": 255, "g": 208, "b": 57, "a": 1},
            "comments": [
                {
                    "id": "c001",
                    "content": "Fix alignment",
                    "author": {"id": "u001", "username": "designer"},
                    "updated": 1700000000,
                    "reactions": [{"id": "r1", "short_code": "thumbsup", "users": [{"id": "u002", "username": "dev"}]}]
                }
            ],
            "created": 1700000000,
            "creator": {"id": "u001", "username": "designer"}
        }
        """
        let note = try decoder.decode(ScreenNote.self, from: Data(json.utf8))
        #expect(note.id == "note001")
        #expect(note.order == "1")
        #expect(note.status == "open")
        #expect(note.position?.x == 0.45)
        #expect(note.color?.name == "yellow")
        #expect(note.color?.r == 255)
        #expect(note.comments?.first?.content == "Fix alignment")
        #expect(note.comments?.first?.reactions?.first?.shortCode == "thumbsup")
        #expect(note.creator?.username == "designer")
    }

    @Test func decodesScreenAnnotation() throws {
        let json = """
        {
            "id": "ann001",
            "content": "Button padding",
            "note_type": {"id": "nt001", "name": "Design", "color": "#00FF00"},
            "position": {"x": 100.5, "y": 200.0},
            "created": 1700000000
        }
        """
        let annotation = try decoder.decode(ScreenAnnotation.self, from: Data(json.utf8))
        #expect(annotation.id == "ann001")
        #expect(annotation.content == "Button padding")
        #expect(annotation.noteType?.name == "Design")
        #expect(annotation.noteType?.color == "#00FF00")
        #expect(annotation.position?.x == 100.5)
        #expect(annotation.position?.y == 200.0)
    }

    @Test func decodesScreenAnnotationNoteType() throws {
        let json = """
        {"id": "nt001", "name": "Feedback", "color": "#0000FF"}
        """
        let noteType = try decoder.decode(ScreenAnnotationNoteType.self, from: Data(json.utf8))
        #expect(noteType.id == "nt001")
        #expect(noteType.name == "Feedback")
        #expect(noteType.color == "#0000FF")
    }

    @Test func decodesScreenVariantGroup() throws {
        let json = """
        {
            "id": "vg001",
            "name": "Dark Mode",
            "variants": [{"screen_id": "scr001", "value": "Default"}]
        }
        """
        let group = try decoder.decode(ScreenVariantGroup.self, from: Data(json.utf8))
        #expect(group.id == "vg001")
        #expect(group.name == "Dark Mode")
        #expect(group.variants.count == 1)
        #expect(group.variants.first?.screenId == "scr001")
        #expect(group.variants.first?.value == "Default")
    }

    @Test func decodesConnectedComponent() throws {
        let json = """
        {
            "name": "Button",
            "description": "Primary button component",
            "file_path": "src/components/Button.tsx",
            "components": [{"id": "comp001", "name": "PrimaryButton"}]
        }
        """
        let cc = try decoder.decode(ConnectedComponent.self, from: Data(json.utf8))
        #expect(cc.name == "Button")
        #expect(cc.description == "Primary button component")
        #expect(cc.filePath == "src/components/Button.tsx")
        #expect(cc.components?.first?.id == "comp001")
    }

    @Test func decodesFlowBoardGroup() throws {
        let json = """
        {"id": "grp001", "name": "Auth Flow", "created": 1700000000}
        """
        let group = try decoder.decode(FlowBoardGroup.self, from: Data(json.utf8))
        #expect(group.id == "grp001")
        #expect(group.name == "Auth Flow")
    }

    @Test func decodesWorkflowStatus() throws {
        let json = """
        {"id": "ws001", "name": "In Review"}
        """
        let status = try decoder.decode(WorkflowStatus.self, from: Data(json.utf8))
        #expect(status.id == "ws001")
        #expect(status.name == "In Review")
    }

    @Test func decodesUserWebhook() throws {
        let json = """
        {
            "id": "uwh001",
            "url": "https://example.com/user-hook",
            "status": "active",
            "events": ["project.created"],
            "created": 1700000000,
            "updated": 1700100000
        }
        """
        let webhook = try decoder.decode(UserWebhook.self, from: Data(json.utf8))
        #expect(webhook.id == "uwh001")
        #expect(webhook.url == "https://example.com/user-hook")
        #expect(webhook.status == "active")
        #expect(webhook.events == ["project.created"])
    }

    @Test func decodesPage() throws {
        let json = """
        {"id": "page001", "name": "Home", "type": "design", "description": "Home page"}
        """
        let page = try decoder.decode(Page.self, from: Data(json.utf8))
        #expect(page.id == "page001")
        #expect(page.name == "Home")
        #expect(page.type == "design")
        #expect(page.description == "Home page")
    }

    @Test func decodesSpacingSection() throws {
        let json = """
        {"id": "ss001", "name": "Base", "description": "Base spacing values"}
        """
        let section = try decoder.decode(SpacingSection.self, from: Data(json.utf8))
        #expect(section.id == "ss001")
        #expect(section.name == "Base")
        #expect(section.description == "Base spacing values")
    }

    @Test func decodesVariableCollection() throws {
        let json = """
        {"id": "vc001", "name": "Colors"}
        """
        let vc = try decoder.decode(VariableCollection.self, from: Data(json.utf8))
        #expect(vc.id == "vc001")
        #expect(vc.name == "Colors")
    }

    @Test func decodesComponentSection() throws {
        let json = """
        {"id": "cs001", "name": "Buttons"}
        """
        let section = try decoder.decode(ComponentSection.self, from: Data(json.utf8))
        #expect(section.id == "cs001")
        #expect(section.name == "Buttons")
    }
}
