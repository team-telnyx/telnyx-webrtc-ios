import SwiftUI

struct SipInputCredentialsView: View {
    @State private var username: String
    @State private var password: String
    @State private var isPasswordVisible: Bool
    @State private var hasError: Bool
    @State private var isTokenLogin: Bool = false
    @State private var tokenCallerId: String = ""
    @State private var callerIdNumber: String = ""
    @State private var callerName: String = ""
    
    let onSignIn: (SipCredential?) -> Void
    var onCancel: () -> Void
    
    init(username: String = "",
         password: String = "",
         isPasswordVisible: Bool = false,
         hasError: Bool = false,
         onSignIn: @escaping (SipCredential?) -> Void = { _ in },
         onCancel: @escaping () -> Void = {}) {
        self._username = State(initialValue: username)
        self._password = State(initialValue: password)
        self._isPasswordVisible = State(initialValue: isPasswordVisible)
        self._hasError = State(initialValue: hasError)
        self.onSignIn = onSignIn
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(alignment: .leading,
               spacing: 12) {
            if hasError {
                ErrorView(errorMessage: "That username/password combination does not match our records. Please try again.")
            }
            Toggle("Token Login", isOn: $isTokenLogin)
                .toggleStyle(SwitchToggleStyle(tint: .black))
                .padding(.bottom, 12)
            
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
                    } else {
                        SecureField("Enter password", text: $password)
                            .padding(.horizontal, 10)
                            .frame(height: 40)
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
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
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    let credential = SipCredential(username: username, password: password)
                    onSignIn(credential)
                }) {
                    Text("Sign In")
                        .font(.system(size: 16).bold())
                        .foregroundColor(Color(hex: "#525252"))
                        .frame(width: 100)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#F5F3E4"))
                        .cornerRadius(20)
                }
                
                Button(action: { onCancel() }) {
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
                Spacer()
            }
            .padding(.vertical, 12)
            .background(.white)
            Spacer()
        }.padding(.horizontal, 5)

    }
    
}

#Preview {
    SipInputCredentialsView(username: "testuser",
                            password: "password",
                            isPasswordVisible: true,
                            hasError: true) { credential in
        print("Signed in with: \(credential?.username ?? "nil")")
    }
}
