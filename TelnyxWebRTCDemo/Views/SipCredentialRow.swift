import SwiftUI

struct SipCredentialRow: View {
    @ObservedObject var viewModel: SipCredentialRowViewModel
    
    var body: some View {
        HStack {
            HStack {
                Text(viewModel.credential.username)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 16)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(viewModel.isSelected ? Color(hex: "#F5F3E4") : .white)
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.onSelect()
            }
            
            Spacer()
            HStack(spacing: 16) {
                if viewModel.isSelected {
                    Button(action: { viewModel.onEdit() }) {
                        Image("Edit")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 30, height: 30)
                    
                    Button(action: { viewModel.onDelete() }) {
                        Image("Delete")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 30, height: 30)
                }
            }
            .frame(width: 100, alignment: .center)
            .contentShape(Rectangle())
        }
        .onTapGesture {
            viewModel.isSelected.toggle()
        }
    }
}


#Preview {
    VStack {
        SipCredentialRow(
            viewModel: SipCredentialRowViewModel(
                credential: SipCredential(username: "test_user", password: ""),
                isSelected: true,
                onDelete: {},
                onEdit: {},
                onSelect: {}
            )
        )
        SipCredentialRow(
            viewModel: SipCredentialRowViewModel(
                credential: SipCredential(username: "gencredzGcUippdfjdfldsfsfdjnmnssdsdadcsn", password: ""),
                isSelected: false,
                onDelete: {},
                onEdit: {},
                onSelect: {}
            )
        )
    }
    .padding()
}
// MARK: - ViewModel para SipCredentialRow
class SipCredentialRowViewModel: ObservableObject {
    @Published var credential: SipCredential
    @Published var isSelected: Bool
    
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onSelect: () -> Void

    init(credential: SipCredential,
         isSelected: Bool,
         onDelete: @escaping () -> Void,
         onEdit: @escaping () -> Void,
         onSelect: @escaping () -> Void) {
        self.credential = credential
        self.isSelected = isSelected
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.onSelect = onSelect
    }
}
