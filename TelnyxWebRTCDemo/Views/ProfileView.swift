import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel

    let onAddProfile: () -> Void
    let onSwitchProfile: () -> Void
    
    var body: some View {
        VStack {
            Text("Profile")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(hex: "#525252"))
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                if viewModel.selectedProfile == nil {
                    Button(action: onAddProfile) {
                        Text("+ Add new profile")
                            .font(.system(size: 14).bold())
                            .foregroundColor(Color(hex: "#1D1D1D"))
                            .frame(width: 150)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#F5F3E4"))
                            .cornerRadius(16)
                    }
                } else {
                    HStack {
                        Text(viewModel.selectedProfile?.username ?? "")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color(hex: "1D1D1D"))
                            .frame(maxWidth: 150, alignment: .leading)
                            .lineLimit(1)
                        
                        Button(action: onSwitchProfile) {
                            Text("Switch Profile")
                                .font(.system(size: 14).bold())
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(hex: "#EBEBEB"))
                                .cornerRadius(16)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
