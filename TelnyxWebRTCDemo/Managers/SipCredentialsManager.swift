import Foundation
import TelnyxRTC

class SipCredentialsManager {
    
    // Get the current environment
    private static func currentEnvironment() -> WebRTCEnvironment {
        return UserDefaults.standard.getEnvironment()
    }
    
    // Generate the key for credentials based on the environment
    private static func credentialsKey(for environment: WebRTCEnvironment) -> String {
        return "\(UserDefaultsKey.sipUser.rawValue)_\(environment.toString())"
    }
    
    // Get credentials for the current environment
    static func getCredentials() -> [SipCredential] {
        let environment = currentEnvironment()
        let key = credentialsKey(for: environment)
        guard let data = UserDefaults.standard.data(forKey: key),
              let credentials = try? JSONDecoder().decode([SipCredential].self, from: data) else {
            return []
        }
        return credentials
    }
    
    // Save credentials for the current environment
    static func saveCredentials(_ credentials: [SipCredential]) {
        let environment = currentEnvironment()
        let key = credentialsKey(for: environment)
        if let encoded = try? JSONEncoder().encode(credentials) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    // Add a new credential
    static func addCredential(_ credential: SipCredential) {
        var credentials = getCredentials()
        
        // Check if the username already exists
        if credentials.contains(where: { $0.username == credential.username }) {
            print("User already exists. Cannot add.")
            return
        }
        
        credentials.append(credential)
        saveCredentials(credentials)
    }
    
    // Update an existing credential
    static func updateCredential(_ credential: SipCredential) {
        var credentials = getCredentials()
        
        // Find the index of the existing credential by username
        if let index = credentials.firstIndex(where: { $0.username == credential.username }) {
            credentials[index] = credential
            saveCredentials(credentials)
        } else {
            print("User not found. Cannot update.")
        }
    }
    
    // Remove a credential by username
    static func removeCredential(username: String) {
        var credentials = getCredentials()
        
        // Remove the credential with the matching username
        credentials.removeAll { $0.username == username }
        saveCredentials(credentials)
    }
}
