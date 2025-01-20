import SwiftUI

struct SipCredentialsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var credentialsList: [SipCredential] = []
    @State private var selectedCredential: SipCredential?
    @State private var tempSelectedCredential: SipCredential?
    @State private var isSelectedCredentialChanged = false
    
    let onCredentialSelected: (SipCredential?) -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
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
                                    isSelected: credential.username == tempSelectedCredential?.username,
                                    onDelete: {
                                        withAnimation {
                                            if selectedCredential?.username == credential.username {
                                                isSelectedCredentialChanged = true
                                            }
                                            SipCredentialsManager.shared.removeCredential(username: credential.username)
                                            credentialsList = SipCredentialsManager.shared.getCredentials()
                                        }
                                    }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    tempSelectedCredential = credential
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                        }
                    } header: {
                        SipCredentialHeader(
                            title: "SIP Credentials",
                            subtitle: UserDefaults.standard.getEnvironment().toString(),
                            onClose: { dismiss() },
                            onAddProfile: {
                                // TODO: Implement add profile functionality
                            }
                        )
                        .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.plain)
                
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: "#1D1D1D"), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        if let credential = tempSelectedCredential {
                            SipCredentialsManager.shared.saveSelectedCredential(credential)
                            isSelectedCredentialChanged = true
                        }
                        dismiss()
                    }) {
                        Text("Confirm")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#1D1D1D"))
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(uiColor: .systemBackground))
            }
        }
        .onAppear {
            credentialsList = SipCredentialsManager.shared.getCredentials()
            selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
            tempSelectedCredential = selectedCredential
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
    .preferredColorScheme(.light)
}