import SwiftUI

struct SipCredentialsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var credentialsList: [SipCredential] = []
    @State private var selectedCredential: SipCredential?
    @State private var tempSelectedCredential: SipCredential?
    @State private var isSelectedCredentialChanged = false
    @Binding var isShowingCredentialsInput: Bool
    @State private var internalIsShowingCredentialsInput: Bool
    @State private var viewHeight: CGFloat = 0
    @State private var isEditMode: Bool = false
    @State private var credentialToEdit: SipCredential? = nil
    
    let onCredentialSelected: (SipCredential?) -> Void
    let onSignIn: (SipCredential?) -> Void
    
    init(isShowingCredentialsInput: Binding<Bool>,
         onCredentialSelected: @escaping (SipCredential?) -> Void,
         onSignIn: @escaping (SipCredential?) -> Void) {
        self._isShowingCredentialsInput = isShowingCredentialsInput
        self._internalIsShowingCredentialsInput = State(initialValue: isShowingCredentialsInput.wrappedValue)
        self.onCredentialSelected = onCredentialSelected
        self.onSignIn = onSignIn
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SipCredentialHeader(
                title: "SIP Credentials",
                subtitle: UserDefaults.standard.getEnvironment().toString(),
                onClose: { dismiss() },
                onAddProfile: {
                    withAnimation {
                        internalIsShowingCredentialsInput.toggle()
                        isShowingCredentialsInput = internalIsShowingCredentialsInput
                    }
                }
            )
            if internalIsShowingCredentialsInput {
                ScrollView {
                    
                    SipInputCredentialsView(
                        username: credentialToEdit?.username ?? "",
                        password: credentialToEdit?.password ?? "",
                        isPasswordVisible: false,
                        hasError: false,
                        isTokenLogin: credentialToEdit?.isToken ?? false,
                        tokenCallerId: credentialToEdit?.isToken == true ? credentialToEdit?.username ?? "" : "",
                        callerIdNumber: credentialToEdit?.callerNumber ?? "",
                        callerName: credentialToEdit?.callerName ?? "",
                        isEditMode: isEditMode,
                        onSignIn: { newCredential, isEdit, originalUsername in
                            if isEdit {
                                // Check if username was changed and already exists
                                if originalUsername != newCredential?.username && 
                                   credentialsList.contains(where: { $0.username == newCredential?.username }) {
                                    // Show error - username already exists
                                    // This would be handled in the real implementation
                                    print("Error: Username already exists")
                                } else {
                                    // If editing the currently selected credential
                                    if selectedCredential?.username == originalUsername {
                                        // Update the selected credential
                                        selectedCredential = newCredential
                                        tempSelectedCredential = newCredential
                                        isSelectedCredentialChanged = true
                                    }
                                    
                                    // Remove the old credential if username changed
                                    if originalUsername != newCredential?.username {
                                        SipCredentialsManager.shared.removeCredential(username: originalUsername)
                                    }
                                    
                                    // Add or update the credential
                                    if let credential = newCredential {
                                        SipCredentialsManager.shared.addOrUpdateCredential(credential)
                                    }
                                    
                                    // Refresh the credentials list
                                    credentialsList = SipCredentialsManager.shared.getCredentials()
                                    
                                    // Reset edit mode
                                    isEditMode = false
                                    credentialToEdit = nil
                                    
                                    // Close the input view
                                    withAnimation {
                                        internalIsShowingCredentialsInput = false
                                        isShowingCredentialsInput = false
                                    }
                                }
                            } else {
                                // Normal sign in flow
                                onSignIn(newCredential)
                                
                                // Refresh the credentials list
                                credentialsList = SipCredentialsManager.shared.getCredentials()
                                
                                // Close the input view
                                withAnimation {
                                    internalIsShowingCredentialsInput = false
                                    isShowingCredentialsInput = false
                                }
                            }
                        },
                        onCancel: {
                            withAnimation {
                                internalIsShowingCredentialsInput = false
                                isShowingCredentialsInput = false
                                isEditMode = false
                                credentialToEdit = nil
                            }
                        }
                    )
                    .transition(.move(edge: .top))
                    .frame(height: viewHeight)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .offset(y: 0)
                    .onAppear {
                        viewHeight = 500
                    }
                    .onDisappear {
                        viewHeight = 0
                    }
                    Spacer()
                }
            } else {
                List {
                    Section {
                        if credentialsList.isEmpty && !internalIsShowingCredentialsInput {
                            Text("No SIP credentials available. Credentials will appear here after using them to connect.")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .listRowBackground(Color.clear)
                                .padding(.vertical, 20)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(credentialsList, id: \.username) { credential in
                                SipCredentialRow(
                                    viewModel: SipCredentialRowViewModel(
                                        credential: credential,
                                        isSelected: credential.username == tempSelectedCredential?.username,
                                        onDelete: {
                                            withAnimation {
                                                if selectedCredential?.username == credential.username {
                                                    SipCredentialsManager.shared.removeSelectedCredential()
                                                    selectedCredential = nil
                                                    tempSelectedCredential = nil
                                                    isSelectedCredentialChanged = true
                                                    SipCredentialsManager.shared.removeCredential(username: credential.username)
                                                    credentialsList = SipCredentialsManager.shared.getCredentials()
                                                    if !credentialsList.isEmpty {
                                                        tempSelectedCredential = credentialsList.first
                                                        SipCredentialsManager.shared.saveSelectedCredential(tempSelectedCredential!)
                                                        isSelectedCredentialChanged = true
                                                    }
                                                }
                                            }

                                        },
                                        onEdit: {
                                            withAnimation {
                                                credentialToEdit = credential
                                                isEditMode = true
                                                internalIsShowingCredentialsInput = true
                                                isShowingCredentialsInput = true
                                            }

                                        }
                                    )
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.white)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .background(.white)
                .applyScrollContentBackground()
                Spacer()
                HStack(spacing: 12) {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                            .frame(width: 100)
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
                            .frame(width: 100)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#1D1D1D"))
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.white)
            }
            
        }
        .onAppear {
            credentialsList = SipCredentialsManager.shared.getCredentials()
            selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
            tempSelectedCredential = selectedCredential
            internalIsShowingCredentialsInput = isShowingCredentialsInput
        }
        .onDisappear {
            if isSelectedCredentialChanged {
                selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
                onCredentialSelected(selectedCredential)
            }
            internalIsShowingCredentialsInput = false
            isShowingCredentialsInput = false
        }
    }
}

// MARK: -
struct SipCredentialsView_Previews: PreviewProvider {
    @State static var isShowingCredentialsInput = true
    
    static var previews: some View {
        SipCredentialsView(
            isShowingCredentialsInput: $isShowingCredentialsInput,
            onCredentialSelected: { _ in },
            onSignIn: { _ in }
        )
    }
}

