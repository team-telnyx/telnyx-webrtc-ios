import SwiftUI

struct SipCredentialHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    SipCredentialHeader(
        title: "SIP Credentials",
        subtitle: "Development"
    )
}