import SwiftUI

struct DTMFKeyboardView: View {
    @ObservedObject var viewModel: DTMFKeyboardViewModel
    let onClose: () -> Void
    let onDTMF: (String) -> Void
    
    private let keypadButtons = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"]
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("DTMF Dialpad")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.dtmfClose)
            }
            .padding(.horizontal)
            .padding(.top)
            
            TextField("", text: .constant(viewModel.displayText))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(true)
                .accessibilityIdentifier(AccessibilityIdentifiers.dtmfPad)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(keypadButtons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                onDTMF(key)
                                viewModel.displayText += key
                            }) {
                                Text(key)
                                    .font(.title)
                                    .foregroundColor(Color(hex: "#1D1D1D"))
                                    .frame(width: 70, height: 70)
                                    .background(Color(hex: "#F5F3E4"))
                                    .clipShape(Circle())
                            }
                            .accessibilityIdentifier(AccessibilityIdentifiers.dtmfKey(key))
                        }
                    }
                }
            }
        }
        .background(Color.white)
        Spacer()
    }
}

struct DTMFKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        DTMFKeyboardView(
            viewModel: DTMFKeyboardViewModel(),
            onClose: {},
            onDTMF: { _ in })
            .padding()
    }
}
