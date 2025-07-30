import SwiftUI
import TelnyxRTC

class ProfileViewModel: ObservableObject {
    @Published var selectedProfile: SipCredential? = nil
    @Published var selectedRegion: Region = .auto
    
    init() {
        loadSelectedProfile()
    }
    
    private func loadSelectedProfile() {
        selectedProfile = SipCredentialsManager.shared.getSelectedCredential()
        selectedRegion = selectedProfile?.effectiveRegion ?? getGlobalRegion()
    }
    
    func updateRegion(_ region: Region) {
        selectedRegion = region
        
        // Update the selected profile with the new region
        if var profile = selectedProfile {
            profile.region = region
            selectedProfile = profile
            SipCredentialsManager.shared.addOrUpdateCredential(profile)
            SipCredentialsManager.shared.saveSelectedCredential(profile)
        } else {
            // If no profile is selected, still persist the region choice
            // This could be saved in UserDefaults for global region preference
            UserDefaults.standard.set(region.rawValue, forKey: "GlobalSelectedRegion")
        }
    }
    
    func updateSelectedProfile(_ profile: SipCredential?) {
        selectedProfile = profile
        selectedRegion = profile?.effectiveRegion ?? getGlobalRegion()
    }
    
    private func getGlobalRegion() -> Region {
        if let savedRegion = UserDefaults.standard.string(forKey: "GlobalSelectedRegion"),
           let region = Region(rawValue: savedRegion) {
            return region
        }
        return .auto
    }
    
    func refreshProfile() {
        loadSelectedProfile()
    }
}
