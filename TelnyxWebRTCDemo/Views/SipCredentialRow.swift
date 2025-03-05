import SwiftUI

struct SipCredentialRow: View {
    let credential: SipCredential
    let isSelected: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    @State private var showDeleteToast: Bool = false
    @State private var longPressInProgress: Bool = false
    @State private var deleteToastTimer: Timer? = nil
    
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
            HStack(spacing: 16) {
                if isSelected {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                    }
                    .frame(width: 16, height: 16)
                    .accessibilityIdentifier(AccessibilityIdentifiers.editCredentialButton)
                    
                    Button(action: {
                        if !showDeleteToast {
                            showDeleteToast = true
                            deleteToastTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                showDeleteToast = false
                            }
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.0)
                            .onChanged { _ in
                                longPressInProgress = true
                            }
                            .onEnded { _ in
                                longPressInProgress = false
                                showDeleteToast = false
                                deleteToastTimer?.invalidate()
                                onDelete()
                            }
                    )
                    .frame(width: 16, height: 16)
                    .accessibilityIdentifier(AccessibilityIdentifiers.deleteCredentialButton)
                }
            }
            .frame(width: 60, alignment: .center)
        }
        .overlay(
            Group {
                if showDeleteToast {
                    VStack {
                        Text("Hold down to delete")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .accessibilityIdentifier(AccessibilityIdentifiers.deleteToastMessage)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 40)
                    .transition(.opacity)
                    .animation(.easeInOut, value: showDeleteToast)
                }
            }
        )
    }
}

#Preview {
    VStack {
        SipCredentialRow(
            credential: SipCredential(username: "test_user", password: ""),
            isSelected: true,
            onDelete: {},
            onEdit: {}
        )
        SipCredentialRow(
            credential: SipCredential(username: "gencredzGcUippdfjdfldsfsfdjnmnssdsdadcsn", password: ""),
            isSelected: false,
            onDelete: {},
            onEdit: {}
        )
    }
    .padding()
}
