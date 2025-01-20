import SwiftUI

struct SipCredentialRow: View {
    let credential: SipCredential
    let isSelected: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            HStack {
                Text(credential.username)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 16)
                    .lineLimit(1)                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color(hex: "#F5F3E4") : .white)
            .contentShape(Rectangle())
            .cornerRadius(4)
            Spacer()
            HStack {
                if isSelected {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                    }
                    .frame(width: 16, height: 16)
                }
                
            }
            .frame(width: 30 , alignment: .center)

        }.padding(.horizontal, 24)
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
            credential: SipCredential(username: "gencredzGcUippdfjdfldsfsfdjnmnssdsdadcsn", password: ""),
            isSelected: false,
            onDelete: {}
        )
    }
    .padding()
}
