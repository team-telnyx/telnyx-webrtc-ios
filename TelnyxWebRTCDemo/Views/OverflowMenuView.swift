//
//  OverflowMenuView.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 2025-06-19.
//


import SwiftUI
import TelnyxRTC

struct OverflowMenuView: View {
    @Binding var showMenu: Bool
    @Binding var showPreCallDiagnosisSheet: Bool
    @Binding var showRegionMenu: Bool
    @Binding var selectedRegion: Region


    var body: some View {
        if showMenu {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { showMenu = false }

            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    MenuButton(title: "Pre-call Diagnosis", icon: "waveform.path.ecg") {
                        showMenu = false
                        showPreCallDiagnosisSheet = true
                    }
                    MenuButton(title: "Region: \(selectedRegion.rawValue)", icon: "globe") {
                        showMenu = false
                        showRegionMenu = true
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
                .padding()
            }
        }
    }
}

struct MenuButton: View {
    var title: String
    var icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .foregroundColor(.primary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}
