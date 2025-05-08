import SwiftUI

struct SipInputCredentialsView: View {
    @State private var username: String
    @State private var password: String
    @State private var isPasswordVisible: Bool
    @State private var hasError: Bool
    @State private var errorMessage: String
    @State private var isTokenLogin: Bool
    @State private var tokenCallerId: String
    @State private var callerIdNumber: String
    @State private var callerName: String
    @State private var isEditMode: Bool
    @State private var originalUsername: String
    
    let onSignIn: (SipCredential?, Bool, String) -> Void
    var onCancel: () -> Void
    
    init(username: String = "",
         password: String = "",
         isPasswordVisible: Bool = false,
         hasError: Bool = false,
         errorMessage: String = "That username/password combination does not match our records. Please try again.",
         isTokenLogin: Bool = false,
         tokenCallerId: String = "",
         callerIdNumber: String = "",
         callerName: String = "",
         isEditMode: Bool = false,
         onSignIn: @escaping (SipCredential?, Bool, String) -> Void = { _, _, _ in },
         onCancel: @escaping () -> Void = {}) {
        self._username = State(initialValue: username)
        self._password = State(initialValue: password)
        self._isPasswordVisible = State(initialValue: isPasswordVisible)
        self._hasError = State(initialValue: hasError)
        self._errorMessage = State(initialValue: errorMessage)
        self._isTokenLogin = State(initialValue: isTokenLogin)
        self._tokenCallerId = State(initialValue: tokenCallerId)
        self._callerIdNumber = State(initialValue: callerIdNumber)
        self._callerName = State(initialValue: callerName)
        self._isEditMode = State(initialValue: isEditMode)
        self._originalUsername = State(initialValue: username)
        self.onSignIn = onSignIn
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if hasError {
                ErrorView(errorMessage: errorMessage)
            }            
            DestinationToggle(
                isFirstOptionSelected: $isTokenLogin,
                firstOption: "Credential Login",
                secondOption: "Token Login"
            )
            
            if isTokenLogin {
                Text("Token")
                    .foregroundColor(.black)
                
                HStack {
                    TextField("Enter token", text: $tokenCallerId)
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                }
                .background(RoundedRectangle(cornerRadius: 4)
                    .stroke(hasError ? Color(hex: "#D40000") : Color(hex: "#525252"), lineWidth: 2))
                
                Text("Caller Number")
                    .foregroundColor(.black)
                
                HStack {
                    TextField("Enter caller number", text: $callerIdNumber)
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                }
                .background(RoundedRectangle(cornerRadius: 4)
                    .stroke(hasError ? Color(hex: "#D40000") : Color(hex: "#525252"), lineWidth: 2))
                
                Text("Caller Name")
                    .foregroundColor(.black)
                
                HStack {
                    TextField("Enter caller name", text: $callerName)
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                }
                .background(RoundedRectangle(cornerRadius: 4)
                    .stroke(hasError ? Color(hex: "#D40000") : Color(hex: "#525252"), lineWidth: 2))
            } else {
                Text("Username")
                    .foregroundColor(.black)
                
                HStack {
                    TextField("Enter username", text: $username)
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(hex: "#525252"), lineWidth: 1)
                        )
                        .accessibilityIdentifier(AccessibilityIdentifiers.usernameTextField)
                }
                .background(RoundedRectangle(cornerRadius: 4)
                    .stroke(hasError ? Color(hex: "#D40000") : Color(hex: "#525252"), lineWidth: 2))
                
                Text("Password")
                    .foregroundColor(.black)
                
                HStack {
                    if isPasswordVisible {
                        TextField("Enter password", text: $password)
                            .padding(.horizontal, 10)
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "#525252"), lineWidth: 1)
                            )
                            .accessibilityIdentifier(AccessibilityIdentifiers.passwordTextField)
                    } else {
                        SecureField("Enter password", text: $password)
                            .padding(.horizontal, 10)
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "#525252"), lineWidth: 1)
                            )
                            .accessibilityIdentifier(AccessibilityIdentifiers.passwordTextField)
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(isPasswordVisible ? "Hide" : "View")
                            .foregroundColor(Color(hex: "#525252"))
                            .padding(.trailing, 10)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 4)
                    .stroke(hasError ? Color(hex: "#D40000") : Color(hex: "#525252"), lineWidth: 2))
                
                Text("Caller Number")
                    .foregroundColor(.black)
                
                HStack {
                    TextField("Enter caller number", text: $callerIdNumber)
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                        .accessibilityIdentifier(AccessibilityIdentifiers.callerNumberTextField)
                }
                .background(RoundedRectangle(cornerRadius: 4)
                    .stroke(hasError ? Color(hex: "#D40000") : Color(hex: "#525252"), lineWidth: 2))
                
                Text("Caller Name")
                    .foregroundColor(.black)
                
                HStack {
                    TextField("Enter caller name", text: $callerName)
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                        .accessibilityIdentifier(AccessibilityIdentifiers.callerNameTextField)
                }
                .background(RoundedRectangle(cornerRadius: 4)
                    .stroke(hasError ? Color(hex: "#D40000") : Color(hex: "#525252"), lineWidth: 2))
            }
            
            Spacer(minLength: 4)
            
            HStack(spacing: 12) {
                Button(action: {
                    let credential = SipCredential(username: isTokenLogin ? tokenCallerId : username,
                                                   password: isTokenLogin ? "" : password,
                                                   isToken: isTokenLogin,
                                                   callerName: callerName,
                                                   callerNumber: callerIdNumber)
                    onSignIn(credential, isEditMode, originalUsername)
                }) {
                    Text(isEditMode ? "Update" : "Sign In")
                        .font(.system(size: 16,weight: .semibold))
                        .foregroundColor(Color(hex: "#525252"))
                        .frame(width: 100)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#F5F3E4"))
                        .cornerRadius(20)
                        .accessibilityIdentifier(isEditMode ?
                                                 AccessibilityIdentifiers.updateCredentialButton :
                                                    AccessibilityIdentifiers.signInButton)
                }
                
                Button(action: { onCancel() }) {
                    Text("Cancel")
                        .font(.system(size: 16,weight: .semibold))
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 100)
                        .padding(.vertical, 12)
                        .background(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#1D1D1D"), lineWidth: 1)
                        )
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .background(.white)
            Spacer()
        }
        .padding(.horizontal, 5)
    }
}

#Preview {
    VStack {
        SipInputCredentialsView(
            username: "testuser",
            password: "password",
            isPasswordVisible: true,
            hasError: true,
            errorMessage: "That username/password combination does not match our records. Please try again."
        ) { credential, isEditMode, originalUsername in
            print("Signed in with: \(credential?.username ?? "nil"), Edit mode: \(isEditMode), Original username: \(originalUsername)")
        }
        
        SipInputCredentialsView(
            username: "edituser",
            password: "editpassword",
            isPasswordVisible: false,
            hasError: false,
            isTokenLogin: false,
            callerIdNumber: "+1234567890",
            callerName: "Edit User",
            isEditMode: true
        ) { credential, isEditMode, originalUsername in
            print("Updated credential: \(credential?.username ?? "nil"), Edit mode: \(isEditMode), Original username: \(originalUsername)")
        }
    }
}


