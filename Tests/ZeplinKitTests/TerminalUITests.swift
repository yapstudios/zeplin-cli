import Testing
@testable import ZeplinKit

@Suite("Terminal UI")
struct TerminalUITests {
    @Test func boldFormatting() {
        let result = TerminalUI.bold("test")
        #expect(result.contains("test"))
        #expect(result.contains("\u{1B}[1m"))
        #expect(result.contains("\u{1B}[0m"))
    }

    @Test func cyanFormatting() {
        let result = TerminalUI.cyan("hello")
        #expect(result.contains("hello"))
        #expect(result.contains("\u{1B}[36m"))
        #expect(result.contains("\u{1B}[0m"))
    }

    @Test func dimFormatting() {
        let result = TerminalUI.dim("faded")
        #expect(result.contains("faded"))
        #expect(result.contains("\u{1B}[2m"))
        #expect(result.contains("\u{1B}[0m"))
    }

    @Test func greenFormatting() {
        let result = TerminalUI.green("success")
        #expect(result.contains("success"))
        #expect(result.contains("\u{1B}[32m"))
        #expect(result.contains("\u{1B}[0m"))
    }

    @Test func redFormatting() {
        let result = TerminalUI.red("error")
        #expect(result.contains("error"))
        #expect(result.contains("\u{1B}[31m"))
        #expect(result.contains("\u{1B}[0m"))
    }

    @Test func yellowFormatting() {
        let result = TerminalUI.yellow("warning")
        #expect(result.contains("warning"))
        #expect(result.contains("\u{1B}[33m"))
        #expect(result.contains("\u{1B}[0m"))
    }

    @Test func formattingPreservesText() {
        let text = "The quick brown fox jumps over the lazy dog"
        #expect(TerminalUI.bold(text).contains(text))
        #expect(TerminalUI.cyan(text).contains(text))
        #expect(TerminalUI.dim(text).contains(text))
        #expect(TerminalUI.green(text).contains(text))
        #expect(TerminalUI.red(text).contains(text))
        #expect(TerminalUI.yellow(text).contains(text))
    }

    @Test func keyEventCases() {
        let cases: [TerminalUI.KeyEvent] = [.up, .down, .left, .right, .enter, .back, .quit, .other]
        #expect(cases.count == 8)

        // Verify each case is distinct via exhaustive switch
        for event in cases {
            switch event {
            case .up, .down, .left, .right, .enter, .back, .quit, .other:
                break
            }
        }
    }

    @Test func formattingWrapsCorrectly() {
        let bold = TerminalUI.bold("x")
        #expect(bold == "\u{1B}[1mx\u{1B}[0m")

        let cyan = TerminalUI.cyan("x")
        #expect(cyan == "\u{1B}[36mx\u{1B}[0m")

        let dim = TerminalUI.dim("x")
        #expect(dim == "\u{1B}[2mx\u{1B}[0m")

        let green = TerminalUI.green("x")
        #expect(green == "\u{1B}[32mx\u{1B}[0m")

        let red = TerminalUI.red("x")
        #expect(red == "\u{1B}[31mx\u{1B}[0m")

        let yellow = TerminalUI.yellow("x")
        #expect(yellow == "\u{1B}[33mx\u{1B}[0m")
    }

    @Test func emptyStringFormatting() {
        #expect(TerminalUI.bold("") == "\u{1B}[1m\u{1B}[0m")
        #expect(TerminalUI.red("") == "\u{1B}[31m\u{1B}[0m")
    }
}
