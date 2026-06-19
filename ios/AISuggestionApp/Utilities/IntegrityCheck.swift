import Foundation

enum IntegrityCheck {
    static var isCompromised: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return hasJailbreakFiles || hasWritableSystemPaths || hasSuspiciousEnvironment
        #endif
    }

    private static var hasJailbreakFiles: Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/bin/ssh",
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private static var hasWritableSystemPaths: Bool {
        let path = "/private/jailbreak_check_\(UUID().uuidString)"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    private static var hasSuspiciousEnvironment: Bool {
        if let env = getenv("DYLD_INSERT_LIBRARIES"), !String(cString: env).isEmpty {
            return true
        }
        return false
    }
}
