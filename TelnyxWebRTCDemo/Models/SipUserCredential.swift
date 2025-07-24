import TelnyxRTC
import Foundation

struct SipCredential: Codable, Equatable {
    let username: String
    let password: String
    let isToken: Bool?
    let callerName: String?
    let callerNumber: String?
    var region: Region?

    
    init(username: String,
         password: String,
         isToken: Bool? = nil,
         callerName: String? = nil,
         callerNumber: String? = nil,
         region: Region? = .auto
    ) {
        self.username = username
        self.password = password
        self.isToken = isToken
        self.callerName = callerName
        self.callerNumber = callerNumber
        self.region = region
    }
    
    /// Returns the region to use for connection, defaulting to .auto if nil
    var effectiveRegion: Region {
        return region ?? .auto
    }
}
