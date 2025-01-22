import Foundation

struct SipCredential: Codable {
    let username: String
    let password: String?
    let callerNumber: String
    let callerName: String
    let isTokenLogin: Bool
    
    init(username: String, password: String? = nil, callerNumber: String = "", callerName: String = "", isTokenLogin: Bool = false) {
        self.username = username
        self.password = password
        self.callerNumber = callerNumber
        self.callerName = callerName
        self.isTokenLogin = isTokenLogin
    }
}