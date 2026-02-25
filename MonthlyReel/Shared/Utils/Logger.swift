import OSLog

/// OSLog-based logging with per-subsystem categories.
extension Logger {
    private static let subsystem = "com.monthlyreel"

    static let scanning    = Logger(subsystem: subsystem, category: "scanning")
    static let selection   = Logger(subsystem: subsystem, category: "selection")
    static let composition = Logger(subsystem: subsystem, category: "composition")
    static let grading     = Logger(subsystem: subsystem, category: "grading")
    static let storage     = Logger(subsystem: subsystem, category: "storage")
}
