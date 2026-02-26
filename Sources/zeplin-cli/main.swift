import ZeplinCLI
import Foundation

do {
    let args = CommandLine.arguments
    let envSkip = ProcessInfo.processInfo.environment["ZEPLIN_NO_UPDATE_CHECK"] == "1"
    let flagSkip = args.contains("--quiet") || args.contains("-q") || args.contains("--no-update-check")
    let isUpdateCommand = args.contains("check-for-update")

    if !envSkip && !flagSkip && !isUpdateCommand {
        UpdateChecker.checkAndNotify()
    }
}

Zeplin.main()
