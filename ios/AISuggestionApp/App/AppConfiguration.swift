import Foundation

enum AppConfiguration {
    static let apiBaseURL: URL = {
        guard let url = URL(string: "https://223ri5jfyl.execute-api.eu-west-1.amazonaws.com/v1") else {
            fatalError("Invalid API base URL")
        }
        return url
    }()

    static let requestTimeout: TimeInterval = 25
    static let environment = "production"
}
