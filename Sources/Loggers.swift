import Foundation
import OSLog

struct Log {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.inplaceai.InplaceAI", category: "general")
    static let processing = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.inplaceai.InplaceAI", category: "processing")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.inplaceai.InplaceAI", category: "network")
}
