import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(Color(hex: "#D40000"))
            Text(errorMessage)
                .foregroundColor(.black)
                .font(.system(size: 14))
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding()
        .background(Color(hex: "#FDE6E6"))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(hex: "#D40000"), lineWidth: 1)
        )
        .cornerRadius(4)
    }
}

#Preview {
    ErrorView(errorMessage: "Error message")
}
