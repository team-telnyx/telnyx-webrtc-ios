import Foundation
import TelnyxRTC

class SipCredentialsManager {
    
    public static let shared = SipCredentialsManager()
    
    private init() {}
    
    // Get the current environment
    private static func currentEnvironment() -> WebRTCEnvironment {
        return UserDefaults.standard.getEnvironment()
    }
    
    // Generate the key for credentials based on the environment
    private static func credentialsKey(for environment: WebRTCEnvironment) -> String {
        return "\(UserDefaultsKey.sipCredentials.rawValue)_\(environment.toString())"
    }
    
    // Get credentials for the current environment
    func getCredentials() -> [SipCredential] {
        let environment = SipCredentialsManager.currentEnvironment()
        let key = SipCredentialsManager.credentialsKey(for: environment)
        guard let data = UserDefaults.standard.data(forKey: key),
              let credentials = try? JSONDecoder().decode([SipCredential].self, from: data) else {
            return []
        }
        return credentials
    }
    
    // Save credentials for the current environment
    func saveCredentials(_ credentials: [SipCredential]) {
        let environment = SipCredentialsManager.currentEnvironment()
        let key = SipCredentialsManager.credentialsKey(for: environment)
        if let encoded = try? JSONEncoder().encode(credentials) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    // Add a new credential
    func addCredential(_ credential: SipCredential) {
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
    func updateCredential(_ credential: SipCredential) {
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
    func removeCredential(username: String) {
        var credentials = getCredentials()
        
        // Remove the credential with the matching username
        credentials.removeAll { $0.username == username }
        saveCredentials(credentials)
    }
    
}

// MARK: - Selected Credential
extension SipCredentialsManager {

    private static func selectedCredentialKey(for environment: WebRTCEnvironment) -> String {
        return "\(UserDefaultsKey.selectedSipCredential.rawValue)_\(environment.toString())"
    }

    func getSelectedCredential() -> SipCredential? {
        return getSelectedCredential(for: SipCredentialsManager.currentEnvironment())
    }
    
    private func getSelectedCredential(for environment: WebRTCEnvironment) -> SipCredential? {
        let key = SipCredentialsManager.selectedCredentialKey(for: environment)
        guard let data = UserDefaults.standard.data(forKey: key),
              let credential = try? JSONDecoder().decode(SipCredential.self, from: data) else {
            return nil
        }
        return credential
    }
    
    func saveSelectedCredential(_ credential: SipCredential) {
        let environment = SipCredentialsManager.currentEnvironment()
        let key = SipCredentialsManager.selectedCredentialKey(for: environment)
        
        // Save the selected credential to UserDefaults
        if let encoded = try? JSONEncoder().encode(credential) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
        
        // Ensure the selected credential is also stored in the list of credentials
        var credentials = getCredentials()
        if !credentials.contains(where: { $0.username == credential.username }) {
            credentials.append(credential)
            saveCredentials(credentials)
        }
    }
}
