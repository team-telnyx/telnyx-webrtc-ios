import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var selectedProfile: SipCredential? = nil
}
