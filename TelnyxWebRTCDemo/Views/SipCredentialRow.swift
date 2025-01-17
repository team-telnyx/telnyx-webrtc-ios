import SwiftUI

struct SipCredentialRow: View {
    let credential: SipCredential
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(credential.username)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isSelected ? .white : .black)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color(red: 0/255, green: 192/255, blue: 139/255) : .white)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        SipCredentialRow(
            credential: SipCredential(username: "test_user", password: ""),
            isSelected: true
        )
        SipCredentialRow(
            credential: SipCredential(username: "another_user", password: ""),
            isSelected: false
        )
    }
    .padding()
}