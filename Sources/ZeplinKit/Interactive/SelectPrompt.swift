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

        // Reserve 3 lines for prompt, bottom indicator, and cursor padding
        let maxVisible = max(TerminalUI.terminalHeight() - 3, 5)
        let needsPaging = choices.count > maxVisible
        var windowStart = 0

        TerminalUI.enableRawMode()
        TerminalUI.hideCursor()

        defer {
            TerminalUI.showCursor()
            TerminalUI.restoreTerminal()
        }

        let displayCount = needsPaging ? min(maxVisible, choices.count) : choices.count
        // +1 for prompt, +1 for paging indicator if needed
        let totalLines = displayCount + 1 + (needsPaging ? 1 : 0)
        let startRow = TerminalUI.reserveLines(totalLines)

        func adjustWindow() {
            if selected < windowStart {
                windowStart = selected
            } else if selected >= windowStart + maxVisible {
                windowStart = selected - maxVisible + 1
            }
        }

        adjustWindow()
        renderPagedFrame(prompt: prompt, choices: choices, selected: selected,
                         windowStart: windowStart, maxVisible: maxVisible,
                         startRow: startRow, needsPaging: needsPaging)

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

            adjustWindow()
            renderPagedFrame(prompt: prompt, choices: choices, selected: selected,
                             windowStart: windowStart, maxVisible: maxVisible,
                             startRow: startRow, needsPaging: needsPaging)
        }
    }

    private static func renderPagedFrame(
        prompt: String, choices: [Choice], selected: Int,
        windowStart: Int, maxVisible: Int, startRow: Int, needsPaging: Bool
    ) {
        TerminalUI.moveTo(row: startRow)
        TerminalUI.clearToEnd()

        var lines = [String]()

        let arrow = TerminalUI.cyan("?")
        let hint = TerminalUI.dim("(arrow keys, enter to select)")
        lines.append("\(arrow) \(TerminalUI.bold(prompt)) \(hint)")

        let windowEnd = min(windowStart + maxVisible, choices.count)

        if needsPaging && windowStart > 0 {
            lines.append(TerminalUI.dim("  \u{2191} \(windowStart) more above"))
        }

        for i in windowStart..<windowEnd {
            let choice = choices[i]
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

        if needsPaging && windowEnd < choices.count {
            lines.append(TerminalUI.dim("  \u{2193} \(choices.count - windowEnd) more below"))
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
