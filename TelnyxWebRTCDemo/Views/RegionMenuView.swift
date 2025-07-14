//
//  RegionMenuView.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 2025-06-19.
//
import SwiftUI
import TelnyxRTC


struct RegionMenuView: View {
    @Binding var showRegionMenu: Bool
    @Binding var selectedRegion: Region
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        if showRegionMenu {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { showRegionMenu = false }

            VStack {
                Spacer()
                VStack(spacing: 0) {
                    ForEach(Region.allCases, id: \.self) { region in
                        RegionRow(
                            region: region,
                            isSelected: region == selectedRegion,
                            isDisabled: viewModel.isRegionSelectionDisabled
                        ) {
                            if !viewModel.isRegionSelectionDisabled {
                                selectedRegion = region
                                showRegionMenu = false
                            }
                        }
                        Divider()
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 8)
                .padding()
            }
        }
    }
}

struct RegionRow: View {
    var region: Region
    var isSelected: Bool
    var isDisabled: Bool = false
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(isDisabled ? .gray : .blue)
                        .frame(width: 24)
                } else {
                    Spacer().frame(width: 24)
                }

                Text(region.rawValue)
                    .foregroundColor(isDisabled ? .gray : .primary)
                    .padding(.leading, 4)
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(isDisabled ? 0.5 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}
