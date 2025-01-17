import SwiftUI

struct SipCredentialsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var credentialsList: [SipCredential] = []
    @State private var selectedCredential: SipCredential?
    @State private var isSelectedCredentialChanged = false
    
    let onCredentialSelected: (SipCredential?) -> Void
    
    var body: some View {
        List {
            Section {
                if credentialsList.isEmpty {
                    Text("No SIP credentials available. Credentials will appear here after using them to connect.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 20)
                } else {
                    ForEach(credentialsList, id: \.username) { credential in
                        SipCredentialRow(
                            credential: credential,
                            isSelected: credential.username == selectedCredential?.username
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            SipCredentialsManager.shared.saveSelectedCredential(credential)
                            isSelectedCredentialChanged = true
                            dismiss()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    if selectedCredential?.username == credential.username {
                                        isSelectedCredentialChanged = true
                                    }
                                    SipCredentialsManager.shared.removeCredential(username: credential.username)
                                    credentialsList = SipCredentialsManager.shared.getCredentials()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                SipCredentialHeader(
                    title: "SIP Credentials",
                    subtitle: UserDefaults.standard.getEnvironment().toString()
                )
            }
        }
        .listStyle(.plain)
        .onAppear {
            credentialsList = SipCredentialsManager.shared.getCredentials()
            selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
        }
        .onDisappear {
            if isSelectedCredentialChanged {
                selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
                onCredentialSelected(selectedCredential)
            }
        }
    }
}

#Preview {
    SipCredentialsView { credential in
        print("Selected credential: \(String(describing: credential?.username))")
    }
}