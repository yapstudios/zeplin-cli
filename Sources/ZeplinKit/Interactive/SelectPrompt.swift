import Foundation

public struct Choice: Sendable {
    public let label: String
    public let value: String
    public let description: String?

    public init(label: String, value: String, description: String? = nil) {
        self.label = label
        self.value = value
        self.description = description
    }
}

public enum SelectPrompt {
    public static func run(prompt: String, choices: [Choice], initialSelection: Int = 0) throws -> Choice {
        guard !choices.isEmpty else {
            throw SelectPromptError.noChoices
        }

        var selected = min(initialSelection, choices.count - 1)
        let totalLines = choices.count + 1

        TerminalUI.enableRawMode()
        TerminalUI.hideCursor()

        defer {
            TerminalUI.showCursor()
            TerminalUI.restoreTerminal()
        }

        let startRow = TerminalUI.reserveLines(totalLines)
        renderFrame(prompt: prompt, choices: choices, selected: selected, startRow: startRow)

        while true {
            let key = TerminalUI.readKey()

            switch key {
            case .up:
                if selected > 0 { selected -= 1 }
            case .down:
                if selected < choices.count - 1 { selected += 1 }
            case .enter:
                TerminalUI.moveTo(row: startRow)
                TerminalUI.clearToEnd()
                let check = TerminalUI.cyan("?")
                TerminalUI.writeLine("\(check) \(TerminalUI.bold(prompt)) \(TerminalUI.cyan(choices[selected].label))")
                return choices[selected]
            case .back:
                TerminalUI.moveTo(row: startRow)
                TerminalUI.clearToEnd()
                throw SelectPromptError.cancelled
            case .quit:
                TerminalUI.moveTo(row: startRow)
                TerminalUI.clearToEnd()
                TerminalUI.showCursor()
                TerminalUI.restoreTerminal()
                fputs("\n", stdout)
                exit(0)
            case .other:
                continue
            }

            renderFrame(prompt: prompt, choices: choices, selected: selected, startRow: startRow)
        }
    }

    private static func renderFrame(prompt: String, choices: [Choice], selected: Int, startRow: Int) {
        TerminalUI.moveTo(row: startRow)
        TerminalUI.clearToEnd()

        var lines = [String]()

        let arrow = TerminalUI.cyan("?")
        let hint = TerminalUI.dim("(arrow keys, enter to select)")
        lines.append("\(arrow) \(TerminalUI.bold(prompt)) \(hint)")

        for (i, choice) in choices.enumerated() {
            let safeLabel = choice.label.replacingOccurrences(of: "\n", with: " ")
            let safeDesc = choice.description?.replacingOccurrences(of: "\n", with: " ")
            if i == selected {
                let cursor = TerminalUI.cyan("\u{276F}")
                var line = "\(cursor) \(TerminalUI.cyan(safeLabel))"
                if let desc = safeDesc { line += " \(TerminalUI.dim(desc))" }
                lines.append(line)
            } else {
                var line = "  \(safeLabel)"
                if let desc = safeDesc { line += " \(TerminalUI.dim(desc))" }
                lines.append(line)
            }
        }

        let frame = lines.joined(separator: "\r\n")
        TerminalUI.writeFlush(frame)
    }
}

public enum SelectPromptError: Error, CustomStringConvertible {
    case cancelled
    case noChoices

    public var description: String {
        switch self {
        case .cancelled: return "Selection cancelled"
        case .noChoices: return "No choices available"
        }
    }
}
