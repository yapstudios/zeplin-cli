import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public enum TerminalUI {

    public enum KeyEvent {
        case up
        case down
        case left
        case right
        case enter
        case back
        case quit
        case other
    }

    nonisolated(unsafe) private static var originalTermios = termios()
    nonisolated(unsafe) private static var isRawMode = false

    public static func enableRawMode() {
        guard !isRawMode else { return }
        tcgetattr(STDIN_FILENO, &originalTermios)
        var raw = originalTermios
        raw.c_lflag &= ~(UInt(ECHO | ICANON | ISIG))
        raw.c_cc.16 = 1
        raw.c_cc.17 = 0
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        isRawMode = true
        installSignalHandler()
    }

    public static func restoreTerminal() {
        guard isRawMode else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        isRawMode = false
        showCursor()
    }

    private static func installSignalHandler() {
        signal(SIGINT) { _ in
            TerminalUI.restoreTerminal()
            fputs("\n", stdout)
            exit(0)
        }
    }

    public static func readKey() -> KeyEvent {
        var buf = [UInt8](repeating: 0, count: 3)
        let n = read(STDIN_FILENO, &buf, 3)

        if n == 1 {
            switch buf[0] {
            case 0x1B:
                var seq = [UInt8](repeating: 0, count: 2)
                var pollFd = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
                let ready = poll(&pollFd, 1, 50)
                if ready > 0 {
                    let seqN = read(STDIN_FILENO, &seq, 2)
                    if seqN == 2, seq[0] == 0x5B {
                        switch seq[1] {
                        case 0x41: return .up
                        case 0x42: return .down
                        case 0x43: return .right
                        case 0x44: return .left
                        default: return .other
                        }
                    }
                    return .other
                }
                return .back
            case 10, 13: return .enter
            case 3: return .quit
            case 113: return .back
            default: return .other
            }
        }

        if n == 3, buf[0] == 0x1B, buf[1] == 0x5B {
            switch buf[2] {
            case 0x41: return .up
            case 0x42: return .down
            case 0x43: return .right
            case 0x44: return .left
            default: return .other
            }
        }

        return .other
    }

    public static var isInteractiveTerminal: Bool {
        isatty(STDIN_FILENO) != 0 && isatty(STDOUT_FILENO) != 0
    }

    public static func terminalHeight() -> Int {
        var ws = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &ws) == 0 {
            return Int(ws.ws_row)
        }
        return 24
    }

    public static func getCursorRow() -> Int {
        fputs("\u{1B}[6n", stdout)
        fflush(stdout)

        var response = [UInt8]()
        while true {
            var c: UInt8 = 0
            let n = read(STDIN_FILENO, &c, 1)
            if n != 1 { break }
            response.append(c)
            if c == 0x52 { break }
        }

        let str = String(bytes: response, encoding: .ascii) ?? ""
        if let start = str.firstIndex(of: "["),
           let semi = str.firstIndex(of: ";") {
            let rowStr = str[str.index(after: start)..<semi]
            return Int(rowStr) ?? 1
        }
        return 1
    }

    public static func moveTo(row: Int) {
        writeFlush("\u{1B}[\(row);1H")
    }

    public static func reserveLines(_ count: Int) -> Int {
        for _ in 0..<count {
            writeFlush("\n")
        }
        moveCursorUp(count)
        return getCursorRow()
    }

    public static func hideCursor() { writeFlush("\u{1B}[?25l") }
    public static func showCursor() { writeFlush("\u{1B}[?25h") }
    public static func clearToEnd() { writeFlush("\u{1B}[J") }
    public static func clearLine() { writeFlush("\r\u{1B}[2K") }

    public static func moveCursorUp(_ n: Int) {
        if n > 0 { writeFlush("\u{1B}[\(n)A") }
    }

    public static func writeLine(_ text: String) { writeFlush(text + "\n") }

    public static func writeFlush(_ text: String) {
        fputs(text, stdout)
        fflush(stdout)
    }

    public static func bold(_ text: String) -> String { "\u{1B}[1m\(text)\u{1B}[0m" }
    public static func cyan(_ text: String) -> String { "\u{1B}[36m\(text)\u{1B}[0m" }
    public static func dim(_ text: String) -> String { "\u{1B}[2m\(text)\u{1B}[0m" }
    public static func green(_ text: String) -> String { "\u{1B}[32m\(text)\u{1B}[0m" }
    public static func red(_ text: String) -> String { "\u{1B}[31m\(text)\u{1B}[0m" }
    public static func yellow(_ text: String) -> String { "\u{1B}[33m\(text)\u{1B}[0m" }
}
