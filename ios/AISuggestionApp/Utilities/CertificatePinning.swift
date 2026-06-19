import Foundation
import Security

final class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    // SHA-256 fingerprints of pinned certificates (Amazon Root CA 1)
    private let pinnedHashes: Set<String> = [
        // Amazon Root CA 1
        "++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=",
        // Amazon Root CA 2
        "f0KW/FtqTjs108NpYj42SrGvOB2PpxIVM8nWxjPqJGE=",
        // Amazon Root CA 3
        "NqvDJlas/GRcYbcWE8S/IceH9cq77kg0jVhZeAPXq8k=",
        // Amazon Root CA 4
        "9+ze1cZgR9KO1kZrVDxA4HQ6voHRCSVNz4RdTCx4U8U=",
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        var foundPinnedCert = false

        for index in 0..<certificateCount {
            guard let chain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
                  index < chain.count else {
                continue
            }
            let certificate = chain[index]
            let certData = SecCertificateCopyData(certificate) as Data
            let hash = certData.sha256Base64()
            if pinnedHashes.contains(hash) {
                foundPinnedCert = true
                break
            }
        }

        if foundPinnedCert {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

import CryptoKit

extension Data {
    func sha256Base64() -> String {
        let hash = SHA256.hash(data: self)
        return Data(hash).base64EncodedString()
    }
}
