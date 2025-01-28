import SwiftUI

struct CallView: View {
    var body: some View {
        VStack {
            Text("Call View")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(hex: "#525252"))
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            // Add more UI elements for the connected state
        }
        .padding(.leading, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
