import SwiftUI

struct SipCredentialRow: View {
    let credential: SipCredential
    let isSelected: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(credential.username)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#1D1D1D"))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            
            Spacer()
            
            if isSelected {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#1D1D1D"))
                }
                .frame(width: 16, height: 16)
                .padding(.trailing, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color(hex: "#F5F3E4") : .white)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        SipCredentialRow(
            credential: SipCredential(username: "test_user", password: ""),
            isSelected: true,
            onDelete: {}
        )
        SipCredentialRow(
            credential: SipCredential(username: "another_user", password: ""),
            isSelected: false,
            onDelete: {}
        )
    }
    .padding()
}