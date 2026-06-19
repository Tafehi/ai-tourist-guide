import Foundation

enum InputValidator {
    enum ValidationError: LocalizedError {
        case destinationTooLong
        case originTooLong
        case notesTooLong
        case tooManyInterests
        case invalidCharacters(field: String)

        var errorDescription: String? {
            switch self {
            case .destinationTooLong: "Destination must be under 200 characters"
            case .originTooLong: "Origin must be under 200 characters"
            case .notesTooLong: "Notes must be under 500 characters"
            case .tooManyInterests: "Maximum 20 interests allowed"
            case .invalidCharacters(let field): "\(field) contains invalid characters"
            }
        }
    }

    static func validate(request: TripRequest) throws {
        if request.destination.count > 200 {
            throw ValidationError.destinationTooLong
        }
        if let origin = request.origin, origin.count > 200 {
            throw ValidationError.originTooLong
        }
        if let notes = request.notes, notes.count > 500 {
            throw ValidationError.notesTooLong
        }
        if request.interests.count > 20 {
            throw ValidationError.tooManyInterests
        }

        try validateText(request.destination, field: "Destination")
        if let origin = request.origin {
            try validateText(origin, field: "Origin")
        }
    }

    private static func validateText(_ text: String, field: String) throws {
        let forbidden = CharacterSet(charactersIn: "<>{}[]\\|`~")
        if text.unicodeScalars.contains(where: { forbidden.contains($0) }) {
            throw ValidationError.invalidCharacters(field: field)
        }
    }
}
