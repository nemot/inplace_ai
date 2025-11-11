import Foundation

class FileLogger {
    static let shared = FileLogger()

    private let fileManager = FileManager.default
    private let maxLines = 1000
    private var logFileURL: URL?

    private init() {
        setupLogFile()
    }

    private func setupLogFile() {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("InplaceAI") else { return }

        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        logFileURL = appSupport.appendingPathComponent("inplaceai.log")
    }

    func log(_ message: String, level: String = "INFO") {
        guard let url = logFileURL else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(level)] \(message)\n"

        // Append to file
        if let data = logEntry.data(using: .utf8) {
            if fileManager.fileExists(atPath: url.path) {
                if let fileHandle = FileHandle(forWritingAtPath: url.path) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: url)
            }
        }

        // Rotate if needed
        rotateIfNeeded()
    }

    private func rotateIfNeeded() {
        guard let url = logFileURL else { return }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

            if lines.count > maxLines {
                let trimmedLines = Array(lines.suffix(maxLines))
                let newContent = trimmedLines.joined(separator: "\n") + "\n"
                try newContent.write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            // Ignore rotation errors
        }
    }

    func getLogFilePath() -> String? {
        return logFileURL?.path
    }
}

struct Log {
    static func info(_ message: String, category: String = "general") {
        FileLogger.shared.log(message, level: "INFO")
    }

    static func error(_ message: String, category: String = "general") {
        FileLogger.shared.log(message, level: "ERROR")
    }

    static let processing = ProcessingLogger()
    static let network = NetworkLogger()
}

struct ProcessingLogger {
    func info(_ message: String) {
        FileLogger.shared.log(message, level: "INFO")
    }

    func error(_ message: String) {
        FileLogger.shared.log(message, level: "ERROR")
    }
}

struct NetworkLogger {
    func info(_ message: String) {
        FileLogger.shared.log(message, level: "INFO")
    }

    func error(_ message: String) {
        FileLogger.shared.log(message, level: "ERROR")
    }
}
