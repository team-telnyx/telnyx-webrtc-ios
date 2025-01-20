import SwiftUI

struct SipInputCredentialsView: View {
    @State private var username: String
    @State private var password: String
    @State private var isPasswordVisible: Bool
    @State private var hasError: Bool
    
    var onSignIn: () -> Void
    var onCancel: () -> Void
    
    init(username: String = "",
         password: String = "",
         isPasswordVisible: Bool = false,
         hasError: Bool = false,
         onSignIn: @escaping () -> Void = {},
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
            HStack(spacing: 12) {
                Button(action: { onSignIn() }) {
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
        }
    }
}

#Preview {
    Group {
        SipInputCredentialsView(username: "testuser",
                                password: "password",
                                isPasswordVisible: true,
                                hasError: true)
    }
}




