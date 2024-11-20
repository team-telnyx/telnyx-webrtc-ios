import TelnyxRTC

extension WebRTCEnvironment {

    func toString() -> String {
        switch self {
            case .development:
                return "development"
            case .production:
                return "production"
        }
    }

    static func fromString(_ value: String) -> WebRTCEnvironment {
        switch value {
            case "development":
                return .development
            case "production":
                return .production
            default:
                return .production
        }
    }
}
