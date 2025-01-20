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
            
            Button(action: onAddProfile) {
                Text("+ Add new profile")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#F5F3E4"))
                    .cornerRadius(16)
            }
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
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