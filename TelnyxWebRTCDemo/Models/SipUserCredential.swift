struct SipCredential: Codable, Equatable {
    let username: String
    let password: String
    let isToken: Bool?
    let callerName: String?
    let callerNumber: String?
    
    init(username: String,
         password: String,
         isToken: Bool? = nil,
         callerName: String? = nil,
         callerNumber: String? = nil) {
        self.username = username
        self.password = password
        self.isToken = isToken
        self.callerName = callerName
        self.callerNumber = callerNumber
    }
}
