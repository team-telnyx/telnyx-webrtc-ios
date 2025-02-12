import SwiftUI

struct SipCredentialHeader: View {
    let title: String
    let subtitle: String
    let onClose: () -> Void
    let onAddProfile: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Existing Profiles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#1D1D1D"))
                }
            }
            .padding(.top, 20)
            HStack {
                Button(action: onAddProfile) {
                    Text("+ Add new profile")
                        .font(.system(size: 14).bold())
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 150)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#F5F3E4"))
                        .cornerRadius(16)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.addProfileButton)
                Spacer()
            }
            HStack {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    SipCredentialHeader(
        title: "SIP Credentials",
        subtitle: "Development",
        onClose: {},
        onAddProfile: {}
    )
}
