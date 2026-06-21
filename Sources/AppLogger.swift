import Foundation

class AppLogger {
    static let shared = AppLogger()

    func log(_ message: String) {
        print("[StrikeScore] \(message)")
    }

    func error(_ message: String) {
        print("[StrikeScore] ERROR: \(message)")
    }
}
